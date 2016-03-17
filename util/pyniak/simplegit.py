"""
This is a simple class to implement things I need to do with git

"""

__author__ = 'poquirion'

import os
import queue
import subprocess
import sys
import signal
import time
import threading

# This way of dealing with error seems pretty crappy!
# but lets test before I make a better opinion
def std_return_on_error(func):
    def wrapper_func(*args, **kwargs):
        # Invoke the wrapped function first
        stdout, stderr = func(*args, **kwargs)
        print(stdout)
        if stderr:
            print(stderr)
            # raise ChildProcessError ("Git has failed")
            return stderr
        return stdout, stderr
    return wrapper_func


def clone(source, dest):

    r = Repo(dest)
    ret = r._clone(source, dest)

    if ret is None:
        r._initialize()
    return r


class Repo(object):

    __deleted_tag = "D"
    __modified_tag = "M"
    __untracked_tag = "??"
    __merge_strategy = ["ours", "theirs"]

    def __init__(self, path):
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
        self._init_hash = None
        self._init_branch = None
        self._new_branch = None

        if not os.path.isdir(".git/{0}".format(self.path)):
            self._initialize()
            #Todo load origin


    def _initialize(self):
        # self.which_git = "/usr/bin/git"
        self._init_hash, _ = self.hash()
        self._init_branch, _ = self.branch(None)
        self._init_branches, _ = self.branch(None)


    def _clean(self, commit=None, branch=None):
        """
        Remove commit or branch added after
        _initialize has been called

        :param commit: True to revert all
        :param branch: only delete the given branch
        :return:
        """
        pass

    def git_go(self, cmd, cwd=None):
        """

        :param cmd: the git command to execute
        :return: std out and std err
        """
        # Cleaning before each call
        stderr = []
        stdout = []
        self._activity = {}
        stdout_is_close = False
        stderr_is_close = False
        process_is_done = False
        completion_time = 0

        # Running the process
        print("running {0}".format(" ".join(self.which_git+cmd)))
        print("  in {0}".format(cwd))
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
                interrupt_the_process = False
                stdout_is_close = True
            if process_is_done:
                while not stderr_queue.empty():
                    stderr.append(stderr_queue.get_nowait())
                interrupt_the_process = False
                stderr_is_close = True

            # Start the countdown for the done_timeout
            if process_is_done and not completion_time:
                completion_time = now
            #
            # Sleep a bit to avoid using too much CPU while waiting for execution to be done.
            time.sleep(self._process_loop_sleep)

        return_code = p.poll()

        if return_code is None:

            if interrupt_the_process:
                print("The git process is running (PID {0}). Sending it an "
                      "interrupt signal...".format(p.pid))
                p.send_signal(signal.SIGKILL)

            # Let the subprocess die peacefully...
            time_to_wait = self._timeout_once_done
            while time_to_wait > 0 and p.poll() is None:
                time.sleep(0.1)
                time_to_wait -= 0.1

            # Force the process to die if it's still running.
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

    # @property
    # def remote(self):
    #     if self._remote is None:
    #         if not self.initialized:
    #             raise IOError("Repo at {0} no initialised yet".format(self.path))
    #
    #         self._remote =
    #
    #     return self._remote

    @std_return_on_error
    def remote(self, remote_name=None):
        """

        :param remote_name:
        :return: a dictionary
                {remote_name: url}
        """


        return {}

    @std_return_on_error
    def _clone(self, source, dest):
        """

        :param source: an url or path
        :param dest: The repo path
        :return:
        """

        cmd = ["clone", source, dest]
        return self.git_go(cmd, cwd=None)


    @std_return_on_error
    def checkout(self, *args, force=False):
        """

        :param args: any of git checkout args
        :return: The error string or None if successful
        """

        cmd = ["checkout"]
        if force:
            cmd.append("-f")
        cmd.extend(args)
        return self.git_go(cmd, cwd=self.path)


    @std_return_on_error
    def reset(self, commit, hard=False):

        cmd = ["reset"]
        if hard:
            cmd.append("--hard")
        cmd.append(commit)
        return self.git_go(cmd, cwd=self.path)


    @std_return_on_error
    def pull(self, branch="master", remote_name="origin"):

        cmd = ["pull", remote_name, branch]
        return self.git_go(cmd, cwd=self.path)

    @std_return_on_error
    def tag(self, name, force=False):

        cmd = ["tag", name]
        if force:
            cmd.append("-f")
        return self.git_go(cmd, cwd=self.path)

    @std_return_on_error
    def push(self, branch="master", remote_name="origin", push_tags=None):

        cmd = ["push", remote_name, branch]
        if push_tags:
            cmd.append("--tags")
        return self.git_go(cmd, cwd=self.path)


    @std_return_on_error
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

    @std_return_on_error
    def add_all(self):

        cmd = ["add", "-A"]

        return self.git_go(cmd, cwd=self.path)

    @std_return_on_error
    def commit(self, message, add_all=True):

        if add_all:
            option = "-am"
        else:
            option = "-m"

        cmd = ["commit", option, '"{0}"'.format(message)]

        return self.git_go(cmd, cwd=self.path)

    @std_return_on_error
    def branch(self, name= None, checkout=False, delete=False):
        """
        :param name: branch name or None or ""
        :param checkout: Will checkout the branch
        :return: If name is a "False" boolean, returns the current branch name
        """
        cmd = ["branch"]
        if name is not None:
            cmd.append(name)
            if delete:
                cmd.append("-D")

        out, err = self.git_go(cmd)

        if checkout:
            self.checkout(name)

        if name is None:
            for o in out:
                if o.startswith("*"):
                    _out = o.split()[0]
                    return _out, err

        return out, err

    @std_return_on_error
    def hash(self):
        """
        :return: the actual git hash
        """
        cmd = ["rev-parse", "--verify", "HEAD"]
        out, err = self.git_go(cmd=cmd)
        if isinstance(out, str):
            return out, err
        else:
            return str(out[0]), err

    @std_return_on_error
    def status(self):
        """
            update repo status
            modified_files
            deleted files
            added files

        :return:
        """
        cmd = ["status", "-s"]

        out, err = self.git_go(cmd=cmd)

        if err:
            return out, err
        else:
            for line in out.splitlines():
                line = line.strip()
                if line.startswith(self.__deleted_tag):
                    self._deleted.append(line.split()[-1])
                elif line.startswith(self.__untracked_tag):
                    self._untracked.append(line.split()[-1])
                elif line.startswith(self.__modified_tag):
                    self._modified.append(line.split()[-1])
                else:
                    err_m = "{0} is not a recognise git status".format(line)
                    return out, err_m
        return out, None




def test_func():
    repo_url = "https://github.com/poquirion/empty_repo.git"
    destination = os.path.expanduser("~/test/")
    g = clone(repo_url, destination)

    with open("{0}/toto".format(destination),"w") as fp:
        fp.write("HELLO")

    g.status()



if __name__ == '__main__':

    test_func()