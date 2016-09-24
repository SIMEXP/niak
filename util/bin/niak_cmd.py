#!/usr/bin/env python2
"""
This module parse arbitrary NIAK opt arguments to run a pipeline with the needed inputs
"""
__author__ = 'poquirion'


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
    # return
    if args is None:
        args = sys.argv[1:]

    print('{0}'.format(__file__, " ".join(args)))

    parser = argparse.ArgumentParser(description='Run a niak script')

    parser.add_argument("pipeline", default=None)

    parser.add_argument("--file_in", default=None)

    parser.add_argument("--folder_out", default=None)

    parser.add_argument("--subjects", default=None)

    parsed, unformated_options = parser.parse_known_args(args)

    options = build_opt(unformated_options)

    pipeline_name = parsed.pipeline

    if pipeline_name is None:
        pipeline_name = "Niak_fmri_preprocess"

    pipeline = pyniak.load_pipeline.load(pipeline_name, parsed.file_in, parsed.folder_out,
                                         subjects=parsed.subjects, options=options)

    pipeline.run()


if __name__ == '__main__':
    main()
    # main(["-p", "Niak_fmri_preprocess", '--subjects', "290-292", '--file_in', 'data_test_niak_mnc1', '--folder_out', 'results-directory', '--opt-psom-max_queued', '4', '--opt-slice_timing-type_scanner', 'Bruker', '--opt-slice_timing-type_acquisition', '"interleaved ascending"', '--opt-slice_timing-delay_in_tr', '0', '--opt-resample_vol-voxel_size', '10', '--opt-t1_preprocess-nu_correct-arg', "'-distance 75'", '--opt-time_filter-hp', '0.01', '--opt-time_filter-lp', 'Inf', '--opt-regress_confounds-flag_gsc', 'true', '--opt-regress_confounds-flag_scrubbing','true', '--opt-regress_confounds-thre_fd', '0.5', '--opt-smooth_vol-fwhm', '6'])
    # main(["-p", "Niak_fmri_preprocess", '--subjects', "290-292", '--file_in', 'GSP-bids', '--folder_out', 'results-directory', '--opt-psom-max_queued', '4', '--opt-slice_timing-type_scanner', 'Bruker', '--opt-slice_timing-type_acquisition', '"interleaved ascending"', '--opt-slice_timing-delay_in_tr', '0', '--opt-resample_vol-voxel_size', '10', '--opt-t1_preprocess-nu_correct-arg', "'-distance 75'", '--opt-time_filter-hp', '0.01', '--opt-time_filter-lp', 'Inf', '--opt-regress_confounds-flag_gsc', 'true', '--opt-regress_confounds-flag_scrubbing','true', '--opt-regress_confounds-thre_fd', '0.5', '--opt-smooth_vol-fwhm', '6'])
    # main(["/home/niak/util/bin/niak_cmd.py","Niak_fmri_preprocess",'--subjects', "290-292","--file_in","Cambridge_Buckner","--folder_out","results-directory","--opt-psom-max_queued","100","--opt-slice_timing-type_scanner","Siemens","--opt-slice_timing-type_acquisition","interleaved","--opt-slice_timing-delay_in_tr","0","--opt-resample_vol-voxel_size","3","--opt-t1_preprocess-nu_correct-arg","'-distance","50'","--opt-time_filter-hp","0.01","--opt-time_filter-lp","Inf","--opt-regress_confounds-flag_gsc","true","--opt-regress_confounds-flag_scrubbing","true","--opt-regress_confounds-thre_fd","0.5","--opt-smooth_vol-fwhm","6","--opt-corsica-sica-nb_comp","50","--opt-corsica-threshold","0.15","--opt-corsica-flag_skip","false","--opt-size_output","quality_control","--opt-motion_correction-suppress_vol","0","--opt-granularity","max"])