function [pipeline,opt_pipe,files_in] = niak_demo_fmri_preprocess(path_demo,opt)
% This function runs NIAK_PIPELINE_FMRI_PREPROCESS on the DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_FMRI_PREPROCESS(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%   the full path to the NIAK demo dataset. The dataset can be found in 
%   multiple file formats at the following address : 
%   http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_FMRI_PREPROCESS
%   will do here. The demo only changes one default and enforces a few 
%   parameters (see COMMENTS below):
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/fmri_preprocess) where to store the 
%      results of the pipeline.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE
%   (structure) a formal description of the pipeline. See
%   PSOM_RUN_PIPELINE.
%
% OPT_PIPE
%   (structure) the option to call NIAK_PIPELINE_FMRI_PREPROCESS
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% Note 1:
% The demo will apply the full fMRI preprocessing pipeline on the 
% functional data of subject 1 (rest and motor conditions) as well 
% as their anatomical image. It is possible to configure the pipeline 
% manager to use parallel computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% NOTE 2:
% The demo database exists in multiple file formats. NIAK looks into the demo 
% path and is supposed to figure out which format you are intending to use 
% by itself. 
%
% NOTE 3:
% The following parameters are hard-coded and cannot be modified:
%   opt.slice_timing.type_acquisition = 'interleaved ascending'; 
%   opt.slice_timing.type_scanner     = 'Bruker';                
%   opt.t1_preprocess.nu_correct.arg = '-distance 50';
%   
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, demo, pipeline, preprocessing, fMRI

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

%% Default for PATH_DEMO
niak_gb_vars

if ~exist('path_demo','var')
    path_demo = '';
end

if isempty(path_demo)
    path_demo = gb_niak_path_demo;
end

path_demo = niak_full_path(path_demo);

%% Set up defaults options
folder_out = [path_demo 'fmri_preprocess' filesep];
if nargin < 2
    opt.folder_out = folder_out;
else
    opt = psom_struct_defaults(opt,{'folder_out'},{folder_out},false);
end

% Hard-coded processing parameters
opt.slice_timing.type_acquisition = 'interleaved ascending'; 
opt.slice_timing.type_scanner     = 'Bruker';                
opt.t1_preprocess.nu_correct.arg = '-distance 50'; 

%% In which format is the niak demo ?
if psom_exist(cat(2,path_demo,'anat_subject1.img'))
    ext = '.img';
    error('analyze format is not currently supported');
elseif psom_exist(cat(2,path_demo,'anat_subject1.mnc.gz'))
    ext = '.mnc.gz';
elseif psom_exist(cat(2,path_demo,'anat_subject1.nii'))
    ext = '.nii';
    error('analyze format is not currently supported');
else
    ext = '.mnc';
end

%% Setting up input files
files_in.subject1.anat                = [path_demo 'anat_subject1' ext];
files_in.subject1.fmri.session1.motor = [path_demo 'func_motor_subject1' ext];
files_in.subject1.fmri.session1.rest  = [path_demo 'func_rest_subject1' ext];
        
files_in.subject2.anat                = [path_demo 'anat_subject2' ext];
files_in.subject2.fmri.session1.motor = [path_demo 'func_motor_subject2' ext];
files_in.subject2.fmri.session2.rest  = [path_demo 'func_rest_subject2' ext];
        
%% Build (and possibly run) the fmri_preprocess pipeline  
[pipeline,opt_pipe] = niak_pipeline_fmri_preprocess(files_in,opt);