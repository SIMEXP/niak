__author__ = 'poquirion'

import os
import re
import json
import subprocess

import psutil




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
    """
    This is the base class to run PSOM/NIAK pipeline under CBRAIN and the
    BOUTIQUE interface.
    """

    BOUTIQUE_PATH = "{0}/boutique_descriptor"\
        .format(os.path.dirname(os.path.realpath(__file__)))
    BOUTIQUE_INPUTS = "inputs"
    BOUTIQUE_CMD_LINE = "command-line-flag"
    BOUTIQUE_TYPE_CAST = {"Number": num, "String": string, "File": string}
    BOUTIQUE_TYPE = "type"

    def __init__(self, folder_in, folder_out, options=None):

        # The name must be Provided in the derived class
        self.pipeline_name =  None

        self.octave_options = None
        if os.path.islink(folder_in):
            self.folder_in = os.readlink(folder_in)
        else:
            self.folder_in = folder_in
        self.folder_out = folder_out
        self.octave_options = options

        self._options = []

    def run(self):
        print(" ".join(self.octave_cmd))
        p = None
        try:
            p = subprocess.Popen(self.octave_cmd)
            p.wait()
        except BaseException as e:
            if p:
                parent = psutil.Process(p.pid)
                try:
                    children = parent.children(recursive=True)
                except AttributeError:
                    children = parent.get_children(recursive=True)
                for child in children:
                    child.kill()
                parent.kill()
            raise e

    @property
    def octave_cmd(self):
        return ["/usr/bin/env", "octave", "--eval", "{0};{1}(files_in, opt)"
                           .format(";".join(self.octave_options), self.pipeline_name )]

    @property
    def octave_options(self):

        opt_list = ["opt.folder_out=\'{0}\'".format(self.folder_out)]

        opt_list += self.get_file_in()

        if self._options:
            opt_list += self._options

        return opt_list

    @octave_options.setter
    def octave_options(self, value):
        if value is not None:
            self.type_cast_options(value)
            self._options += ["{0}={1}".format(a[0], a[1]) for a in value.items()]


    def type_cast_options(self, options):

        with open("{0}/{1}.json".format(self.BOUTIQUE_PATH, self.__class__.__name__)) as fp :
            boutique_descriptor = json.load(fp)

        for opt_description in boutique_descriptor[self.BOUTIQUE_INPUTS]:
            if opt_description.get(self.BOUTIQUE_CMD_LINE) \
                    and opt_description[self.BOUTIQUE_CMD_LINE].startswith("--opt"):
                opt = opt_description[self.BOUTIQUE_CMD_LINE].replace("--opt-", "opt.").replace("-", ".")
                options[opt] = self.BOUTIQUE_TYPE_CAST[opt_description[self.BOUTIQUE_TYPE]](options[opt])


    def get_file_in(self):
        """
        This function need to be overload to fill the file_in requirement of NIAK
        :return: A list that contains octave string that fill init the file_in variable
        """
        # TODO write that methide for bids




class FmriPreprocess(BasePipeline):

    def __init__(self, *args, **kwargs):
        super(FmriPreprocess, self).__init__(*args, **kwargs)

        self.pipeline_name = "niak_pipeline_fmri_preprocess"


    def get_file_in(self):
        """

        :return: A list that contains octave string that fill init the file_in variable
        """
        opt_list = []
        in_full_path = "{0}/{1}".format(os.getcwd(), self.folder_in)
        list_in_dir = os.listdir(in_full_path)

        # TODO Control that with an option
        subject_input_list = None
        for f in list_in_dir:
            if f.endswith("_demographics.txt"):
                subject_input_list = f

        if subject_input_list:
            opt_list += ["list_subject=fcon_read_demog('{0}/{1}')".format(in_full_path, subject_input_list)]
            opt_list += ["opt_g.path_database='{0}/'".format(in_full_path)]
            opt_list += ["files_in=fcon_get_files(list_subject,opt_g)"]
        else:
            # Todo find a good strategy to load subject, to is make it general! --> BIDS
            # % Structural scan
            opt_list += ["files_in.subject1.anat=\'{0}/anat_subject1.mnc.gz\'".format(self.folder_in)]
            # % fMRI run 1
            opt_list += ["files_in.subject1.fmri.session1.motor=\'{0}/func_motor_subject1.mnc.gz\'".format(self.folder_in)]
            opt_list += ["files_in.subject2.anat=\'{0}/anat_subject2.mnc.gz\'".format(self.folder_in)]
            # % fMRI run 1
            opt_list += ["files_in.subject2.fmri.session1.motor=\'{0}/func_motor_subject2.mnc.gz\'".format(self.folder_in)]

        return opt_list


class BASC(BasePipeline):
    """
    Class to run basc. Only work with outputs from niak preprocessing,
    at least for now.
    """

    def __init__(self, grabber_option, *args, **kwargs):
        super(BASC, self).__init__(*args, **kwargs)

        self.pipeline_name = "niak_pipeline_stability_rest"

        self.grabber_option = grabber_option

    def get_file_in(self):
        """
        :return:
        """
        file_in = []


        file_in.append("opt_g.min_nb_vol = 100")

        file_in.append("opt_g.type_files = 'roi'")
        file_in.append("files_in = niak_grab_fmri_preprocess('{0}',opt_g)".format(self.folder_in))


        return file_in



# Dictionary for supported class
SUPPORTED_PIPELINES = {"Niak_fmri_preprocess": FmriPreprocess,
                       "Niak_basc": BASC,
                       "Niak_stability_rest": BASC}


def load(pipeline_name, folder_in, folder_out, options=None):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name,SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(folder_in, folder_out, options)


if __name__ == '__main__':
    folder_in = "/home/poquirion/test/data_test_niak_mnc1"
    folder_out = "/var/tmp"

    basc = BASC(folder_in=folder_in, folder_out=folder_out)

    print(basc.octave_cmd)