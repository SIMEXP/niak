__author__ = 'poquirion'
import json
import os
import re
import shutil
import subprocess
import time
import tempfile

import yaml

def num(s):
    try:
        return int(s)
    except ValueError:
        return float(s)

def string(s):
    """
    :param s: A PSOM option
    :return: The right cast for octave
    """
    s.replace("\\", '')
    s = re.match("[\'\"]?([\w+\ -]*)[\'\"]?", s).groups()[0]
    if s in ['true', 'false', 'Inf']:
        return "{0}".format(s)
    return "'{0}'".format(s)


def unroll_numbers(numbers):
    unrolled = []

    def unroll_string(number, unrolled):
        entries = [a[0].split('-') for a in re.findall("([0-9]+((-[0-9]+)+)?)", number)]
        for elem in entries:
            if len(elem) == 1:
                unrolled.append(int(elem[0]))
            elif len(elem) == 2:
                unrolled += [a for a in range(int(elem[0]), int(elem[1]) + 1)]
            elif len(elem) == 3:
                unrolled += [a for a in range(int(elem[0]), int(elem[1]) + 1, int(elem[2]))]

    if isinstance(numbers, basestring):
        unroll_string(numbers, unrolled)
    else:
        for n in numbers:
            unroll_string(n, unrolled)

    return sorted(list(set(unrolled)))






# Dictionary for supported class
SUPPORTED_PIPELINES = {"Niak_fmri_preprocess": FmriPreprocess,
                       "Niak_basc": BASC,
                       "Niak_stability_rest": BASC}


def load(pipeline_name, *args, **kwargs):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name, SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(*args, **kwargs)


# if __name__ == '__main__':
    # f = "/home/poquirion/simexp/bids-app/niak/default_config.yaml"
    # print (load_config(f))
    # print(unroll_numbers(["1","","3-8","8-33-2","275-278"]))