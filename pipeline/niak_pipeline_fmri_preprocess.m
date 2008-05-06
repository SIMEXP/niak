function pipeline = niak_pipeline_fmri_preprocess(files_in,opt)

% Build a pipeline structure for performing preprocessing of an fMRI
% database. Mutliple preprocessing "styles" are available, depending on the
% analysis planned afterwards, and the amount of outputs generated can adjusted.
%
% INPUTS : 
% FILES_IN  (structure) with the following fields : 
%       FILES_IN.<SUBJECT>.FMRI.<SESSION>   (cell of strings) a list of fMRI 
%           datasets, acquired in the same session (small displacements). 
%           The field names <SUBJECT> and <SESSION> can be any arbitrary strings.
%           All data in FILES_IN.<SUBJECT> should be from the same subject.
%
%       FILES_IN.<SUBJECT>.ANAT (string) anatomical volume, from the same
%           subject as in FILES_IN.<SUBJECT>.FMRI
%
% OPT   (structure) with the following fields : 
%       STYLE (string) 
%           possible values : ‘fmristat’, ‘standard-native’,
%           ‘standard-stereotaxic’.
%           Select the "style" of preprocessing, i.e. the exact series of 
%           processing steps that will be applied to the data. See the
%           NOTES at the end of this documentation.
%
%       SIZE_OUTPUTS (string, default 'quality_control') 
%           possible values : ‘minimum’, 'quality_control’, ‘all’.
%           The quantity of intermediate results that are generated. For a 
%           detailed list of outputs in each mode, see the internet
%           documentation (http://?.?)
%           * With the option ‘minimum’, only the raw data and preprocessed 
%              data at the final stage are generated. All intermediate 
%              outputs are cleaned as soon as possible. 
%           * With the option ‘quality_control’ some outputs are generated 
%              at each step of the analysis for purposes of quality control. 
%           * With the option ‘all’, all possible outputs are generated at 
%              each stage of the pipeline. 
%       
%       FOLDER_OUT (string)
%           where to write the results of the pipeline. For the actual 
%           content of folder_out, see the internet documentation (http://?.?)
%
%       ENVIRONMENT (string, default 'octave') 
%           Available options : 'matlab', 'octave'. 
%           The environment where the pipeline will run. 
%
%       BRICKS (structure) The fields of OPT.BRICKS depend on the style of 
%       pre-processing. 
%       Note that the options will be common to all runs, all sessions and 
%       all subjects. Subjects with different options need to be processed 
%       in different pipelines. 
%       The following fields are common to all styles. Each field
%       correspond to one brick, which is indicated. Please refer to the
%       help of the brick for detail. Unless specified, the fields can be
%       simply omitted, in which case the default options are used.
%       
%          MOTION_CORRECTION (structure) options of
%               NIAK_BRICK_MOTION_CORRECTION 
%       
%          CIVET (structure) Options of NIAK_BRICK_CIVET, the brick of 
%               spatial normalization (non-linear transformation of T1 image 
%               in the stereotaxic space). If OPT.CIVET.CIVET is used to 
%               specify the use of previously generated data, there is no need 
%               to fill the subfields OPT.CIVET.CIVET.ID. The subject ids will 
%               be assumed to match the field names <SUBJECT> in FILES_IN. 
%               It is still necessay to specify OPT.CIVET.CIVET.PREFIX and 
%               OPT.CIVET.CIVET.FOLDER though.
%
%         COREGISTER (structure) options of NIAK_BRICK_COREGISTER 
%               (coregistration between T1 and T2).
%
%         SMOOTH_VOL (structure) options of NIAK_BRICK_SMOOTH_VOL (spatial
%               smoothing).
%
%         The Following additional fields have (or can) be used if the
%         preprocessing style is 'standard-native' or 'standard-stereotaxic':
%
%         SLICE_TIMING (structure) options of NIAK_BRICK_SLICE_TIMING
%              (correction of slice timing effects). The following fields
%              need to be specified :
%
%            SLICE_ORDER (vector of integer) SLICE_ORDER(i) = k means
%                that the kth slice was acquired in ith position. The
%                order of the slices is assumed to be the same in all
%                volumes.
%                ex : slice_order = [1 3 5 2 4 6]
%                    for 6 slices acquired in 'interleaved' mode,
%                    starting by odd slices(slice 5 was acquired in 3rd 
%                    position).
% 
%            TIMING		(vector 2*1) 
%                TIMING(1) : time between two slices
%                TIMING(2) : time between last slice and next volume
%
%         TIME_FILTER (structure) options of NIAK_BRICK_TIME_FILTER
%           (temporal filtering).
%
%  OUTPUTS : 
%
%  PIPELINE (structure) describes all jobs that need to be performed in the
%           pipeline. This structure is meant to be use in the function
%           NIAK_INIT_PIPELINE.
%
%  NOTES :
%  The steps of the pipeline are the following :
%  
%  * style 'fmristat' :
%       1.  Motion correction (within- and between-run for each subject).
%       2.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       3.  Spatial normalization of the anatomical image, after 
%           coregistration with the functional.
%       4.  Spatial smoothing.
%
%  * style 'standard-native'
%       1.  Motion correction (within- and between-run for each subject).
%       2.  Slice timing correction
%       3.  Coregistration of the anatomical volume with the mean 
%           functional volume.
%       4.  Correction of slow time drifts.
%       5.  Spatial smoothing.
%       6.  Spatial normalization of the anatomical image, after 
%           coregistration with the functional.
%   
%  * style 'standard-stereotaxic'
%       Same as 'standard-native', with the following additional step : 
%       7.  Resampling of the functional data in the stereotaxic space.
%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if ~exist('files_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess'' for more info.')
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
            error('FILE_IN.%s should be a struture!',upper(subject));
        end
        
        if ~isfield(data_subject,'fmri')
            error('I could not find the field FILE_IN.%s.FMRI!',upper(subject));
        end
        
        data_fmri = getfield(data_subject,'fmri');
        list_session{num_s} = fieldnames(data_fmri);
        
        for num_c = 1:length(list_session{num_s})
            session = list_session{num_s}{num_c};
            data_session = getfield(data_fmri,session);
            if ~iscellstr(data_session)
                error('FILE_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end
        end
        
        if ~isfield(data_subject,'anat')
            error('I could not find the field FILE_IN.%s.ANAT!',upper(subject));
        end
        
        data_anat = getfield(data_subject,'anat');
        if ~ischar(data_anat)
             error('FILE_IN.%s.ANAT is not a string!',upper(subject));
        end
        
    end
    
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'style','size_output','folder_out','environment','bricks'};
gb_list_defaults = {NaN,'quality_control',NaN,'octave',struct([])};
niak_set_defaults

%% The options for the bricks
gb_name_structure = 'opt.bricks';
opt_tmp.flag_test = 1;

switch style
    
    case 'fmristat'
    
        gb_list_fields = {'motion_correction','coregister','civet','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp};
    
    case {'standard-native','standard-stereotaxic'}
        
        gb_list_fields = {'motion_correction','slice_timing','coregister','time_filter','civet','smooth_vol'};
        gb_list_defaults = {opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp,opt_tmp};
        
end
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

%%%%%%%%%%%%%%%%%%%%%%%
%% Motion correction %%
%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'motion_correction';
opt_tmp = opt.bricks.motion_correction;
opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep);

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    name_stage = cat(2,'motion_correction_',subject);
    data_subject = getfield(files_in,subject);    
    
    %% Bulding inputs for NIAK_BRICK_MOTION_CORRECTION
    files_in_tmp.sessions = getfield(data_subject,'fmri');

    switch size_output
        
        case 'minimum'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.mean_volume = '';
            
        case 'quality_control'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.mean_volume = '';
            
        case 'all'
            
            files_out_tmp.motion_corrected_data = '';
            files_out_tmp.transf_within_session = '';
            files_out_tmp.transf_between_session = '';
            files_out_tmp.fig_motion = '';
            files_out_tmp.motion_parameters = '';
            files_out_tmp.mean_volume = '';
            files_out_tmp.mask_volume = '';
            
    end
    
    %% Setting up defaults of the motion correction
    opt_tmp.flag_test = 1;    
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_motion_correction(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;
    
    %% Adding the stage to the pipeline
    stage.label = 'Correction of within- and between-sessions motion correction';
    stage.command = 'niak_brick_motion_correction(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;
    
    if isempty(pipeline)
        eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
    else
        pipeline = setfield(pipeline,name_stage,stage);
    end
        
end
          
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% slice-timing correction %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'slice_timing';    

    for num_s = 1:nb_subject

        subject = list_subject{num_s};        
        name_stage_in = cat(2,'motion_correction_',subject);
        files_run = niak_files2cell(getfield(pipeline,name_stage_in,'files_out','motion_corrected_data'));
        nb_run = length(files_run);
        
        for num_r = 1:nb_run

            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,'slice_timing_',subject,'_',run);

            %% Bulding inputs for NIAK_BRICK_SLICE_TIMING
            files_in_tmp = files_run{num_r};
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.slice_timing;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep,name_process,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_slice_timing(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline
            clear stage
            stage.label = 'Correction of slice-timing';
            stage.command = 'niak_brick_slice_timing(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;

            if isempty(pipeline)
                eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
            else
                pipeline = setfield(pipeline,name_stage,stage);
            end
            
            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the motion-corrected data when slice-timing corrected
            %% images have been successfully generated.
            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                clear files_in_tmp
                files_in_tmp = {stage.files_out};
                clear opt_tmp
                opt_tmp.clean = {stage.files_in};
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                clear stage
                stage.label = 'Cleaning motion-corrected data';
                stage.command = 'niak_brick_clean(files_in,files_out,opt)';
                stage.files_in = files_in_tmp;
                stage.files_out = files_out_tmp;
                stage.opt = opt_tmp;
                stage.environment = opt.environment;
                pipeline = setfield(pipeline,cat(2,'clean_motion_',subject,'_run',num2str(num_r)),stage);
            end
            
        end % run
    end % subject
end % style of pipeline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CIVET (spatial normalization %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'anat';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    data_anat = getfield(files_in,subject,'anat');
    name_stage = cat(2,name_process,'_',subject);
        
    %% Inputs and options
    clear files_in_tmp files_out_tmp opt_tmp
    opt_tmp = opt.bricks.civet;
    opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep,name_process,filesep);

    if isfield(opt_tmp,'civet')
        opt_tmp.civet.id = subject;
        files_in_tmp.anat = '';
    else
        files_in_tmp.anat = data_anat;
    end

    %% Outputs
    files_out_tmp.transformation_lin = '';
    files_out_tmp.transformation_nl = '';
    files_out_tmp.transformation_nl_grid = '';
    files_out_tmp.anat_nuc_native = '';
    files_out_tmp.anat_nuc_stereo_lin = '';
    files_out_tmp.anat_nuc_stereo_nl = '';
    files_out_tmp.mask_native = '';
    files_out_tmp.mask_stereo = '';
    files_out_tmp.classify = '';
    files_out_tmp.pve_wm = '';
    files_out_tmp.pve_gm = '';
    files_out_tmp.pve_csf = '';
    files_out_tmp.verify = '';

    %% set the default values
    opt_tmp.flag_test = 1;
    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_civet(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = 0;

    %% Adding the stage to the pipeline
    clear stage
    stage.label = 'Processing of the anatomical data (transformation to stereotaxic space)';
    stage.command = 'niak_brick_civet(files_in,files_out,opt)';
    stage.files_in = files_in_tmp;
    stage.files_out = files_out_tmp;
    stage.opt = opt_tmp;
    stage.environment = opt.environment;

    if isempty(pipeline)
        eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
    else
        pipeline = setfield(pipeline,name_stage,stage);
    end

end % subject

%%%%%%%%%%%%%%%%%%%%%%%%
%% temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(style,'standard-native')|strcmp(style,'standard-stereotaxic')
    
    name_process = 'time_filter';    

    for num_s = 1:nb_subject

        subject = list_subject{num_s};               
        job_pipeline = fieldnames(pipeline);
        files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
        nb_run = length(files_raw);
        
        for num_r = 1:nb_run

            clear opt_tmp files_in_tmp files_out_tmp
            
            run = cat(2,'run',num2str(num_r));            
            name_stage = cat(2,name_process,'_',subject,'_',run);
            name_stage_in = cat(2,'slice_timing_',subject,'_',run);

            %% Building inputs for NIAK_BRICK_TIME_FILTER
            files_in_tmp = getfield(pipeline,name_stage_in,'files_out');
            
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
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep,name_process,filesep);

            %% Setting up defaults of the motion correction
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_time_filter(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
                        
            %% Adding the stage to the pipeline
            clear stage
            stage.label = 'temporal filtering';
            stage.command = 'niak_brick_time_filter(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;

            if isempty(pipeline)
                eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
            else
                pipeline = setfield(pipeline,name_stage,stage);
            end
            
            %% If the amount of outputs is 'minimum' or 'quality_control',
            %% clean the slice-timing-corrected data when temporally
            %% filtered images have been successfully generated.
            
            if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
                clear files_in_tmp
                files_in_tmp = stage.files_out.filtered_data;
                clear opt_tmp
                opt_tmp.clean = stage.files_in;
                files_out_tmp = {};
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Adding the stage to the pipeline
                clear stage
                stage.label = 'Cleaning slice-timing-corrected data';
                stage.command = 'niak_brick_clean(files_in,files_out,opt)';
                stage.files_in = files_in_tmp;
                stage.files_out = files_out_tmp;
                stage.opt = opt_tmp;
                stage.environment = opt.environment;
                pipeline = setfield(pipeline,cat(2,'clean_slice_timing_',subject,'_run',num2str(num_r)),stage);
            end
            
        end % run
    end % subject
end % style of pipeline


%%%%%%%%%%%%%%%%%%%%%%%
%% spatial smoothing %%
%%%%%%%%%%%%%%%%%%%%%%%

name_process = 'smooth_vol';

for num_s = 1:nb_subject

    subject = list_subject{num_s};
    job_pipeline = fieldnames(pipeline);
    files_raw = niak_files2cell(getfield(files_in,subject,'fmri'));
    nb_run = length(files_raw);
    
    switch style
            case 'fmristat'
                name_stage_in = cat(2,'motion_correction_',subject);
                files_run = niak_files2cell(getfield(pipeline,name_stage_in,'files_out','motion_corrected_data'));                
            case {'standard-native','standard-stereotaxic'}
                name_stage_in = cat(2,'time_filter_',subject,'_',run);
                files_in_tmp = getfield(pipeline,name_stage_in,'files_out','filtered_data');
        end     
    

    
    
        
    for num_r = 1:nb_run

        clear opt_tmp files_in_tmp files_out_tmp

        run = cat(2,'run',num2str(num_r));
        name_stage = cat(2,name_process,'_',subject,'_',run);
        
        %% Building inputs for NIAK_BRICK_TIME_FILTER
        switch style
            case 'fmristat'                
                files_in_tmp = files_run{num_r};
            case {'standard-native','standard-stereotaxic'}
                name_stage_in = cat(2,'time_filter_',subject,'_',run);
                files_in_tmp = getfield(pipeline,name_stage_in,'files_out','filtered_data');
        end                

        %% Building outputs for NIAK_BRICK_SMOOTH_VOL
        files_out_tmp = '';
        
        %% Setting up options
        opt_tmp = opt.bricks.smooth_vol;
        opt_tmp.folder_out = cat(2,opt.folder_out,filesep,subject,filesep,name_process,filesep);

        %% Setting up defaults of the motion correction
        opt_tmp.flag_test = 1;
        [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_smooth_vol(files_in_tmp,files_out_tmp,opt_tmp);
        opt_tmp.flag_test = 0;

        %% Adding the stage to the pipeline
        clear stage
        stage.label = 'spatial smoothing';
        stage.command = 'niak_brick_smooth_vol(files_in,files_out,opt)';
        stage.files_in = files_in_tmp;
        stage.files_out = files_out_tmp;
        stage.opt = opt_tmp;
        stage.environment = opt.environment;

        if isempty(pipeline)
            eval(cat(2,'pipeline(1).',name_stage,' = stage;'));
        else
            pipeline = setfield(pipeline,name_stage,stage);
        end

        %% If the amount of outputs is 'minimum' or 'quality_control',
        %% clean the inputs when the outpus have been successfully
        %% generated

        if strcmp(size_output,'minimum')|strcmp(size_output,'quality_control')
            clear files_in_tmp
            files_in_tmp = stage.files_out;
            clear opt_tmp
            opt_tmp.clean = stage.files_in;
            files_out_tmp = {};
            
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_clean(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;

            %% Adding the stage to the pipeline
            clear stage
            switch style
                case 'fmristat'
                    stage.label = 'Cleaning motion-corrected data';
                case {'standard-native','standard-stereotaxic'}
                    stage.label = 'Cleaning temporelly filtered data';
            end
            
            stage.command = 'niak_brick_clean(files_in,files_out,opt)';
            stage.files_in = files_in_tmp;
            stage.files_out = files_out_tmp;
            stage.opt = opt_tmp;
            stage.environment = opt.environment;
            
            switch style
                case 'fmristat'
                    pipeline = setfield(pipeline,cat(2,'clean_motion_correction_',subject,'_run',num2str(num_r)),stage);
                case {'standard-native','standard-stereotaxic'}
                    pipeline = setfield(pipeline,cat(2,'clean_time_filter_',subject,'_run',num2str(num_r)),stage);
            end            
        end

    end % run
end % subject


