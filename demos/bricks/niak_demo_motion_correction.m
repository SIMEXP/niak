% This is a script to demonstrate the usage of :
% NIAK_BRICK_MOTION_CORRECTION
%
% SYNTAX:
% Just type in NIAK_DEMO_MOTION_CORRECTION 
%
% OUTPUT:
%
% This script will clear the workspace !!
% It will apply a motion correction on the functional data of subject
% 1 and use the default output name.
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
        
        %% There is only one session...
        files_in.sessions.session1 = {cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'),cat(2,gb_niak_path_demo,filesep,'func_rest_subject1.mnc')};        
        files_in.t1 = cat(2,gb_niak_path_demo,filesep,'anat_subject1.mnc');
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)        
end

%% Setting output files
files_out.motion_corrected_data = ''; % use default names
files_out.motion_parameters_dat = ''; % use default names
files_out.motion_parameters_xfm = ''; % use default names
files_out.transf_within_session_dat = ''; % use default names
files_out.transf_within_session_xfm = ''; % use default names
files_out.transf_between_session_dat  = ''; % use default names
files_out.transf_between_session_xfm  = ''; % use default names
files_out.transf_func2t1_xfm = ''; % use default names

%% Options
opt.vol_ref = 40;

opt.flag_test = 1;
[files_in,files_out,opt] = niak_brick_motion_correction(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out

