function [files_in,files_out,opt] = niak_brick_mask_head_t1(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MASK_HEAD_T1
%
% Derive a head mask from one T1 volume
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_HEAD_T1(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  * FILES_IN        
%       (string) the name of a file with a t1 volume.
%
%  * FILES_OUT   
%       (string, default <BASE FILES_IN>_mask.<EXT FILES_IN>) 
%       the name of a file with a binary mask of the brain.
%   
%  * OPT           
%       (structure) with the following fields.  
%
%       NB_CLUSTERS_MAX
%           (integer, default 10) the number of largest connected
%           components in the mask.
%
%       THRESH_DIST
%           (real value, default 15) the distance applied to expand /
%           shrink the head mask.
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
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MASK_HEAD_T1, NIAK_BRICK_T1_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% The steps of the segmentation are the following : 
%
%   1. Extraction of a rough mask using intensity thresholding with the
%   Ostu algorithm as implemented in NIAK_MASK_BRAIN
%
%   2. Keep the largest NB_CLUSTERS spatially connected clusters
%
%   3. Expanding the mask with a distance transform (max distance from the
%   mask is THRESH_DIST).
%
%   4. Closure on the mask using morphomath.
%
%   5. Shrinkage of the mask with a distance transform (max distance from
%   ~mask is THRESH_DIST).
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, t1, mask, segmentation

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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_HEAD_T1(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_head_t1'' for more info.')
end

%% FILES_IN
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

%% FILES_OUT
if exist('files_out','var')&&~ischar(files_out)&&~isempty(files_out)
    error('FILES_OUT should be a string');
end


%% Options
gb_name_structure = 'opt';
gb_list_fields = {'folder_out','thresh_dist','nb_clust_max','flag_verbose','flag_test'};
gb_list_defaults = {'',15,10,true,false};
niak_set_defaults

%% Output files
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
if ~exist('files_out','var')||isempty(files_out)
    files_out = cat(2,opt.folder_out,filesep,name_f,'_mask_head',ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('*****************\nMasking the head \n*****************\n');
end

%% Reading data
if flag_verbose
    fprintf('Reading T1 image %s ...\n',files_in);
end
[hdr,anat] = niak_read_vol(files_in);

%% Masking individual data
opt_mask = rmfield(opt,{'folder_out','flag_test'});
opt_mask.voxel_size = hdr.info.voxel_size;
mask = niak_mask_head_t1(anat,opt_mask);

%% Writting output 
if flag_verbose
    fprintf('Writting the mask in %s ...\n',files_out);
end
hdr.file_name = files_out;
niak_write_vol(hdr,mask);