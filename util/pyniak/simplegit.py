"""
This is a simple class to implement things I need to do with git

"""

__author__ = 'poquirion'

import collections
import logging
import os
import queue
import subprocess
import sys
import signal
import time
import threading


# This way of dealing with error seems pretty crappy!
# but lets test before I make a better opinion
def stderror_handling(func):
    def wrapper_func(self, *args, **kwargs):
        # Invoke the wrapped function first
        did_fail = False
        stdout, stderr = func(self, *args, **kwargs)
        logging.info(stdout)
        if isinstance(stderr, str):
            stdout = stderr.splitlines()
        for line in stderr:
            if "warning" in line:
                logging.warning(line)
            elif "error" in line:
                logging.error(line)
                did_fail = False
            else:
                logging.warning(line)
            if self.fail_on_error and did_fail:
                # raise in the end so the full std_err logged
                raise ChildProcessError("Git has failed")

        if isinstance(stdout, str):
            stdout = stdout.splitlines()
        return stdout
    return wrapper_func


def clone(source, dest):

    r = Repo(dest)
    ret = r.clone(source, dest)

    if ret is None:
        r.initialize()
    return r


class Repo(object):

    __deleted_tag = "D"
    __modified_tag = "M"
    __untracked_tag = "??"
    __merge_strategy = ["ours", "theirs"]

    def __init__(self, path, fail_on_error=False):
        """

        :param path: the repo path
        :return:
        """
        self.path = path
        self.which_git = ["/usr/bin/env", "git"]
        self._activity = {}
        self._remote = None
        self._deleted = []
        self._modified = []
        self._untracked = []
        self._process_loop_sleep = 0.01
        self._timeout_once_done = 10
        self._init_sha1 = None
        self._init_branch = None
        self._new_branch = None
        self.fail_on_error = fail_on_error

        if os.path.isdir("{0}.git".format(self.path)):
            self.initialize()
            # Todo load origin

    def initialize(self):
        self._init_sha1 = self.sha1()
        self._init_branch = self.branch(None)
        # self._init_branches = self.branch(None)

    @property
    def init_branch(self):
        return self._init_branch

    @property
    def init_hash(self):
        return self._init_sha1

    @stderror_handling
    def git_go(self, cmd, cwd=None):
        """

        :param cmd: the git command to execute
        :return: std out and std err
        """
        # Cleaning before each call

        if cwd is None:
            cwd = self.path
        if not cwd:
            cwd = None

        stderr = []
        stdout = []
        self._activity = {}
        stdout_is_close = False
        stderr_is_close = False
        process_is_done = False
        completion_time = 0

        # Running the process
        logging.info("running {0}".format(" ".join(self.which_git+cmd)))
        logging.info("  in {0}".format(cwd))
        p = subprocess.Popen(self.which_git+cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # p = subprocess.Popen(self.which_git+cmd, cwd=cwd)

        # Put logs in threat to avoid dead lock
        stdout_queue = queue.Queue()
        stderr_queue = queue.Queue()
        stdout_monitor_thread = threading.Thread(
            target=self.read_from_stream,
            args=(p.stdout, self._activity, stdout_queue, True),
            )
        stderr_monitor_thread = threading.Thread(
            target=self.read_from_stream,
            args=(p.stderr, self._activity, stderr_queue, True),
            )
        stdout_monitor_thread.daemon = True
        stdout_monitor_thread.start()
        stderr_monitor_thread.daemon = True
        stderr_monitor_thread.start()

        while not (process_is_done and (stdout_is_close and stderr_is_close)):
            now = time.time()

            # If the subprocess is dead/done, we exit the loop.
            if p.poll() is not None:
                process_is_done = True

            # Once the process is done, we keep
            # receiving standard out/err up until we reach the done_timeout.
            if (completion_time > 0) and (self._timeout_once_done > 0) \
                    and (now - completion_time > self._timeout_once_done):
                break

            # Handle the standard output from the child process
            if process_is_done:
                while not stdout_queue.empty():
                    stdout.append(stdout_queue.get_nowait())
                stdout_is_close = True
            if process_is_done:
                while not stderr_queue.empty():
                    stderr.append(stderr_queue.get_nowait())
                stderr_is_close = True

            # Start the countdown for the done_timeout
            if process_is_done and not completion_time:
                completion_time = now
            #
            # Sleep a bit to avoid using too much CPU while waiting for execution to be done.
            time.sleep(self._process_loop_sleep)

        return_code = p.poll()
        return stdout, stderr

    @staticmethod
    def read_from_stream(stream, activity, std_queue=None, echo=False):
        for line in iter(stream.readline, b''):
            if std_queue:
                std_queue.put(line.decode('utf-8'))
            activity['last'] = time.time()
            if echo:
                sys.stderr.write(line.decode('utf-8'))
        stream.close()

    def show_ref(self):
        """
        A sha1 can point to many ref tags
        :return: A dictionary with
                  {sha1: [ref_tag1, ref_tag2], sha1, [ref_tag3]}
        """

        cmd = ["show-ref"]
        refs = self.git_go(cmd=cmd)
        refs_dico = collections.defaultdict(list)
        # format the dico according to doc
        for ref in refs:
            k, v = ref.split()
            refs_dico[k].append(v)

        return refs_dico

    def clone(self, source, dest):
        """

        :param source: an url or path
        :param dest: The repo path
        :return:
        """

        cmd = ["clone", source, dest]
        return self.git_go(cmd, cwd=False)

    def checkout(self, reference, force=False):
        """
        :param reference: Can be a branch, a tag, a commit...
        :return: The error string or None if successful
        """

        if not reference:
            reference = " "

        cmd = ["checkout"]
        if force:
            cmd.append("-f")
        cmd.append(reference)
        return self.git_go(cmd, cwd=self.path)


    def reset(self, commit, hard=False):

        cmd = ["reset"]
        if hard:
            cmd.append("--hard")
        cmd.append(commit)
        return self.git_go(cmd, cwd=self.path)

    def pull(self, branch=None, remote_name=None):
        if branch is None:
            branch = "master"
        if remote_name is None:
            remote_name = "origin"

        cmd = ["pull", remote_name, branch]
        return self.git_go(cmd, cwd=self.path)

    def tag(self, name, force=False):

        cmd = ["tag", name]
        if force:
            cmd.append("-f")
        return self.git_go(cmd, cwd=self.path)

    def push(self, branch=None, remote_name=None, push_tags=None):

        if remote_name is None:
            remote_name = "origin"

        cmd = ["push", remote_name]
        if branch:
            cmd.append(branch)
        if push_tags:
            cmd.append("--tags")
        return self.git_go(cmd, cwd=self.path)


    def merge(self, to_branch, from_branch, strategy=None):


        if strategy is None:
            cmd = ["merge", from_branch]
        elif strategy in self.__merge_strategy:
            cmd = ["merge", strategy, from_branch]
        else:
            message = ("Merge strategy \"{0}\" not supported, use {1}"
                       .fromat(strategy, self.__merge_strategy))
            raise IOError(message)

        self.checkout(to_branch)
        cmd = ["merge", from_branch]
        return self.git_go(cmd, cwd=self.path)

    def add_all(self):

        cmd = ["add", "-A"]

        return self.git_go(cmd, cwd=self.path)

    def commit(self, message, add_all=True):

        if add_all:
            option = "-am"
        else:
            option = "-m"

        cmd = ["commit", option, '"{0}"'.format(message)]

        return self.git_go(cmd, cwd=self.path)

    def branch(self, name=None, checkout=False, delete=False):
        """
        :param name: branch name or None or ""
        :param checkout: Will checkout the branch
        :param delete: If true Force delete the 'name' branch
        :return: If name is a "False" boolean, returns the current branch name
        """
        cmd = ["branch"]
        if name is not None:
            cmd.append(name)
            if delete:
                cmd.append("-D")

        out = self.git_go(cmd)

        if checkout:
            self.checkout(name)

        if name is None:
            for o in out:
                if o.startswith("*"):
                    _out = o.split()[1]
                    return _out

        return out

    def sha1(self):
        """
        :return: the actual git sha1 hash
        """
        cmd = ["rev-parse", "--verify", "HEAD"]
        out = self.git_go(cmd=cmd)
        return str(out[0])

    def status(self):
        """
            update repo status
            modified_files
            deleted files
            added files

        :return:
        """
        cmd = ["status", "-s"]

        out = self.git_go(cmd=cmd)
        for line in out:
            line = line.strip()
            if line.startswith(self.__deleted_tag):
                self._deleted.append(line.split()[-1])
            elif line.startswith(self.__untracked_tag):
                self._untracked.append(line.split()[-1])
            elif line.startswith(self.__modified_tag):
                self._modified.append(line.split()[-1])
        return out




def test_func():
    repo_url = "https://github.com/poquirion/empty_repo.git"
    destination = os.path.expanduser("~/test/")
    g = clone(repo_url, destination)

    with open("{0}/toto".format(destination),"w") as fp:
        fp.write("HELLO")

    g.status()



if __name__ == '__main__':

    test_func()