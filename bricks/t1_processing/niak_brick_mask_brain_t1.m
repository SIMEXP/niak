function [files_in,files_out,opt] = niak_brick_mask_brain_t1(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MASK_BRAIN_T1
%
% Derive a brain mask from one T1 volume
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN_T1(FILES_IN,FILES_OUT,OPT)
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
%       PERC_CONF
%           (scalar, default 0.5) the portion of brain tissue that is
%           excluded when defining core dense regions (the darkest voxels
%           are excluded first).
%
%       REGION_GROWING
%           (structure) with the following fields :
%
%           NB_EROSIONS
%               (integer, default 0) number of erosions to apply on the mask
%               before defining the spatial density.
%
%           THRE_DENSITY
%               (scalar, default 0.9) the spatial density threshold to define
%               the core clusters.
%
%           TYPE_NEIG_GROW
%               (integer, default 6) defines the spatial neighbourhood in the
%               region growing.
%               Available options 4 (2D), 6 (3D), 8 (2D) and 26 (3D).
%
%           NB_ITER_MAX
%               (integer, default Inf) the maximal number of iteration in the
%               region growing to propagate cluster labels
%
%           MIN_SIZE_CORES
%               (scalar, default 30) the minimum size of dense cores for
%               region growing. This is expressed in volume with a unit
%               consistent with OPT.VOXEL_SIZE.
%
%       FILL_HOLES
%           (structure) with the following fields :
%
%           THRESH_DIST
%               (scalar, default 10) the distance for expansion/shrinking
%               of the brain, expressed in the same units as VOXEL_SIZE.
%
%       DIST_BRAIN
%           (scalar, default 130) voxels that are further away than
%           DIST_BRAIN from the center of mass of the brain are excluded of
%           the mask. That can be used to get rid of the spinal cord.
%           Setting up DIST_BRAIN to Inf will result in keeping the whole
%           mask.
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
% NIAK_MASK_BRAIN_T1, NIAK_CLUSTERING_SPACE_DENSITY
%
% _________________________________________________________________________
% COMMENTS:
%
% The algorithm is similar conceptually to the competitive region growing
% approach proposed in :
%
% J. G. Park & C. Lee (2009). `Skull stripping based on region growing for
% magnetic resonance brain images'. NeuroImage 47(4):1394-1407.
%
% The actual implementation was still markedly different. It is 3D rather
% than 2D and the competitive region growing algorithm exploits the concept 
% of spatial density rather than more standard morphomathematical 
% operations. Specifically, the main stages are the following :
%
%   1. Intensity segmentation resulting into a binary mask of most brain 
%   tissues.
%
%   2. Competitive region growing. The seed regions are the bigger
%   connected components within the dense portions of the white matter. 
%   Labels are propageted to grey matter through region-growing. This
%   method is adapted from DBSCAN and has been proposed in :
%
%   Martin Ester, Hans-Peter Kriegel, Jörg Sander, Xiaowei Xu (1996).
%   "A density-based algorithm for discovering clusters in large spatial
%   databases with noise"
%   in Evangelos Simoudis, Jiawei Han, Usama M. Fayyad.
%   Proceedings of the Second International Conference on Knowledge
%   Discovery and Data Mining (KDD-96). AAAI Press. pp. 226–231.
%   ISBN 1-57735-004-9.
%   http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.71.1980.
%
%   3. Holes in the brain mask are filled using morphomathematical
%   operations.
%
% 	4. The spinal cord can optionally be removed from the mask. This is 
%   done by excluding voxels that are more than 150mm apart from the center 
%   of mass of the brain. This distance threshold can be ajusted using
%   OPT.DIST_BRAIN . Setting it up to Inf will result in keeping
%   everything.
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN_T1(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_brain_t1'' for more info.')
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
opt_tmp.flag_verbose = 1;

gb_name_structure = 'opt';
gb_list_fields = {'folder_out','fill_holes','region_growing','dist_brain','perc_conf','flag_verbose','flag_test'};
gb_list_defaults = {'',opt_tmp,opt_tmp,130,0.5,true,false};
niak_set_defaults

gb_name_structure = 'opt.region_growing';
gb_list_fields = {'flag_verbose','type_neig_grow','thre_density','nb_iter_max','nb_erosions','min_size_cores'};
gb_list_defaults = {opt.flag_verbose,6,0.9,10,0,30};
niak_set_defaults
opt.region_growing.flag_verbose = opt.flag_verbose;

gb_name_structure = 'opt.fill_holes';
gb_list_fields = {'flag_verbose','thresh_dist'};
gb_list_defaults = {true,10};
niak_set_defaults
opt.fill_holes = rmfield(opt.fill_holes,'flag_verbose');
flag_verbose = opt.flag_verbose;

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
    files_out = cat(2,opt.folder_out,filesep,name_f,'_mask',ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('*****************\nMasking the brain \n*****************\n');
end

%% Reading data
if flag_verbose
    fprintf('Reading T1 image %s ...\n',files_in);
end
[hdr,anat] = niak_read_vol(files_in);

%% Masking individual data
opt_mask = rmfield(opt,{'folder_out','flag_test'});
opt_mask.voxel_size = hdr.info.voxel_size;
mask = niak_mask_brain_t1(anat,opt_mask);

%% Writting output 
if flag_verbose
    fprintf('Writting the mask in %s ...\n',files_out);
end
hdr.file_name = files_out;
niak_write_vol(hdr,mask);