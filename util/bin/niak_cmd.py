#!/usr/bin/env python2
"""
This module parse arbitrary NIAK opt arguments to run a pipeline with the needed inputs
"""
__author__ = 'poquirion'



import argparse
import os
import re
import sys
import subprocess

sys.path.append("../")


OPTION_PREFIX = "--opt"
ESCAPE_STRING = "666_____666_____666"

SUPPORTED_PIPES = ["niak_pipeline_fmri_preprocess"]

# class prefixArgParser(argparse.ArgumentParser)
#
#     def __init__(self, option):
#         super().__init__()


def build_opt(option):

    parser = argparse.ArgumentParser(description="All options")

    command = []
    for i, o in enumerate(option):
        if OPTION_PREFIX in o:
            # option[i] = o.replace("-", ESCAPE_STRING)
            option[i] = re.sub("(\w)-(\w)","\g<1>{}\g<2>".format(ESCAPE_STRING), o)
            parser.add_argument(option[i], nargs='+')

    parsed = parser.parse_known_args(option)
    print(parser)

    for k, v in parsed[0].__dict__.items():
        command += ["{}=\'{}\'".format(k.replace(ESCAPE_STRING, "."), " ".join(v))]

    return command


class ParseInputDir( object ):
    def __init__(self, pipe_name):
        pass


def main(args=None):

    if args is None:
        args = sys.argv[1:]

    parser = argparse.ArgumentParser(description='Create and release new Niak target')

    parser.add_argument("--file_in")

    parser.add_argument("--folder_out")

    parsed, options = parser.parse_known_args(args)

    opt_list = ["opt=struct"]

    opt_list += ["file_in=struct"]

    opt_list += build_opt(options)

    opt_list += ["opt.folder_out=\'{}\'".format(parsed.folder_out)]

    # Todo find a good strategyy to load subject
    # % Structural scan
    opt_list += ["files_in.subject1.anat=\'{}/anat_subject1.mnc.gz\'".format(parsed.file_in)]
    # % fMRI run 1
    opt_list += ["files_in.subject1.fmri.session1.motor=\'{}/func_motor_subject1.mnc.gz\'".format(parsed.file_in)]

    opt_list += ["files_in.subject2.anat=\'{}/anat_subject2.mnc.gz\'".format(parsed.file_in)]
    # % fMRI run 1
    opt_list += ["files_in.subject2.fmri.session1.motor=\'{}/func_motor_subject2.mnc.gz\'".format(parsed.file_in)]


    # octave_cmd = ["/usr/bin/env", "octave", "--eval \"{0};niak_pipeline_fmri_preprocess(files_in,opt)\""\
    octave_cmd = ["/usr/bin/env", "octave", "--eval", "{0};niak_pipeline_fmri_preprocess(files_in, opt)"\
        .format(";".join(opt_list), parsed.file_in)]

    print(octave_cmd)
    print("")
    print(" ".join(octave_cmd))
    subprocess.call(octave_cmd)


if __name__ == '__main__':
    main()
