%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_PIPELINE_MASK_BRAIN
%
% This is a script to demonstrate the usage of :
% NIAK_PIPELINE_MASK_BRAIN
%
% SYNTAX:
% Just type in NIAK_DEMO_PIPELINE_MASK_BRAIN
%
% _________________________________________________________________________
% OUTPUT
%
% It will create a mask for the 'rest' and 'motor' run of subject 1 
% with the demo data, and combine these masks into a mean and group masks.
% The results will be saved in ~/data_demo/masks
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

%% Setting input/output files
switch gb_niak_format_demo
    
     case 'minc1' % If data are in minc1 format
        
        files_in{1} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz'); 
        files_in{2} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc.gz'); 
        
    case 'minc2' % If data are in minc2 format
        
        files_in{1} = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'); 
        files_in{2} = cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc'); 
        
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%% Options
opt.thresh_mean = 0.3;
opt.mask_brain.fwhm = 5;
opt.mask_brain.flag_remove_eyes = true;
opt.psom.mode = 'session';
opt.psom.max_queued = 1;
opt.psom.mode_pipeline_manager = 'session';
opt.flag_test = false; 
opt.folder_out = [gb_niak_path_demo,filesep,'masks',filesep];

pipeline = niak_pipeline_mask_brain(files_in,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out

