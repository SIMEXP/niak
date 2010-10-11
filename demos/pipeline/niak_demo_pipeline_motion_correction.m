function [pipeline,opt] = niak_demo_pipeline_motion_correction(path_demo,opt)
% This is a script to demonstrate the usage of NIAK_PIPELINE_MOTION_CORRECTION
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_PIPELINE_MOTION_CORRECTION(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%       the full path to the NIAK demo dataset. The dataset can be found in 
%       multiple file formats at the following address : 
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% OPT
%       (structure) options for NIAK_PIPELINE_MOTION_CORRECTION.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE,OPT : outputs of NIAK_PIPELINE_MOTION_CORRECTION.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% geriatrie de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, motion correction, fMRI

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

if nargin>=1
    if ~isempty(path_demo)
        gb_niak_path_demo = path_demo;
    end
end

niak_gb_vars

%% In which format is the niak demo ?
format_demo = 'minc2';
if exist(cat(2,path_demo,'anat_subject1.mnc'))
    format_demo = 'minc2';
elseif exist(cat(2,path_demo,'anat_subject1.mnc.gz'))
    format_demo = 'minc1';
elseif exist(cat(2,path_demo,'anat_subject1.nii'))
    format_demo = 'nii';
elseif exist(cat(2,path_demo,'anat_subject1.img'))
    format_demo = 'analyze';
end

%% Setting input/output files
switch format_demo
        
    case 'minc2' % If data are in minc2 format
        
        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        files_in.session1{1} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc');        
        files_in.session1{2} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc');        
        files_in.session2{1} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject2.mnc');        
        files_in.session2{2} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject2.mnc');        
        
    case 'minc1'
        
        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        files_in.session1{1} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc.gz');        
        files_in.session1{2} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz');        
        files_in.session2{1} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject2.mnc.gz');        
        files_in.session2{2} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject2.mnc.gz');        
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo.',gb_niak_format_demo)
end

opt.folder_out = [gb_niak_path_demo 'motion_correction_subject1' filesep];
[pipeline,opt] = niak_pipeline_motion_correction(files_in,opt);

