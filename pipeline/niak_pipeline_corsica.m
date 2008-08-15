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
%           FILES_IN.<SUBJECT> should be from the same subject.
%
%       <SUBJECT>.TRANSFORMATION 
%           (string, default identity) a transformation from the functional 
%           space to the "MNI152 non-linear" space.
%
%  * OPT   
%       (structure) with the following fields : 
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. For the 
%           actual content of FOLDER_OUT, see the internet documentation 
%           (http://?.?)
%
%       ENVIRONMENT 
%           (string, default current environment) Available options : 
%           'matlab', 'octave'. The environment where the pipeline will run. 
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
%                   will be suppressed. If the threshold is Inf, an 
%                   adaptative method based on the Otsu algorithm will be 
%                   applied to select the threshold automatically.
%
% _________________________________________________________________________
% OUTPUTS
%
%  * PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline. This structure is meant to be use in the function
%       NIAK_INIT_PIPELINE.
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
        
        data_transf = getfield(data_subject,'transformation');
        if ~ischar(data_transf)
             error('FILE_IN.%s.TRANSFORMATION is not a string!',upper(subject));
        end
        
    end
    
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'folder_out','environment','bricks'};
gb_list_defaults = {NaN,gb_niak_language,struct([])};
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
        name_stage = cat(2,name_process,'_',subject,'_',num2str(num_r));
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
        stage.label = 'Individual spatial independent component analysis';
        stage.command = 'niak_brick_sica(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

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
        
        name_stage = cat(2,name_process,'_',subject,'_',num2str(num_r));
               
        name_stage_in = cat(2,'sica_',subject,'_',num2str(num_r));
        stage_in = getfield(pipeline,name_stage_in);
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.component = stage_in.files_out.time;
        files_in_tmp.mask = cat(2,gb_niak_path_niak,'template',filesep,'roi_ventricle.mnc');

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
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

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
        
        name_stage = cat(2,name_process,'_',subject,'_',num2str(num_r));
               
        name_stage_in = cat(2,'sica_',subject,'_',num2str(num_r));
        stage_in = getfield(pipeline,name_stage_in);
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.component = stage_in.files_out.time;
        files_in_tmp.mask = cat(2,gb_niak_path_niak,'template',filesep,'roi_stem.mnc');

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
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

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
        
        name_stage = cat(2,name_process,'_',subject,'_',num2str(num_r));
               
        %% Names of previous stages
        name_stage_in0 = cat(2,'sica_',subject,'_',num2str(num_r));
        name_stage_in1 = cat(2,'component_sel_ventricle_',subject,'_',num2str(num_r));
        name_stage_in2 = cat(2,'component_sel_stem_',subject,'_',num2str(num_r));
        stage_in0 = getfield(pipeline,name_stage_in);
        stage_in1 = getfield(pipeline,name_stage_in1);
        stage_in2 = getfield(pipeline,name_stage_in2);        
        
        %% Inputs 
        files_in_tmp.fmri = data_subj.fmri{num_r};        
        files_in_tmp.space = stage_in0.files_out.space;
        files_in_tmp.time = stage_in0.files_out.time;
        files_in_tmp.compsel{1} = stage_in1.files_out;
        files_in_tmp.compsel{2} = stage_in2.files_out;

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
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

    end % run

end % subject

