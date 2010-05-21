function [files_in,files_out,opt] = niak_demo_glm_level1(path_demo,opt_demo)
% This function demonstrates how to use NIAK_BRICK_GLM_LEVEL1
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_GLM_LEVEL1(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% OUTPUT
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%       the full path to the NIAK demo dataset. The dataset can be found in 
%       multiple file formats at the following address : 
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% OPT
%       (structure, optional) with the following fields : 
%
%       FLAG_TEST
%           (boolean, default false) if FLAG_TEST == true, the demo will 
%           just generate the FILES_IN, FILES_OUT and OPT structure, 
%           otherwise it will run the brick.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1
%   This demo will run an analysis of the motor condition of subject 1, 
%   using a boxcar design.
% 
% NOTE 2:
%   The demo database exists in multiple file formats.NIAK looks into the 
%   demo path and is supposed to figure out which format you are 
%   intending to use by himself. You can the format by changing the 
%   variable GB_NIAK_FORMAT_DEMO in the script NIAK_GB_VARS.
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, general linear model, fMRI, demo

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

niak_gb_vars

if ~exist('path_demo','var')
    path_demo = '';
end

if isempty(path_demo)
    path_demo = gb_niak_path_demo;
end

if ~strcmp(path_demo(end),filesep)
    path_demo = [path_demo filesep];
end

%% Set up defaults
gb_name_structure = 'opt_demo';
default_psom.path_logs = '';
gb_list_fields = {'flag_test'};
gb_list_defaults = {false};
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up inputs %%
%%%%%%%%%%%%%%%%%%%%%%%

%% Generating the design
frame_times = (0:49)*2.33;
slice_times = [0:2:40 1:2:41]*(2.33/42);
events = [1 -13.98 30 1; 1 43.98 30 1; 1 103.98 30 1]; % The design is block/rest/block/rest/block, each block being 30 sec long. The first and last block have been truncated
X_cache = fmridesign(frame_times,slice_times,events);
files_in.design = cat(2,gb_niak_path_demo,filesep,'motor_design.mat');
save(files_in.design,'X_cache');
   
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
    
    case 'minc1' % If data are in minc1 format

        files_in.fmri = cat(2,path_demo,filesep,'func_motor_subject1.mnc.gz');
        
    case 'minc2' % If data are in minc2 format

        files_in.fmri = cat(2,path_demo,filesep,'func_motor_subject1.mnc');
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%% Outputs
files_out.df = '';
files_out.spatial_av = '';
files_out.mag_t = '';
files_out.del_t = '';
files_out.mag_ef = '';
files_out.del_ef = '';
files_out.mag_sd = '';
files_out.del_sd = '';
files_out.fwhm = '';
files_out.cor = '';
files_out.resid = '';
files_out.wresid = '';
files_out.ar = '';

%% Options
opt.folder_out = cat(2,path_demo,filesep,'glm_motor',filesep);
if ~exist(opt.folder_out)
    str = mkdir(opt.folder_out);
end
opt.contrast.motor = 1;
opt.flag_test = opt_demo.flag_test;
opt.nb_trends_spatial = 1;
opt.nb_trends_temporal = 0;
opt.pcnt = 0;

[files_in,files_out,opt] = niak_brick_glm_level1(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out

