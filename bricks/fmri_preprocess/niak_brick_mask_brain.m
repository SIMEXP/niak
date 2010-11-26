function [files_in,files_out,opt] = niak_brick_mask_brain(files_in,files_out,opt)
% Derive a brain mask from one fMRI dataset
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN        
%   (string) file name of one 3D+t dataset.
%
% FILES_OUT   
%   (string, default <NAME FILES_IN>_mask<EXT FILES_IN>) the name of a 4D
%   file with a binary mask of the brain.
%   
% OPT           
%   (structure) with the following fields :
%
%   FWHM 
%       (real value, default 8) the FWHM of the blurring kernel in the same 
%       unit as the voxel size. A value of 0 for FWHM will skip the 
%       smoothing step.
%       
%   FLAG_REMOVE_EYES 
%       (boolean, default 0) if FLAG_REMOVE_EYES == 1, an attempt is made 
%       to remove the eyes from the mask.
%           
%   FOLDER_OUT 
%       (string, default: path of FILES_IN) If present, the output will be 
%       created in the folder FOLDER_OUT. 
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST 
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MASK_BRAIN
%
% _________________________________________________________________________
% COMMENTS:
%
% The algorithm is a threshold on the intensity of the average
% of the absolute values of all volumes. The threshold is selected with the
% following method :
%
% Otsu, N.
% A Threshold Selection Method from Gray-Level Histograms.
% IEEE Transactions on Systems, Man, and Cybernetics, Vol. 9, No. 1, 1979, 
% pp. 62-66.
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : brain mask, fMRI, segmentation, Otsu

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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_brain'' for more info.')
end

%% FILES_IN
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

%% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields   = {'fwhm' , 'flag_remove_eyes' , 'flag_verbose' ,'flag_test' ,'folder_out' };
gb_list_defaults = {8      , 0                  , true           ,false       ,''           };
niak_set_defaults

[path_f,name_f,ext_f] = niak_fileparts(files_in);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out)
    files_out = [opt.folder_out name_f,'_mask',ext_f];
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Masking individual data
opt_mask.flag_remove_eyes = opt.flag_remove_eyes;
opt_mask.fwhm = opt.fwhm;
if flag_verbose
    fprintf('Masking brain in file %s ...\n',files_in);
end

[hdr,vol] = niak_read_vol(files_in);
opt_mask.voxel_size = hdr.info.voxel_size;
mask = niak_mask_brain(vol,opt_mask);

%% Saving outputs
if flag_verbose
    fprintf('Saving the mask in the file %s ...\n',files_out);
end
hdr.file_name = files_out;
niak_write_vol(hdr,mask);