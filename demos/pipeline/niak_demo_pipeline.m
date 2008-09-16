% This is a script to demonstrate the usage of :
% NIAK_PIPELINE 
% It shows how to perform a series of processing on functional data
% using the NIAK pipeline system.
%
% SYNTAX:
% Just type in NIAK_DEMO_PIPELINE
%
% OUTPUT:
%
% This script will clear the workspace !!
%
% It will apply a slice timing correction, a temporal filtering and a 
% spatial smoothing on functional data of subjects
% 1 and 2 (MOTOR and REST condition). It will create specific subfolders 
% for each stage of the pipeline as well as logs.
%
% Note that the path to access the demo data is stored in a variable
% called GB_NIAK_PATH_DEMO defined in the NIAK_GB_VARS script.
% 
% The demo database exists in multiple file formats. By default, it is
% using 'minc2' files. You can change that by changing the variable
% GB_NIAK_FORMAT_DEMO in the file NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, pipeline, fMRI

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

clear
niak_gb_vars

%% Setting up the correct file extension depending on the file format
switch gb_niak_format_demo
    case {'minc1','minc2'}
        ext_f = '.mnc';
    case {'nifti'}
        ext_f = '.nii';
    case {'analyze'}
        ext_f = '*.img';
    otherwise
        error('niak:demo','%s is an unsupported file format for this demo. See help to change the format.',gb_niak_format_demo)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up the pipeline structure %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%
%% Initialization %%
%%%%%%%%%%%%%%%%%%%%

pipeline = struct([]);

list_subject = {'1','2'}; % List of the tags used to build path and file names for each subject
list_condition = {'rest','motor'}; % List of the tags used to build path and file names for each condition

list_num_subject = 1:2; % Modify this line to process a subset of subjects
list_num_condition = 1:2; % Modify this line to process a subset of conditions

path_data = gb_niak_path_demo; % Where to find the raw data
folder_a = 'slice_timing'; % subfolder for slice-timing corrected data
folder_f = 'time_filter'; % subfolder for data after temporal filtering
folder_s = 'smooth'; % subfolder for data after spatial smoothing
folder_logs = 'logs'; % subfolder for the logs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creation of the pipeline stages for slice timing %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TR = 2.33; % Repetition time in seconds
nb_slices = 42; % Number of slices in a volume

for num_s = list_num_subject
    for num_c = list_num_condition
        
        subject = list_subject{num_s};
        condition = list_condition{num_c};
        
        %% Set up inputs, outputs and options
        clear files_in files_out opt
        files_in = cat(2,gb_niak_path_demo,filesep,'func_',condition,'_subject',subject,ext_f); 
        files_out = '';
        opt.folder_out = cat(2,path_data,filesep,folder_a,filesep); % The outputs will be written in this folder
        opt.slice_order = [1:2:nb_slices 2:2:nb_slices]; % Interleaved acquisition of slices
        opt.timing(1)=TR/nb_slices; % Time beetween slices
        opt.timing(2)=TR/nb_slices; % Time between the last slice of a volume and the first slice of next volume

        %% Getting the default values of options and output files
        opt.flag_test = 1;
        [files_in,files_out,opt] = niak_brick_slice_timing(files_in,files_out,opt);
        opt.flag_test = 0;
        
        %% Adding stage to the pipeline
        name_stage = cat(2,'slice_timing_',subject,'_',condition);
        stage.label = 'Correction of difference in slice timing via temporal interpolation';
        stage.command = 'niak_brick_slice_timing(files_in,files_out,opt)';        
        stage.files_in = files_in;
        stage.files_out = files_out;
        stage.opt = opt;
        stage.environment = 'octave';
        
        pipeline(1).(name_stage) = stage;

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creation of the pipeline stages for temporal filtering %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_s = list_num_subject
    for num_c = list_num_condition
        
        subject = list_subject{num_s};
        condition = list_condition{num_c};
               
        %% Set up inputs, outputs and options
        clear files_in files_out opt
        stage_in = getfield(pipeline,cat(2,'slice_timing_',subject,'_',condition));
        files_in = stage_in.files_out; % We use the outputs of the slice timing as inputs, whatever these may be
        files_out.filtered_data = ''; % Create the data after temporal filtering
        files_out.var_high = ''; % Create the volume of the relative variance suppressed in high frequencies
        files_out.var_low = ''; % Create the volume of the relative variance suppressed in low frequencies
        opt.folder_out = cat(2,path_data,filesep,folder_f,filesep); % The outputs will be written in this folder
        opt.tr = 2.33; % Repetition time in seconds
        opt.lp = 0.1; % Exclude frequencies above 0.1 Hz
        opt.hp = 0.01; % Exclude frequencies below 0.01 Hz

        %% Getting the default values of options and output files
        opt.flag_test = 1;
        [files_in,files_out,opt] = niak_brick_time_filter(files_in,files_out,opt);
        opt.flag_test = 0;
        
        %% Adding stage to the pipeline
        name_stage = cat(2,'time_filter_',subject,'_',condition);
        stage.label = 'Temporal filtering of fMRI data';
        stage.command = 'niak_brick_time_filter(files_in,files_out,opt)';       
        stage.files_in = files_in;
        stage.files_out = files_out;
        stage.opt = opt;
        stage.environment = 'octave';
        pipeline(1).(name_stage) = stage;

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creation of the pipeline stages for spatial smoothing  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for num_s = list_num_subject
    for num_c = list_num_condition
        
        subject = list_subject{num_s};
        condition = list_condition{num_c};

        %% Set up inputs, outputs and options
        clear files_in files_out opt
        stage_in = getfield(pipeline,cat(2,'time_filter_',subject,'_',condition));
        files_in = stage_in.files_out.filtered_data; % We use the outputs of the slice timing as inputs, whatever these may be
        files_out = ''; % Create the smoothed data with default name               
        opt.folder_out = cat(2,path_data,filesep,folder_s,filesep); % The outputs will be written in this folder
        opt.fwhm = 4;

        %% Getting the default values of options and output files
        opt.flag_test = 1;
        [files_in,files_out,opt] = niak_brick_smooth_vol(files_in,files_out,opt);
        opt.flag_test = 0;        
        
        %% Adding stage to the pipeline
        name_stage = cat(2,'smooth_',subject,'_',condition);
        stage.label = 'Spatial smoothing of fMRI data';
        stage.command = 'niak_brick_smooth_vol(files_in,files_out,opt)';        
        stage.files_in = files_in;
        stage.files_out = files_out;
        stage.opt = opt;
        stage.environment = 'octave';
        pipeline(1).(name_stage) = stage;

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

opt_pipe.path_logs = cat(2,path_data,filesep,'logs',filesep);
opt_pipe.clobber = 1;

file_pipeline = niak_init_pipeline(pipeline,opt_pipe); % Initialization

niak_visu_pipeline(file_pipeline,'graph_stages');

%niak_manage_pipeline(file_pipeline,'run');



