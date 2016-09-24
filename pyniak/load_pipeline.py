__author__ = 'poquirion'

import json
import os
import re
import shutil
import subprocess
import time

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
    import re

    entries = [a[0].split('-') for a in  re.findall("([0-9]+((-[0-9]+)+)?)", numbers)]

    unrolled = []
    for elem in entries:
        if len(elem) == 1:
            unrolled.append(int(elem[0]))
        elif len(elem) == 2:
            unrolled += [a for a in range(int(elem[0]), int(elem[1])+1)]
        elif len(elem) == 3:
            unrolled += [a for a in range(int(elem[0]), int(elem[1])+1, int(elem[2]))]

    return sorted(list(set(unrolled)))


def load_config(yaml_file):
    """
        Tranlate a yaml file into opt and opt.tune pipeline config
    :param yaml_file: a yaml file
    :return: a list of command to be executed before pipeline execution
    """
    with open(yaml_file) as fp:
        config = yaml.load(fp)

    bidon = ['']
    all_cmd = []
    s_cmd = []
    prefix = ''
    def unfold(value):

        if isinstance(value, dict):
            for k, v in value.items():
                bidon[0] = "{0}.{1}".format(bidon[0], k)
                unfold(v)
        else:
            if isinstance(value, basestring):
                cast_value = "'{}'".format(value)
            else:
                cast_value = value
            if '{0}'in prefix:
                s_cmd.append("{0}{1}={2}".format(prefix, bidon[0], cast_value))
            else:
                all_cmd.append("{0}{1}={2}".format(prefix, bidon[0], cast_value))
        bidon[0] = ''
    counter = 1
    for k_, v in config.items():
        k = str(k_)
        if k.lower().startswith('group'):
            bidon = ['']
            prefix = 'opt'
            unfold(v)
        else:
            s_cmd = []
            prefix = "opt.tune({0})"
            unfold(v)
            for i, subject in enumerate(unroll_numbers(k), counter):
                all_cmd.append('opt.tune({0}).subject="sub-{1:04d}"'.format(i, subject))
                for line in s_cmd:
                #  TODO make the 4 in {1:04d} a configurable thing
                    all_cmd.append(line.format(i))
            counter = i + 1
    return all_cmd

class BasePipeline(object):
    """
    This is the base class to run PSOM/NIAK pipeline under CBRAIN and the
    BOUTIQUE interface.
    """

    BOUTIQUE_PATH = "{0}/boutique_descriptor"\
        .format(os.path.dirname(os.path.realpath(__file__)))
    BOUTIQUE_INPUTS = "inputs"
    BOUTIQUE_CMD_LINE = "command-line-flag"
    BOUTIQUE_TYPE_CAST = {"Number": num, "String": string, "File": string, "Flag": string}
    BOUTIQUE_TYPE = "type"
    BOUTIQUE_LIST = "list"
    PIPELINE_M_FILE = 'pipeline.m'

    def __init__(self, pipeline_name, folder_in, folder_out, config_file=None, options=None):

        # literal file name in niak
        self.pipeline_name = pipeline_name

        # The name should be Provided in the derived class
        self._grabber_options = []
        self._pipeline_options = []

        if os.path.islink(folder_in):
            self.folder_in = os.readlink(folder_in)
        else:
            self.folder_in = folder_in
        self.folder_out = folder_out
        self.octave_options = options

        if config_file:
           self.opt_and_tune_config = load_config(config_file)
        else:
            self.opt_and_tune_config = []

    def run(self):
        print(" ".join(self.octave_cmd))
        p = None

        try:
            print(self.folder_out)
            p = subprocess.Popen(self.octave_cmd)
            run_worker(self.folder_out, 1)
            p.wait()
        finally:
            try:
                os.remove('{0}/logs/PIPE.lock'.format(self.folder_out))
                shutil.rmtree('{0}/logs/tmp'.format(self.folder_out))
            except OSError:
                pass

    @property
    def octave_cmd(self):
        m_file = "{0}/{1}".format(self.folder_out, self.PIPELINE_M_FILE)
        with open(m_file,'w') as fp:
            print(self.opt_and_tune_config + self.octave_options)
            fp.write(";\n".join(self.opt_and_tune_config + self.octave_options))
            fp.write(";\n{0}(files_in, opt);\n".format(self.pipeline_name))
        return ["/usr/bin/env", "octave", m_file]

    @property
    def octave_options(self):

        opt_list = ["opt.folder_out=\'{0}\'".format(self.folder_out)]

        opt_list += self.grabber_construction()

        if self._pipeline_options:
            opt_list += self._pipeline_options

        return opt_list

    @octave_options.setter
    def octave_options(self, options):

        if options is not None:
            # Sort options between grabber (the input file reader) and typecast
            # them with the help of the boutique descriptor
            with open("{0}/{1}.json".format(self.BOUTIQUE_PATH, self.__class__.__name__)) as fp:
                boutique_descriptor = json.load(fp)

            casting_dico = {elem.get(self.BOUTIQUE_CMD_LINE, "")
                            .replace("--opt", "opt").replace("-", "."): [elem.get(self.BOUTIQUE_TYPE),
                                                                         elem.get(self.BOUTIQUE_LIST)]
                            for elem in boutique_descriptor[self.BOUTIQUE_INPUTS]}

            for optk, optv in options.items():


                optv = self.BOUTIQUE_TYPE_CAST[casting_dico[optk][0]](optv)

                # if casting_dico[boutique_opt][1] is True:

                if optk.startswith("--opt_g"):
                    self._grabber_options.append("{0}={1}".format(optk, optv))
                else:
                    self._pipeline_options.append("{0}={1}".format(optk, optv))



    def grabber_construction(self):
        """
        This method needs to be overload to fill the file_in requirement of NIAK
        :return: A list that contains octave string that fill init the file_in variable
        """
        pass



class FmriPreprocess(BasePipeline):

    def __init__(self, *args, **kwargs):
        super(FmriPreprocess, self).__init__("niak_pipeline_fmri_preprocess", *args, **kwargs)

    def grabber_construction(self):
        """

        :return: A list that contains octave string that fill init the file_in variable

        TODO write that method for bids

        """
        opt_list = []
        in_full_path = "{1}".format(os.getcwd(), self.folder_in)
        list_in_dir = os.listdir(in_full_path)
        # TODO Control that with an option
        bids_description = None
        subject_input_list = None
        for f in list_in_dir:
            if f.endswith("dataset_description.json"):
                bid_path = "{0}/{1}".format(in_full_path, f)
                with open(bid_path) as fp:
                    bids_description = json.load(fp)

            elif f.endswith("_demographics.txt"):
                subject_input_list = f

        if subject_input_list:
            opt_list += ["list_subject=fcon_read_demog('{0}/{1}')".format(in_full_path, subject_input_list)]
            opt_list += ["opt_g.path_database='{0}/'".format(in_full_path)]
            opt_list += ["files_in=fcon_get_files(list_subject,opt_g)"]

        elif bids_description:
                opt_list += ["files_in=niak_grab_bids('{0}')".format(in_full_path)]
                opt_list += ["opt.slice_timing.flag_skip=true"]

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

    def __init__(self, *args, **kwargs):
        super(BASC, self).__init__("niak_pipeline_stability_rest", *args, **kwargs)

    def grabber_construction(self):
        """
        :return:
        """
        file_in = []


        file_in.append("opt_g.min_nb_vol = {0}")
        file_in.append("opt_g.type_files = 'rest'")

        file_in.append("files_in = niak_grab_fmri_preprocess('{0}',opt_g)".format(self.folder_in))


        return file_in


def run_worker(dir, num):
    cmd = ['psom_worker.py', '-d', dir, '-w', str(num)]
    while not os.path.exists("{0}/logs/tmp/".format(dir)):
        # sleep long enough to be last on the race condition TODO (FIND A BETTER WAY TO DO THAT)
        time.sleep(5)
    return subprocess.Popen(cmd)

# Dictionary for supported class
SUPPORTED_PIPELINES = {"Niak_fmri_preprocess": FmriPreprocess,
                       "Niak_basc": BASC,
                       "Niak_stability_rest": BASC}


def load(pipeline_name, *args, **kwargs):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name,SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(*args, **kwargs)


if __name__ == '__main__':
    f = "/home/poquirion/simexp/bids-app/niak/default_config.yaml"
    print (load_config(f))
