function [files_in,files_out,opt] = niak_brick_correct_vol(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_CORRECT_VOL
%
% Correct the distribution of spatial components to pseudo-z scores.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CORRECT_VOL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (structure) with the following fields : 
%
%       SPACE
%           (string) a 4D datasets with multiple space components.
%       
%       MASK
%           (string) a mask of the brain.
%
%  * FILES_OUT       
%       (string, default <BASE_NAME FILES_IN.SPACE>_corr.<EXT>) 
%       File name for output. If FILES_OUT is absent or an empty string, 
%       the default will be used.
%
%  * OPT           
%       (structure) with the following fields.  
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_CORRECT_VOL, NIAK_BRICK_SICA
%
% _________________________________________________________________________
% COMMENTS
%
% This conversion to pseudo-z scores is similar to what was done, e.g., in
% 
% McKeown et al, Analysis of fMRI data by blind separation into independent
% spatial components. Hum Brain Mapp, Vol. 6, No. 3. (1998), pp. 160-188.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : ICA, space component, correction, z-value

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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CORRECT_VOL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_correct_vol'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'space','mask'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_verbose','flag_test','folder_out'};
gb_list_defaults = {1,0,''};
niak_set_defaults

%% Output files

[path_f,name_f,ext_f] = fileparts(files_in.space);
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

%% Building default output names

files_out = cat(2,opt.folder_out,filesep,name_f,'_corr',ext_f);

if flag_test == 1
    return
end

if flag_verbose
    msg = sprintf('Converting spatial distributions to pseudo-z scores');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read mask
if flag_verbose
    fprintf('Reading mask %s ...\n',files_in.mask)
end
[hdr_mask,mask] = niak_read_vol(files_in.mask);
mask = mask>0;

%% Read components
if flag_verbose
    fprintf('Reading spatial components %s ...\n',files_in.space)
end
[hdr,vol] = niak_read_vol(files_in.space);

%% Correct distributions
if flag_verbose
    fprintf('Conversion to pseudo-z ...\n')
end
vol_c = niak_correct_vol(vol,mask);

%% Writting outputs
if flag_verbose
    fprintf('Writting output %s ...\n',files_out)
end
hdr.file_name = files_out;
niak_write_vol(hdr,vol_c);
