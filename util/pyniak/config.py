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
    HASH = ""
    # PATH = "/home/pquirion/simexp/software/niak"
    # PATH = "{}/niak".format(ROOT)
    PATH = "{}/niak".format(ROOT)
    URL = "https://github.com/simexp/niak.git"
    RELEASE_BRANCH = "niak-bos"
    DEV_BRANCH = "master"
    # RELEASE_BRANCH = ""
    TAG_NAME = "v0.13.1"

class PSOM:
    PATH = "{}/psom".format(ROOT)
    url = "https://github.com/simexp/psom.git"
    tag = "v1.2.0"

