"""
This module is ...
"""
# @TODO Write doc!
# @TODO Let config file path be set by from a init file so it can be share with niak octave more easily
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'



import logging
import os.path

class TARGET:
    """ Path to the repo where the target lives
    """
    URL = "https://github.com/poquirion/target_tests.git"
    WORK_DIR = "/niak/targets"
    PATH = "/home/pquirion/travail/simexp/software/target_tests"
    RESULT_DIR = os.path.join(WORK_DIR, "result")# Niak default output
    AUTO_VERSION = True

class NIAK:
    # PATH = "/home/pquirion/travail/simexp/software/niak"
    PATH = "/home/pquirion/travail/simexp/software/niak_test_auto"
    URL = "https://github.com/poquirion/docker_build.git"
    # RELEASE_BRANCH = "niak-bos"
    RELEASE_BRANCH = ""


#[psom]
class PSOM:
    PATH = "/home/pquirion/travail/simexp/software/psom"
    url = "https://github.com/poquirion/psom.git"


def to_full_dir_path(path):
    return os.path.dirname(os.path.abspath(os.path.expandvars(os.path.expanduser(path))))

