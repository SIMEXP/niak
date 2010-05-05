function [files_in,files_out,opt] = niak_demo_anat2stereonl(path_demo)
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_ANAT2STEREONL
%
% This is a script to demonstrate the usage of :
% NIAK_BRICK_ANAT2STEREONL
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_ANAT2STEREONL(PATH_DEMO)
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
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_IN,FILES_OUT,OPT : outputs of NIAK_BRICK_ANAT2STEREONL (a 
% description of input and output files with all options).
%
% _________________________________________________________________________
% COMMENTS:
%
% 
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

if exist('path_demo','var')
    gb_niak_path_demo = path_demo;
end

niak_gb_vars

%% Setting input/output files
switch gb_niak_format_demo
        
    case 'minc2' % If data are in minc2 format
        
        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        file_anat = cat(2,gb_niak_path_demo,filesep,'anat_subject1.mnc');
        
    case 'minc1'
        
        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        file_anat = cat(2,gb_niak_path_demo,filesep,'anat_subject1.mnc.gz');
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)        
end

%% Apply non-uniformity correction
clear files_in files_out opt
files_in.vol = file_anat;
files_out.vol_nu = '';
opt.arg = '-distance 50';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_nu_correct(files_in,files_out,opt);
opt.flag_test = false;
file_anat_nu = files_out.vol_nu;
niak_brick_nu_correct(files_in,files_out,opt);

%% Derive a mask of the brain
clear files_in files_out opt
files_in = file_anat_nu;
files_out = '';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_mask_brain_t1(files_in,files_out,opt);
opt.flag_test = false;
file_anat_mask = files_out;
niak_brick_mask_brain_t1(files_in,files_out,opt);

%% Run a linear coregistration in Talairach space
clear files_in files_out opt
files_in.t1 = file_anat_nu;
files_in.t1_mask = file_anat_mask;
files_out.transformation = '';
files_out.t1_stereolin = '';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_anat2stereolin(files_in,files_out,opt);
opt.flag_test = false;
file_anat_stereolin = files_out.t1_stereolin;
file_anat2stereolin = files_out.transformation;
niak_brick_anat2stereolin(files_in,files_out,opt);

%% Apply non-uniformity correction in Talairach space
clear files_in files_out opt
files_in.vol = file_anat_stereolin;
files_in.mask = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a_mask_eroded5mm.mnc.gz'];
files_out.vol_nu = '';
opt.arg = '-distance 50';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_nu_correct(files_in,files_out,opt);
opt.flag_test = false;
file_anat_stereolin_nu = files_out.vol_nu;
niak_brick_nu_correct(files_in,files_out,opt);

%% Derive a mask of the brain in Talairach space
clear files_in files_out opt
files_in = file_anat_stereolin_nu;
files_out = '';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_mask_brain_t1(files_in,files_out,opt);
opt.flag_test = false;
file_anat_stereolin_mask = files_out;
niak_brick_mask_brain_t1(files_in,files_out,opt);

%% Run a non-linear coregistration in Talairach space
clear files_in files_out opt
files_in.t1 = file_anat_stereolin_nu;
files_in.t1_mask = file_anat_stereolin_mask;
files_out.transformation = '';
files_out.t1_stereonl = '';
opt.flag_test = true;
[files_in,files_out,opt] = niak_brick_anat2stereonl(files_in,files_out,opt);
opt.flag_test = false;
file_anat_stereonl = files_out.t1_stereonl;
file_anat2stereonl = files_out.transformation;
opt.arg = '-normalize';
niak_brick_anat2stereonl(files_in,files_out,opt);
