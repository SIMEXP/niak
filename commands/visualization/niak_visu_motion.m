function [] = niak_visu_motion(vol,opt)

% Visualization of a 3D+t series as a little movie
%
% SYNTAX:
% []=niak_montage(vol,opt)
%
% INPUTS:
% VOL           (3D array) a 3D volume
% OPT           (structure, optional) has the following fields:
%
%                   SPEED (real number, default 0.2) pause between two
%                       images (in sec)
%                   TYPE_SLICE (string, default 'axial') the plane of slices
%                       in the montage. Available options : 'axial', 'coronal',
%                       'sagital'. This option assumes the volume is in
%                       'xyz' convention (left to right, posterior to
%                       anterior, ventral to dorsal).
%
%                   TYPE_COLOR (string, default 'jet') colormap name.
%
%                   FWHM (double, default 0) smooth the image with a 
%                       isotropic Gaussian kernel of SMOOTH fwhm (in voxels).
%
%                   TYPE_FLIP (boolean, default 'rot90') make rotation and
%                           flip of the slice representation. see
%                           niak_flip_vol for options. 'rot90' will work
%                           for images whose voxels is x/y/z respectively
%                           oriented from left to right, from anterior to
%                           posterior, and from ventral to dorsal. In this
%                           case, left is left on the image.
%
% OUTPUTS:
% Each time frame (volume) is displayed in a montage style for a brief
% time, resulting in a little movie of the 3D+t dataset.
%
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, montage, visualization

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
gb_list_fields = {'speed','type_slice','vol_limits','type_color','fwhm','type_flip'};
gb_list_defaults = {0.2,'axial',[min(vol(:)) max(vol(:))],'jet',0,'rot90'};
niak_set_defaults

opt = rmfield(opt,'speed');
opt.vol_limits = [min(vol(:)) max(vol(:))];

nt = size(vol,4);

fprintf('Volume : ')
num_t = 1;
flag_exit = 0;
flag_play = 0;

while ~flag_exit
    niak_montage(vol(:,:,:,num_t),opt);
    if ~flag_play
        uk = input('Press a key (w : rewind, x : exit, c : forward, p : play)','s')
    end
    
    switch uk
        case 'w'
            if num_t > 1
                num_t = num_t-1;
            end
        case 'x'
            return
        case 'c'
            if num_t < nt
                num_t = num_t+1;
            end
        case 'p'
            if num_t == nt
                flag_play = 0;
            else
                pause(speed)
                num_t = num_t+1;
                flag_play = 1;
            end
                
    end
    fprintf(' %i',num_t)
    %pause(speed);
end
fprintf('\n')