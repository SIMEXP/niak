__author__ = 'poquirion'

import subprocess


class BasePipeline(object):


    def __init__(self, folder_in, folder_out, options):

        self.octave_cmd = None
        self.folder_in = folder_in
        self.folder_out = folder_out
        self.options = options

    def run(self):
        print(" ".join(self.octave_cmd))
        subprocess.call(self.octave_cmd)


class FmriPreprocess(BasePipeline):

    def __init__(self, *args):
        super(FmriPreprocess, self).__init__(*args)

        self.octave_options = None

        self.load_options()
        self.build_cmd()

    def load_options(self):

        opt_list = ["opt.folder_out=\'{0}\'".format(self.folder_out)]

        # Todo find a good strategy to load subject, that is make it general!
        # % Structural scan
        opt_list += ["files_in.subject1.anat=\'{0}/anat_subject1.mnc.gz\'".format(self.folder_in)]
        # % fMRI run 1
        opt_list += ["files_in.subject1.fmri.session1.motor=\'{0}/func_motor_subject1.mnc.gz\'".format(self.folder_in)]
        opt_list += ["files_in.subject2.anat=\'{0}/anat_subject2.mnc.gz\'".format(self.folder_in)]
        # % fMRI run 1
        opt_list += ["files_in.subject2.fmri.session1.motor=\'{0}/func_motor_subject2.mnc.gz\'".format(self.folder_in)]
        opt_list += self.options

        self.octave_options = opt_list

    def build_cmd(self):

        self.octave_cmd = ["/usr/bin/env", "octave", "--eval", "{0};niak_pipeline_fmri_preprocess(files_in, opt)"
                           .format(";".join(self.octave_options))]


SUPPORTED_PIPELINES = {"niak_pipeline_fmri_preprocess": FmriPreprocess}


def load(pipeline_name, folder_in, folder_out, options=None):

    if not pipeline_name or not pipeline_name in SUPPORTED_PIPELINES:
        m = 'Pipeline {0} is not in not supported\nMust be part of {1}'.format(pipeline_name,SUPPORTED_PIPELINES)
        raise IOError(m)

    pipe = SUPPORTED_PIPELINES[pipeline_name]

    return pipe(folder_in, folder_out, options)



