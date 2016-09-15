__author__ = 'poquirion'

import shutil
import json
import os
import re
import subprocess
import tempfile

LOCAL_CONFIG_PATH = '/local_config'
PSOM_GB_LOCAL =\
"""
%% Here are important PSOM variables. Whenever needed, PSOM will call
%% this script to initialize the variables. If PSOM does not behave the way
%% you want, this might be the place to fix that.

%% Use the local configuration file if any
if ~exist('gb_psom_gb_vars_local','var')&&exist('psom_gb_vars_local.m','file')
	gb_psom_gb_vars_local = true;
	psom_gb_vars_local
	return
end
gb_psom_DEBUG = true;

% how to invoke octave
gb_psom_command_octave = 'octave';

% Options for the sge qsub system, example : '-q all.q@yeatman,all.q@zeus'
% will force qsub to only use the yeatman and zeus workstations through the
% queue called all.q
gb_psom_qsub_options = '-A gsf-624-aa -q sw -l walltime=36:00:00';

% Options for the shell in batch or qsub modes
gb_psom_shell_options = '';

% Options for the execution mode of the pipeline
%gb_psom_mode = 'docker';
gb_psom_mode = 'cbrain';
%gb_psom_mode = 'session';
%gb_psom_mode = 'background';

% Options for the execution mode of the pipeline manager
gb_psom_mode_pm = 'session';

% Options for the execution mode of the deamon
gb_psom_mode_deamon = 'background';
%gb_psom_mode_deamon = 'session';

% Options for the execution mode of the garbage collector
gb_psom_mode_garbage = 'background';

% Options for the maximal number of jobs
gb_psom_max_queued = 10;

% Default number of attempts of re-submission for failed jobs
% [] is 0 for session, batch and background modes, and 1 for
% qsub/msub modes.
gb_psom_nb_resub = 5;


% Matlab search path. An empty value will correspond to the search path of
% the session used to invoke PSOM_RUN_PIPELINE. A value 'gb_psom_omitted'
% will result in no search path initiated (the default Octave path is
% used).
gb_psom_path_search = '';

% where to store temporary files
pbs_jobid = getenv('PBS_JOBID');
if isempty(pbs_jobid)
    gb_psom_tmp = '/tmp/';
else
    gb_psom_tmp = ['/localscratch/' pbs_jobid filesep];
end

dgb_psom_tmp = [tempdir filesep];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PSOM version
gb_psom_version = '1.0.4'; % PSOM release number

%% Is the environment Octave or Matlab ?
if exist('OCTAVE_VERSION','builtin')
    % this is octave !
    gb_psom_language = 'octave';
else
    % this is not octave, so it must be matlab
    gb_psom_language = 'matlab';
end

% Options to start matlab
switch gb_psom_language
    case 'matlab'
        if ispc
            gb_psom_opt_matlab = '-automation -nodesktop -singleCompThread -r';
        else
            gb_psom_opt_matlab = '-nosplash -nodesktop -singleCompThread -r';
        end
    case 'octave'
        gb_psom_opt_matlab = '--silent --eval';
end

% Get langage version
if strcmp(gb_psom_language,'octave');
    gb_psom_language_version = OCTAVE_VERSION;
else
    gb_psom_language_version = version;
end

%% In which path is PSOM ?
str_gb_vars = which('psom_gb_vars');
if isempty(str_gb_vars)
    error('PSOM is not in the path ! (could not find PSOM_GB_VARS)')
end
gb_psom_path_psom = fileparts(str_gb_vars);
if strcmp(gb_psom_path_psom,'.')
    gb_psom_path_psom = pwd;
end
gb_psom_path_psom = [gb_psom_path_psom filesep];

%% In which path is the PSOM demo ?
gb_psom_path_demo = cat(2,gb_psom_path_psom,'data_demo',filesep);

%% What is the operating system ?
if isunix
    gb_psom_OS = 'unix';
elseif ispc
    gb_psom_OS = 'windows';
else
    warning('System %s unknown!',comp);
    gb_psom_OS = 'unkown';
end

%% getting user name.
switch (gb_psom_OS)
    case 'unix'
	gb_psom_user = getenv('USER');
    case 'windows'
	gb_psom_user = getenv('USERNAME');
    otherwise
	gb_psom_user = 'unknown';
end

%% Getting the local computer's name
switch (gb_psom_OS)
    case 'unix'
	[gb_psom_tmp_var,gb_psom_localhost] = system('uname -n');
        gb_psom_localhost = deblank(gb_psom_localhost);
    otherwise
	gb_psom_localhost = 'unknown';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Any following line will be executed at the begining of every PSOM command and every job %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Uncomment the following line to load the image processing package in Octave

% pkg load image

%% Don't use more to verbose "on-the-fly" in Octave

% more off

%% Use .mat files compatible with Matlab in Octave

% default_save_options('-7');

%% This is a bit of a dangerous option, but it makes things run faster in Octave.
%% You'll have to exit octave and start again if you want any change in the functions to be
%% taken into account.

% ignore_function_time_stamp ('all')

gb_psom_command_octave = 'octave';
gb_psom_mode = 'cbrain';
gb_psom_mode_pm = 'session';
gb_psom_mode_deamon = 'background';
gb_psom_mode_garbage = 'background';
gb_psom_nb_resub = 5;
pbs_jobid = getenv('PBS_JOBID');
if isempty(pbs_jobid)
    gb_psom_tmp = '/tmp/';
else
    gb_psom_tmp = ['/localscratch/' pbs_jobid filesep];
end

"""

try:
    import psutil
    psutil_loaded = True
except ImportError:
    psutil_loaded = False


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
    BOUTIQUE_TYPE_CAST = {"Number": num, "String": string, "File": string, "Flag": string}
    BOUTIQUE_TYPE = "type"
    BOUTIQUE_LIST = "list"

    def __init__(self, pipeline_name, folder_in, folder_out, subjects=None, options=None):

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

        self.subjects = unroll_numbers(subjects)
        self.psom_gb_local_path = None

    def psom_gb_vars_local_setup(self):
        """
        This method is crucial to have psom/niak running properly on cbrain.
        :return:
        """

        self.psom_gb_local_path = "{0}/psom_gb_vars_local.m".format(LOCAL_CONFIG_PATH)

        with open(self.psom_gb_local_path, 'w') as fp:
            fp.write(PSOM_GB_LOCAL)

    def run(self):
        print(" ".join(self.octave_cmd))
        p = None

        self.psom_gb_vars_local_setup()

        try:
            p = subprocess.Popen(self.octave_cmd)
            p.wait()
        except BaseException as e:
            if p and psutil_loaded:
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
                           .format(";".join(self.octave_options), self.pipeline_name)]

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
        in_full_path = "{0}/{1}".format(os.getcwd(), self.folder_in)
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
                if self.subjects is not None and len(self.subjects) >= 1:
                    opt_list += ["opt_gr.subject_list = {0}".format(self.subjects).replace('[', '{').replace(']', '}')]
                    opt_list += ["files_in=niak_grab_bids('{0}',opt_gr)".format(in_full_path)]
                else:
                    opt_list += ["files_in=niak_grab_bids('{0}')".format(in_full_path)]

                # opt_list += ["opt.slice_timing.flag_skip=true"]

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
        if self.subjects is not None and len(self.subjects) >= 1:
            file_in.append("opt_g.include_subject = {0}".format(self.subjects).replace('[', '{').replace(']', '}'))
        file_in.append("files_in = niak_grab_fmri_preprocess('{0}',opt_g)".format(self.folder_in))


        return file_in



# Dictionary for supported class
SUPPORTED_PIPELINES = {"Niak_fmri_preprocess": FmriPreprocess,
                       "Niak_basc": BASC,
                       "Niak_stability_rest": BASC}


def load(pipeline_name, folder_in, folder_out, *args, **kwargs):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name, SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(folder_in, folder_out, *args, **kwargs)



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
            unrolled += [a for a in range(int(elem[0]), int(elem[1])+1, int(elem[2]) )]

    return sorted(list(set(unrolled)))

if __name__ == '__main__':
    # folder_in = "/home/poquirion/test/data_test_niak_mnc1"
    # folder_out = "/var/tmp"
    #
    # basc = BASC(folder_in=folder_in, folder_out=folder_out)
    #
    # print(basc.octave_cmd)

    print (unroll_numbers("1,3,4 15-20, 44, 18-27-2"))