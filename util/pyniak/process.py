"""
This module runs octave modules
"""
# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'

from distutils.version import StrictVersion, LooseVersion
import logging
import os
import psutil
import queue
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

try:
    from . import config
except SystemError:
    import config



class Runner(object):
    """
    Class that can be used to execute script
    TODO write a parent class that will be used to build runner for other software (niak)
    """

    def __init__(self):
        """
        "super" the __ini__ in your class and fill the
        self.subprocess_cmd as a minimum
        """
        self.subprocess_cmd = []

        self.cancel = False
        self._activity = {}
        self._timeout_once_done = 5 # in seconds
        self.sleep_loop = 0.05
        self._activity = {}

    def run(self):
        """

        :return: the return value of the executed process
        """

        cmd = self.subprocess_cmd
        logging.info('Executing {0}'.format(" ".join(cmd)))

        child = subprocess.Popen(cmd,
                                 stderr=subprocess.PIPE,
                                 stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE,
                                 bufsize=1)

        completion_time = 0
        process_is_done = False
        stdout_is_close = False
        interrupt_the_process = False

        # (stdout, stderr) = child.communicate()

        stdout_queue = queue.Queue()
        stdout_monitor_thread = threading.Thread(
            target=self.read_from_stream,
            args=(child.stdout, self._activity, stdout_queue, True),
            )

        stdout_monitor_thread.daemon = True
        stdout_monitor_thread.start()

        stderr_monitor_thread = threading.Thread(
            target=self.read_from_stream,
            args=(child.stderr, self._activity, None, True),
            )
        stderr_monitor_thread.daemon = True
        stderr_monitor_thread.start()

        stdout_lines = []
        while not (process_is_done or stdout_is_close):

            now = time.time()

            # We need to cancel the processing!
            if self.cancel:
                logging.info('The execution needs to be stopped.')
                break

            # If the subprocess is dead/done, we exit the loop.
            if child.poll() is not None:
                logging.info("Subprocess is done.")
                process_is_done = True

            # Once the process is done, we keep
            # receiving standard out/err up until we reach the done_timeout.
            if (completion_time > 0) and (self._timeout_once_done > 0) and (now - completion_time > self._timeout_once_done):
                logging.info("Done-timeout reached.")
                break

            # TODO Check if that is really necessary
            # If there is nothing received from child process, either from the
            # standard output or the standard error streams, past a given amount
            # of time, we assume that the sidekick is done/dead.
            # if (self.inactivity_timeout > 0) and (now - self._activity['last'] > self.inactivity_timeout):
            #     logging.info("Inactivity-timeout reached.")
            #     break

            # Handle the standard output from the child process
            if child.stdout:
                while not stdout_queue.empty():
                    stdout_lines.append(stdout_queue.get_nowait())
            else:
                interrupt_the_process = False
                stdout_is_close = True
                process_is_done = True

            # Start the countdown for the done_timeout
            if process_is_done and not completion_time:
                completion_time = now

            # Sleep a bit to avoid using too much CPU while waiting for execution to be done.
            time.sleep(self.sleep_loop)

        return_code = child.poll()

        if return_code is None:

            if interrupt_the_process:
                logging.info("The sidekick is running (PID {0}). Sending it an interrupt signal..."
                             .format(child.pid))
                child.send_signal(signal.SIGTERM)


            # Let the subprocess die peacefully...
            time_to_wait = self._timeout_once_done
            while time_to_wait > 0 and child.poll() is None:
                time.sleep(0.1)
                time_to_wait -= 0.1

            # Force the process to die if it's still running.
            return_code = child.poll()
            if return_code is None:
                logging.info("The sidekick is still running (PID {}). Sending it a kill signal..."
                             .format(child.pid))
                self.force_stop(child)

        return_code = child.poll()
        if return_code == 0:
            logging.error("The process has exited with a non-zero return code: {}".format(return_code))
        else:
            logging.info("The process was completed and returned 0 (success)")

        return return_code


    @staticmethod
    def read_from_stream(stream, activity, std_queue=None, echo=False):
        for line in iter(stream.readline, b''):
            if std_queue:
                std_queue.put(line)
            activity['last'] = time.time()
            if echo:
                sys.stderr.write(line.decode('utf-8'))
        stream.close()

    @staticmethod
    def force_stop(sub_proc, including_parent=True):
        """
        Stops the execution of process and of its children
        :param sub_proc a process with a pid attribute:
        :param including_parent:
        :return:
        """
        parent = psutil.Process(sub_proc.pid)
        logging.info("Killing the sub-processes using psutil.")
        for child in parent.children(recursive=True):
            child.kill()
        if including_parent:
            parent.kill()


class TargetRelease(object):
    """
    Used for releasing targets

    """

    GIT_CMD = "/usr/bin/env git "

    RESULT_DIR = "results/"

    TAG_PREFIX = "target_test_niak_mnc1-"

    TARGET_NAME_IN_NIAK = "gb_niak_target_test"

    NIAK_GB_VARS = "commands/misc/niak_gb_vars.m"

    IS_UP_TO_DATE = "Your branch is up-to-date with 'origin/master'."


    def __init__(self, tag=None, target_path=None, niak_path=None, release_branch=False):

        self.tag_number = tag
        self.target_path = target_path if target_path else tempfile.mkdtemp()
        self.niak_path = niak_path if niak_path else config.NIAK.PATH

        self.release_branch = release_branch


    @property
    def tag_w_prefix(self):
        return self.TAG_PREFIX + self.tag

    def auto_tag(self, repo):

        tag_cmd = [self.GIT_CMD, "tag"]

        all_tag = subprocess.check_output(tag_cmd, universal_newlines=True, cwd=repo).splitlines()


        tag = [t.replace(self.TAG_PREFIX, "") for t in all_tag]


        new_tag = ""

        while new_tag not in all_tag.split():
            new_tag = input("Here are the used tags {}\n What TAG should this release have?\nuse X.X format\n:".format(all_tag))
            #TODO check if format is right
            if new_tag in all_tag:
                print("Tag needs to be new, try again")

        self._execute([self.GIT_CMD, "tag", "{0}{1}".format(self.TAG_PREFIX, new_tag)], cwd=repo)

        return new_tag

    def commit_to_branch(self, source_version, branch_name, repo, tag_name=None):
        """
            Merge the version to be release in the designated branch
        """

        if tag_name is None:
            tag_name = self.tag = self.auto_tag(repo)

        git = self.GIT_CMD

        git_cmds = []

        co = [git, "checkout  {0}".format(branch_name)]
        merge  = [git, "merge {} -X theirs".format(source_version)]
        tag  = [git, "tag {}".format(tag_name)]

        git_cmds = [co, merge, tag]

        for cmd in git_cmds:
            self._execute(cmd, repo)

    def _execute(self, cmd, cwd):

        return subprocess.check_output(cmd, cwd=cwd, universal_newlines=True)


    def start(self):

        self._build()

        if self.release_branch:
            self._release()



    def _build(self):
        """
        build the target with niak_test_all

        Returns
        -------
        bool
            True if successful, False otherwise.
        """
        target = TargetBuilder(work_dir=self.target_path)
        ret_val = target.run()


    def _pull_target(self):
        """
        If target exit pull latest version, if not creates repo

        """

        if not os.path.isdir(config.TARGET.PATH):
            self._execute([self.GIT_CMD, "clone", config.TARGET.URL, config.TARGET.PATH])


        self._execute([self.GIT_CMD + 'pull'], cwd=config.TARGET.PATH)



    def _update_target(self, test_run=False):
        """
        replace old target with newly computed one
        """
        # do not remove the git info!

        to_be_removed = [os.path.join(a, config.TARGET.PATH)
                         for a in os.listdir(config.TARGET.PATH) if a != '.git']

        for d in to_be_removed:
            shutil.rmtree(d)

        result_path = os.path.join(config.TARGET.WORK_DIR, self.RESULT_DIR)
        to_be_moved = [os.path.join(a, config.TARGET.PATH) for a in os.listdir(result_path)]

        for d in to_be_moved:
            shutil.move(d, config.TARGET.PATH)

        self._commit(config.TARGET.PATH, "Automatically built target")
        self.tag = self.auto_tag(config.TARGET.PATH)
        self._push(config.TARGET.PATH, push_tags=True)


    def _push(self, path, push_tag=False):

        if push_tag:
            follow_tag = "--follow-tags"

        self._execute([self.GIT_CMD, 'push', follow_tag], cwd=path)

    def _commit(self, path, comment):
        """
        Add all change and commit
        """

        self._execute([self.GIT_CMD, 'add', '-A'], cwd=path)
        self._execute([self.GIT_CMD, 'commit', '-m', "'{}'".format(comment)], cwd=path)


    def _update_niak(self, test_run=False):
        """
        point to the right zip file
        """
        # must be up to date
        git_output = self._execute([self.GIT_CMD, "status"], cwd=config.NIAK.PATH)
        niak_gb_vars = os.path.join(config.NIAK.PATH, self.NIAK_GB_VARS)

        if self.IS_UP_TO_DATE in git_output:
            with open(niak_gb_vars, "rt").read() as fin:

                fout = re.sub("gb_niak_target_test =.*", "gb_niak_target_test = {}".format(self.tag), fin)

            with open(niak_gb_vars, "wt") as fp:
                fp.write(fout)
        self._commit(config.NIAK.PATH, "Updated target name")

        self._push(config.NIAK.PATH)

    def _release(self, test_run=False):
        """
        Pushes the target to the repo and update niak_test_all and niak_gb_vars

        Returns
        -------
        bool
            True if successful, False otherwise.

        """
        # update target repo and push
        self._update_target(test_run=test_run)
        self._update_niak(test_run=test_run)


class TargetBuilder(Runner):
    """ This class is used to release niak target

    """

    # DOCKER OPT CST
    MT = "-v"
    DOCKER_RUN = ["docker", "run"]
    FULL_PRIVILEDGE = ["--privileged"]
    RM = ["--rm"]
    MT_SHADOW = [MT, "/etc/shadow:/etc/shadow"]
    MT_GROUP = [MT, "/etc/group:/etc/group"]
    MT_PASSWD = [MT, "/etc/passwd:/etc/passwd"]
    MT_X11 = [MT, "/tmp/.X11-unix:/tmp/.X11-unix"]
    MT_HOME = [MT, "{0}:{0}".format(os.getenv("HOME"))]
    ENV_DISPLAY = ["-e", "DISPLAY=unix$DISPLAY"]
    USER = ["--user", str(os.getuid())]
    IMAGE = ["simexp/octave"]

    def __init__(self, work_dir=None, niak_path=None, psom_path=None):

        super().__init__()

        self.niak_path = niak_path if niak_path else config.NIAK.PATH
        self.psom_path = psom_path if psom_path else config.PSOM.PATH
        self.work_dir = work_dir if work_dir else config.TARGET.WORK_DIR

        if not os.path.isdir(self.work_dir):
            os.mkdir(self.work_dir)


        self.load_niak_psom = \
            "addpath(genpath('{0}'));addpath(genpath('{1}'))".format(self.psom_path, self.niak_path)


        # Only builds the target
        cmd_line = ['/bin/bash', '-c',
                    "cd {0} ;source /opt/minc-itk4/minc-toolkit-config.sh; octave "
                    "--eval \"{1};{{0}};opt = struct; opt.FLAG_TARGET=true ; niak_test_all(opt)\""
                    .format(self.work_dir, self.load_niak_psom)]

        # convoluted docker command
        self.docker = self.DOCKER_RUN + self.FULL_PRIVILEDGE + self.RM + self.MT_HOME + self.MT_SHADOW + self.MT_GROUP \
                        + self.MT_PASSWD + self.MT_X11 + self.ENV_DISPLAY + self.USER + self.IMAGE + cmd_line

        self.subprocess_cmd = self.docker


class OctavePortal(Runner):
    """ This class is used to execute octave code

        @todo Make the tool more sophisticated by having a pipe to
            a continuously running octave process that listen to stdin
            and run lines using eval(cmd) in octave

        @todo create a mapping dictionary for niak to pyniak fct

    """

    # DOCKER OPT CST

    MT = "-v"
    DOCKER_RUN = ["docker", "run"]
    FULL_PRIVILEDGE = ["--privileged"]
    RM = ["--rm"]
    MT_SHADOW = [MT, "/etc/shadow:/etc/shadow"]
    MT_GROUP = [MT, "/etc/group:/etc/group"]
    MT_PASSWD = [MT, "/etc/passwd:/etc/passwd"]
    MT_X11 =  [MT, "/tmp/.X11-unix:/tmp/.X11-unix"]
    MT_HOME = [MT, "{0}:{0}".format(os.getenv("HOME"))]
    ENV_DISPLAY = ["-e", "DISPLAY=unix$DISPLAY"]
    USER = ["'--user", str(os.getuid())]
    IMAGE = ["simexp/octave"]

    def __init__(self, work_dir=None):

        self.bin = ["/usr/bin/env", "octave", "--eval"]

        self.load_niak_psom = \
            "addpath(genpath('{0}'));addpath(genpath('{1}'))".format(config.NIAK.PATH, config.PSOM.PATH)

        # target dir as default'
        self.work_dir = work_dir if work_dir else config.TARGET.WORK_DIR

        if not os.path.isdir(self.work_dir):
            os.mkdir(self.work_dir)

        cmd_line = ['/bin/bash', '-c',
                    "cd {0} ;source /opt/minc-itk4/minc-toolkit-config.sh; octave --eval \"{1};{{0}}\""
                    .format(self.work_dir, self.load_niak_psom)]

        # convoluted docker command
        self.docker = self.DOCKER_RUN + self.FULL_PRIVILEDGE + self.RM + self.MT_SHADOW + self.MT_GROUP \
                        + self.MT_PASSWD + self.MT_X11 + self.ENV_DISPLAY + self.USER + self.IMAGE + cmd_line



    def _execute(self, cmds):
        """
        calls octave
        """
        if isinstance(cmds, str):
            cmds = [cmds]

        cmds = ';'.join(cmds)

        self.docker[-1] = self.docker[-1].format(cmds)

        logging.info("executing {0}".format(self.docker))
        print("executing {0}".format(' '.join(self.docker)))
        print("executing \n\t{0}".format(' '.join(self.docker)))
        oct_process = subprocess.Popen(self.docker)

        stdout, stderr = oct_process.communicate()

        logging.info(stdout)
        logging.error(stderr)

    def test_all(self, flag_target=True):
        # niak test all

        options = []

        if flag_target:
            options.append('OPT.FLAG_TARGET=true')

        opt = ','.join(options)

        self._execute("niak_test_all({0})".format(opt))



if __name__ == "__main__":

    # logging.basicConfig(level=logging.DEBUG)
    # release = TargetBuilder()
    # release.run()

    t = TargetRelease()

    t.auto_tag(config.NIAK.PATH)