"""
This module is ...
"""
# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'



import logging
import os.path



def to_full_dir_path(path):
    return os.path.dirname(os.path.abspath(os.path.expandvars(os.path.expanduser(path))))

ROOT = "/niak"

class DOCKER:
    """
    Needed docker stuff
    """
    # Version of octave docker image used
    OCTAVE = "simexp/niak_dependency"
    FILE = "Dockerfile"

class TARGET:
    """ Path to the repo where the target lives
    """
    URL = "https://github.com/simexp/niak_target.git"
    WORK_DIR = "{}/work/targets".format(ROOT)
    PATH = "{}/niak_target".format(ROOT)
    RESULT_DIR = os.path.join(WORK_DIR, "result")# Niak default output
    AUTO_VERSION = False
    TAG_NAME = "0.13.1"


class NIAK:
    """
    Repo that will be used for the release
    """
    # Hash that will be used for the release
    REPO = "niak"
    HASH = ""
    # PATH = "/home/pquirion/simexp/software/niak"
    # PATH = "{}/niak".format(ROOT)
    PATH = "{}/niak".format(ROOT)
    URL = "https://github.com/simexp/niak.git"
    RELEASE_BRANCH = "niak-boss"
    DEV_BRANCH = "master"
    # RELEASE_BRANCH = ""
    TAG_NAME = "v0.13.1"
    # release Name
    DEPENDENCY_RELEASE = "niak-with-dependencies.zip"
    WORK_DIR = "{}/work/niak-{}".format(ROOT, TAG_NAME)

    VERSION_ENV_VAR = "NIAK_VERSION"


class PSOM:
    PATH = "{}/psom".format(ROOT)
    URL = "https://github.com/simexp/psom.git"
    RELEASE_TAG = "v1.2.0"

class BCT:
    url = "https://sites.google.com/site/bctnet/Home/functions/BCT.zip"


class GIT:
    API = "https://api.github.com"
    UPLOAD_API = "https://uploads.github.com"
    TOKEN = os.getenv("GIT_TOKEN")
    OWNER = "simexp"