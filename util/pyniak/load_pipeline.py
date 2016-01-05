__author__ = 'poquirion'

import os
import re
import subprocess

import json



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


class BasePipeline(object):

    BOUTIQUE_PATH = "{0}/boutique_descriptor".format(os.path.dirname(os.path.realpath(__file__)))
    BOUTIQUE_INPUTS = "inputs"
    BOUTIQUE_CMD_LINE = "command-line-flag"
    BOUTIQUE_TYPE_CAST = {"Number": num, "String": string, "File": string}
    BOUTIQUE_TYPE = "type"

    def __init__(self, folder_in=None, folder_out=None, options=None):

        self.octave_cmd = None
        self.folder_in = folder_in
        self.folder_out = folder_out
        self.options = options

    def run(self):
        print(" ".join(self.octave_cmd))
        subprocess.call(self.octave_cmd)

    def type_cast_options(self, options):

        with open("{0}/{1}.json".format(self.BOUTIQUE_PATH, self.__class__.__name__)) as fp :
            boutique_descriptor = json.load(fp)

        for opt_description in boutique_descriptor[self.BOUTIQUE_INPUTS]:
            if opt_description.get(self.BOUTIQUE_CMD_LINE) \
                    and opt_description[self.BOUTIQUE_CMD_LINE].startswith("--opt"):
                opt = opt_description[self.BOUTIQUE_CMD_LINE].replace("--opt-", "opt.").replace("-", ".")
                options[opt] = self.BOUTIQUE_TYPE_CAST[opt_description[self.BOUTIQUE_TYPE]](options[opt])


class FmriPreprocess(BasePipeline):

    # regex to catch anatomical and functional scans
    INPUT = "(([^\W_]+)_(([^\W_]+)_)*(subject[0-9]+).mnc(.gz)?)"
    # FUNCTIONAL = r"(func_((\w+)_)*(subject[0-9]+).mnc(.gz)?)"

    def __init__(self, *args, **kwargs):
        super(FmriPreprocess, self).__init__(*args, **kwargs)

        self.octave_options = None

        self.load_options()
        self.build_cmd()


    def load_options(self):

        opt_list = ["opt.folder_out=\'{0}\'".format(self.folder_out)]

        in_full_path = "{0}/{1}".format(os.getcwd(), self.folder_in)
        list_in_dir = os.listdir(in_full_path)

        # TODO Control that with an option
        subject_input_list = None
        for f in list_in_dir:
            if f.endswith("_demographics.txt"):
                subject_input_list = f

        if subject_input_list:
            opt_list += ["list_subject = fcon_read_demog([{0} '{1}']);".format(in_full_path, subject_input_list)]
            opt_list += ["opt_g.path_database = {0};".format(in_full_path)]
            opt_list += ["files_in = fcon_get_files(list_subject,opt_g);"]
        else:
            # Todo find a good strategy to load subject, that is make it general!
            # % Structural scan
            opt_list += ["files_in.subject1.anat=\'{0}/anat_subject1.mnc.gz\'".format(self.folder_in)]
            # % fMRI run 1
            opt_list += ["files_in.subject1.fmri.session1.motor=\'{0}/func_motor_subject1.mnc.gz\'".format(self.folder_in)]
            opt_list += ["files_in.subject2.anat=\'{0}/anat_subject2.mnc.gz\'".format(self.folder_in)]
            # % fMRI run 1
            opt_list += ["files_in.subject2.fmri.session1.motor=\'{0}/func_motor_subject2.mnc.gz\'".format(self.folder_in)]
        if self.options:
            # Type casting option with the help of the json descriptor
            self.type_cast_options(self.options)
            opt_list += [ "{0}={1}".format(a[0], a[1]) for a in self.options.items()]

        self.octave_options = opt_list

    def load_subject(self, number=None):
        " write that properly with bids"

        # all_scans = "\n".join(os.listdir(self.folder_in))
        # inputs = re.compile(self.INPUT)
        # all_inputs = inputs.findall(all_scans)
        # all_inputs.sort(key=lambda x: x[-2])
        #
        #
        # for match in all_inputs:
        #     "file_in.{0}".format(match[-2])
        #
        #     opt_list = ["".format(match)]

        # for anat_sub
        opt_list = []
        opt_list += ["files_in.subject1.anat=\'{0}/anat_subject1.mnc.gz\'".format(self.folder_in)]
        # % fMRI run 1
        opt_list += ["files_in.subject1.fmri.session1.motor=\'{0}/func_motor_subject1.mnc.gz\'".format(self.folder_in)]
        opt_list += ["files_in.subject2.anat=\'{0}/anat_subject2.mnc.gz\'".format(self.folder_in)]
        # % fMRI run 1
        opt_list += ["files_in.subject2.fmri.session1.motor=\'{0}/func_motor_subject2.mnc.gz\'".format(self.folder_in)]



    def build_cmd(self):

        self.octave_cmd = ["/usr/bin/env", "octave", "--eval", "{0};niak_pipeline_fmri_preprocess(files_in, opt)"
                           .format(";".join(self.octave_options))]


SUPPORTED_PIPELINES = {"Niak_fmri_preprocess": FmriPreprocess}


def load(pipeline_name, folder_in, folder_out, options=None):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name,SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(folder_in, folder_out, options)


if __name__ == '__main__':
    folder_in = "/home/poquirion/test/data_test_niak_mnc1"
    folder_out = "/var/tmp"

    fmrip = FmriPreprocess(folder_in=folder_in, folder_out=folder_out)

    fmrip.load_subject()
