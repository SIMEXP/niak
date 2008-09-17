function [files_in,files_out,opt] = niak_brick_percentile_vol(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_PERCENTILE_VOL
%
% Extracts percentile of the distribution of a 3D volume within a mask. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_PERCENTILE_VOL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (structure) with the following fields.
%
%       VOL
%           (string) file name of a 3D volume. 
%
%       MASK
%           (string) file name of a binary volume. If left unspecified, a
%           mask will be extracted from VOL using NIAK_MASK_BRAIN.
%
%  * FILES_OUT 
%       (string, default <BASE VOL>_perc.dat) percentiles of the volume
%       inside the mask, in a text file. If left empty, the default output
%       name will be used.
%
%  * OPT           
%       (structure) with the following fields.  
%
%       PERCENTILES (default [0 0.01 0.05 0.1 0.25 0.5 0.75 0.9 0.95 0.99 1])
%           The percentiles under investigation.
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
% NIAK_BUILD_AUTOCORRELATION
% _________________________________________________________________________
% COMMENTS
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
gb_list_fields = {'percentiles','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[0 0.01 0.05 0.1 0.25 0.5 0.75 0.9 0.95 0.99 1],0,'',1};
niak_set_defaults

%% Output files
if ~exist('files_out','var')
    error('Please specify an argument FILES_OUT')
end

if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'vol','mask'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in.vol);
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
    files_out = cat(2,opt.folder_out,filesep,name_f,'_perc.dat');
end

if flag_test == 1
    return
end

%% Reading data
[hdr,vol] = niak_read_vol(files_in.vol);
vol = vol(:,:,:,1);

%% Reading mask
if strcmp(files_in.mask,'gb_niak_omitted')
    mask = niak_mask_brain(abs(vol));
else
    [hdr_mask,mask] = niak_read_vol(files_in.mask);
    mask = mask > 0;
end

%% Extracting empirical cdf
val = sort(vol(mask));
cdf = (1:length(val))/(length(val)+1);

%% Building requested percentiles
perc = zeros([1 length(opt.percentiles)]);

for num_e = 1:length(opt.percentiles);
    ind = min(find(cdf>=opt.percentiles(num_e)));
    if isempty(ind)
        perc(num_e) = val(end);
    else
        perc(num_e) = val(ind);
    end
end

%% Saving output
niak_write_tab(files_out,[opt.percentiles(:) perc(:)],[],{'percentiles','values'});