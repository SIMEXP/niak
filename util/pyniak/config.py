"""
This module is ...
"""
# @TODO Write doc!
# @TODO Let config file path be set by env vars
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'


import logging
import os.path

class TARGET:
    """ Path to the repo where the target lives
    """
    URL = "https://github.com/poquirion/target_tests.git"
    WORK_DIR = "/tmp"
    PATH = "/home/pquirion/travail/simexp/software/target_tests"

class NIAK:
    # PATH = "/home/pquirion/travail/simexp/software/niak"
    PATH = "/home/pquirion/travail/simexp/software/niak"
    URL = "https://github.com/poquirion/niak_test.git"
    # RELEASE_BRANCH = "niak-bos"
    RELEASE_BRANCH = ""


#[psom]
class PSOM:
    PATH = "/home/pquirion/travail/simexp/software/psom"
    url = "https://github.com/poquirion/psom.git"


def to_full_dir_path(path):
    return os.path.dirname(os.path.abspath(os.path.expandvars(os.path.expanduser(path))))

