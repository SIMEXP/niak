function [files_in,files_out,opt] = niak_demo_t1_preprocess(path_demo)
% A script to demonstrate the usage of NIAK_BRICK_T1_PREPROCESS
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_T1_PREPROCESS(PATH_DEMO)
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
% FILES_IN,FILES_OUT,OPT : outputs of NIAK_BRICK_T1_PREPROCESS (a 
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

files_out.transformation_lin = '';
files_out.transformation_nl = '';
files_out.transformation_nl_grid = '';
files_out.anat_nuc = '';
files_out.anat_nuc_stereolin = '';
files_out.anat_nuc_stereonl = '';
files_out.mask_stereolin = '';
files_out.mask_stereonl = '';
files_out.classify = '';

opt.nu_correct.arg = '-distance 50';

niak_brick_t1_preprocess(file_anat,files_out,opt);