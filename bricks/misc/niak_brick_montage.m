function [in,out,opt] = niak_brick_montage(in,out,opt)
% Generate a figure with a montage of different slices of a volume 
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_VOL2IMG(IN,OUT,OPT)
%
% IN.SOURCE (string) the file name of a 3D volume
% IN.TARGET (string, default '') the file name of a 3D volume defining the target space. 
%   If left empty, or unspecified, OUT is the world space associated with IN.SOURCE 
%   i.e. the volume is resamples to have no direction cosines. 
% OUT (string) the file name for the figure. The extension will determine the type. 
% OPT.NB_SLICES (scalar, default Inf) the number of slices to produce (with a parameter
%   Inf, all possible slices will be generated). 
% OPT.TYPE_VIEW (default 'sagital') type of montage ('axial' or 'coronal' or 'sagital'). 
% OPT.COLORMAP (string, default 'gray') The type of colormap. Anything supported by 
%   the instruction `colormap` will work. 
% OPT.LIMITS (vector 1x2) the limits for the colormap. By defaut it is using [min,max].
%    If a string is specified, the function will implement an adaptative strategy. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but 
%    update IN, OUT and OPT.
%
% The montage is generated in voxel space associated with the target. If no target is specified,
% the source space is resampled with direction cosines, and the field of view is adjusted 
% such that it includes all of the voxels. Only nearest neighbour interpolation is 
% available. For 4D data, the median volume is extracted.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization, montage, 3D brain volumes

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

%% Defaults
in = psom_struct_defaults( in , ...
    { 'source' , 'target' }, ...
    { NaN       , ''          });

if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults ( opt , ...
    { 'nb_slices' , 'type_view' , 'limits' , 'colormap' , 'flag_test' }, ...
    { Inf         , 'sagital'   , ''       , 'gray'     , false       });

if opt.flag_test 
    return
end

%% Read headers
[hdr.source,vol] = niak_read_vol(in.source);
if ~isempty(in.target)
    hdr.target = niak_read_vol(in.target);
else
    hdr.target = '';
end
if ndims(vol)==4
    vol = median(vol,4);
end

%% resample volume
vol_r = niak_resample_vol(hdr,vol);

%% Build montage
dim_v = size(vol_r);
switch opt.type_view
case 'sagital'
    vol_rf = zeros(dim_v(1),dim_v(3),dim_v(2));
    for xx = 1:dim_v(1)
        vol_rf(xx,:,:) = niak_flip_vol(squeeze(vol_r(xx,:,:)),'rot90');
    end
    dim_v = size(vol_rf);
    npix = sqrt(prod(dim_v));
    wy = floor(npix/dim_v(3));
    wx = ceil(prod(dim_v)/(wy*dim_v(3)*dim_v(2)));
    img = zeros([wx*dim_v(2) wy*dim_v(3)]);
    ss = 1;
    for xx = 1:wx
        for yy = 1:wy
            indx_l = (xx-1)*dim_v(2)+1;
            indx_h = xx*dim_v(2);
            indy_l = (yy-1)*dim_v(3)+1;
            indy_h = yy*dim_v(3);
            if ss<=size(vol_r,1)
                img(indx_l:indx_h,indy_l:indy_h) = squeeze(vol_rf(ss,:,:));
                ss = ss + 1;
            end
        end
    end
end

%% image limits
if ischar(opt.limits)
    mask = niak_mask_brain(vol);
    mvol = median(vol(mask));
    svol = niak_mad(vol(mask));
    climits = [0 mvol+2*svol];
    opt.limits = climits;
end

if isempty(opt.limits)
    opt.limits = [min(img(:)) max(img(:))];
end
climits = opt.limits;

%% build the image
img(img>climits(2)) = climits(2);
img(img<climits(1)) = climits(1);
cm = colormap(opt.colormap);
bins = linspace(climits(1),climits(2),size(cm,1));
[tmp,idx] = histc(img,bins);
idx(idx==0) = 1;
rgb = zeros([size(img),3]);
rgb(:,:,1) = reshape(cm(idx(:),1),size(img));
rgb(:,:,2) = reshape(cm(idx(:),2),size(img));
rgb(:,:,3) = reshape(cm(idx(:),3),size(img));
imwrite(rgb,out);