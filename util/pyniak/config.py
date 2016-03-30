"""
This module is ...
"""
# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'



import logging
import os.path

DEBUG = False

def to_full_dir_path(path):
    return os.path.dirname(os.path.abspath(os.path.expandvars(os.path.expanduser(path))))

if DEBUG:
    import getpass
    ROOT = "/niak/niak_debug"
    USER = getpass.getuser()
else:
    ROOT = "/niak"

class DOCKER:
    """
    Docker Config
    """
    # Version of octave docker image used
    IMAGE = "simexp/niak_dependency"
    FILE = "Dockerfile"

class TARGET:
    """
        Target config
    """
    if DEBUG:
        URL = "https://github.com/poquirion/niak_target.git"
    else:
        URL = "https://github.com/simexp/niak_target.git"

    WORK_DIR = "{}/work/target".format(ROOT)
    PATH = "{}/niak_target".format(ROOT)
    RESULT_DIR = os.path.join(WORK_DIR, "result")  # Niak default output
    AUTO_VERSION = False
    # TAG_NAME is typically "X.Y.Z"
    TAG_NAME = "0.15.6"
    LOG_PATH = "{}/result/logs".format(WORK_DIR)


class NIAK:
    """
    Niak release Config
    """
    # Hash that will be used for the release
    REPO = "niak"
    HASH = ""
    PATH = "{}/niak".format(ROOT)
    if DEBUG:
        URL = "https://github.com/poquirion/niak.git"
    else:
        URL = "https://github.com/simexp/niak.git"
    RELEASE_BRANCH = "niak-boss"
    RELEASE_FROM_BRANCH = "master"
    RELEASE_FROM_COMMIT = "c26f8a83190255540cf09cd7a3d260b61e2a7c16"  # If none will release from tip

    # RELEASE_BRANCH = ""
    TAG_NAME = "v0.13.5"
    # release Name
    DEPENDENCY_RELEASE = "niak-with-dependencies.zip"
    WORK_DIR = "{}/work/niak-{}".format(ROOT, TAG_NAME)

    VERSION_ENV_VAR = "NIAK_VERSION"


class PSOM:
    """
    PSOM config
    """

    PATH = "{}/psom".format(ROOT)
    if DEBUG:
        URL = "https://github.com/poquirion/psom.git"
    else:
        URL = "https://github.com/simexp/psom.git"
# URL = "https://github.com/poquirion/psom.git"
    RELEASE_TAG = "v1.2.0"


class BCT:
    """
    BCT config
    """
    url = "https://sites.google.com/site/bctnet/Home/functions/BCT.zip"


class GIT:
    """
    GIT api config
    Do not forget to setup you git token! 
    You get one on git hub and set it as en env var in your .bashrc.
    """
    API = "https://api.github.com"
    UPLOAD_API = "https://uploads.github.com"
    TOKEN = os.getenv("GIT_TOKEN")
    if DEBUG:
        OWNER = "poquirion"
    else:
        OWNER = "simexp"
