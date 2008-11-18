function [files_in,files_out,opt] = niak_brick_diff_variance(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_DIFF_VARIANCE
%
% Build the difference of temporal variance between two 4D datasets
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_VARIANCE(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (cell of strings 2*1) file names of two 3D+t dataset. 
%
%  * FILES_OUT       
%       (string, default <BASE_NAME FILE 1>_diff_var.<EXT>) 
%       File name for output difference of variance map (variance of file 1
%       minus variance of file 2).
%
%  * OPT           
%       (structure) with the following fields.  
%
%       FLAG_STD
%           (boolean, default 0) if FLAG_STD == 1, the difference of
%           variance is converted in a standard deviation (i.e. a square
%           root of the absolute value is applied).
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
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
% _________________________________________________________________________
% COMMENTS
%
% If the second file name is left empty, the variance of the second dataset
% is assumed to be zero, i.e. the output variance is exactly the variance
% of the first dataset.
%
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

niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_DIFF_VARIANCE(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_diff_variance'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_std','flag_test','folder_out','flag_zip'};
gb_list_defaults = {0,0,'',0};
niak_set_defaults

%% Output files

if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings');
end

if isempty(files_in{2})
    files_in{2} = 'gb_niak_omitted';
end

[path_f,name_f,ext_f] = fileparts(files_in{1});
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
if isempty(files_out)
    files_out = cat(2,opt.folder_out,filesep,name_f,'_var_diff',ext_f);
end

if flag_test == 1
    return
end

%% Performing slice timing correction 
if ~strcmp(files_in{2},'gb_niak_omitted')
    [hdr2,vol2] = niak_read_vol(files_in{2});
end
[hdr1,vol1] = niak_read_vol(files_in{1});


var1 = var(vol1,1,4);

if ~strcmp(files_in{2},'gb_niak_omitted')
    var2 = var(vol2,1,4);
    if flag_std
        diff = sqrt(abs(var1 - var2));
    else
        diff = var1 - var2;
    end
else
    if flag_std
        diff = sqrt(var1);
    else
        diff = var1;
    end
end

hdr1.file_name = files_out;
niak_write_vol(hdr1,diff);