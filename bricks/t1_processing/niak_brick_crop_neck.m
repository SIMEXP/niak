function [in,out,opt] = niak_brick_crop_neck(in,out,opt)
% Crop the neck in a T1 scan
%
% SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CROP_NECK(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN (string) a T1 scan.
% FILES_OUT (string) a T1 scan, with neck cropped
% OPT.CROP_NECK (scalar) the percentage of the field of view to crop. Must be between 0 and 1. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick only checks
%   IN, OUT, OPT but does not do anything. 
% OPT.FLAG_VERBOSE (boolean, default true) if the flag is true, verbose progress info
%
% NOTE: the crop is implemented in voxel space, along the axis that fits most 
%   closely with ventro-dorsal (z) axis. Slices that are closer to the neck are 
%   suppressed first. This can be the first or the last slices in voxel space, 
%   depending on storage conventions. 
% See license information in the code. 

% Copyright (c) Pierre Bellec, Department of Computer Science and Operations Research
% University of Montreal, 2016
% Maintainer : pierre.bellec@criugm.qc.ca
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

if ~ischar(in)
    error('FILES_IN should be a string')
end

if ~ischar(out)
    error('FILES_IN should be a string')
end

if nargin < 3
    error('Please specify OPT.CROP_NECK')
end

opt = psom_struct_defaults( opt , { 'crop_neck' , 'flag_test' , 'flag_verbose' }, { NaN , false , true} );

if (opt.crop_neck < 0)||(opt.crop_neck>1)
    error('OPT.CROP_NECK needs to be comprised between 0 and 1')
end
if opt.flag_test 
    return
end


if opt.flag_verbose
    fprintf('***********************************\nNeck Cropping\n***********************************\n');
    fprintf('Reading file %s...\n',in);
end
[hdr,vol] = niak_read_vol(in);
ind = findstr(hdr.info.dimension_order,'z');
[direction_cosine,step,start,dimension_order] = niak_hdr_mat2minc(hdr.info.mat);
nb_slice = min(size(vol,ind)-1,ceil(opt.crop_neck*size(vol,ind)));
if opt.flag_verbose
    fprintf('Cropping dimension number %i\n',ind)
end

if step(ind)>0
    switch ind
      case 1
          vol = vol(nb_slice+1:end,:,:);
      case 2
          vol = vol(:,nb_slice+1:end,:);
      case 3 
          vol = vol(:,:,nb_slice+1:end);
    end
    start(ind) = start(ind) + nb_slice*step(ind);
    hdr.info.mat = niak_hdr_minc2mat(direction_cosine,step,start);
else
    switch ind
      case 1
          vol = vol(1:(end-nb_slice),:,:);
      case 2
          vol = vol(:,1:(end-nb_slice),:);
      case 3 
          vol = vol(:,:,1:(end-nb_slice));
    end
end
if opt.flag_verbose
    fprintf('Writing results in %s\n',out);
end
hdr.file_name = out;
niak_write_vol(hdr,vol);