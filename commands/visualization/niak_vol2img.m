function [img,slices] = niak_vol2img(hdr,vol,coord,opt)
% Generate an image file with a series of brain views.
%
% [IMG,SLICES] = NIAK_VOL2IMG( VOL , HDR , COORD , OPT )
%
% HDR.SOURCE (structure) the header of the volume
% HDR.TARGET (structure) the header of a volume defining the sampling space
% VOL        (3D array) brain volume, in stereotaxic space.
% COORD      (vector Nx3) each row define a series of slices to display (X,Y,Z).
% OPT.TYPE_FLIP (string, default 'rot90') how to flip slices to represent them.
% OPT.TYPE_VIEW (string, default 'all') the  type of views to include:
%   'axial', 'sagital', 'coronal', 'all'
% OPT.PADDING (scalar, default 0) the value used to padd slices together
% IMG (array) all three slices assembled into a single image, in target space.
% SLICES (cell of array) each entry is one slice (x, y, then z).
%
% Note: The montage is generated in voxel space associated with the target.
% If no target is specified, the source space is resampled with direction cosines,
% and the field of view is adjusted such that it includes all of the voxels.
% Only nearest neighbour interpolation is available.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization

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

%% Default options
if nargin < 3
    error('Please specify VOL, HDR, and COORD')
end

if ~isfield(hdr,'source')||~isfield(hdr,'target')
    hdr = struct('source',hdr,'target',[]);
end

if nargin < 4
    opt = struct;
    method = 'linear';
end

opt = psom_struct_defaults(opt, ...
    { 'padding' , 'type_view' , 'method' , 'type_flip' }, ...
    { 0         , 'all'              , 'linear'     , 'rot90'      });

%% stack slices, if multiple sets of coordinates are specified
nb_slices = size(coord,1);
if nb_slices > 1
    img = [];
    for ss = 1:nb_slices
        switch opt.type_view
            case 'all'
                img = [img ; niak_vol2img(hdr,vol,coord(ss,:),opt)];
            case {'sagital','coronal','axial'}
                img = [img niak_vol2img(hdr,vol,coord(ss,:),opt)];
            otherwise
                error('%s is an unknown type of view',opt.type_view);
        end
    end
    return
end

%% size of the source space
dim_s = hdr.source.info.dimensions(1:3);

%% Extract world coordinates for the source sampling grid
[xx_vs,yy_vs,zz_vs] = ndgrid(1:dim_s(1),1:dim_s(2),1:dim_s(3));
slice_ws = niak_coord_vox2world([xx_vs(:) yy_vs(:) zz_vs(:)],hdr.source.info.mat);
xx_ws = reshape(slice_ws(:,1),size(xx_vs));
yy_ws = reshape(slice_ws(:,2),size(yy_vs));
zz_ws = reshape(slice_ws(:,3),size(zz_vs));

%% Automatically choose axis and bounding box if a single image is provided
if isempty(hdr.target)
    N = [diag(hdr.source.info.voxel_size) zeros(3,1) ; 0 0 0 1];
    N(1:3,4) = -hdr.source.info.mat(1:3,4);
    hdr.target.info.mat = N;
    coord_vt = niak_coord_world2vox(slice_ws,hdr.target.info.mat);
    cmin = floor(min(coord_vt,[],1));
    cmax = ceil(max(coord_vt,[],1));
    hdr.target.info.dimensions = cmax - cmin + 1;
    tsl = hdr.target.info.mat(1:3,1:3)*(cmin(:) -1);
    hdr.target.info.mat(1:3,4) = hdr.target.info.mat(1:3,4) + tsl(:);
end

%% Size of the target space
dim_t = hdr.target.info.dimensions(1:3);

%% Check if user selected center
if ischar(coord)
    coord = niak_coord_vox2world( floor(dim_t/2),hdr.target.info.mat );
end

%% get target coordinates
coord_w = coord(1:3);
coord_w = coord_w(:)';

%% get coordinates in voxel (target) space
coord_vt = round(niak_coord_world2vox(coord_w,hdr.target.info.mat));

%% Type of view
switch opt.type_view
    case 'all'
        list_view = 1:3;
    case 'axial'
        list_view = 3;
    case 'sagital'
        list_view = 1;
    case 'coronal'
        list_view = 2;
    otherwise
        error('%s is an unknown type of view',opt.type_view);
end

%% resample the three slices
slices = cell(length(list_view),1);
for vv = 1:length(list_view) % loop over types of views
    % generate the source image
    % and the coordinates of pixels in source and target
    switch list_view(vv)
        case 1
            [xx_vt,yy_vt,zz_vt] = ndgrid(coord_vt(1),1:dim_t(2),1:dim_t(3));
        case 2
            [xx_vt,yy_vt,zz_vt] = ndgrid(1:dim_t(1),coord_vt(2),1:dim_t(3));
        case 3
            [xx_vt,yy_vt,zz_vt] = ndgrid(1:dim_t(1),1:dim_t(2),coord_vt(3));
    end

    % Build voxel coordinates in source space for the slice in target space
    slice_wt = niak_coord_vox2world([xx_vt(:) yy_vt(:) zz_vt(:)],hdr.target.info.mat);
    slice_vt = niak_coord_world2vox(slice_wt,hdr.source.info.mat);
    slice_vt = round(slice_vt);
    mask = (slice_vt(:,1)>=1)&(slice_vt(:,1)<=dim_s(1))&(slice_vt(:,2)>=1)&(slice_vt(:,2)<=dim_s(2))&(slice_vt(:,3)>=1)&(slice_vt(:,3)<=dim_s(3));
    slice_vt = slice_vt(mask,:);

    % resample
    slice_res = zeros(size(xx_vt));
    ind_slice = niak_sub2ind_3d(size(vol),slice_vt(:,1),slice_vt(:,2),slice_vt(:,3));
    slice_res(mask) = vol(ind_slice);
    slices{vv} = niak_flip_vol(squeeze(slice_res),opt.type_flip);
end

%% The montage image
size_h = 0;
size_w = 0;
for vv = 1:length(list_view)
    size_h = max( size_h , size(slices{vv},1) );
    size_w = size_w + size(slices{vv},2);
end
img = opt.padding*ones(size_h,size_w);
pos = 0;
for vv = 1:length(list_view)
    npad = floor((size_h-size(slices{vv},1))/2);
    img((npad+1):(npad+size(slices{vv},1)),(pos+1):(pos+size(slices{vv},2))) = slices{vv};
    pos = pos+size(slices{vv},2);
end
