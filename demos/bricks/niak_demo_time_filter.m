function [files_in,files_out,opt] = niak_demo_time_filter(path_demo,opt)
% This is a script to demonstrate the usage of :
% NIAK_BRICK_TIME_FILTER
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_TIME_FILTER(PATH_DEMO,OPT)
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
%       (structure) the options of NIAK_BRICK_TIME_FILTER. The options TR,
%       LP and HP are set by the demo and cannot be modified.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_IN,FILES_OUT,OPT : outputs of NIAK_BRICK_TIME_FILTER (a description 
% of input and output files with all options).
%
% _________________________________________________________________________
% COMMENTS:
%
% This script will apply a temporal filtering on the functional data of subject
% 1 (motor condition) and use the default output name. The frequencies
% below 0.01 Hz and above 0.1 Hz will be suppressed.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, temporal filtering, fMRI

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

%% Setting input files
switch gb_niak_format_demo
    
    case 'minc1' % If data are in minc1 format

        files_in = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz');

    case 'minc2' % If data are in minc2 format
        
        files_in = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc'); 
    
    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%% Setting output files
files_out.filtered_data = '';
files_out.var_high = '';
files_out.var_low = '';
files_out.dc_high = '';
files_out.dc_low = '';
files_out.beta_high = '';
files_out.beta_low = '';

%% Setting options
opt.tr = 2.33; % Repetition time in seconds
opt.lp = 0.1; % Exclude frequencies above 0.1 Hz
opt.hp = 0.01; % Exclude frequencies below 0.01 Hz

[files_in,files_out,opt] = niak_brick_time_filter(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out
