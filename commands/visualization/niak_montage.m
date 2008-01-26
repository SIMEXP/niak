function [] = niak_montage(vol,opt)

% Visualization of a 3D volume in a montage style (all slices in one image)
%
% SYNTAX
% []=niak_montage(vol,opt)
%
% INPUTS
% vol           (3D array) a 3D volume
% opt           (structure, optional) has the following fields:
%
%                   type_visu (string, default 'axial') the plane of slices
%                       in the montage. Available options :'axial', 'coronal',
%                       'sagital'.
%
%                   limits (vector 2*1, default [min(vol(:)) max(vol(:))]) limits of color scaling.
%
%                   type_color (string, default 'gray') colormap name.
%
%                   flag_smooth (boolean, default 0) smooth the image with a 3
%                          voxels whm Gaussian kernel.
%
%                   'type_flip' (boolean, default '') make rotation and
%                           flip of the slice representation. see
%                           niak_flip_vol for options.
%
% OUTPUTS
% a 'montage' style visualization of each slice of the volume
%
% TODO
% The smoothing option is not currently implemented.
%
% COMMENTS
%
% Copyright (c) Pierre Bellec 01/2008
%
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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'type_visu','limits','type_color','flag_smooth','type_flip'};
gb_list_defaults = {'axial',[min(vol(:)) max(vol(:))],'gray',0,''};
niak_set_defaults

colormap(type_color);

if strcmp(type_visu,'coronal');

    vol = permute(vol,[1 3 2]);

elseif strcmp(type_visu,'sagital');

    vol = permute(vol,[2 3 1]);

elseif strcmp(type_visu,'axial')

else
    fprintf('%s is an unkwon view type.\n',type_visu);
    return
end

[nx,ny,nz] = size(vol);

N = ceil(sqrt(nz));
M = ceil(nz/N);

if strcmp(type_flip,'rot270')|strcmp(type_flip,'rot90')
    vol2 = zeros([nx*N ny*M]);
else
    vol2 = zeros([ny*N nx*M]);
end

[indy,indx] = find(ones([M,N]));
ind = find(ones([M*N]));

for num_z = 1:nz
    if strcmp(type_flip,'rot270')|strcmp(type_flip,'rot90')
        vol2(1+(indx(num_z)-1)*ny:indx(num_z)*ny,1+(indy(num_z)-1)*nx:indy(num_z)*nx) = niak_flip_vol(squeeze(vol(:,:,ind(num_z))),type_flip);
    else
        vol2(1+(indx(num_z)-1)*nx:indx(num_z)*nx,1+(indy(num_z)-1)*ny:indy(num_z)*ny) = niak_flip_vol(squeeze(vol(:,:,ind(num_z))),type_flip);
    end
end

imagesc(vol2,limits)
