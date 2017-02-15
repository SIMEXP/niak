function vol_r = niak_resample_vol(hdr,vol)
% Resample a volume in a given space
%
% VOL_R = NIAK_RESAMPLE_VOL( HDR , VOL , OPT )
%
% HDR.SOURCE (structure) the header of the volume
% HDR.TARGET (structure) the header of a volume defining the sampling space
% VOL        (3D array) brain volume, in stereotaxic space.
% VOL_R      (3D array) same as VOL, resampled in the voxel space of TARGET
% 
% Note: The new volume is generated in the voxel space associated with the target. 
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
if nargin < 2
    error('Please specify VOL and HDR') 
end

if ~isfield(hdr,'source')||~isfield(hdr,'target')
    hdr = struct('source',hdr,'target',[]);
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

%% get coordinates in voxel (target) space
[xx_vt,yy_vt,zz_vt] = ndgrid(1:dim_t(1),1:dim_t(2),1:dim_t(3));  
slice_wt = niak_coord_vox2world([xx_vt(:) yy_vt(:) zz_vt(:)],hdr.target.info.mat);
xx_wt = reshape(slice_wt(:,1),size(xx_vt));
yy_wt = reshape(slice_wt(:,2),size(yy_vt));
zz_wt = reshape(slice_wt(:,3),size(zz_vt));

% Build voxel coordinates from target to source space 
slice_vt = niak_coord_world2vox(slice_wt,hdr.source.info.mat);
slice_vt = round(slice_vt);
mask = (slice_vt(:,1)>=1)&(slice_vt(:,1)<=dim_s(1))&(slice_vt(:,2)>=1)&(slice_vt(:,2)<=dim_s(2))&(slice_vt(:,3)>=1)&(slice_vt(:,3)<=dim_s(3));
slice_vt = slice_vt(mask,:);
    
% resample
vol_r = zeros(size(xx_vt));
ind_slice = niak_sub2ind_3d(size(vol),slice_vt(:,1),slice_vt(:,2),slice_vt(:,3));
vol_r(mask) = vol(ind_slice);