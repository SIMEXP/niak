function pipeline = niak_pipeline_diagnostic(pipeline_in,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_PIPELINE_DIAGNOSTIC
%
% Build diagnostic measures from an individual GLM pipeline
% ('standard-native' preprocessing style with " opt.size_output = 'all' "/
%
% PIPELINE = NIAK_PIPELINE_DIAGNOSTIC(PIPELINE_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * PIPELINE_IN
%       (structure) generated through NIAK_PIPELINE_GLM (not available at
%       this point 09/2008).
%
%  * OPT   
%       (structure) with the following fields : 
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline.
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
%           DIFF_VARIANCE
%               (structure) options of NIAK_BRICK_DIFF_VARIANCE
%
%           AUTOCORRELATION
%               (structure) options of NIAK_BRICK_AUTOCORRELATION
%
%           SPCA 
%               (structure) options of NIAK_BRICK_SPCA
%
%               NB_COMP 
%                   (integer) the number of components (default 60).
%
%           BOOT_MEAN_VOLS
%               (structure) options of NIAK_BRICK_BOOT_MEAN_VOLS
%               
%               FLAG_MASK 
%                   (boolean, default 1) if FLAG_MASK equals one, the
%                   standard deviation will only be evaluated in a mask of 
%                   the brain (that's speeding up bootstrap calculations).
% 
%               NB_SAMPS
%                   (integer, default 1000) the number of bootstrap samples 
%                   used to compute the standard-deviation-of-the-mean map.
%
%           BOOT_CURVES
%               (structure) options of NIAK_BRICK_BOOT_CURVES.
%               
%              PERCENTILES
%                   (vector, default [0.0005 0.025 0.975 0.9995])
%                   the (unilateral) confidence level of bootstrap
%                   confidence intervals.
%
%              NB_SAMPS
%                   (integer, default 10000) the number of bootstrap samples
%                   used to compute the standard-deviation-of-the-mean 
%                   and the bootstrap confidence interval on the mean.
%
% _________________________________________________________________________
% OUTPUTS
%
%  * PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline. This structure is meant to be use in the function
%       NIAK_INIT_PIPELINE. It includes PIPELINE_IN.
%
% _________________________________________________________________________
% COMMENTS
%
%  The steps of the diagnostic pipeline are the following : 
%  
%  1. A temporal and spatial autocorrelation map is derived for all
%  motion-corrected data. A mean map is derived over all subjects & runs 
%  along with bootstrap statistics.
%
%  2. A curve of relative variance in a PCA basis is derived for all
%  motion-corrected data. A mean curve is derived over all subjects & runs 
%  along with bootstrap statistics. 
%
%  3. A standard deviation map of slow time drifts is derived for all runs 
%  of all subjects. A mean map is derived over all subjects & runs along with 
%  bootstrap statistics.
%
%  4. A standard deviation map of physiological noise is derived for all 
%  runs of all subjects. A mean map is derived over all subjects & runs 
%  along with bootstrap statistics.
%
%  5. A map of the absolute value of the effect of each contrast is derived.
%  Maps for all subjects that have this contrast are combined into a 
%  group-level average along with bootstrap statistics.
%
%  6. For each contrast, a map of standard deviation of the residuals is 
%  derived. Maps for all subjects that have this contrast are combined into
%  a group-level average along with bootstrap statistics.
%
%  7. For each contrast, a temporal and spatial autocorrelation map of the 
%  residuals is derived. Maps for all subjects that have this contrast 
%  are combined into a group-level average along with bootstrap statistics.
%  
%  8. For each contrast, curve of relative variance in a PCA basis is 
%  derived on the residuals. Maps for all subjects that have this contrast 
%  are combined into a group-level average along with bootstrap statistics.
%
% _________________________________________________________________________
% REFERENCES
% 
% P. Bellec;V. Perlbarg;H. Benali;K. Worsley;A. Evans, Realistic fMRI
% simulations using parametric model estimation over a large database (ICBM 
% FRB). Proceedings of the 13th International Conference on Functional 
% Mapping of the Human Brain, 2007.
%
% Hopefully a regular article will come soon.
% 
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
gb_list_fields = {'size_output','folder_out','environment','bricks'};
gb_list_defaults = {'quality_control',NaN,gb_niak_language,struct([])};
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
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
               
        name_stage_in = cat(2,'sica_',subject,'_',run);
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
        
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
               
        name_stage_in = cat(2,'sica_',subject,'_',run);
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
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

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
            pipeline(1).(name_stage).command = 'niak_brick_component_supp(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
            pipeline(1).(name_stage).environment = opt.environment;           

        end % run

    end % subject

end % size_output

