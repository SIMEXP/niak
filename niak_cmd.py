#!/usr/bin/env python2
"""
This module parse arbitrary NIAK opt arguments to run a pipeline with the needed inputs
"""
__author__ = 'poquirion'
__version__ = 1.0


import argparse
import os
import re
import sys

sys.path.append("{}/..".format(os.path.dirname(os.path.realpath(__file__))))
import pyniak.load_pipeline

OPTION_PREFIX = "--opt"
ESCAPE_STRING = "666_____666_____666"

def build_opt(option):
    """
    Translate all option with prefix --opt to into pom options

    :param option: option of the form  --opt-some-value-meaningful-for-psom VAL
    :return: a string of the form opt.some.value.meaningful.for.psom=VAL
    """
    parser = argparse.ArgumentParser(description="All options")

    opt_dico = {}
    for i, o in enumerate(option):
        if OPTION_PREFIX in o:
            option[i] = re.sub("(\w)-(\w)", "\g<1>{0}\g<2>".format(ESCAPE_STRING), o)
            parser.add_argument(option[i], nargs='?')

    parsed = parser.parse_known_args(option)
    print(parser)

    for k, v in parsed[0].__dict__.items():
        if v is None:
            opt_dico["{0}".format(k.replace(ESCAPE_STRING, "."))] = "true"
        else:
            opt_dico["{0}".format(k.replace(ESCAPE_STRING, "."))] = "{0}".format(v)

    return opt_dico


def main(args=None):

    if args is None:
        args = sys.argv[1:]

    parser = argparse.ArgumentParser(description='Run a niak script')

    # parser.add_argument("pipeline", default=None)
    parser.add_argument("--participant_label",
                        help='The label(s) of the participant(s) that should be analyzed. The label '
                        'corresponds to sub-<participant_label> from the BIDS spec '
                        '(so it does not include "sub-"). If this parameter is not '
                        'provided all subjects should be analyzed. Multiple '
                        'participants can be specified with a space separated list.',
                         nargs="+")

    parser.add_argument('analysis_level', help='Level of the analysis that will be performed. '
                    'Multiple participant level analyses can be run independently '
                    '(in parallel) using the same output_dir.',
                    choices=['participant', 'group'])

    parser.add_argument('bids_dir', help='The directory with the input dataset '
                    'formatted according to the BIDS standard.')

    parser.add_argument('output_dir', help='The directory where the output files '
                    'should be stored. If you are running group level analysis '
                    'this folder should be prepopulated with the results of the'
                    'participant level analysis.')

    parser.add_argument('-v', '--version', action='version',
                        version='BIDS-App example version {}'.format(__version__))

    parsed, unformated_options = parser.parse_known_args(args)

    options = build_opt(unformated_options)

    pipeline_name = None

    if pipeline_name is None:
        pipeline_name = "Niak_fmri_preprocess"

    if parsed.analysis_level =="group":
        pipeline = pyniak.load_pipeline.load(pipeline_name, parsed.bids_dir, parsed.output_dir, options=options)
        pipeline.run()
    else:
        pyniak.run_worker(parsed.output_dir, parsed.participant_label)



if __name__ == '__main__':
    main()
    #main([ "-p", "Niak_fmri_preprocess",  '--file_in', 'data_test_niak_mnc1', '--folder_out', 'results-directory', '--opt-psom-max_queued', '4', '--opt-slice_timing-type_scanner', 'Bruker', '--opt-slice_timing-type_acquisition', '"interleaved ascending"', '--opt-slice_timing-delay_in_tr', '0', '--opt-resample_vol-voxel_size', '10', '--opt-t1_preprocess-nu_correct-arg', "'-distance 75'", '--opt-time_filter-hp', '0.01', '--opt-time_filter-lp', 'Inf', '--opt-regress_confounds-flag_gsc', 'true', '--opt-regress_confounds-flag_scrubbing','true', '--opt-regress_confounds-thre_fd', '0.5', '--opt-smooth_vol-fwhm', '6'])
    # main(["/home/niak/util/bin/niak_cmd.py","Niak_fmri_preprocess","--file_in","Cambridge_Buckner","--folder_out","results-directory","--opt-psom-max_queued","100","--opt-slice_timing-type_scanner","Siemens","--opt-slice_timing-type_acquisition","interleaved","--opt-slice_timing-delay_in_tr","0","--opt-resample_vol-voxel_size","3","--opt-t1_preprocess-nu_correct-arg","'-distance","50'","--opt-time_filter-hp","0.01","--opt-time_filter-lp","Inf","--opt-regress_confounds-flag_gsc","true","--opt-regress_confounds-flag_scrubbing","true","--opt-regress_confounds-thre_fd","0.5","--opt-smooth_vol-fwhm","6","--opt-corsica-sica-nb_comp","50","--opt-corsica-threshold","0.15","--opt-corsica-flag_skip","false","--opt-size_output","quality_control","--opt-motion_correction-suppress_vol","0","--opt-granularity","max"])