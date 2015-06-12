"""
This module is an executable that should be able
- to create a niak target and, give it a name (default is YYYY-MM-DD).
- to update the target link in the niak distro.
- push the target to a git repo (or lfs) with the name as a tag.
"""


import argparse
import os
import sys

from ..pyniak import target


# @TODO Write doc!
__author__ = 'Pierre-Olivier Quirion <pioliqui@gmail.com>'

def main(args=None):


    if args is None:
        args = sys.argv[1:]

    parser = argparse.ArgumentParser(description='Create and release new Niak target')

    parser.add_argument('--path', '-p', help='the path to the Niak repo')


    parser.add_argument('--release', '-r', action='store_true', help='if True, will push the target to the'
                                                                     'repo and update Niak so niak_test_all point '
                                                                     'to the target')

    parsed = parser.parse_args(args)

    if parsed.path:
        path = os.path.abspath(os.path.expanduser(parsed.path))
    else:
        # this file in one down the git directory!
        path = os.join(os.path.dirname(os.path.abspath(__file__)), '..')


    new_target = target.Release(niak_path=path, release=parsed.release)




if __name__ == "__main__":
    main()

