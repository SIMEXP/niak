function [files_in,files_out,opt] = niak_demo_smooth_vol(path_demo)
% This is a script to demonstrate the usage of NIAK_BRICK_SMOOTH_VOL
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_SMOOTH_VOL(PATH_DEMO)
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
% FILES_IN,FILES_OUT,OPT : outputs of NIAK_BRICK_SMOOTH_VOL (a 
% description of input and output files with all options).
%
% _________________________________________________________________________
% COMMENTS:
%
% This function applies a spatial smoothing on the functional data of 
% subject 1 (motor condition) and use the default output name.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_SMOOTH_VOL
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, smoothing, fMRI

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
    gb_niak_path_demo = path_demo;
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
        
        files_in = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'); 
        files_out = ''; % The default output name will be used
        
    case 'minc1' % If data are in minc1 format

        files_in = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_out = ''; % The default output name will be used

    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%% Options
opt.fwhm=[8 8 8]; % A 5 mm isotropic smoothing
opt.flag_zip = 0; % Do not attempt to zip the outputs
opt.flag_test = 0; % This is not a test, the slice timing is actually performed

[files_in,files_out,opt] = niak_brick_smooth_vol(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out

