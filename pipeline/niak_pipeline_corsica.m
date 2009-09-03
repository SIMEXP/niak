function pipeline = niak_pipeline_corsica(files_in,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_PIPELINE_CORSICA
%
% Build a pipeline structure to apply the CORSICA method for correction of
% the physiological noise.
%
% PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN  
%       (structure) with the following fields : 
%
%       <SUBJECT>.FMRI 
%           (cell of strings) a list of fMRI datasets. The field name 
%           <SUBJECT> can be any arbitrary string. All data in 
%           FILES_IN.<SUBJECT> should come from the same subject.
%
%       <SUBJECT>.TRANSFORMATION 
%           (string, default identity) a transformation from the functional 
%           space to the "MNI152 non-linear" space.
%
%       <SUBJECT>.COMPONENT_TO_KEEP
%           (string, default none) a text file, whose first line is a
%           a set of string labels, and each column is otherwise a temporal
%           component of interest. The ICA component with higher
%           correlation with each signal of interest will be automatically
%           attributed a selection score of 0.
%  * OPT   
%       (structure) with the following fields : 
%
%       SIZE_OUTPUT
%           (string, default 'quality_control') possible values : 
%            ‘minimum’, 'quality_control’, ‘all’.
%           The quantity of intermediate results that are generated. 
%           * With the option ‘minimum’, only the physiological-noise
%           corrected data is written. 
%           * With the option ‘quality_control’, in addition to the outputs 
%           of the 'minimum' option, a pdf document recapitulating 
%           the ICA components and the score of components in the stepwise 
%           regression are generated.
%           * With the option ‘all’, in addition to the outputs of the 
%           'minimum' option, the space and time distributions of the ICA 
%           are generated.
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
%       FLAG_TEST
%           (boolean, default false) If FLAG_TEST is true, the pipeline
%           will just produce a pipeline structure, and will not actually
%           process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%           process the data.
%
%       BRICKS 
%           (structure) The fields of OPT.BRICKS set the options for each
%           brick used in the pipeline
%           Note that the options will be common to all runs of all 
%           subjects. Subjects with different options need to be processed 
%           in different pipelines. 
%           Each field correspond to one brick, which is indicated. 
%           Please refer to the help of the brick for details. Unless 
%           specified, the fields can be simply omitted, in which case the 
%           default options are used.
%   
%           SICA 
%               (structure) options of NIAK_BRICK_SICA
%
%               NB_COMP 
%                   (integer) the number of components (default 60).
%
%           COMPONENT_SEL 
%               (structure) options of NIAK_BRICK_COMPONENT_SEL.
%
%           COMPONENT_SUPP 
%               (structure) options of NIAK_BRICK_COMPONENT_SUPP.
%
%               THRESHOLD 
%                   (scalar, default 0.15) a threshold to apply on the 
%                   score for suppression (scores above the thresholds are 
%                   selected). If the threshold is -Inf, all components 
%                   will be suppressed. If the threshold is Inf, no
%                   component will be suppressed (the algorithm is 
%                   basically copying the file, expect that the data is 
%                   masked inside the brain).
%
% _________________________________________________________________________
% OUTPUTS
%
%  * PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline. 
%
% _________________________________________________________________________
% COMMENTS
%
%  The steps of the pipeline are the following :
%  
%       1.  Individual spatial independent component of each functional
%       run.
%
%       2. Selection of independent component related to physiological
%          noise, using spatial priors (masks of the ventricle and a part of
%          the brain stem).
%
%       3. Generation of a "physiological noise corrected" fMRI dataset for
%          each run, where the effect of the selected independent components
%          has been removed. 
%
% The PSOM pipeline manager is used to process the pipeline if
% OPT.FLAG_TEST is false. PSOM has a number of interesting features to deal
% with job failures or pipeline updates. You can read the following
% tutorial for a review of its capabilities : 
% http://code.google.com/p/psom/wiki/HowToUsePsom
%
% _________________________________________________________________________
% REFERENCES
%
% Perlbarg, V., Bellec, P., Anton, J.-L., Pelegrini-Issac, P., Doyon, J. and 
% Benali, H.; CORSICA: correction of structured noise in fMRI by automatic
% identification of ICA components. Magnetic Resonance Imaging, Vol. 25,
% No. 1. (January 2007), pp. 35-46.
%
% MJ Mckeown, S Makeig, GG Brown, TP Jung, SS Kindermann, AJ Bell, TJ
% Sejnowski; Analysis of fMRI data by blind separation into independent
% spatial components. Hum Brain Mapp, Vol. 6, No. 3. (1998), pp. 160-188.
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% import NIAK global variables

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if ~exist('files_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT).\n Type ''help niak_pipeline_corsica'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)
    error('FILE_IN should be a struture!')
else
   
    list_subject = fieldnames(files_in);
    nb_subject = length(list_subject);
    
    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        data_subject = getfield(files_in,subject);
        
        if ~isstruct(data_subject)
            error('FILE_IN.%s should be a structure!',upper(subject));
        end
        
        if ~isfield(data_subject,'fmri')
            error('I could not find the field FILE_IN.%s.FMRI!',upper(subject));
        end
        
        data_fmri = getfield(data_subject,'fmri');
        if ~iscellstr(data_fmri)
            error('FILE_IN.%s.fmri is not a cell of strings!',upper(subject));
        end        
        
        if ~isfield(data_subject,'transformation')
            eval(cat(2,'files_in.',subject,'.transformation = ''gb_niak_omitted'';'));
        end
        
        if ~isfield(data_subject,'component_to_keep')
            files_in.(subject).component_to_keep = 'gb_niak_omitted';            
        end
        
        data_transf = getfield(data_subject,'transformation');
        if ~ischar(data_transf)
             error('FILE_IN.%s.TRANSFORMATION is not a string!',upper(subject));
        end
        
    end
    
end

%% Options
gb_name_structure = 'opt';
default_psom.path_logs = '';
gb_list_fields = {'size_output','psom','flag_test','folder_out','bricks'};
gb_list_defaults = {'quality_control',default_psom,false,NaN,struct([])};
niak_set_defaults

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = 1;
gb_list_fields = {'sica','component_sel','component_supp'};
gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp};

niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

%%%%%%%%%%
%% SICA %%
%%%%%%%%%%

name_process = 'sica';

for num_s = 1:nb_subject

    subject = list_subject{num_s};           
    data_subj = getfield(files_in,subject);        
    nb_run = length(data_subj.fmri);
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        files_in_tmp = data_subj.fmri{num_r};

        %% Options
        opt_tmp = opt.bricks.sica;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp.space = '';
        files_out_tmp.time = '';
        files_out_tmp.figure = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_sica(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.command = 'niak_brick_sica(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        
        pipeline(1).(name_stage) = stage;

    end % run

end % subject


%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPONENT SELECTION %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%% with the ventricles
name_process = 'component_sel_ventricle';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_subj = getfield(files_in,subject);        
    nb_run = length(data_subj.fmri);
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
               
        name_stage_in = cat(2,'sica_',subject,'_',run);
        stage_in = getfield(pipeline,name_stage_in);
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.component = stage_in.files_out.time;
        files_in_tmp.mask = cat(2,gb_niak_path_niak,'template',filesep,'roi_ventricle.mnc');
        files_in_tmp.transformation = data_subj.transformation;
        files_in_tmp.component_to_keep = data_subj.component_to_keep;

        %% Options
        opt_tmp = opt.bricks.component_sel;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_component_sel(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Selection of ICA components using a mask of the ventricles';
        stage.command = 'niak_brick_component_sel(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;

        pipeline.(name_stage) = stage;

    end % run

end % subject

%% with the brain stem
name_process = 'component_sel_stem';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_subj = getfield(files_in,subject);        
    nb_run = length(data_subj.fmri);
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
               
        name_stage_in = cat(2,'sica_',subject,'_',run);
        stage_in = getfield(pipeline,name_stage_in);
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.component = stage_in.files_out.time;
        files_in_tmp.mask = cat(2,gb_niak_path_niak,'template',filesep,'roi_stem.mnc');
        files_in_tmp.transformation = data_subj.transformation;
        files_in_tmp.component_to_keep = data_subj.component_to_keep;

        %% Options
        opt_tmp = opt.bricks.component_sel;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_component_sel(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Selection of ICA components using a mask of the ventricles';
        stage.command = 'niak_brick_component_sel(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;        

        pipeline.(name_stage) = stage;

    end % run

end % subject


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPONENT SUPPRESSION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'component_supp';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_subj = getfield(files_in,subject);        
    nb_run = length(data_subj.fmri);
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
               
        %% Names of previous stages
        name_stage_sica = cat(2,'sica_',subject,'_',run);
        name_stage_comp_vent = cat(2,'component_sel_ventricle_',subject,'_',run);
        name_stage_comp_stem = cat(2,'component_sel_stem_',subject,'_',run);      
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.space = pipeline.(name_stage_sica).files_out.space;
        files_in_tmp.time = pipeline.(name_stage_sica).files_out.time;
        files_in_tmp.compsel{1} = pipeline.(name_stage_comp_vent).files_out;
        files_in_tmp.compsel{2} = pipeline.(name_stage_comp_stem).files_out;

        %% Options
        opt_tmp = opt.bricks.component_supp;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_component_supp(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Suppression of noise-related ICA components from individual fMRI data';
        stage.command = 'niak_brick_component_supp(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;

        pipeline.(name_stage) = stage;

    end % run

end % subject

%%%%%%%%%%%%%%
%% CLEANING %%
%%%%%%%%%%%%%%

name_process = 'clean_corsica_intermediate';

if strcmp(opt.size_output,'minimum')|strcmp(opt.size_output,'quality_control')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        data_subj = getfield(files_in,subject);
        nb_run = length(data_subj.fmri);

        for num_r = 1:nb_run

            clear files_in_tmp files_out_tmp opt_tmp
            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,name_process,'_',subject,'_',run);

            %% Names of previous stages
            name_stage_in0 = cat(2,'sica_',subject,'_',run);
            name_stage_in1 = cat(2,'component_sel_ventricle_',subject,'_',run);
            name_stage_in2 = cat(2,'component_sel_stem_',subject,'_',run);
            name_stage_in3 = cat(2,'component_supp_',subject,'_',run);

            %% Inputs
            files_in_tmp = pipeline.(name_stage_in3).files_out;

            %% Cleaning options
            switch opt.size_output

                case 'minimum'

                    opt_tmp.clean.space = pipeline.(name_stage_in0).files_out.space;
                    opt_tmp.clean.time = pipeline.(name_stage_in0).files_out.time;
                    opt_tmp.clean.figure = pipeline.(name_stage_in0).files_out.figure;
                    opt_tmp.clean.compsel{1} = pipeline.(name_stage_in1).files_out;
                    opt_tmp.clean.compsel{2} = pipeline.(name_stage_in2).files_out;

                case 'quality_control'

                    opt_tmp.clean.space = pipeline.(name_stage_in0).files_out.space;
                    opt_tmp.clean.time = pipeline.(name_stage_in0).files_out.time;
                    
            end

            %% Options
            opt_tmp.flag_verbose = 1;

            %% Outputs
            files_out_tmp = '';

            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline            
            pipeline(1).(name_stage).label = 'Suppression of noise-related ICA components from individual fMRI data';
            pipeline(1).(name_stage).command = 'niak_brick_clean(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;                       

        end % run

    end % subject

end % size_output

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end