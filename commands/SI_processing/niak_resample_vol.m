function [vol_r,hdr_r] = niak_resample_vol(vol,hdr,opt)

% Resample a 3D volume by allowing a change in "voxel-to-world" coordinates
% rigid-body transformation, and change in the voxel size.
%
% SYNTAX:
% [VOL_R,HDR_R] = NIAK_RESAMPLE_VOL(VOL,HDR,OPT)
% 
% INPUT:
% VOL   (3D or 3D+t array) data that needs to be resampled.
%
% HDR   (structure) the header associated with the data (see
%           NIAK_READ_VOL). The only important fields are HDR.INFO.VOXEL_SIZE 
%           and HDR.INFO.MAT (they define the "voxel-to-world" coordinates 
%           transformation and the sampling rate).
%
% OPT   (structure) with the following fields :
%
%       INTERPOLATION (string, default 'linear') The method for performing 
%           the spatial interpolation. Available options are :
%           'nearest','linear','spline','cubic'
% 
%       VOXEL_SIZE (vector 3*1) the new voxel size for the respective
%          dimensions of VOL.
%
%       MAT (4*4 matrix, default identity) a transformation to apply on 
%           the data. TRANSF(1:3,1:3) defines the rotation, while
%           TRANSF(1:3,4) defines the translation. For 3D+t data, MAT can
%           have a fourth dimension (time) matching the one of VOL. In this
%           case, volume-specific transformation will be used.
% 
% OUTPUT:
% VOL_R (3D+t or 3D array) the resampled data.
%
% HDR_R (structure) an updated version of HDR.
% 
% COMMENTS:
% This function is based on the matlab function INTERP3.
%
% SEE ALSO:
% niak_read_hdr_minc, niak_write_minc, niak_write_vol.
%
% Copyright (c) Pierre Bellec, McConnel Brain Imaging Center, Montreal 
% Neurological Institute, McGill University, Montreal, Canada, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc

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

%% Setting up default values for the header
if ~exist('hdr')
    error('Please specify HDR, the header associated with your data');
else
    if ~isfield(hdr,'info')
        error('HDR should have a field INFO');
    else
        if ~isfield(hdr.info,'mat')
            error('HDR.INFO should have a field MAT');
        end
        if ~isfield(hdr.info,'voxel_size')
            error('HDR.INFO should have a field VOXEL_SIZE');
        end
    end
end

transf1 = hdr.info.mat;
voxel_size1 = abs(hdr.info.voxel_size);
step = sign(hdr.info.voxel_size);
%% Setting up default values for options
gb_name_structure = 'opt';
gb_list_fields = {'interpolation','mat','voxel_size'};
gb_list_defaults = {'linear',[eye(3) zeros([3 1]); zeros([1 3]) 1],[]};
niak_set_defaults

transf2 = opt.mat;
if isempty(opt.voxel_size)
    voxel_size2 = voxel_size1;
else
    voxel_size2 = opt.voxel_size;
end

%% Initializing the coordinates 
[nx,ny,nz,nt] = size(vol);

nx2 = ceil((voxel_size1(1)/voxel_size2(1))*nx);
ny2 = ceil((voxel_size1(2)/voxel_size2(2))*ny);
nz2 = ceil((voxel_size1(3)/voxel_size2(3))*nz);

ind2 = (1:prod([nx2,ny2,nz2]))'; % the target space ....
[indx2,indy2,indz2] = ind2sub([nx2,ny2,nz2],ind2);
clear ind2
coord2 = transf1^(-1)*transf2*transf1*[diag(voxel_size2./voxel_size1) zeros([3 1]); zeros([1 3]) 1]*[indx2'-1;indy2'-1;indz2'-1; ones([1 length(indx2)])];
clear indx2 indy2 indz2
coord2 = coord2(1:3,:)';

%% Applying the resampling
vol_r = interp3(0:nx-1,0:ny-1,0:nz-1,vol,coord2(:,2),coord2(:,1),coord2(:,3),interpolation,0);
vol_r = reshape(vol_r,[nx2,ny2,nz2]);
hdr_r = hdr;
hdr_r.info.mat = transf2*transf1*[diag(voxel_size2./voxel_size1) zeros([3 1]); zeros([1 3]) 1];
hdr_r.info.voxel_size = voxel_size2.*step;

