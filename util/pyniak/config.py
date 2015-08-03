"""
This module is ...
"""
# @TODO Write doc!
# @TODO Let config file path be set by from a init file so it can be share with niak octave more easily
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
    PATH = "{}/pniak".format(ROOT)
    URL = "https://github.com/poquirion/pniak.git"
    RELEASE_BRANCH = "niak-bos"
    DEV_BRANCH = "master"
    # RELEASE_BRANCH = ""
    TAG_NAME = "v0.13.1"


#[psom]
# class PSOM:
#     PATH = "/home/poquirion/simexp/psom"
#     url = "https://github.com/poquirion/psom.git"


