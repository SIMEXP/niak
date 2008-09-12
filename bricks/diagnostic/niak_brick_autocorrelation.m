function [files_in,files_out,opt] = niak_brick_autocorrelation(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_AUTOCORRELATION
%
% Build spatial and temporal autocorrelation maps of a 3D+t dataset
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_AUTOCORRELATION(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (string) file name of a 3D+t dataset. See NIAK_READ_VOL for
%       supported formats
%
%  * FILES_OUT 
%       (structure) with the following fields. Note that if a field
%       is left empty, the default name will be used. If a field is absent, 
%       the specified output will not be generated.
%
%       SPATIAL 
%           (string, default <BASE NAME>_autocorr_spat.<EXT>)
%           Output name for the spatial autocorrelation map
%
%       TEMPORAL
%           (string, default <BASE NAME>_autocorr_temp.<EXT>)
%           Output name for the temporal autocorrelation map
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
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
% NIAK_BUILD_AUTOCORRELATION
% _________________________________________________________________________
% COMMENTS
%
% If the first file name is left empty, the variance of the first dataset
% is assumed to be zero, i.e. the output variance is exactly the variance
% of the second dataset.
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_AUTOCORRELATION(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_autocorrelation'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_test','folder_out','flag_verbose'};
gb_list_defaults = {0,'',1};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'spatial','temporal'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Input files
if ~ischar(files_in)
    error('FILES_IN should be a cell of strings');
end

[path_f,name_f,ext_f] = fileparts(files_in);
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
if isempty(files_out.spatial)
    files_out.spatial = cat(2,opt.folder_out,filesep,name_f,'_autocorr_spat',ext_f);
end

if isempty(files_out.temporal)
    files_out.temporal = cat(2,opt.folder_out,filesep,name_f,'_autocorr_temp',ext_f);
end

if flag_test == 1
    return
end

%% Reading data
[hdr,vol] = niak_read_vol(files_in);

mask = niak_mask_brain(mean(abs(vol),4));
[vol_s,vol_t] = niak_build_autocorrelation(vol,mask);

if ~strcmp(files_out.spatial,'gb_niak_omitted')
    hdr.file_name = files_out.spatial;
    niak_write_vol(hdr,vol_s);
end

if ~strcmp(files_out.temporal,'gb_niak_omitted')
    hdr.file_name = files_out.temporal;
    niak_write_vol(hdr,vol_t);
end
