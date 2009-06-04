function [files_out] = niak_brick_spatial_av(files_in,opt)

% SYNTAX:
% [FILES_OUT,OPT] = NIAK_BRICK_FMRI_DESIGN(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN  
%       (structure) with the following field :
%
%       FMRI 
%           (string) the name of a file containing an fMRI dataset. 
%     
%
% _________________________________________________________________________
% OPT   
%     (structure) with the following fields.
%     Note that if a field is omitted, it will be set to a default
%     value if possible, or will issue an error otherwise.
%
%     EXCLUDE 
%           (vector, default []) 
%           A list of frames that should be excluded from the
%           analysis. This must be used with Siemens EPI scans to remove the
%           first few frames, which do not represent steady-state images.
%           If OPT.NUMLAGS=1, the excluded frames can be arbitrary, 
%           otherwise they should be from the beginning and/or end.
%
%     FOLDER_OUT 
%           (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%     FLAG_VERBOSE 
%           (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%     FLAG_TEST 
%           (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
%
% _________________________________________________________________________
% OUTPUTS
%
%  * FILES_OUT 
%       (structure) with the following field. Note that if
%       a field is an empty string, a default value will be used to
%       name the outputs. If a field is omitted, the output won't be
%       saved at all (this is equivalent to setting up the output file
%       names to 'gb_niak_omitted').
%
%       SPATIAL_AV 
%            column vector of the spatial average time courses.
%
%      The structure OPT is updated with default values. 
%      If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, 2009.
%               Pierre Bellec, McConnell Brain Imaging Center, 2009.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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


niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('opt','var')
    error('SYNTAX: [FILES_OUT] = NIAK_BRICK_SPATIAL_AV(FILES_IN,OPT).\n Type ''help niak_brick_spatial_av'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','mask'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

if ~ischar(files_in.fmri)
    error('niak_brick_spatial_av: FILES_IN.FMRI should be a string');
end

if ~ischar(files_in.mask)
    error('niak_brick_spatial_av: FILES_IN.MASK should be a string');
end

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'exclude','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[],0,'',1};
niak_set_defaults


%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'spatial_av'};
gb_list_defaults = {'gb_niak_omitted'};
niak_set_defaults

%% Parsing base names
[path_f,name_f,ext_f] = fileparts(files_in.fmri);
[path_m,name_m,ext_m] = fileparts(files_in.mask);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f] = fileparts(name_f);
    flag_zip = 1;
else
    flag_zip = 0;
end

if strcmp(ext_m,gb_niak_zip_ext)
    flag_zip_mask = 1;
else
    flag_zip_mask = 0;
end


if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end

files_out.spatial_av = cat(2,folder_f,filesep,name_f,'_spatial_av.mat');

%% Input file
if flag_zip
    file_input = niak_file_tmp(cat(2,'_func.mnc',gb_niak_zip_ext));
    instr_cp = cat(2,'cp ',files_in.fmri,' ',file_input);
    system(instr_cp);
    instr_unzip = cat(2,gb_niak_unzip,' ',file_input);
    system(instr_unzip);
    file_input = file_input(1:end-length(gb_niak_zip_ext));
else
    file_input = files_in.fmri;
end
%% Input mask
if flag_zip_mask
    file_mask = niak_file_tmp(cat(2,'_func.mnc',gb_niak_zip_ext));
    instr_cp = cat(2,'cp ',files_in.mask,' ',file_mask);
    system(instr_cp);
    instr_unzip = cat(2,gb_niak_unzip,' ',file_mask);
    system(instr_unzip);
    file_mask = file_mask(1:end-length(gb_niak_zip_ext));
else
    file_mask = files_in.mask;
end

%% Open file_input:
[hdr_vol,vol] = niak_read_vol(file_input);

%% Open file_mask:
[hdr_mask,vol_mask] = niak_read_vol(file_mask);

%% Creates spatial_av:
vol_mask = vol_mask>0;
spatial_av = niak_spatial_av(vol,vol_mask);

if ~strcmp(files_out.spatial_av,'gb_niak_omitted');
    save(files_out.spatial_av,'spatial_av');
end

%% Deleting temporary files
if flag_zip
    delete(file_input);
end

if flag_zip_mask
    delete(file_mask);
end

