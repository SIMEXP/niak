function [] = niak_visu_motion(vol,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_VISU_MOTION
%
% Visualization of a 3D+t series as a little movie
%
% SYNTAX:
% [] = NIAK_VISU_MOTION(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL           
%       (4D array) a 3D+t dataset.
%
% OPT           
%       (structure, optional) has the following fields:
%
%       SPEED 
%           (real number, default 0.2) pause between two images (in sec)
%
%       TYPE_SLICE 
%           (string, default 'axial') the plane of slices in the montage. 
%           Available options : 'axial', 'coronal', 'sagital'. This option 
%           assumes the volume is in 'xyz' convention (left to right, 
%           posterior to anterior, ventral to dorsal).
%
%       TYPE_COLOR 
%           (string, default 'jet') colormap name.
%
%       FWHM 
%           (double, default 0) smooth the image with an isotropic Gaussian 
%           kernel of FWHM fwhm (in voxels).
%
%       TYPE_FLIP 
%           (string, default 'rot90') make rotation and flip of the slice 
%           representation. see NIAK_FLIP_VOL for options. 
%           'rot90' will work for axial slices of a volume oriented
%           from left to right, from anterior to posterior, and 
%           from ventral to dorsal. In this case, left is left on the 
%           image.
%
%       VOL_LIMITS 
%           (vector 1*2, default [min(vol(:)) max(vol(:))]) limits of the 
%           color scaling.
%
%       ORDER
%           (vector, default []) it VOL is a set of vectorized matrices,
%           set an order on the regions.
%
% _________________________________________________________________________
% OUTPUTS:
%
% Each time frame (volume) is displayed in a montage style for a brief
% time, resulting in a little movie of the 3D+t dataset.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_MONTAGE
%
% _________________________________________________________________________
% COMMENTS:
%
% To make a movie of a MINC or NIFTI dataset, you will first need to read
% that dataset using NIAK_READ_VOL :
%
% >> [hdr,vol] = niak_read_vol('my_data.mnc');
%
% Then you may want to use matlab syntax to extract a subpart of the
% volume, because a movie of a full volume with tens of slices is a bit
% too much. For example, the following command will make a motion of the 
% 20th and 21st axial slices of the 4D data. :
%
% >> niak_visu_motion(vol(:,:,20:21,:));
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
gb_list_fields    = {'speed' , 'type_slice' , 'vol_limits'              , 'type_color' , 'fwhm' , 'type_flip' , 'order' };
gb_list_defaults  = {0.2     , 'axial'      , [min(vol(:)) max(vol(:))] , 'jet'        , 0      , 'rot90'     , []      };
niak_set_defaults

opt = rmfield(opt,'speed');

if ndims(vol)==2
    nt = size(vol,2);
else
    nt = size(vol,4);
end

fprintf('Volume : ')
num_t = 1;
flag_exit = 0;
flag_play = 0;

if ndims(vol)~=2
    opt = rmfield(opt,'order');
end

while ~flag_exit
    if ndims(vol)==2
        if ~isempty(order)
            mat = niak_vec2mat(vol(:,num_t));
            niak_visu_matrix(mat(order,order));
        else
            niak_visu_matrix(vol(:,num_t));
        end
    else        
        niak_montage(vol(:,:,:,num_t),opt);
    end
    if ~flag_play
        uk = input('Press a key (w : rewind, x : exit, '' : forward, p : play)','s');
    end
    switch uk
        case 'w'
            if num_t > 1
                num_t = num_t-1;
            end
        case 'x'
            return
        case ''
            if num_t < nt
                num_t = num_t+1;
            else 
                num_t = 1;
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