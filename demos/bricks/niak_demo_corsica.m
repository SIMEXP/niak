
%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_CORSICA
%
% This is a script to demonstrate the usage of :
% NIAK_PIPELINE_CORSICA
%
% SYNTAX:
% Just type in NIAK_DEMO_CORSICA
%
% _________________________________________________________________________
% OUTPUT
%
% This script will apply corsica on the motor condition of subject 1. There
% is no transformation from the native space to MNI152 specified, so the
% resuts of the selection are completely random. This demo is mainly to
% demonstrate how to invoke the pipeline, and to test that the script
% actually works.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1
% This script will clear the workspace !!
%
% NOTE 2
% Note that the path to access the demo data is stored in a variable
% called GB_NIAK_PATH_DEMO defined in the script NIAK_GB_VARS.
% 
% NOTE 3
% The demo database exists in multiple file formats.NIAK looks into the demo 
% path and is supposed to figure out which format you are intending to use 
% by himself.You can the format by changing the variable GB_NIAK_FORMAT_DEMO 
% in the script NIAK_GB_VARS.
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

%%%%%%%%%%%%%%%
%% FILES IN %%%
%%%%%%%%%%%%%%%
switch gb_niak_format_demo
    
    case 'minc2' % If data are in minc2 format
        
        %% Subject 1
        files_in.subject1.fmri = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc')};
        files_in.subject1.transformation = 'gb_niak_omitted';                                                               
        
        %% Subject 2
        files_in.subject2.fmri = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject2.mnc'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject2.mnc')};
        files_in.subject2.transformation = 'gb_niak_omitted';
        
        % Here, no transformation to the MNI152 space is specified. This is a disaster because the spatial apriori 
        % used by corsica will not work at all.
        % This is just to demonstrate how to invoke the pipeline template.
        % Usually, you need to preprocess the fMRI data, and the correct
        % transformation is estimated as part of the preprocessing.
        
    case 'minc1' % If data are in minc1 format

        %% Subject 1
        files_in.subject1.fmri = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc.gz')};
        files_in.subject1.transformation = 'gb_niak_omitted';

        %% Subject 2
        files_in.subject2.fmri = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject2.mnc.gz'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject2.mnc.gz')};
        files_in.subject2.transformation = 'gb_niak_omitted';

        % Here, no transformation to the MNI152 space is specified. This is a disaster because the spatial apriori
        % used by corsica will not work at all.
        % This is just to demonstrate how to invoke the pipeline template.
        % Usually, you need to preprocess the fMRI data, and the correct
        % transformation is estimated as part of the preprocessing.
 
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%
opt.folder_out = cat(2,gb_niak_path_demo,filesep,'corsica',filesep);


%%%%%%%%%%%%%%%%%%%%
%% Bricks options %%
%%%%%%%%%%%%%%%%%%%%

%% These options correspond to the 'corsica' style of
%% pipeline.

%% 1. Individual spatial ICA (niak_brick_sica)

%% 2. Component selection

%% 3. Component suppression

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Building pipeline using the fmri_preprocess template  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pipeline = niak_pipeline_corsica(files_in,opt);

%% Initialization of the pipeline
opt_pipe.path_logs = cat(2,opt.folder_out,'logs',filesep);
%file_pipeline = niak_init_pipeline(pipeline,opt_pipe)

