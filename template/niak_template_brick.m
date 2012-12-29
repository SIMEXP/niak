function [in,out,opt] = niak_template_brick(in,out,opt)
% This is a template file for "brick" functions in NIAK.
%
% SYNTAX:
% [IN,OUT,OPT] = NIAK_TEMPLATE_BRICK(IN,OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% IN        
%   (string) a file name of a 3D+t fMRI dataset .
%
% OUT
%   (structure) with the following fields:
%       
%   CORRECTED_DATA
%       (string, default <BASE NAME FMRI>_c.<EXT>) File name for processed 
%       data.
%       If OUT is an empty string, the name of the outputs will be 
%       the same as the inputs, with a '_c' suffix added at the end.
%
%   MASK
%       (string, default <BASE NAME FMRI>_mask.<EXT>) File name for a mask 
%       of the data. If OUT is an empty string, the name of the 
%       outputs will be the same as the inputs, with a '_mask' suffix added 
%       at the end.
%
% OPT           
%   (structure) with the following fields.  
%
%   TYPE_CORRECTION       
%      (string, default 'mean_var') possible values :
%      'none' : no correction at all                       
%      'mean' : correction to zero mean.
%      'mean_var' : correction to zero mean and unit variance
%      'mean_var2' : same as 'mean_var' but slower, yet does not use as 
%      much memory).
%
%   FOLDER_OUT 
%      (string, default: path of IN) If present, all default outputs 
%      will be created in the folder FOLDER_OUT. The folder needs to be 
%      created beforehand.
%
%   FLAG_VERBOSE 
%      (boolean, default 1) if the flag is 1, then the function prints 
%      some infos during the processing.
%
%   FLAG_TEST 
%      (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%      anything but update the default values in IN, OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% IN, OUT, OPT: same as inputs but updated with default values.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_CORRECT_MEAN_VAR
%
% _________________________________________________________________________
% COMMENTS:
%
% That code is just to demonstrate the guidelines for NIAK bricks. It is
% also a good idea to start a new command project by editing this file and
% saving it under the new command name.
%
% Note that this function is actually a fully functional brick to perform a
% temporal normalization on fMRI time series (correction of mean, variance,
% etc). That brick is pretty much useless, because it is just as simple to
% apply NIAK_CORRECT_MEAN_VARIANCE "on-the-fly" in other bricks. It is 
% still a good brick example.
%
% _________________________________________________________________________
% Copyright (c) <NAME>, <INSTITUTION>, <START DATE>-<END DATE>.
% Maintainer : <EMAIL ADDRESS>
% See licensing information in the code.
% Keywords : NIAK, documentation, template, brick

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% global NIAK variables
flag_gb_niak_fast_gb = true; % Only load the most important global variables for fast initialization
niak_gb_vars 

%% Syntax
if ~exist('in','var')||~exist('out','var')||~exist('opt','var')
    error('niak:brick','Bad syntax, type ''help %s'' for more info.',mfilename)
end

%% Inputs
if ~ischar(in)
    error('IN should be a string');
end
    
%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'type_correction' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {'mean_var'        , true           , false       , ''           };
niak_set_defaults


%% Check the output files structure
gb_name_structure = 'out';
gb_list_fields    = {'corrected_data'  , 'mask'            };
gb_list_defaults  = {'gb_niak_omitted' , 'gb_niak_omitted' };
niak_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = niak_fileparts(in(1,:)); % parse the folder, file name and extension of the input

if strcmp(opt.folder_out,'') % if the output folder is left empty, use the same folder as the input
    opt.folder_out = path_f;
    folder_out = path_f;
end

if isempty(out.corrected_data)

    if size(in,1) == 1 % There is only one input volume

        out.corrected_data = cat(2,opt.folder_out,filesep,name_f,'_c',ext_f);

    else % Multiple volumes have been specified, must be an old analyze format

        name_files = cell([size(in,1) 1]);

        for num_f = 1:size(in,1)
            [path_f,name_f,ext_f] = fileparts(deblank(in(num_f,:)));

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f] = fileparts(name_f);
            end
            
            name_files{num_f} = cat(2,opt.folder_out,filesep,name_f,'_c',ext_f);
        end
        out = char(name_filtered_data);
    end
end

if isempty(out.mask)

    out.mask = cat(2,opt.folder_out,filesep,name_f,'_mask',ext_f);

end

%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = sprintf('Performing temporal correction of %s on the fMRI time series in file %s',type_correction,in);
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Correct the time series 
if flag_verbose
    fprintf('Correct the time series ...\n');
end
[hdr,vol] = niak_read_vol(in); % read fMRI data
mask = niak_mask_brain(mean(abs(vol),4)); % extract a brain mask
tseries = niak_vol2tseries(vol,mask); % extract the time series in the mask
tseries = niak_correct_mean_var(tseries,type_correction); % Correct the time series
vol = niak_tseries2vol(tseries,mask);

%% Save outputs
if flag_verbose
    fprintf('Save outputs ...\n');
end

if ~strcmp(out.corrected_data,'gb_niak_omitted');
    hdr.file_name = out.corrected_data;
    niak_write_vol(hdr,vol);
end

if ~strcmp(out.mask,'gb_niak_omitted');
    hdr.file_name = out.mask;
    niak_write_vol(hdr,mask);
end
