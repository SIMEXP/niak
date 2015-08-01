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

class DOCKER:
    """
    Needed docker stuff
    """
    # Version of octave docker image used
    OCTAVE = "simexp/niak_dependency"


class TARGET:
    """ Path to the repo where the target lives
    """
    URL = "https://github.com/poquirion/target_tests.git"
    WORK_DIR = to_full_dir_path("~/simexp/work/targets")
    PATH = "/home/poquirion/simexp/target_tests"
    RESULT_DIR = os.path.join(WORK_DIR, "result")# Niak default output
    AUTO_VERSION = False
    TAG_NAME = "0.13.1"


class NIAK:
    # PATH = "/home/pquirion/simexp/software/niak"
    PATH = "/home/poquirion/simexp/niak"
    URL = "https://github.com/poquirion/docker_build.git"
    RELEASE_BRANCH = "niak-bos"
    # RELEASE_BRANCH = ""
    TAG_NAME = "v0.13.1"


#[psom]
class PSOM:
    PATH = "/home/poquirion/simexp/psom"
    url = "https://github.com/poquirion/psom.git"


