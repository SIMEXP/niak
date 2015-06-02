function [in, out, opt] = niak_brick_split_clusters(in, out, opt)
% Split clusters into regions, that span only one hemisphere
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SPLIT_CLUSTERS(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN (string) a 3D volume with clusters (cluster I is filled with I)
% FILES_OUT (string) a 3D volume with the splitted clusters.
% OPT.TYPE_NEIG (integer, default 8) the spatial neighbourhood of a
%    voxel, possible values: 4,6,8,10,18,26
% OPT.FLAG_VERBOSE (boolean, default true) turn verbose on/off
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does 
%   not do anything but update FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% COMMENTS:
% The clusters are assumed to be in symmetric stereotaxic space, i.e. the left/right hemispheres
% are separated by the plane x==0.
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Geriatrie de Montreal
%   Departement d'informatique et de recherche operationnelle
%   Universite de Montreal, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability analysis, bootstrap, jacknife.

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

%% Initialization and syntax checks

% Syntax
if ~exist('in','var')||~exist('out','var')
    error('niak:brick','syntax: [files_in,files_out,opt] = niak_brick_split_clusters(files_in,files_out,opt)\n Type ''help niak_brick_split_clusters'' for more info.')
end

if ~ischar(in)
    error('files_in should be a string')
end

if ~ischar(out)
    error('files_out should be a string')
end

if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      { 'type_neig' , 'flag_verbose' , 'flag_test' } , ...
      { 8           , true           , false       });
      
% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

% Read the input volume
[hdr,vol] = niak_read_vol(in);

%% Get the world coordinates of all voxels
mask = false(size(vol));
mask(:,1,1) = true;
ind = find(mask);
[x,y,z] = ind2sub(size(vol),ind);
coord_w = niak_coord_vox2world([x y z]-1,hdr.info.mat);
cutx = max(x(coord_w(:,1)<0));

%% Build a new volume with enforced split between the left and right hemispheres
vol2 = zeros(size(vol,1)+1,size(vol,2),size(vol,3));
vol2(1:cutx,:,:) = vol(1:cutx,:,:);
vol2((cutx+2):end,:,:) = vol((cutx+1):end,:,:);

%% Extract connected components, and save the result
vol_c = zeros(size(vol2));
list_roi = unique(vol2(:));
list_roi = list_roi(list_roi~=0);
nb_roi = 0;
for rr = 1:length(list_roi)
    mask_roi = niak_find_connex_roi(vol2 == list_roi(rr),struct('type_neig',opt.type_neig));
    vol_c(mask_roi>0) = mask_roi(mask_roi>0)+nb_roi;
    nb_roi = nb_roi+max(mask_roi(:));
end
vol_c = vol_c([1:cutx (cutx+2):end],:,:);
hdr.file_name = out;
niak_write_vol(hdr,vol_c);