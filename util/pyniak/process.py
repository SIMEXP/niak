"""
This module runs octave modules
"""
# @TODO Write doc!
# @TODO Remove hard coded path and reference to config inside methods
# @TODO Make the exception - crash system more robust (except, finally)
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'

from distutils.version import LooseVersion
import io
import simplejson as json
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
import urllib.request
import zipfile

# TODO Add these in setup.py
import git
import psutil
import requests

try:
    from . import config
    from . import simplegit
except SystemError:
    import config
    import simplegit

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
        if return_code != 0:
            logging.error("The process has exited with the following return code: {}".format(return_code))
        else:
            logging.info("The process was completed and returned 0 (success)")

        if self.error_from_log and self._activity['error']:

            logging.error( "The subprocess return code is {}, it has also logged line with"
                           " \"error\" in them\nreturning ".format(return_code))
            retval = input("Do you want to continue process? Y/[N]")
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


def delete_git_asset(repo_owner, repo_name, tag, asset_name):
    """ Delete the assset "asset_name" of the git release "repo_owner/repo_name:tag"
    :param repo_owner: the repo owner
    :param repo_name: the repo name
    :param tag: the release tag
    :param asset_name: the asset name
    :return:
    """
    import requests
    GIT = config.GIT

    headers = {"Accept": "application/vnd.github.manifold-preview",
                "Authorization": "token {}".format(config.GIT.TOKEN)}
    url = "{api}/repos/{owner}/{repo}/releases".format(api=GIT.API, owner=repo_owner, repo=repo_name)

    get = urllib.request.Request(url=url)

    to_be_deleted_id = None
    with urllib.request.urlopen(url=get) as fp:
        reply = json.loads(fp.read().decode('utf-8'))
        for elem in reply:
            if elem['tag_name'] == tag and elem.get("assets") is not None:
                for asset in elem["assets"]:
                    if asset["name"] == asset_name:
                        to_be_deleted_id = asset["id"]

    if to_be_deleted_id is None:
        print("The asset does not exist")
        return

    del_url = "{api}/repos/{owner}/{repo}/releases/assets/{asset_id}"\
        .format(api=GIT.API, owner=repo_owner, repo=repo_name, asset_id=to_be_deleted_id)
    requests.delete(url=del_url, headers=headers)

def upload_release_to_git(repo_owner, repo_name, tag, file_path, asset_name):
    """A convenience method to upload release file to github

    :param repo_owner: the repo owner
    :param repo_name: the repo name
    :param tag: the release tag
    :param file_path: the file to upload
    :return: the upload post reply

    """
    logging.info("Preparing {} to {}/{} tag {}".format(file_path, repo_owner, repo_name, tag))
    GIT = config.GIT

    headers = {"Accept": "application/vnd.github.manifold-preview",
                "Authorization": "token {}".format(GIT.TOKEN)}


    # find the github  release id using the release tag
    url = "{api}/repos/{owner}/{repo}/releases".format(api=GIT.API, owner=repo_owner, repo=repo_name)
    get = urllib.request.Request(url=url)

    with urllib.request.urlopen(url=get) as fp:
        reply = json.loads(fp.read().decode('utf-8'))
        upload_url, git_id = next(((elem["upload_url"], elem["id"])
                            for elem in reply if elem['tag_name'] == tag), (None, None))

    # Release needs to be created before file is upload
    if git_id is None:
        data = json.dumps({"tag_name": tag, "name": tag, "body": "Complete release",
                           "draft": False, "prerelease": False}).encode(encoding='UTF-8')
        headers.update({"Content-Type": "application/json",
                        "Content-Length": len(data)})
        post = urllib.request.Request(url=url, headers=headers, data=data)
        with urllib.request.urlopen(url=post) as fp:
            reply = json.loads(fp.read().decode('utf-8'))
            upload_url, git_id = reply["upload_url"], reply["id"]

    # upload the file to the release
    if os.path.isfile(file_path):
        dir, file = os.path.split(file_path)
    else:
        raise FileNotFoundError(file_path)
    with open(file_path, "rb") as fp:

        upload_url = re.sub("\{.*\}", "?name={}".format(asset_name), upload_url)

        length = os.path.getsize(file_path)
        headers.update({"Content-Type": "application/zip",
                        "Content-Length": length})

        post = urllib.request.Request(url=upload_url, data=fp, headers=headers)
        #
        logging.info("url:\n{}\nheaders:\n{}".format(upload_url, headers))
        logging.info("uploading {} to github".format(file_path))
        with urllib.request.urlopen(url=post) as reply:
                return json.loads(reply.read().decode('utf-8'))


class TargetRelease(object):
    """
    Used for releasing targets

    """

    TAG_PREFIX = "target_test_niak_mnc1-"

    TARGET_NAME_IN_NIAK = "gb_niak_target_test"

    NIAK_GB_VARS = "commands/misc/niak_gb_vars.m"

    UNCOMMITTED_CHANGE = "Changes to be committed:"

    NOTING_TO_COMMIT = "nothing to commit, working directory clean"

    AT_ORIGIN = "Your branch is up-to-date with 'origin"

    TMP_BRANCH = '_TMP_RELEASE_BRANCH_'

    def __init__(self, target_path=None, niak_path=None, target_name=None,
                 niak_tag=None, dry_run=False, recompute_target=False,
                 result_dir=None, release_target=True, niak_url=None, psom_path=None,
                 psom_url=None, push_niak_release=False, niak_release_from_branch=None,
                 niak_release_from_commit=None, force_niak_release=False):


        # TODO add a niak_release_from_commit option, right now release can only be done
        #       from the tip of a the niak_release_from_branch
        # , niak_release_commit=None):

        niak_release_branch = config.NIAK.RELEASE_BRANCH
        # target tag name
        self.target_name = target_name

        self.target_path = target_path if target_path else config.TARGET.PATH

        self.niak_path = niak_path if niak_path else config.NIAK.PATH
        self.niak_url = niak_url if niak_url else config.NIAK.URL
        self.psom_path = psom_path if psom_path else config.PSOM.PATH
        self.psom_url = psom_url if psom_url else config.PSOM.URL

        # Where the new target is computed
        self.result_dir = result_dir if result_dir else config.TARGET.RESULT_DIR

        self.niak_release_branch = niak_release_branch if niak_release_branch else config.NIAK.RELEASE_BRANCH

        self.release_target = release_target

        self.recompute_target = recompute_target

        self.work_dir = config.TARGET.WORK_DIR

        self.dry_run = dry_run

        # the name of the release
        self.niak_tag = niak_tag if niak_tag else config.NIAK.TAG_NAME

        # release from branch release
        self.niak_release_from_branch = niak_release_from_branch if \
            niak_release_from_branch else config.NIAK.RELEASE_FROM_BRANCH

        # the name of the release
        self.niak_release_commit = niak_release_from_commit if \
            niak_release_from_commit else config.NIAK.RELEASE_FROM_COMMIT

        self.push_niak_release = push_niak_release
        self.force_niak_release = force_niak_release


        self._sanity_check()

        self.niak_repo = simplegit.Repo(self.niak_path)

        self.niak_repo.branch(self.TMP_BRANCH, delete=True)

        self._log_path = config.TARGET.LOG_PATH

    @property
    def tag_w_prefix(self):
        return self.TAG_PREFIX + self.tag

    def auto_tag(self, repo_path, tag_name=None):

        repo = git.Repo(repo_path)

        old_tags = [t.name.replace(self.TAG_PREFIX, "") for t in repo.tags if self.TAG_PREFIX in t.name]


        old_tags = sorted(old_tags, key=LooseVersion, reverse=True)
        new_tag = None

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
                answers = input("are you happy with that? Y/[N]")

                if answers != "Y":
                    answers = input("What name should it be? type [Quit] to exit\n"
                                    "Do not input the target prefix {}".format(self.TAG_PREFIX))
                    if answers != "Quit":
                        new_tag = answers
                    else:
                        raise IOError("not happy with the release tag name!")


        repo.create_tag("{0}{1}".format(self.TAG_PREFIX, new_tag), force=True)

        return new_tag

    def _execute(self, cmd, cwd=None):
        logging.info("Executing \nin {0}: {1}".format(cwd, " ".join(cmd)))
        ret = subprocess.check_output(cmd, cwd=cwd, universal_newlines=True)
        logging.info("returning \n{}".format(ret))
        return ret

    def _sanity_check(self, take_action=True):
        """
            Runs series of test before it it good to go
            This should grow with time!

        :type take_action bool
        :return:
        """

        errors = []
        warning = []
        if os.getenv('GIT_TOKEN') is None:
            errors.append('GIT_TOKEN Missing from your environment, '
                          'take action before you continue!')
        else:
            logging.info('GIT_TOKEN is in your environment')

        # check if niak is at the right place
        if os.path.isdir(os.path.join(self.niak_path, '.git')):
            logging.info("The niak repo seems in place")
        else:
            if take_action:
                logging.info('cleaning niak directory')
                shutil.rmtree(self.niak_path, ignore_errors=True)
                logging.info('cloning niak')
                # git.Repo.clone_from(self.niak_url, self.niak_path)
                simplegit.clone(self.niak_url, self.niak_path)

            else:
                errors.append('"{}" is not a Niak/git repo'.format(self.niak_path))

        # check if psom is at the right place
        if os.path.isdir(os.path.join(self.psom_path, '.git')):
            logging.info("The psom repo is in place")
        else:
            if take_action:
                logging.info('cleaning psom directory')
                shutil.rmtree(self.psom_path, ignore_errors=True)
                logging.info('cloning niak')
                simplegit.clone(self.psom_url, self.psom_path)
                # git.Repo.clone_from(self.psom_url, self.psom_path)
            else:
                errors.append('"{}" is not a Niak/git repo '.format(self.psom_path))

        if errors:
            logging.error(errors)
            raise Exception(errors)

    def start(self):

        self.repo_prerelease_setup(branch=self.niak_release_from_branch
                                   , sha1=self.niak_release_commit)

        if self.release_target:
            if self.recompute_target:
                self.delete_target_log()
            self._build()
            pass
        # if self.niak_release_branch:
        self._release()

        self._finaly()

    def repo_prerelease_setup(self, branch=None, sha1=None):
        """ Move the repo to the revision to be released.
            Targets can only be released at the tip of a branch
            Niak can be released at any revision (branch and commit)
        :param branch: The name of the dev branch to release from
        :return:
        """

        if self.release_target:
            if branch is None:
                raise IOError("can only release target from a specific branch")
            if sha1 is not None:
                ref_dico = self.niak_repo.show_ref()
                if sha1 in ref_dico:
                    for ref in ref_dico[sha1]:
                        if branch in ref:
                            # ALL set!
                            break
                        #  NO
                        m = ("To release a target, the sha1 ref must be at "
                             "the tip a a branch sha1 {} is not in branch {} "
                             .format(sha1, branch))
                        raise IOError(m)
            self.niak_repo.checkout(branch, force=True)
        else:
            if sha1 is not None:
                # Releasing form hash, the release_from_branch will not be updated
                self.niak_repo.checkout(sha1, force=True)
            else:
                self.niak_repo.checkout(branch, force=True)


    def delete_target_log(self):
        """ Delete the target logs so it recomputes

        :return:
        """
        if os.path.isdir(self._log_path):
            os.removedirs(self._log_path)


    def _build(self):
        """
        build the target with niak_test_all

        Returns
        -------
        bool
            True if successful, False otherwise.
        """
        target = TargetBuilder(niak_path=self.niak_path, work_dir=self.work_dir
                               , error_form_log=True,)
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
            target = simplegit.clone(config.TARGET.URL, target_path)
        if branch is not None:
            target.pull(branch=branch)
            target.checkout(branch)
        else:
            target.pull()

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

        if self._commit(self.result_dir, "Automatically built target") is None:
            logging.error("New target is similar to old one, "
                          "nothing needs to be updated")

            return None

        self.tag = self.auto_tag(self.result_dir, self.target_name)

    def _push(self, path, push_tag=False, remote_name=None, branch=None):
        #TODO let change to non defaut
        repo = simplegit.Repo(path)
        # remote = repo.remote(remote_name=remote_name)
        # logging.info("pushing {} to {}".format(path, remote[remote_name]))
        repo.push(remote_name=remote_name, branch=branch)
        if push_tag:
            repo.push(remote_name=remote_name, branch=branch, push_tags=push_tag)


    def _commit(self, path, comment, branch=None, files=None, tag=None):
        """
        Add all change, add and remove files and then commit

        branch: if None, will be commited to current branch

        file : will only add and commit these
        """

        repo = simplegit.Repo(path)

        if branch:
            logging.info("checking out branch {} in ".format(branch, path))
            if branch:
                repo.branch(branch, checkout=True)

        repo.add_all()

        repo.commit(comment)

        if tag:
            logging.warning("Adding tag {} to {} repo".format(tag, path))
            repo.tag(tag, force=True)

        return True

    def _update_niak(self):
        """
        point to the right zip file
        """

        niak_gb_vars_path = os.path.join(self.niak_path, self.NIAK_GB_VARS)
        docker_file = os.path.join(self.niak_path, config.DOCKER.FILE)

        # Update version
        with open(niak_gb_vars_path, "r") as fp:
            rfp = fp.read()
            fout = re.sub("gb_niak_version = .*",
                          "gb_niak_version = \'{}\';".format(self.niak_tag.replace('v', '')), rfp)
            if self.release_target:
                    fout = re.sub("gb_niak_target_test = .*",
                                  "gb_niak_target_test = \'{}\';".format(self.tag), rfp)


        with open(niak_gb_vars_path, "w") as fp:
            fp.write(fout)

        with open(docker_file, "r") as fp:
            fout = re.sub("ENV {}.*".format(config.NIAK.VERSION_ENV_VAR),
                          "ENV {0} {1}".format(config.NIAK.VERSION_ENV_VAR,
                                               self.niak_tag), fp.read())

        with open(docker_file, "w") as fp:
            fp.write(fout)

        self._commit(self.niak_path, "Updated target name", files=[self.NIAK_GB_VARS, config.DOCKER.FILE],
                     branch=self.TMP_BRANCH)

    def _release(self):
        """
        Pushes the target to the repo and update niak_test_all and niak_gb_vars

        Returns
        -------
        bool
            True if successful, False otherwise.

        """
        if self.release_target:
            self._update_target()

        try:
            self._update_niak()
        except BaseException as e:
            self._cleanup()
            raise e

        if not self.dry_run:

            self._merge(self.niak_repo, self.niak_release_branch, self.TMP_BRANCH, self.niak_tag)

            if self.push_niak_release:
                self._push(self.niak_path, push_tag=True, branch=self.niak_release_branch)

            if self.release_target:
                # The tmp branch is also merge to the "release from"
                # branch so this development branch also point to the right target

                # Push target
                self._push(self.result_dir, push_tag=True, branch="master")
                # merge and push niak
                self._merge(self.niak_repo, self.niak_release_from_branch, self.TMP_BRANCH)
                self._push(self.niak_path, push_tag=True, branch=self.niak_release_from_branch)

            zip_file_path = self._build_niak_with_dependecy()

            if self.push_niak_release:
                if self.force_niak_release:
                # Delete the release if it already exist and repush it.
                    delete_git_asset(config.GIT.OWNER, config.NIAK.REPO,
                                     self.niak_tag, config.NIAK.DEPENDENCY_RELEASE)
                upload_release_to_git(config.GIT.OWNER, config.NIAK.REPO,
                                      self.niak_tag, zip_file_path, config.NIAK.DEPENDENCY_RELEASE)

        else:
            self._cleanup()



    def _build_niak_with_dependecy(self):
        """
        Take the released version and bundle it with psom and BCT in a zip file
        :return: the path to the zip file
        """

        if os.path.isdir(config.NIAK.WORK_DIR):
            shutil.rmtree(config.NIAK.WORK_DIR)
        ## HERE REFREACTOR!!!
        # Niak
        shutil.copytree(self.niak_path, config.NIAK.WORK_DIR)
        n_repo = simplegit.Repo(config.NIAK.WORK_DIR)
        n_repo.checkout(config.NIAK.RELEASE_BRANCH)
        shutil.rmtree(config.NIAK.WORK_DIR+"/.git")
        # PSOM
        p_repo = simplegit.Repo(config.PSOM.PATH)
        p_repo.checkout(config.PSOM.RELEASE_TAG)
        shutil.copytree(config.PSOM.PATH, config.NIAK.WORK_DIR+"/extensions/psom-{}".format(config.PSOM.RELEASE_TAG))
        shutil.rmtree(config.NIAK.WORK_DIR+"/extensions/psom-{}/.git".format(config.PSOM.RELEASE_TAG))

        # BCT
        BCTZIP = urllib.request.urlopen(config.BCT.url)
        with zipfile.ZipFile(io.BytesIO(BCTZIP.read())) as z:
            z.extractall(config.NIAK.WORK_DIR+"/extensions/BCT")

        # the base_dir funky stuff is the way to include the leading directory in zip...
        filename, ext = os.path.splitext(config.NIAK.DEPENDENCY_RELEASE)
        shutil.make_archive(config.NIAK.WORK_DIR+"/../"+filename,
                            ext[1:], root_dir=config.NIAK.WORK_DIR+"/../",
                            base_dir="niak-{}".format(self.niak_tag))

        return config.NIAK.WORK_DIR+"/../"+config.NIAK.DEPENDENCY_RELEASE

    def _merge(self, repo, branch1, branch2, tag=None):
        """
        Merge branch2 to branch1
        @TODO Force branch 2 to win every time
        this will prevent merging problems

        :param repo: a simplegit repo
        :param branch1: The branch that receive the merge (does not need to exist)
        :param branch2: The branch that provide the merge (need to exist)
        :param tag: Tag to be added to branch1
        :return: None
        """
        repo.branch(branch1, checkout=True)
        repo.merge(branch1, branch2)

        repo.commit("New Niak Release {0}{0}"
                    .format(self.niak_release_branch, tag))
        if tag is not None:
            repo.tag(tag, force=True)


    def _finaly(self):
        """
        Delete tmp branch and checkout to the tip of the original branch
        :return:
        """
        self.niak_repo.checkout(self.niak_repo._init_branch, force=True)
        self.niak_repo.branch(name=self.TMP_BRANCH, delete=True)

    def _cleanup(self):
        """
        Checkout niak modified file
        Make sure that we are back in the init repo
        Delete the TMP BRANCH and the local release branch
        :return:
        """
        self.niak_repo.checkout(self.niak_repo._init_branch, force=True)
        self.niak_repo.reset(self.niak_repo._init_sha1, hard=True)
        self.niak_repo.branch(self.TMP_BRANCH, delete=True)
        self.niak_repo.branch(self.niak_release_branch, delete=True)



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
    MT_ROOT = [MT, "{0}:{0}".format(config.ROOT)]
    ENV_DISPLAY = ["-e", "DISPLAY=unix$DISPLAY"]
    USER = ["--user", str(os.getuid())]
    IMAGE = [config.DOCKER.IMAGE]

    def __init__(self, work_dir, niak_path, error_form_log=False):

        super().__init__(error_form_log=error_form_log)

        #TODO make them arg not kwargs
        self.niak_path = niak_path
        self.work_dir = work_dir

        if not os.path.isdir(self.work_dir):
            os.makedirs(self.work_dir)

        mt_work_dir = [self.MT, "{0}:{0}".format(self.work_dir)]

        self.load_niak = \
            "addpath(genpath('{}'))".format(self.niak_path)


        # Only builds the target
        cmd_line = ['/bin/bash', '--login',  '-c',
                    "cd {0}; octave "
                    "--eval \"{1};opt = struct(); path_test = struct() ; "
                    "opt.flag_target=true; OPT.flag_test=true ; niak_test_all(path_test,opt)\""
                    .format(self.work_dir, self.load_niak)]

        # convoluted docker command
        self.docker = (self.DOCKER_RUN + self.FULL_PRIVILEDGE + self.RM + self.MT_HOME +
                       self.MT_SHADOW + self.MT_GROUP + self.MT_PASSWD + self.MT_X11 + self.MT_ROOT +
                       self.MT_TMP + mt_work_dir + self.ENV_DISPLAY + self.USER + self.IMAGE + cmd_line)

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
        oct_process = subprocess.Popen(self.docker)

        stdout, stderr = oct_process.communicate()

        logging.info(stdout)
        logging.error(stderr)

    def test_all(self):
        # niak test all

        options = []

        opt = ','.join(options)

        self._execute("niak_test_all({0})".format(opt))



if __name__ == "__main__":

    logging.basicConfig(level=logging.DEBUG)
    # release = TargetRelease()
    # release._build_niak_with_dependecy()

    # delete_git_asset("poquirion", "niak", "v0.13.4", "niak-with-dependencies.zip")
    # upload_release_to_git("poquirion", "niak", "v0.13.4", "/niak/work/niak-with-dependencies.zip"
    #                       , "niak-with-dependencies.zip")
