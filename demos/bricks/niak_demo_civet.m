% This is a script to demonstrate the usage of :
% NIAK_BRICK_CIVET
%
% SYNTAX:
% Just type in NIAK_DEMO_CIVET 
%
% OUTPUT:
%
% This script will clear the workspace !!
% It will run the CIVET pipeline on the anatomical image of subject
% 1 (motor condition) and use the default output names in a subfolder anat_subject1.
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

%% Setting input/output files
switch gb_niak_format_demo
    
    case 'minc2' % If data are in minc2 format

        files_in.anat = cat(2,gb_niak_path_demo,filesep,'anat_subject1.mnc');
        
%         opt.civet.folder = cat(2,gb_niak_path_demo,filesep,'civet',filesep); 
%         opt.civet.prefix = 'anat';
%         opt.civet.id = 'subject1';

        opt.folder_out = cat(2,gb_niak_path_demo,filesep,'anat_subject1',filesep); 
        if ~exist(opt.folder_out)
            str = mkdir(opt.folder_out);
        end
    
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%% Outputs
files_out.transformation_lin = '';
files_out.transformation_nl = '';
files_out.transformation_nl_grid = '';
files_out.anat_nuc_native = '';
files_out.anat_nuc_stereo_lin = '';
files_out.anat_nuc_stereo_nl = '';
files_out.mask_native = '';
files_out.mask_stereo = '';
files_out.classify = '';
files_out.pve_wm = '';
files_out.pve_gm = '';
files_out.pve_csf = '';
files_out.verify = '';

%% Options
opt.flag_test = 0;

[files_in,files_out,opt] = niak_brick_civet (files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out

