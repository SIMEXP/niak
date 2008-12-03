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
%           PERCENTILE_VOL
%               (structure) options of NIAK_BRICK_PERCENTILE_VOL
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
%       (structure) describe all jobs that need to be performed for
%       evaluation.
%
% _________________________________________________________________________
% COMMENTS
%
%  The steps of the diagnostic pipeline are the following : 
%  
%  0. A mean and percentile distribution for the mean volume and std volume
%  for all subjects & runs with bootstrap statistics.
%
%  1. A temporal and spatial autocorrelation map is derived for all runs 
%  of all subjects, along with a table of percentiles.
%  A mean map and percentile distribution is derived over all subjects & 
%  runs along with bootstrap statistics.
%
%  2. A curve of relative variance in a PCA basis is derived for all
%  motion-corrected data. A mean curve is derived over all subjects & runs 
%  along with bootstrap statistics. 
%
%  3. A standard deviation map of slow time drifts is derived for all runs 
%  of all subjects, along with a table of percentiles.
%  A mean map and percentile distribution is derived over all subjects & 
%  runs along with bootstrap statistics.
%
%  4. A standard deviation map of physiological noise is derived for all 
%  runs of all subjects, along with a table of percentiles.
%  A mean map and percentile distribution is derived over all subjects & 
%  runs along with bootstrap statistics.
%
%  5. For each contrast, a map of the absolute value of the effect is 
%  derived, along with a table of percentiles.
%  Maps and curves for all subjects that have this contrast are combined 
%  into a group-level average along with bootstrap statistics.
%
%  6. For each contrast, a map of standard deviation of the residuals is 
%  derived, along with a table of percentiles.
%  Maps and curves for all subjects that have this contrast are combined 
%  into a group-level average along with bootstrap statistics.
%
%  7. For each contrast, a temporal and spatial autocorrelation map of the 
%  residuals is derived, along with a table of percentiles.
%  Maps and curves for all subjects that have this contrast are combined 
%  into a group-level average along with bootstrap statistics.
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
if ~exist('pipeline_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_DIAGNOSTIC(FILES_IN,OPT).\n Type ''help niak_pipeline_diagnostic'' for more info.')
end

%% Checking that PIPELINE_IN is in the correct format
if ~isstruct(pipeline_in)
    error('PIPELINE_IN should be a struture!')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'folder_out','environment','bricks'};
gb_list_defaults = {NaN,gb_niak_language,struct([])};
niak_set_defaults

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = 1;
gb_list_fields = {'percentile_vol','diff_variance','autocorrelation','spca','boot_mean_vols','boot_curves'};
gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};

niak_set_defaults

%% Getting the subjects labels

name_jobs = fieldnames(pipeline_in);

mask_anat = niak_find_str_cell(name_jobs,'anat');

num_s = 1;

list_subject = cell([sum(mask_anat) 1]);
for num_e = find(mask_anat)'
    
    list_subject{num_s} = name_jobs{num_e}(6:end);
    num_s = num_s + 1;
    
end

nb_subject = length(list_subject);

%% Getting the contrast labels

for num_s = 1:nb_subject
    subject = list_subject{num_s};
    pref_glm = cat(2,'glm_level1_',subject);
    glm_jobs = name_jobs(niak_find_str_cell(name_jobs,'glm_level1'));
    glm_jobs = glm_jobs(niak_find_str_cell(glm_jobs,subject));
    
    list_contrast_tmp = cell([length(glm_jobs) 1]);
    for num_j = 1:length(glm_jobs)
        list_contrast_tmp{num_j} = glm_jobs{num_j}(length(pref_glm)+2:end);
    end
    if num_s == 1
        list_contrast = list_contrast_tmp;
    else
        list_contrast = union(list_contrast,list_contrast_tmp);
    end
end

nb_contrast = length(list_contrast);

%% Getting the func2stereonl transformations
for num_s = 1:nb_subject
    name_concat = cat(2,'concat_transf_nl_',list_subject{num_s});
    list_transformation{num_s} = pipeline_in.(name_concat).files_out;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = pipeline_in;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0a. Group-level mean and bootstrap statistics for the mean volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear files_in_tmp files_out_tmp opt_tmp

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));    

    files_in_tmp(1).vol{num_s} = pipeline_in.(subject_job{1}).files_out.mean_volume;
    files_in_tmp(1).transformation{num_s} = list_transformation{niak_find_str_cell(list_subject,subject)};
end
    
%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'mean_func_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'mean_func_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'mean_func_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_mean_func';
stage.label = 'Group-level mean of the mean volume of motion-corrected data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0b. Individual percentiles for the mean volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));    

    clear files_in_tmp files_out_tmp opt_tmp
    
    %% Files in
    files_in_tmp(1).vol = pipeline_in.(subject_job{1}).files_out.mean_volume;
    files_in_tmp(1).mask = pipeline_in.(subject_job{1}).files_out.mask_volume;

    %% Options
    opt_tmp = opt.bricks.percentile_vol;
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

    %% Outputs
    files_out_tmp = cat(2,opt.folder_out,filesep,subject,filesep,'func_mean_perc_',subject,'.dat');

    %% set the default values
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    clear stage
    name_stage = cat(2,'percentile_mean_func_ind_',subject);
    stage.label = 'Percentile of the mean volume motion-corrected data';
    stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;
    pipeline.(name_stage) = stage;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0c. Group-level statistics on the percentile of the mean volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear files_in_tmp files_out_tmp opt_tmp

%% Files in 
files_in = cell([nb_subject 1]);

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    name_stage_in = cat(2,'percentile_mean_func_ind_',subject);
    files_in_tmp{num_s} = pipeline.(name_stage_in).files_out;
    
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'mean_func_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_func_mean';
stage.label = 'Group-level statistics on the percentiles of the mean volume of motion-corrected data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0d. Group-level mean and bootstrap statistics for the std volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear files_in_tmp files_out_tmp opt_tmp

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));    

    files_in_tmp(1).vol{num_s} = pipeline_in.(subject_job{1}).files_out.std_volume;
    files_in_tmp(1).transformation{num_s} = list_transformation{niak_find_str_cell(list_subject,subject)};
end
    
%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'std_func_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'std_func_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'std_func_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_std_func';
stage.label = 'Group-level mean of the std volume of motion-corrected data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0b. Individual percentiles for the mean volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));    

    clear files_in_tmp files_out_tmp opt_tmp
    
    %% Files in
    files_in_tmp(1).vol = pipeline_in.(subject_job{1}).files_out.std_volume;
    files_in_tmp(1).mask = pipeline_in.(subject_job{1}).files_out.mask_volume;

    %% Options
    opt_tmp = opt.bricks.percentile_vol;
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

    %% Outputs
    files_out_tmp = cat(2,opt.folder_out,filesep,subject,filesep,'std_func_perc_',subject,'.dat');

    %% set the default values
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    clear stage
    name_stage = cat(2,'percentile_std_func_ind_',subject);
    stage.label = 'Percentile of the std volume motion-corrected data';
    stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;
    pipeline.(name_stage) = stage;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0c. Group-level statistics on the percentile of the mean volume %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear files_in_tmp files_out_tmp opt_tmp

%% Files in 
files_in = cell([nb_subject 1]);

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    name_stage_in = cat(2,'percentile_std_func_ind_',subject);
    files_in_tmp{num_s} = pipeline.(name_stage_in).files_out;
    
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'std_func_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_func_std';
stage.label = 'Group-level statistics on the percentiles of the std volume of motion-corrected data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1a. autocorrelation maps of motion-corrected data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'autocorrelation_mc';
name_process2 = 'percentile_autocorrspat_mc';
name_process3 = 'percentile_autocorrtemp_mc';

%% Individual maps

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));

    data_subj = niak_files2cell(pipeline_in.(subject_job{1}).files_out.motion_corrected_data);
    nb_run = length(data_subj);  
    
    for num_r = 1:nb_run
        
        %%%%%%%%%%%%%%%%%%%
        %% Building maps %%
        %%%%%%%%%%%%%%%%%%%
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        files_in_tmp = data_subj{num_r};

        %% Options
        opt_tmp = opt.bricks.autocorrelation;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp.spatial = '';
        files_out_tmp.temporal = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_autocorrelation(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Autocorrelation maps of motion-corrected data';
        stage.command = 'niak_brick_autocorrelation(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;      
        
        stage_autocorr = stage;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Extracting percentages %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% Spatial
        
        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process2,'_',subject,'_',run);
        files_in_tmp.vol = stage_autocorr.files_out.spatial;
        files_in_tmp.mask = pipeline_in.(subject_job{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Percentile of spatial autocorrelation map of motion-corrected data';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;    
        
         %% Temporal
        
        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process3,'_',subject,'_',run);
        files_in_tmp.vol = stage_autocorr.files_out.temporal;
        files_in_tmp.mask = pipeline_in.(subject_job{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Percentile of temporal autocorrelation map of motion-corrected data';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;   

    end % run

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1b. Group-level mean and bootstrap statistics %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEMPORAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_autocorr_mc = name_jobs(niak_find_str_cell(name_jobs,'autocorrelation_mc'));
nb_jobs = length(jobs_autocorr_mc);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_autocorr_mc{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out.temporal;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'autocorrelation_mc_temporal_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'autocorrelation_mc_temporal_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'autocorrelation_mc_temporal_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_autocorr_mc_temporal';
stage.label = 'Group-level mean of temporal autocorrelation maps of motion-corrected data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%% SPATIAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_autocorr_mc = name_jobs(niak_find_str_cell(name_jobs,'autocorrelation_mc'));
nb_jobs = length(jobs_autocorr_mc);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_autocorr_mc{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out.spatial;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'autocorrelation_mc_spatial_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'autocorrelation_mc_spatial_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'autocorrelation_mc_spatial_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_autocorr_mc_spatial';
stage.label = 'Group-level mean of spatial autocorrelation maps of motion-corrected data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1c. Group-level percentile statistics %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEMPORAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_autocorrtemp_mc = name_jobs(niak_find_str_cell(name_jobs,'percentile_autocorrtemp_mc'));
nb_jobs = length(jobs_perc_autocorrtemp_mc);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_autocorrtemp_mc{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'autocorrelation_mc_temporal_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_autocorr_mc_temporal';
stage.label = 'Group-level statistics on the percentiles of the temporal autocorrelation maps of motion-corrected data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%% SPATIAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_autocorrspat_mc = name_jobs(niak_find_str_cell(name_jobs,'percentile_autocorrspat_mc'));
nb_jobs = length(jobs_perc_autocorrspat_mc);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_autocorrspat_mc{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'autocorrelation_mc_spatial_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_autocorr_mc_spatial';
stage.label = 'Group-level statistics on the percentiles of the spatial autocorrelation maps of motion-corrected data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2a. Individual curves of PCA variance of motion-corrected data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_PCA_mc_ind';
name_jobs = fieldnames(pipeline);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    subject_job = motion_jobs(niak_find_str_cell(motion_jobs,subject));
    
    data_subj = niak_files2cell(pipeline_in.(subject_job{1}).files_out.motion_corrected_data);
    nb_run = length(data_subj);  
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        files_in_tmp = data_subj{num_r};

        %% Options
        opt_tmp = opt.bricks.spca;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp.variance = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_spca(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Individual curves of PCA variance for motion-corrected data';
        stage.command = 'niak_brick_spca(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        pipeline.(name_stage) = stage;        

    end % run

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2b. Group curves of PCA variance of motion-corrected data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_var_PCA_mc = name_jobs(niak_find_str_cell(name_jobs,'var_PCA_mc_ind'));
nb_jobs = length(jobs_autocorr_mc);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_var_PCA_mc{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out.variance;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'var_PCA_mc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'var_PCA_mc_group';
stage.label = 'Group-level mean of PCA variance of motion-corrected data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3a. Individual standard-deviation maps of slow-time drifts %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_drifts_ind';
name_process2 = 'perc_drifts_ind';
name_jobs = fieldnames(pipeline);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    SliceTiming_jobs = name_jobs(niak_find_str_cell(name_jobs,'slice_timing'));
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    motion_jobs = motion_jobs(niak_find_str_cell(motion_jobs,subject));
    clear jobs_in jobs_in2
    
    jobs_in = SliceTiming_jobs(niak_find_str_cell(SliceTiming_jobs,subject));
    nb_run = length(jobs_in);
    
    jobs_in2 = cell([length(jobs_in) 1]);
    for num_j = 1:length(jobs_in)
        jobs_in2{num_j} = cat(2,'time_filter',jobs_in{num_j}(length('slice_timing')+1:end));
    end                    
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        files_in_tmp{1} = pipeline.(jobs_in{num_r}).files_out;
        files_in_tmp{2} = pipeline.(jobs_in2{num_r}).files_out.filtered_data;

        %% Options
        opt_tmp = opt.bricks.diff_variance;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_diff_variance(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Individual maps of standard deviation of slow time drifts';
        stage.command = 'niak_brick_diff_variance(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        pipeline.(name_stage) = stage;        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Extracting percentages %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        
        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process2,'_',subject,'_',run);
        files_in_tmp.vol = stage.files_out;
        files_in_tmp.mask = pipeline_in.(motion_jobs{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Individual percentile of the standard deviation of slow time drifts';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;    
        
    end % run

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3b. Group standard-deviation maps of slow-time drifts %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_var_drifts = name_jobs(niak_find_str_cell(name_jobs,'var_drifts_ind'));
nb_jobs = length(jobs_var_drifts);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_var_drifts{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'var_drifts_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'var_drifts_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'var_drifts_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'var_drifts_group';
stage.label = 'Group maps of standard deviation of slow time drifts';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3c. Group-level percentile statistics of drifts %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_drifts = name_jobs(niak_find_str_cell(name_jobs,'perc_drifts_ind'));
nb_jobs = length(jobs_perc_drifts);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_drifts{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'var_drifts_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_drifts';
stage.label = 'Group-level statistics on the percentiles of the slow time drifts';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4a. Individual standard-deviation maps of physiological noise %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_physio_ind';
name_process2 = 'perc_physio_ind';
name_jobs = fieldnames(pipeline);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    TimeFilter_jobs = name_jobs(niak_find_str_cell(name_jobs,'time_filter'));
    motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
    motion_jobs = motion_jobs(niak_find_str_cell(motion_jobs,subject));

    clear jobs_in jobs_in2
    
    jobs_in = TimeFilter_jobs(niak_find_str_cell(TimeFilter_jobs,subject));
    nb_run = length(jobs_in);
    
    for num_j = 1:length(jobs_in)
        jobs_in2{num_j} = cat(2,'component_supp',jobs_in{num_j}(length('time_filter')+1:end));
    end                
    
    for num_r = 1:nb_run
        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        files_in_tmp{1} = pipeline.(jobs_in{num_r}).files_out.filtered_data;
        files_in_tmp{2} = pipeline.(jobs_in2{num_r}).files_out;

        %% Options
        opt_tmp = opt.bricks.diff_variance;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_diff_variance(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Individual maps of standard deviation of physiological noise';
        stage.command = 'niak_brick_diff_variance(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        pipeline.(name_stage) = stage;        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Extracting percentages %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        
        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process2,'_',subject,'_',run);
        files_in_tmp.vol = stage.files_out;
        files_in_tmp.mask = pipeline_in.(motion_jobs{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Individual percentile of the physiological noise';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;    
        
    end % run

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4b. Group standard-deviation maps of physiological noise %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_var_physio = name_jobs(niak_find_str_cell(name_jobs,'var_physio_ind'));
nb_jobs = length(jobs_var_physio);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_var_physio{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'var_physio_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'var_physio_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'var_physio_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'var_physio_group';
stage.label = 'Group maps of standard deviation of physiological noise';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4c. Group-level percentile statistics of physiological noise %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_physio_drifts = name_jobs(niak_find_str_cell(name_jobs,'perc_physio_ind'));
nb_jobs = length(jobs_physio_drifts);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_physio_drifts{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'var_physio_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_physio';
stage.label = 'Group-level statistics on the percentiles of the physiological noise';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5a. Contrast-specific individual maps of absolute effect %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_activation_ind';
name_process2 = 'perc_activation_ind';
name_jobs = fieldnames(pipeline);

for num_c = 1:nb_contrast

    contrast = list_contrast{num_c};

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        clear jobs_in

        %% The linear model jobs
        glm_jobs = name_jobs(niak_find_str_cell(name_jobs,'glm_level1'));
        jobs_in = glm_jobs(niak_find_str_cell(glm_jobs,subject));
        jobs_in = jobs_in(niak_find_str_cell(jobs_in,contrast));
        motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
        motion_jobs = motion_jobs(niak_find_str_cell(motion_jobs,subject));
        clear files_in_tmp files_out_tmp opt_tmp

        if ~isempty(jobs_in)
            
            files_in_tmp{1} = pipeline.(jobs_in{1}).files_in.fmri;
            files_in_tmp{2} = pipeline.(jobs_in{1}).files_out.resid{1};

            %% Options
            opt_tmp = opt.bricks.diff_variance;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

            %% Outputs
            files_out_tmp = '';

            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_diff_variance(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            clear stage
            name_stage = cat(2,name_process,'_',contrast,'_',subject);
            stage.label = 'Individual maps of standard deviation explained by the activation model';
            stage.command = 'niak_brick_diff_variance(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;

            pipeline.(name_stage) = stage;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Extracting percentages %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%

            clear files_in_tmp files_out_tmp opt_tmp
            name_stage = cat(2,name_process2,'_',contrast,'_',subject);
            files_in_tmp.vol = stage.files_out;
            files_in_tmp.mask = pipeline_in.(motion_jobs{1}).files_out.mask_volume;

            %% Options
            opt_tmp = opt.bricks.percentile_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

            %% Outputs
            files_out_tmp = '';

            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            clear stage
            stage.label = sprintf('Individual percentile of the activation (contrast %s)',contrast);
            stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;
            pipeline.(name_stage) = stage;

        end % if the contrast exist for this subject
    end % subject
end % contrast

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5b. Contrast-specific group map of absolute effect %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
name_jobs = fieldnames(pipeline);

for num_c = 1:nb_contrast
    contrast = list_contrast{num_c};
    jobs_var_activation = name_jobs(niak_find_str_cell(name_jobs,cat(2,'var_activation_ind_',contrast)));
    
    nb_jobs = length(jobs_var_activation);

    nb_files = 1;
    
    clear files_in_tmp files_out_tmp opt_tmp
    for num_j = 1:nb_jobs
        name_job_in = jobs_var_activation{num_j};
        files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out;
        files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
        nb_files = nb_files + 1;
    end

    %% Files out
    files_out_tmp.mean = cat(2,opt.folder_out,filesep,'var_activation_',contrast,'_mean.mnc');
    files_out_tmp.std = cat(2,opt.folder_out,filesep,'var_activation_',contrast,'_std.mnc');
    files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'var_activation_',contrast,'_meanstd.mnc');

    %% Options
    opt_tmp = opt.bricks.boot_mean_vols;
    opt_tmp.flag_test = 1;

    %% Defaults
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    clear stage
    name_stage = cat(2,'var_activation_group_',contrast);
    stage.label = cat(2,'Group maps of standard deviation explained by the activation model ',contrast);
    stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;
    pipeline.(name_stage) = stage;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5c. Group-level percentile statistics of activation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_jobs = fieldnames(pipeline);
for num_c = 1:nb_contrast
    clear files_in_tmp files_out_tmp opt_tmp
    
    %% Files in
    contrast = list_contrast{num_c};
    jobs_perc_activation = name_jobs(niak_find_str_cell(name_jobs,cat(2,'perc_activation_ind_',contrast)));
    nb_jobs = length(jobs_perc_activation);

    nb_files = 1;
    for num_j = 1:nb_jobs
        name_job_in = jobs_perc_activation{num_j};
        files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
        nb_files = nb_files + 1;
    end

    %% Files out
    files_out_tmp = cat(2,opt.folder_out,filesep,'var_activation_',contrast,'_perc.dat');

    %% Options
    opt_tmp = opt.bricks.boot_curves;
    opt_tmp.flag_test = 1;

    %% Defaults
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    clear stage
    name_stage = cat(2,'boot_perc_activation_',contrast);
    stage.label = sprintf('Group-level statistics on the activation (contrast %s)',contrast);
    stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;
    pipeline.(name_stage) = stage;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6a. Contrast-specific individual maps of residuals %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_residuals_ind';
name_process2 = 'perc_residuals_ind';
name_jobs = fieldnames(pipeline);

for num_c = 1:nb_contrast

    contrast = list_contrast{num_c};

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        clear jobs_in

        %% The linear model jobs
        glm_jobs = name_jobs(niak_find_str_cell(name_jobs,'glm_level1'));
        jobs_in = glm_jobs(niak_find_str_cell(glm_jobs,subject));
        jobs_in = jobs_in(niak_find_str_cell(jobs_in,contrast));
        motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
        motion_jobs = motion_jobs(niak_find_str_cell(motion_jobs,subject));
        clear files_in_tmp files_out_tmp opt_tmp

        if ~isempty(jobs_in)
            
            files_in_tmp{1} = pipeline.(jobs_in{1}).files_out.resid{1};
            files_in_tmp{2} = '';            
            
            %% Options
            opt_tmp = opt.bricks.diff_variance;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

            %% Outputs
            files_out_tmp = '';

            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_diff_variance(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            clear stage
            name_stage = cat(2,name_process,'_',contrast,'_',subject);
            stage.label = 'Individual maps of standard deviation of the residuals';
            stage.command = 'niak_brick_diff_variance(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;

            pipeline.(name_stage) = stage;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Extracting percentages %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%

            clear files_in_tmp files_out_tmp opt_tmp
            name_stage = cat(2,name_process2,'_',contrast,'_',subject);
            files_in_tmp.vol = stage.files_out;
            files_in_tmp.mask = pipeline_in.(motion_jobs{1}).files_out.mask_volume;

            %% Options
            opt_tmp = opt.bricks.percentile_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

            %% Outputs
            files_out_tmp = '';

            %% set the default values
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            clear stage
            stage.label = sprintf('Individual percentile of the residuals (contrast %s)',contrast);
            stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;
            pipeline.(name_stage) = stage;

        end % if the contrast exist for this subject
    end % subject
end % contrast

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6b. Contrast-specific group maps of residuals %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
name_jobs = fieldnames(pipeline);

jobs_var_residuals = name_jobs(niak_find_str_cell(name_jobs,'var_residuals_ind'));

nb_jobs = length(jobs_var_residuals);

nb_files = 1;

clear files_in_tmp files_out_tmp opt_tmp
for num_j = 1:nb_jobs
    name_job_in = jobs_var_residuals{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'var_residuals_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'var_residuals_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'var_residuals_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = cat(2,'var_residuals_group');
stage.label = 'Group maps of standard deviation of the residuals';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6c. Group-level percentile statistics of physiological noise %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_res = name_jobs(niak_find_str_cell(name_jobs,'perc_residuals_ind'));
nb_jobs = length(jobs_perc_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_res{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'var_residuals_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_residuals';
stage.label = 'Group-level statistics on the percentiles of the residuals';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7a. Individual autocorrelation maps of residual data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'autocorrelation_residuals_ind';
name_process2 = 'perc_autocorrspat_res_ind';
name_process3 = 'perc_autocorrtemp_res_ind';
glm_jobs = name_jobs(niak_find_str_cell(name_jobs,'glm_level1'));

%% Individual maps
for num_c = 1:nb_contrast

    contrast = list_contrast{num_c};

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        subject_jobs = glm_jobs(niak_find_str_cell(glm_jobs,subject));
        subject_jobs = subject_jobs(niak_find_str_cell(subject_jobs,contrast));
        motion_jobs = name_jobs(niak_find_str_cell(name_jobs,'motion_correction'));
        motion_jobs = motion_jobs(niak_find_str_cell(motion_jobs,subject));
        clear files_in_tmp files_out_tmp opt_tmp
        files_in_tmp = pipeline.(subject_jobs{1}).files_out.resid{1};

        %% Options
        opt_tmp = opt.bricks.autocorrelation;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp.spatial = '';
        files_out_tmp.temporal = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_autocorrelation(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        name_stage = cat(2,name_process,'_',contrast,'_',subject);
        stage.label = 'Autocorrelation maps of residual data';
        stage.command = 'niak_brick_autocorrelation(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        
        pipeline.(name_stage) = stage;

        stage_autocorr = stage;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Extracting percentages %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Spatial

        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process2,'_',contrast,'_',subject);
        files_in_tmp.vol = stage_autocorr.files_out.spatial;
        files_in_tmp.mask = pipeline_in.(motion_jobs{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Percentile of spatial autocorrelation map of residuals';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;    
        
         %% Temporal
        
        clear files_in_tmp files_out_tmp opt_tmp
        name_stage = cat(2,name_process3,'_',contrast,'_',subject);
        files_in_tmp.vol = stage_autocorr.files_out.temporal;
        files_in_tmp.mask = pipeline_in.(subject_job{1}).files_out.mask_volume;

        %% Options
        opt_tmp = opt.bricks.percentile_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_percentile_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'Percentile of temporal autocorrelation map of residuals';
        stage.command = 'niak_brick_percentile_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;
        pipeline.(name_stage) = stage;   


    end % subject
end % contrast

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7b. Group autocorrelation maps of residual data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEMPORAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_autocorr_res = name_jobs(niak_find_str_cell(name_jobs,'autocorrelation_residuals_ind'));
nb_jobs = length(jobs_autocorr_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_autocorr_res{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out.temporal;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'autocorrelation_res_temporal_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'autocorrelation_res_temporal_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'autocorrelation_res_temporal_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_autocorr_res_temporal';
stage.label = 'Group-level mean of temporal autocorrelation maps of residual data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%% SPATIAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_autocorr_res = name_jobs(niak_find_str_cell(name_jobs,'autocorrelation_residuals_ind'));
nb_jobs = length(jobs_autocorr_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_autocorr_res{num_j};
    files_in_tmp.vol{nb_files} = pipeline.(name_job_in).files_out.spatial;
    files_in_tmp.transformation{nb_files} = list_transformation{niak_find_str_cell(list_subject,name_job_in)};
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp.mean = cat(2,opt.folder_out,filesep,'autocorrelation_res_spatial_mean.mnc');
files_out_tmp.std = cat(2,opt.folder_out,filesep,'autocorrelation_res_spatial_std.mnc');
files_out_tmp.meanstd = cat(2,opt.folder_out,filesep,'autocorrelation_res_spatial_meanstd.mnc');

%% Options
opt_tmp = opt.bricks.boot_mean_vols;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_mean_vols(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_mean_autocorr_res_spatial';
stage.label = 'Group-level mean of spatial autocorrelation maps of residual data';
stage.command = 'niak_brick_boot_mean_vols(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7c. Group-level percentile statistics of autocorrelation maps of the residuals %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEMPORAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_autocorrtemp_res = name_jobs(niak_find_str_cell(name_jobs,'perc_autocorrtemp_res_ind'));
nb_jobs = length(jobs_perc_autocorrtemp_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_autocorrtemp_res{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'autocorrelation_res_temporal_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_autocorr_res_temporal';
stage.label = 'Group-level statistics on the percentiles of the temporal autocorrelation maps of residuals';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%% TEMPORAL

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_perc_autocorrspat_res = name_jobs(niak_find_str_cell(name_jobs,'perc_autocorrspat_res_ind'));
nb_jobs = length(jobs_perc_autocorrspat_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_perc_autocorrspat_res{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'autocorrelation_res_spatial_perc.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'boot_perc_autocorr_res_spatial';
stage.label = 'Group-level statistics on the percentiles of the spatial autocorrelation maps of residuals';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8a. Individual curves of PCA variance of residual data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'var_PCA_residuals_ind';
name_jobs = fieldnames(pipeline);
glm_jobs = name_jobs(niak_find_str_cell(name_jobs,'glm_level1'));

%% Individual curves
for num_c = 1:nb_contrast

    contrast = list_contrast{num_c};
    
    for num_s = 1:nb_subject

       subject = list_subject{num_s};
        subject_jobs = glm_jobs(niak_find_str_cell(glm_jobs,subject));
        subject_jobs = subject_jobs(niak_find_str_cell(subject_jobs,contrast));
        
        clear files_in_tmp files_out_tmp opt_tmp
        
        %% Files in
        files_in_tmp = pipeline.(subject_jobs{1}).files_out.resid{1};
       
        %% Options
        opt_tmp = opt.bricks.spca;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep);

        %% Outputs
        files_out_tmp.variance = '';

        %% set the default values
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_spca(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        name_stage = cat(2,name_process,'_',contrast,'_',subject);
        stage.label = 'Individual curves of PCA variance for residual data';
        stage.command = 'niak_brick_spca(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        pipeline.(name_stage) = stage;

    end % subject
end % contrast

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8b. Group curves of PCA variance of residual data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Files in
clear files_in_tmp files_out_tmp opt_tmp

name_jobs = fieldnames(pipeline);
jobs_var_PCA_res = name_jobs(niak_find_str_cell(name_jobs,'var_PCA_residuals_ind'));
nb_jobs = length(jobs_autocorr_res);

nb_files = 1;

for num_j = 1:nb_jobs
    name_job_in = jobs_var_PCA_res{num_j};
    files_in_tmp{nb_files} = pipeline.(name_job_in).files_out.variance;
    nb_files = nb_files + 1;
end

%% Files out
files_out_tmp = cat(2,opt.folder_out,filesep,'var_PCA_res.dat');

%% Options
opt_tmp = opt.bricks.boot_curves;
opt_tmp.flag_test = 1;

%% Defaults
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_boot_curves(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

%% Adding the stage to the pipeline
clear stage
name_stage = 'var_PCA_res_group';
stage.label = 'Group-level mean of PCA variance of residual data';
stage.command = 'niak_brick_boot_curves(files_in,files_out,opt)';
stage.files_in = files_in_tmp;
stage.files_out = files_out_tmp;
stage.opt = opt_tmp;
stage.environment = opt.environment;
pipeline.(name_stage) = stage;

%% Get rid of the input pipeline
list_jobs = fieldnames(pipeline_in);
for num_j = 1:length(list_jobs);
    pipeline = rmfield(pipeline,list_jobs{num_j});
end
