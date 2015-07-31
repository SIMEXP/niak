"""
This module runs octave modules
"""
# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'

from distutils.version import StrictVersion, LooseVersion
import logging
import os
import queue
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

import git
import psutil

try:
    from . import config
except SystemError:
    import config


class Error(Exception):
    """
    Base exception for this module
    """
    pass


class Runner(object):
    """
    Class that can be used to execute script
    TODO write a parent class that will be used to build runner for other software (niak)
    """

    def __init__(self, error_form_log=False):
        """
        "super" the __ini__ in your class and fill the
        self.subprocess_cmd as a minimum
        """
        self.subprocess_cmd = []

        self.error_from_log = error_form_log
        self.cancel = False
        self._activity = {'last': None, 'error': None}
        self._timeout_once_done = 5 # in seconds
        self.sleep_loop = 0.05

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

        if self.error_from_log and self._activity['error']:

            logging.error( "The subprocess return code is {}, it has also logged line with"
                           " \"error\" in them\nreturning ".format(return_code))
            # retval = input("Do you want to continue process? Y/[N]")
            retval = "Y" ## DEBUG !!!
            if retval == "Y":
                return_code = 0
            else:
                return_code = 1

        return return_code


    @staticmethod
    def read_from_stream(stream, activity, std_queue=None, echo=False):
        error = re.compile("error", re.IGNORECASE)
        for line in iter(stream.readline, b''):
            if std_queue:
                std_queue.put(line)
                std_queue.put("error line!!!")
            if error.search(line.decode('utf-8')):
                activity["error"] = True
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

    GIT_CMD = ["/usr/bin/env", "git"]

    TAG_PREFIX = "target_test_niak_mnc1-"

    TARGET_NAME_IN_NIAK = "gb_niak_target_test"

    NIAK_GB_VARS = "commands/misc/niak_gb_vars.m"

    UNCOMMITTED_CHANGE = "Changes to be committed:"

    NOTING_TO_COMMIT = "nothing to commit, working directory clean"

    AT_ORIGIN = "Your branch is up-to-date with 'origin"

    TMP_BRANCH = 'TMP_BRANCH'

    def __init__(self, target_path=None, niak_path=None, target_name=None, work_dir=None,
                 release_branch=False, dry_run=False, recompute_target=False, result_dir=None):

        self.target_name = target_name
        self.target_path = target_path if target_path else config.TARGET.PATH
        self.niak_path = niak_path if niak_path else config.NIAK.PATH
        self.result_dir = result_dir if result_dir else config.TARGET.RESULT_DIR

        self.recompute_target = recompute_target

        self.release_branch = release_branch

        self.work_dir = work_dir

        self.dry_run = dry_run

        # the name of the release
        self.tag = None

    @property
    def tag_w_prefix(self):
        return self.TAG_PREFIX + self.tag

    def auto_tag(self, repo_path, tag_name=None):

        repo = git.Repo(repo_path)

        old_tags = [t.name.replace(self.TAG_PREFIX, "") for t in repo.tags if self.TAG_PREFIX in t.name]


        old_tags = sorted(old_tags, key=LooseVersion, reverse=True)

        if config.TARGET.AUTO_VERSION and not tag_name:
            new_tag = old_tags[0].split('.')
            new_tag[-1] = str(int(new_tag[-1]) + 1)
            new_tag = ".".join(new_tag)
            print("Here are the used tags {0}{1}\n"
                  "The tag will be {0}{2} :".format(self.TAG_PREFIX, old_tags, new_tag))

        else:
            while not new_tag:
                new_tag = tag_name
                print("Here are the used tags {0}{1}\n"
                      "The tag will be {0}{2} :".format(self.TAG_PREFIX, old_tags, new_tag))

                #TODO check if format is right
                answers = input("are you happy with that? [Y]/N")

                if answers != "Y":
                    answers = input("What name should it be? type [Quit] to exit\n"
                                    "Do not input the target prefix {}".format(self.TAG_PREFIX))
                    if answers != "Quit":
                        new_tag = answers
                    else:
                        raise IOError("not happy with the release tag name!")


        repo.create_tag("{0}{1}".format(self.TAG_PREFIX, new_tag))

        return new_tag

    def _execute(self, cmd, cwd=None):
        logging.info("Executing \nin {0}: {1}".format(cwd, " ".join(cmd)))
        ret = subprocess.check_output(cmd, cwd=cwd, universal_newlines=True)
        logging.info("returning \n{}".format(ret))
        return ret

    def start(self):

        if self.recompute_target:
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
        target = TargetBuilder(error_form_log=True, niak_path=self.niak_path, work_dir=self.work_dir)
        ret_val = target.run()
        happiness = input("Are you happy with the target?Y/[N]")
        logging.info("look at {}/logs for more info".format(self.work_dir))

        if ret_val != 0 or happiness != 'Y':
            raise Error("The target was not computed properly")

    def _pull_target(self, target_path=None, branch=None):
        """
        If target exit pull latest version, if not creates repo

        Will checkout the branch "branch"
        """
        target_path = target_path if target_path else self.target_path

        if not os.path.isdir(target_path):
            git.Repo.clone_from(config.TARGET.URL, target_path)
        target = git.Repo(target_path)
        remote = target.remote()
        remote.pull()
        if branch:
            br = target.refs[branch]
            br.checkout()

    def _update_target(self):
        """
        copy the .git directory in the Niak result dir so the repo can be updated
        """
        # do not remove the git info!

        self._pull_target(self.target_path, branch="master")

        res_git = os.path.join(self.result_dir, ".git")
        # remove repo in the result dir if already present
        if os.path.isdir(res_git):
            shutil.rmtree(res_git)

        shutil.copytree(os.path.join(self.target_path, ".git"), res_git)

        if self._commit(self.result_dir, "Automatically built target", branch=self.TMP_BRANCH) is None:
            logging.error("New target is similar to old one, "
                          "nothing needs to be updated")

            return None

        self.tag = self.auto_tag(self.result_dir, self.target_name)
        if not self.dry_run:
            self._push(self.result_dir, push_tag=True)


    def _push(self, path, push_tag=False):

        repo = git.Repo(path)
        remote = repo.remote()
        remote.push(tags=push_tag)

    def _commit(self, path, comment, branch = None,  file=None):
        """
        Add all change, add and remove files and then commit

        branch: if None, will be comited to current branch

        file : will only add and commit these
        """

        repo = git.Repo(path)

        new_files = repo.untracked_files
        if file is not None:
            new_files = [f for f in new_files if new_files in file]
            modif_files = [diff.a_path for diff in repo.index.diff(None)
                           if not diff.deleted_file and diff.a_path in file]
            del_files = [diff.a_path for diff in repo.index.diff(None)
                         if diff.deleted_file and diff.a_path in file]
        else:
            modif_files = [diff.a_path for diff in repo.index.diff(None) if not diff.deleted_file]
            del_files = [diff.a_path for diff in repo.index.diff(None) if diff.deleted_file]

        if not new_files and not modif_files and not del_files:
            logging.info("Noting to be added or commited in {}".format(repo))
            return None
        repo.index.remove(del_files)
        repo.index.add(new_files+modif_files)

        if branch:
            logging.info("committing to branch {}", format(branch))
            tmp_branch = repo.create_head(branch)
            tmp_branch.checkout()

        repo.index.commit(comment)
        return True

    def _update_niak(self, test_run=False):
        """
        point to the right zip file
        """
        # must be up to date
        repo = git.Repo(self.niak_path)
        diff = [d.a_path for d in repo.index.diff(None)]

        niak_gb_vars = os.path.join(self.niak_path, self.NIAK_GB_VARS)

        if self.NIAK_GB_VARS not in diff:
            with open(niak_gb_vars, "r") as fp:
                fout = re.sub("gb_niak_target_test =.*", "gb_niak_target_test = {}".format(self.tag), fp.read())
            with open(niak_gb_vars, "w") as fp:
                fp.write(fout)
        else:

            logging.error("Uncommitted change in {}".format(niak_gb_vars))
            raise Error("git file needs to be clean {}".format(niak_gb_vars))

        self._commit(config.NIAK.PATH, "Updated target name", file=self.NIAK_GB_VARS, branch=self.TMP_BRANCH)

        if not self.dry_run:
            self._push(config.NIAK.PATH)

    def _release(self):
        """
        Pushes the target to the repo and update niak_test_all and niak_gb_vars

        Returns
        -------
        bool
            True if successful, False otherwise.

        """
        # update target repo and push
        self._update_target()
        self._update_niak()


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
    MT_TMP = [MT, "{0}:{0}".format(tempfile.gettempdir())]
    MT_PASSWD = [MT, "/etc/passwd:/etc/passwd"]
    MT_X11 = [MT, "/tmp/.X11-unix:/tmp/.X11-unix"]
    MT_HOME = [MT, "{0}:{0}".format(os.getenv("HOME"))]
    ENV_DISPLAY = ["-e", "DISPLAY=unix$DISPLAY"]
    USER = ["--user", str(os.getuid())]
    IMAGE = [config.DOCKER.OCTAVE]

    def __init__(self, work_dir=None, niak_path=None, psom_path=None, error_form_log=False):

        super().__init__(error_form_log=error_form_log)

        #TODO make them arg not kwargs
        self.niak_path = niak_path if niak_path else config.NIAK.PATH
        self.psom_path = psom_path if psom_path else config.PSOM.PATH
        self.work_dir = work_dir if work_dir else config.TARGET.WORK_DIR

        if not os.path.isdir(self.work_dir):
            os.mkdir(self.work_dir)


        mt_work_dir = [self.MT, "{0}:{0}".format(self.work_dir)]

        self.load_niak_psom = \
            "addpath(genpath('{0}'));addpath(genpath('{1}'))".format(self.psom_path, self.niak_path)


        # Only builds the target
        cmd_line = ['/bin/bash', '-c',
                    "cd {0} ;source /opt/minc-itk4/minc-toolkit-config.sh; octave "
                    "--eval \"{1};opt = struct(); path_test = struct() ; "
                    "opt.FLAG_TARGET=true; OPT.FLAG_TEST=true ; niak_test_all(path_test,opt)\""
                    .format(self.work_dir, self.load_niak_psom)]

        # convoluted docker command
        self.docker = self.DOCKER_RUN + self.FULL_PRIVILEDGE + self.RM + self.MT_HOME + self.MT_SHADOW + self.MT_GROUP \
                      + self.MT_PASSWD + self.MT_X11 + self.MT_TMP + mt_work_dir + self.ENV_DISPLAY + self.USER \
                      + self.IMAGE + cmd_line

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