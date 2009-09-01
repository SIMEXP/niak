function [files_in,files_out,opt] = niak_brick_spatial_av(files_in,files_out,opt)

% _________________________________________________________________________
% SUMMARY NIAK_BRICK_SPATIAL_AV
%
% Creates the spatial average time course. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SPATIAL_AV(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  FILES_IN  
%       (structure) with the following field :
%
%       FMRI 
%           (string) the name of a file containing an fMRI dataset. 
%
%       MASK
%
%           (string) the name of a 3D binary volume.
%
%
%  FILES_OUT
%       (string) the name a matlab file containing the following variable: 
%
%       SPATIAL_AV 
%            column vector of the spatial average time courses.
%
%  OPT   
%     (structure) with the following fields.
%     Note that if a field is omitted, it will be set to a default
%     value if possible, or will issue an error otherwise.
%
%    MASK_THRESH
%       a scalar value for thresholding a volumen and defininig a brain
%       mask
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
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
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
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SPATIAL_AV(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_spatial_av'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','mask'};
gb_list_defaults = {NaN,[]};
niak_set_defaults

if ~ischar(files_in.fmri)
    error('niak_brick_spatial_av: FILES_IN.FMRI should be a string');
end

if isempty(files_in.mask)
    files_in.mask = files_in.fmri;
end

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'exclude','mask_thresh','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[],[],0,'',1};
niak_set_defaults


%% FILES_OUT
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end

if isempty(files_out)
    files_out = cat(2,folder_f,filesep,name_f,'_spatial_av.mat');
end

if flag_test 
    return
end

%% Open file_input:
[hdr_vol,vol] = niak_read_vol(files_in.fmri);


%% Defining a mask volume:
[hdr_mask,mask] = niak_read_vol(files_in.mask);

if isempty(opt.mask_thresh)
    mask_thresh = niak_mask_threshold(squeeze(mask(:,:,:,1)));
end

mask = mask(:,:,:,1) > mask_thresh;


numframes = size(vol,4);
allpts = 1:numframes;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( allpts > 0);

data = vol(:,:,:,keep(1));
weighted_mask = data.*mask ;




%% Creates spatial_av:
spatial_av = niak_spatial_av(vol,weighted_mask);

if ~strcmp(files_out,'gb_niak_omitted');
    save(files_out,'spatial_av');
end
