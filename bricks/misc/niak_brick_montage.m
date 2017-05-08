function [in,out,opt] = niak_brick_montage(in,out,opt)
% Generate a figure with a montage of sagital slices in the volume 
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_VOL2IMG(IN,OUT,OPT)
%
% IN.SOURCE (string) the file name of a 3D volume
% IN.TARGET (string, default '') the file name of a 3D volume defining the target space. 
%   If left empty, or unspecified, OUT is the world space associated with IN.SOURCE 
%   i.e. the volume is resamples to have no direction cosines. 
% OUT.MONTAGE (string) the file name for the figure. The extension will determine the type. 
% OUT.COLORMAP (string, default 'gb_niak_omitted') the file name for a figure with the color map. 
% OUT.QUANTIZATION (string, default 'gb_niak_omitted') the file name for a .mat file with variables DATA and SIZE_SLICE. 
%   DATA(N) is the data point associated with the Nth color. 
%   SIZE_SLICE (vector 1x2) the size of a slice. 
% OPT.NB_SLICES (scalar, default Inf) the number of slices to produce (with a parameter
%   Inf, all possible slices will be generated). 
% OPT.COLORMAP (string, default 'gray') The type of colormap. Anything supported by 
%   the instruction `colormap` will work, as well as 'hot_cold' (see niak_hot_cold).
%   This last color map always centers on zero.
% OPT.NB_COLOR (default 256) the number of colors to use in quantization. If Inf is 
%   specified, all values are included in the colormap. This is handy for integer 
%   values images (e.g. parcellation).
% OPT.IND (scalar, default 1) for 4D volume, IND is the temporal index of the volume to use
%   starting from 1. 
% OPT.QUALITY (default 90) for jpg images, set the quality of the outputs (from 0, bad, to 100, perfect).
% OPT.THRESH (scalar, default []) if empty, does nothing. If a scalar, any value 
%   below threshold becomes transparent. If two values, anything between these two 
%   values become transparent. 
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
% If OUT is a string, only OUT.MONTAGE is generated. 
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

if ischar(out)
    out = struct('montage',out);
end

out = psom_struct_defaults( out , ...
    { 'montage' , 'colormap'        , 'quantization'    }, ...
    { NaN       , 'gb_niak_omitted' , 'gb_niak_omitted' });
    
opt = psom_struct_defaults ( opt , ...
    { 'ind' , 'nb_color' , 'quality' , 'thresh' , 'nb_slices' , 'type_view' , 'limits' , 'colormap' , 'flag_test' }, ...
    { 1     , 256        , 90        , []       , Inf         , 'sagital'   , []       , 'gray'     , false       });

if opt.flag_test 
    return
end

%% Read headers
[hdr.source,vol] = niak_read_vol(in.source);
vol = vol(:,:,:,opt.ind);

if ~isempty(in.target)
    hdr.target = niak_read_vol(in.target);
else
    hdr.target = '';
end
if ndims(vol)==4
    vol = median(vol,4);
end

%% resample volume
[vol_r,hdr] = niak_resample_vol(hdr,vol);

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
    img = vol_rf(1)*ones([wx*dim_v(2) wy*dim_v(3)]);
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
otherwise 
    error('Only sagital slices are supported')
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

%% Generate colormap
if opt.nb_color < Inf
    bins = linspace(climits(1),climits(2),opt.nb_color);
    delta = (bins(2)-bins(1))/2;
    bins = [bins(1)-delta,bins+delta];
else
    bins = [unique(img(:)) ; Inf];
end
opt.nb_color = length(bins)-1;

switch opt.colormap
	case 'hot_cold'   
    if (opt.limits(2)>0) && (opt.limits(1)<0)
        per_hot = opt.limits(2)/(opt.limits(2)-opt.limits(1));
    elseif opt.limits(2)<=0
        per_hot = 0;
    else 
        per_hot = 1;
    end
    cm = niak_hot_cold(opt.nb_color,per_hot);
	otherwise
		cm = eval([opt.colormap '(opt.nb_color);']);
end

%% build the image
[tmp,idx] = histc(img(:),bins);
idx(img<=bins(1)) = 1;
idx(img>=bins(end)) = opt.nb_color;
rgb = zeros([size(img),3]);
rgb(:,:,1) = reshape(cm(idx(:),1),size(img));
rgb(:,:,2) = reshape(cm(idx(:),2),size(img));
rgb(:,:,3) = reshape(cm(idx(:),3),size(img));
if ~isempty(opt.thresh)
    if (length(opt.thresh)==1)
        mask_alpha = img>=opt.thresh;
    else
        mask_alpha = (img>=opt.thresh(2))|(img<=opt.thresh(1));
    end
    img(~mask_alpha) = 0;
    imwrite(rgb,out.montage,'quality',opt.quality,'Alpha',double(mask_alpha));
else
    imwrite(rgb,out.montage,'quality',opt.quality);
end

%% The color map
if ~strcmp(out.colormap,'gb_niak_omitted')
    rgb = zeros(1,size(cm,1),size(cm,2));
    rgb(1,:,:) = cm;
    if ~isempty(opt.thresh) && (length(opt.thresh)==1)
        rgb = rgb(1,bins(1:(end-1))>=opt.thresh,:);
    end
    imwrite(rgb,out.colormap,'quality',opt.quality);
end

%% Saving the quantization data
if ~strcmp(out.quantization,'gb_niak_omitted')
    data = bins;
    size_slice = dim_v([3 2]);
    voxel_size = hdr.target.info.voxel_size(1); % Currently supports only isotropic voxels
    origin = -hdr.target.info.mat(1:3,4);
    if ~isempty(opt.thresh) && (length(opt.thresh)==1)
        min_img = opt.thresh;
    else
        min_img = climits(1);
    end
    max_img = climits(2);
    save(out.quantization,'data','size_slice','origin','voxel_size','min_img','max_img');    
end
