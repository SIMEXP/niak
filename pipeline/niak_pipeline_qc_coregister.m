function pipeline = niak_pipeline_qc_coregister(files_in,opt)
% Build a summary of the quality of the coregistration of a series of brain
% volumes.
% This includes the generation of the average & std volumes, as well as the
% relative overlap of the brain masks and the cross-correlation of brain
% volumes within a common mask.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_QC_COREGISTER(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN  
%       (structure) with the following fields : 
%
%       VOLUME
%           (cell of strings) a list of file names of brain volumes.
%
%       MASK
%           (cell of strings) a list of file names of binary brain masks,
%           corresponding to FILES_IN.VOLUME
%
%   OPT   
%       (structure) with the following fields : 
%
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. For the 
%           actual content of folder_out, see the internet 
%           documentation (http://wiki.bic.mni.mcgill.ca/index.php/NiakFmriPreprocessing)
%
%       FLAG_TEST
%           (boolean, default false) If FLAG_TEST is true, the pipeline
%           will just produce a pipeline structure, and will not actually
%           process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%           process the data.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
%
% _________________________________________________________________________
% OUTPUTS: 
%
%   PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
% _________________________________________________________________________
% COMMENTS:
%
% The PSOM pipeline manager is used to process the pipeline if
% OPT.FLAG_TEST is false. PSOM has a number of interesting features to deal
% with job failures or pipeline updates. You can read the following
% tutorial for a review of its capabilities : 
% http://code.google.com/p/psom/wiki/HowToUsePsom
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, quality control, coregistration

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
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_QC_COREGISTER(FILES_IN,OPT).\n Type ''help niak_pipeline_qc_coregister'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)

    error('FILES_IN should be a struture!')
    
else
           
        if ~isfield(files_in,'volume')
            error('I could not find the field FILES_IN.VOLUME!');
        end
                
        if ~iscellstr(files_in.volume)
             error('FILES_IN.VOLUME is not a cell of string!');
        end
        
        if ~isfield(files_in,'mask')
            error('I could not find the field FILES_IN.MASK!');
        end
                
        if ~iscellstr(files_in.mask)
             error('FILES_IN.MASK is not a cell of string!');
        end   
    
end

%% Options
gb_name_structure = 'opt';
default_psom.path_logs = '';
gb_list_fields = {'folder_out','flag_test','psom'};
gb_list_defaults = {NaN,default_psom,struct([])};
niak_set_defaults

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

switch opt.size_output % check that the size of outputs is a valid option
    case {'minimum','quality_control','all'}
        
    otherwise
        error(cat(2,opt.size_output,': is an unknown option for OPT.SIZE_OUTPUT. Available options are ''minimum'', ''quality_control'', ''all'''))
end

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = false;

switch style
    
    case 'fmristat'
    
        gb_list_fields = {'mask_brain','resample_vol','motion_correction','coregister','civet','sica','component_sel','component_supp','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
    
    case 'standard-native'
        
        gb_list_fields = {'mask_brain','resample_vol','motion_correction','slice_timing','coregister','time_filter','civet','sica','component_sel','component_supp','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
        
    case 'standard-stereotaxic'
        
        gb_list_fields = {'mask_brain','motion_correction','slice_timing','coregister','time_filter','civet','smooth_vol','resample_vol','sica','component_sel','component_supp',};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
        
end
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CIVET (spatial normalization) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'anat';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_anat = getfield(files_in,subject,'anat');
    name_stage = cat(2,name_process,'_',subject);
        
    %% Inputs and options
    clear files_in_tmp files_out_tmp opt_tmp
    opt_tmp = opt.bricks.civet;
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

    if isfield(opt_tmp,'civet')
        opt_tmp.civet.id = subject;
        files_in_tmp.anat = '';
    else
        files_in_tmp.anat = data_anat;
    end

    %% Outputs
    files_out_tmp.transformation_lin = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_nativet1_to_stereolin.xfm');
    files_out_tmp.transformation_nl = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl.xfm');
    files_out_tmp.transformation_nl_grid = cat(2,opt_tmp.folder_out,filesep,'transf_',subject,'_stereolin_to_stereonl_grid.mnc');
    files_out_tmp.anat_nuc = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_nativet1.mnc');
    files_out_tmp.anat_nuc_stereo_lin = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereolin.mnc');
    files_out_tmp.anat_nuc_stereo_nl = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_stereonl.mnc');
    files_out_tmp.mask = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_nativet1.mnc');
    files_out_tmp.mask_stereo = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_mask_stereolin.mnc');
    files_out_tmp.classify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_classify_stereolin.mnc');
    files_out_tmp.pve_wm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_wm_stereolin.mnc');
    files_out_tmp.pve_gm = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_gm_stereolin.mnc');
    files_out_tmp.pve_csf = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_pve_csf_stereolin.mnc');
    files_out_tmp.verify = cat(2,opt_tmp.folder_out,filesep,'anat_',subject,'_verify.png');

    %% set the default values
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_civet(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline   
    pipeline(1).(name_stage).command = 'niak_brick_civet(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;    

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')||strcmp(style,'standard-stereotaxic')
    
    name_process = 'slice_timing';    

    for num_s = 1:nb_subject

        subject = list_subject{num_s};    
        list_session = fieldnames(files_in.(subject).fmri);
        nb_session = length(list_session);
        
        for num_sess = 1:nb_session
            
            session = list_session{num_sess};
            files_session = files_in.(subject).fmri.(session);
            nb_run = length(files_session);

            for num_r = 1:nb_run

                run = cat(2,'run',num2str(num_r));
                name_stage = cat(2,'slice_timing_',subject,'_',session,'_',run);

                %% Bulding inputs for NIAK_BRICK_SLICE_TIMING
                files_in_tmp = files_session{num_r};
                files_out_tmp = '';

                %% Setting up options
                opt_tmp = opt.bricks.slice_timing;
                opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

                %% Setting up defaults of the motion correction
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_slice_timing(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Keeping track of the file names
                files_a.(subject).(session){num_r} = files_out_tmp;
                
                %% Adding the stage to the pipeline
                pipeline(1).(name_stage).command = 'niak_brick_slice_timing(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

            end % run
        end % session
    end % subject
end % style of pipeline

%%%%%%%%%%%%%%%%%%%%%%%
%% Motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'motion_correction';
opt_tmp = opt.bricks.motion_correction;

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    name_stage = cat(2,'motion_correction_',subject);
    data_subject = files_in.(subject);    
    
    %% Bulding inputs 
    switch style
        case 'fmristat'
            files_in_tmp.sessions = files_in.(subject).fmri;
        otherwise
            files_in_tmp.sessions = files_a.(subject);
    end    

    %% Building outputs
    switch size_output
        
        case {'minimum','quality_control'}
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.fig_motion = ''; 
            
        case 'all'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.transf_within_session = '';
            files_out_tmp.transf_between_session = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.motion_parameters = '';
            
    end

    %% Setting up default options
    opt_tmp = getfield(opt,'bricks',name_process);
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

    %% Setting up defaults of the motion correction
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_motion_correction(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).command = 'niak_brick_motion_correction(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;

    %% If the amount of outputs is 'minimum' or 'quality_control',
    %% clean the motion-corrected data when the slice-timing corrected
    %% images have been successfully generated.

    if (strcmp(size_output,'minimum')||strcmp(size_output,'quality_control'))&&~strcmp(style,'fmristat')
        
        clear files_in_tmp
        files_in_tmp = pipeline(1).(name_stage).files_out.motion_corrected_data;
        clear opt_tmp
        opt_tmp.clean = pipeline(1).(name_stage).files_in.sessions;
        files_out_tmp = {};
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        name_stage_new = cat(2,'clean_slice_timing_',subject,'_run',num2str(num_r));
        pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
        pipeline(1).(name_stage_new).files_in = files_in_tmp;
        pipeline(1).(name_stage_new).files_out = files_out_tmp;
        pipeline(1).(name_stage_new).opt = opt_tmp;

    end
        
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the native space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'mask_ind_native';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_motion = cat(2,'motion_correction_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp = niak_files2cell(pipeline.(name_stage_motion).files_out.motion_corrected_data);    
    
    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp.mean_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_nativefunc.mnc');
    files_out_tmp.std_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_std_nativefunc.mnc');
    files_out_tmp.mask = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_nativefunc.mnc');
    files_out_tmp.mask_average = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_average_nativefunc.mnc');
    files_out_tmp.tab_fit = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_tab_fit.dat');
    
    %% Setting up options
    opt_tmp = opt.bricks.mask_brain;
    opt_tmp.flag_test = true;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

     %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_mask_brain(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1 T2 coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'coregister';

for num_s = 1:nb_subject

    subject = list_subject{num_s};

    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_mask = cat(2,'mask_ind_native_',subject);
    name_stage_anat = cat(2,'anat_',subject);

    %% Building inputs for NIAK_BRICK_COREGISTER
    files_in_tmp.functional = getfield(pipeline,name_stage_mask,'files_out','mean_average');
    files_in_tmp.anat = getfield(pipeline,name_stage_anat,'files_out','anat_nuc_stereo_lin');
    files_in_tmp.csf = getfield(pipeline,name_stage_anat,'files_out','pve_csf');
    files_in_tmp.transformation = getfield(pipeline,name_stage_anat,'files_out','transformation_lin');
    files_in_tmp.mask = getfield(pipeline,name_stage_anat,'files_out','mask_stereo');
    
    %% Building outputs for NIAK_BRICK_COREGISTER
    files_out_tmp.transformation = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'transf_',subject,'_nativefunc_to_stereolin.xfm');
    files_out_tmp.anat_hires = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_hires.mnc');
    files_out_tmp.anat_lowres = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'anat_',subject,'_nativefunc_lowres.mnc');
    
    %% Setting up options
    opt_tmp = opt.bricks.(name_process);
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep);

    %% Setting up defaults of the coregistration
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_coregister(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_coregister(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Concatenate T2-to-T1_stereo_lin and T1_stereo_lin-to-stereotaxic-nl spatial transformation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'concat_transf_nl';

for num_s = 1:nb_subject

    subject = list_subject{num_s};

    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_coregister = cat(2,'coregister_',subject);
    name_stage_anat = cat(2,'anat_',subject);

    %% Building inputs for NIAK_BRICK_CONCAT_TRANSF
    files_in_tmp{1} = getfield(pipeline,name_stage_coregister,'files_out','transformation');
    files_in_tmp{2} = getfield(pipeline,name_stage_anat,'files_out','transformation_nl');

    %% Building outputs for NIAK_BRICK_CONCAT_TRANSF
    files_out_tmp = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'transf_',subject,'_nativefunc_to_stereonl.xfm');

    %% Setting up options
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_concat_transf(files_in,files_out,opt)';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;    

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the stereotaxic (non-linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%MMMM%%%%%%%%

name_process = 'mask_ind_stereonl';
files_mean_nl = cell([nb_subject 1]);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_concat = cat(2,'concat_transf_nl_',subject);
    name_stage_mask = cat(2,'mask_ind_native_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp(1).transformation = pipeline.(name_stage_concat).files_out;
    files_in_tmp(1).source = pipeline.(name_stage_mask).files_out.mean_average;
    files_in_tmp(1).target = opt.template_fmri;

    files_in_tmp(2).transformation = pipeline.(name_stage_concat).files_out;
    files_in_tmp(2).source = pipeline.(name_stage_mask).files_out.mask;
    files_in_tmp(2).target = opt.template_fmri;

    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp{1} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_stereonl.mnc');
    files_out_tmp{2} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_stereonl.mnc');
    files_mean_nl{num_s} = files_out_tmp{1};
    
    %% Setting up options
    opt_tmp(1) = opt.bricks.resample_vol;
    opt_tmp(2) = opt.bricks.resample_vol;
    opt_tmp(1).interpolation = 'tricubic';
    opt_tmp(2).interpolation = 'nearest_neighbour';

    %% Adding the stage to the pipeline
    pipeline(1).(name_stage).command = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate masks in the stereotaxic (linear) space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'mask_ind_stereolin';
files_mean_lin = cell([nb_subject 1]);

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp

    %% Names of input/output stages
    name_stage = cat(2,name_process,'_',subject);
    name_stage_coregister = cat(2,'coregister_',subject);
    name_stage_mask = cat(2,'mask_ind_native_',subject);
    
    %% Building inputs for NIAK_BRICK_RESAMPLE_VOL
    files_in_tmp(1).transformation = pipeline.(name_stage_coregister).files_out.transformation;
    files_in_tmp(1).source = pipeline.(name_stage_mask).files_out.mean_average;
    files_in_tmp(1).target = opt.template_fmri;
    
    files_in_tmp(2).transformation = pipeline.(name_stage_coregister).files_out.transformation;
    files_in_tmp(2).source = pipeline.(name_stage_mask).files_out.mask;
    files_in_tmp(2).target = opt.template_fmri;

    %% Building outputs for NIAK_BRICK_RESAMPLE_VOL
    files_out_tmp{1} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mean_stereolin.mnc');
    files_out_tmp{2} = cat(2,opt.folder_out,filesep,'anat',filesep,subject,filesep,'func_mask_stereolin.mnc');
    files_mean_lin{num_s} = files_out_tmp{1};
    
    %% Setting up options
    opt_tmp(1) = opt.bricks.resample_vol;
    opt_tmp(2) = opt.bricks.resample_vol;
    opt_tmp(1).interpolation = 'tricubic';
    opt_tmp(2).interpolation = 'nearest_neighbour';
    
     %% Adding the stage to the pipeline        
    pipeline(1).(name_stage).command = 'niak_brick_resample_vol(files_in(1),files_out{1},opt(1)),niak_brick_resample_vol(files_in(2),files_out{2},opt(2))';
    pipeline(1).(name_stage).files_in = files_in_tmp;
    pipeline(1).(name_stage).files_out = files_out_tmp;
    pipeline(1).(name_stage).opt = opt_tmp;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group mask (stereolin) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_job = 'mask_group_stereolin';

clear opt_tmp files_in_tmp files_out_tmp

%% FILES IN
files_in_tmp = files_mean_lin;

%% FILES OUT
[path_f,name_f,ext_f] = fileparts(files_in_tmp{1});

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

files_out_tmp.mean_average = [opt.folder_out filesep 'group' filesep 'func_mean_average_stereolin' ext_f];
files_out_tmp.mask_average = [opt.folder_out filesep 'group' filesep 'func_mask_average_stereolin' ext_f];
files_out_tmp.mask = [opt.folder_out filesep 'group' filesep 'func_mask_group_stereolin' ext_f];
files_out_tmp.tab_fit = [opt.folder_out filesep 'group' filesep 'func_mask_tab_fit_stereolin.dat'];

%% OPT
opt_tmp = opt.bricks.mask_brain;
opt_tmp.flag_test = 1;
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

pipeline.(name_job).command = 'niak_brick_mask_brain(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group mask (stereonl) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_job = 'mask_group_stereonl';

clear opt_tmp files_in_tmp files_out_tmp

%% FILES IN
files_in_tmp = files_mean_nl;

%% FILES OUT
[path_f,name_f,ext_f] = fileparts(files_in_tmp{1});

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

files_out_tmp.mean_average = [opt.folder_out filesep 'group' filesep 'func_mean_average_stereonl' ext_f];
files_out_tmp.mask_average = [opt.folder_out filesep 'group' filesep 'func_mask_average_stereonl' ext_f];
files_out_tmp.mask = [opt.folder_out filesep 'group' filesep 'func_mask_group_stereonl' ext_f];
files_out_tmp.tab_fit = [opt.folder_out filesep 'group' filesep 'func_mask_tab_fit_stereonl.dat'];

%% OPT
opt_tmp = opt.bricks.mask_brain;
opt_tmp.flag_test = 1;
[files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
opt_tmp.flag_test = 0;

pipeline.(name_job).command = 'niak_brick_mask_brain(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'time_filter';

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        name_stage_motion = cat(2,'motion_correction_',subject);
        files_motion = pipeline.(name_stage_motion).files_out.motion_corrected_data;
        list_session = fieldnames(files_motion);
        nb_session = length(list_session);
        nb_run_tot = 0;
        
        for num_sess = 1:nb_session

            session = list_session{num_sess};

            list_files = files_motion.(session);
            nb_run = length(list_files);

            for num_r = 1:nb_run

                nb_run_tot = nb_run_tot + 1;
                
                clear opt_tmp files_in_tmp files_out_tmp

                run = cat(2,'run',num2str(nb_run_tot));
                name_stage = cat(2,name_process,'_',subject,'_',run);
                

                %% Building inputs for NIAK_BRICK_TIME_FILTER
                files_in_tmp = list_files{num_r};

                %% Building outputs for NIAK_BRICK_TIME_FILTER
                switch size_output

                    case 'minimum'

                        files_out_tmp.filtered_data = '';

                    case 'quality_control'

                        files_out_tmp.filtered_data = '';
                        files_out_tmp.var_high = '';
                        files_out_tmp.var_low = '';

                    case 'all'

                        files_out_tmp.filtered_data = '';
                        files_out_tmp.var_high = '';
                        files_out_tmp.var_low = '';
                        files_out_tmp.beta_high = '';
                        files_out_tmp.beta_low = '';
                        files_out_tmp.dc_high = '';
                        files_out_tmp.dc_low = '';

                end

                %% Setting up options
                opt_tmp = opt.bricks.time_filter;
                opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

                %% Setting up defaults of the motion correction
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_time_filter(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                pipeline(1).(name_stage).command = 'niak_brick_time_filter(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

                %% If the amount of outputs is 'minimum' or 'quality_control',
                %% clean the slice-timing-corrected data when temporally
                %% filtered images have been successfully generated.

                if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                    clear files_in_tmp
                    files_in_tmp = pipeline(1).(name_stage).files_out.filtered_data;
                    clear opt_tmp
                    opt_tmp.clean = pipeline(1).(name_stage).files_in;
                    files_out_tmp = {};
                    opt_tmp.flag_test = 1;
                    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                    opt_tmp.flag_test = 0;

                    %% Adding the stage to the pipeline
                    name_stage_new = cat(2,'clean_slice_timing_',subject,'_run',num2str(num_r));
                    pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                    pipeline(1).(name_stage_new).files_in = files_in_tmp;
                    pipeline(1).(name_stage_new).files_out = files_out_tmp;
                    pipeline(1).(name_stage_new).opt = opt_tmp;
                end

            end % run
        end % session
    end % subject
end % style of pipeline

%%%%%%%%%%%%%
%% CORSICA %%
%%%%%%%%%%%%%

name_process = 'corsica';

if flag_corsica % If the user requested a correction of physiological noise

    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        
        switch opt.style
            case 'fmristat'
                
                name_stage_in = cat(2,'motion_correction_',subject);
                nb_run = length(pipeline.(name_stage_in).files_out.motion_corrected_data);
                
            case {'standard-native','standard-stereotaxic'}
                
                name_stage_in = cat(2,'time_filter_',subject);
                job_pipeline = fieldnames(pipeline);
                list_stage_in = job_pipeline(find(niak_find_str_cell(job_pipeline,[name_stage_in '_'])));
                nb_run = length(list_stage_in);
                
        end
           
        name_stage_transf = cat(2,'concat_transf_nl_',subject);

        %% Building inputs for NIAK_PIPELINE_CORSICA
        clear opt_tmp files_in_tmp files_out_tmp
        
        switch opt.style
            
            case 'fmristat'
                                
                files_in_tmp.(subject).fmri = niak_files2cell(pipeline.(name_stage_in).files_out.motion_corrected_data);

            case {'standard-native','standard-stereotaxic'}
                
                for num_r = 1:nb_run
                    files_in_tmp.(subject).fmri{num_r} = deal(pipeline.(list_stage_in{num_r}).files_out.filtered_data);
                end % run
                
        end

        files_in_tmp.(subject).component_to_keep = files_in.(subject).component_to_keep;
        files_in_tmp.(subject).transformation = pipeline.(name_stage_transf).files_out;

        %% Setting up options
        gb_name_structure = 'opt_tmp';
        gb_list_fields = {'flag_test','size_output','folder_out'};
        gb_list_defaults = {true,opt.size_output,cat(2,opt.folder_out,filesep,'sica',filesep)};
        niak_set_defaults;
        opt_tmp.bricks.sica = opt.bricks.sica;
        opt_tmp.bricks.component_sel = opt.bricks.component_sel;
        opt_tmp.bricks.component_supp = opt.bricks.component_supp;
        
        %% Adding the stages to the pipeline
        pipeline_corsica = niak_pipeline_corsica(files_in_tmp,opt_tmp);
        pipeline = niak_merge_structs(pipeline,pipeline_corsica);
        
        %% If the amount of outputs is 'minimum' or 'quality_control',
        %% clean the temporally filtered data when phyisiological-noise 
        %% corrected images have been successfully generated.
        
        if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')

            for num_r = 1:nb_run
                run = cat(2,'run',num2str(num_r));
                name_stage = cat(2,'component_supp_',subject,'_',run);
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in.fmri;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                switch style
                    case 'fmristat'
                        name_stage_new = cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r));
                    case {'standard-native'}
                        name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                end
                
                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                               
            end % run
        end % Cleaning ('minimum' or 'quality_control')

    end % subject

end % if flag_corsica

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (native space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

if strcmp(style,'fmristat')|strcmp(style,'standard-native')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        job_pipeline = fieldnames(pipeline);
        stage_motion = cat(2,'motion_correction_',subject);
        files_motion = niak_files2cell(pipeline.(stage_motion).files_out.motion_corrected_data);        
        nb_run = length(files_motion);

        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp

            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,name_process,'_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_SMOOTH_VOL

            if flag_corsica
                
                %% CORSICA has been applied, we use the
                %% physiologically-corrected data
                name_stage_in = cat(2,'component_supp_',subject,'_',run);
                files_in_tmp = pipeline.(name_stage_in).files_out;
                
            else
                %% NO CORSICA !
                
                switch style
                    
                    case 'fmristat'                     
                        
                        %% For fMRIstat
                        files_in_tmp = files_motion{num_r};
                        
                    case {'standard-native'}
                        
                        name_stage_in = cat(2,'time_filter_',subject,'_',run);
                        files_in_tmp = pipeline.(name_stage_in).files_out.filtered_data;
                        
                end
            end

            %% Building outputs for NIAK_BRICK_SMOOTH_VOL
            files_out_tmp = '';

            %% Setting up options
            opt_tmp = opt.bricks.smooth_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline           
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;            

            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the inputs when the outpus have been successfully
            %% generated

            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                if flag_corsica
                    
                    name_stage_new = cat(2,'clean_corsica_',subject,'_run',num2str(num_r));                                        
                    
                else

                    switch style
                        case 'fmristat'
                            name_stage_new = cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r));
                        case {'standard-native'}
                            name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));
                    end                    
                    
                end

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                

            end

        end % run
    end % subject
end % Styles 'fmristat' or 'standard_native'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial resampling in stereotaxic space %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-stereotaxic')

    name_process = 'resample_vol';

    for num_s = 1:nb_subject

        subject = list_subject{num_s};               
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);
        name_stage_transf = cat(2,'concat_transf_nl_',subject);
        
        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp
            
            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,name_process,'_',subject,'_',run);
            if flag_corsica
                name_stage_in = cat(2,'component_supp_',subject,'_',run);
            else
                name_stage_in = cat(2,'time_filter_',subject,'_',run);
            end

            %% Building inputs 
            if flag_corsica
                files_in_tmp.source = pipeline.(name_stage_in).files_out;
            else
                files_in_tmp.source = pipeline.(name_stage_in).files_out.filtered_data;
            end            
            files_in_tmp.target = opt.template_fmri;
            files_in_tmp.transformation = getfield(pipeline,name_stage_transf,'files_out');

            %% Building outputs 
            files_out_tmp = '';            
            
            %% Setting up options
            opt_tmp = opt.bricks.resample_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults 
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_resample_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline                        
            pipeline(1).(name_stage).command        =   'niak_brick_resample_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in       =   files_in_tmp;
            pipeline(1).(name_stage).files_out      =   files_out_tmp;
            pipeline(1).(name_stage).opt            =   opt_tmp;            
            
            %% If the amount of outputs is 'minimum' 
            %% clean the slice-timing-corrected data when temporally
            %% filtered images have been successfully generated.
            %% In 'quality_control mode' we keep these images as there are
            %% the only one left in native space.
            
            if strcmp(opt.size_output,'minimum')|strcmp(opt.size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in.source;
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                
                if flag_corsica
                    name_stage_new = cat(2,'clean_corsica_',subject,'_run',num2str(num_r));                    
                else
                    name_stage_new = cat(2,'clean_time_filter_',subject,'_run',num2str(num_r));                    
                end
                                
                pipeline(1).(name_stage_new).command     =  'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in    =  files_in_tmp;
                pipeline(1).(name_stage_new).files_out   =  files_out_tmp;
                pipeline(1).(name_stage_new).opt         =  opt_tmp;                

            end
            
        end % run
    end % subject
end % style of pipeline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing (stereotaxic space) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

if strcmp(style,'standard-stereotaxic')

    for num_s = 1:nb_subject

        subject = list_subject{num_s};
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);      

        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp

            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,name_process,'_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_SMOOTH_VOL
            name_stage_in = cat(2,'resample_vol_',subject,'_',run);
            files_in_tmp = pipeline.(name_stage_in).files_out;


            %% Building outputs for NIAK_BRICK_SMOOTH_VOL
            files_out_tmp = '';

            %% Setting up options
            opt_tmp = opt.bricks.smooth_vol;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline            
            pipeline(1).(name_stage).command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;            

            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the inputs when the outpus have been successfully
            %% generated

            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                
                clear files_in_tmp
                files_in_tmp = pipeline(1).(name_stage).files_out;
                clear opt_tmp
                opt_tmp.clean = pipeline(1).(name_stage).files_in;
                files_out_tmp = {};

                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;

                %% Adding the stage to the pipeline
                name_stage_new = cat(2,'clean_resample_vol_',subject,'_run',num2str(num_r));                

                pipeline(1).(name_stage_new).command = 'niak_brick_clean(files_in,files_out,opt)';
                pipeline(1).(name_stage_new).files_in = files_in_tmp;
                pipeline(1).(name_stage_new).files_out = files_out_tmp;
                pipeline(1).(name_stage_new).opt = opt_tmp;                

            end

        end % run
    end % subject
end % Styles 'fmristat' or 'standard_native'

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end