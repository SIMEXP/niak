function [files_in,files_out,opt] = niak_brick_resample_aal(files_in,files_out,opt)
% Resample a volume template with a transformation to a target space. 
% The function allows to change the target resolution, and to resample the 
% data such that the direction cosines are exactly x, y and z.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_RESAMPLE_AAL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN      
%       (structure) with the following fields :
%
%       SOURCE 
%           (string) name of the file to resample (can be 3D+t).
%
%       TARGET 
%           (string) name of the file defining space (can be the same as 
%           SOURCE).
%
%       TRANSFORMATION 
%           (string or cell of strings, default identity) the name of a XFM 
%           transformation file to apply on SOURCE. If it is a cell of 
%           string, each entry is assumed to correspond to one volume of 
%           SOURCE (for 4D file). 
%           TRANSFORMATION can also be a .mat file with one variable TRANSF 
%           containing a 4*4 matrix coding for an affine transformation. In 
%           case TRANSF has three dimensions and the source is 4D, the Ith 
%           volume will be resampled using TRANSF(:,:,I). The name of the 
%           variable can be modified (see OPT.TRANSF_NAME below).
%
%   FILES_OUT 
%       (string,default <BASE_SOURCE>_res) the name of the output resampled 
%       volume.
%
%   OPT           
%       (structure, optional) has the following fields:
%
%       INTERPOLATION 
%          (string, default 'tricubic') the spatial interpolation method. 
%          Available options : 'trilinear', 'tricubic', 'nearest_neighbour'
%          ,'sinc'.
%
%       FLAG_SKIP
%           (boolean, default false) if FLAG_SKIP==1, the brick does not do
%           anything, just copy the input on the output. 
%
%       FLAG_KEEP_RANGE
%           (boolean, default 0) if the flag is on, the range of values of
%           the new volume will be kept to the initial one. Otherwise the
%           range will be adapted to the new range of the interpolated
%           data.
%
%       FLAG_TFM_SPACE 
%           (boolean, default 0) if FLAG_TFM_SPACE is 0, the transformation 
%           is applied and the volume is resampled in the target space. 
%           If FLAG_TFM_SPACE is 1, the volume is resampled in such a way 
%           that there is no rotations anymore between voxel and world 
%           space.  In this case, the target space is only
%           used to set the resolution, unless this parameter was
%           additionally specified using OPT.VOXEL_SIZE, in which case the
%           target space is not used at all (e.g. use the source file).
%
%       FLAG_INVERT_TRANSF 
%           (boolean, default 0) if FLAG_INVERT_TRANSF is 1,
%           the specified transformation is inverted before being applied.
%
%       FLAG_ADJUST_FOV
%           (boolean, default 0) if FLAG_ADJUST_FOV is true and 
%           FLAG_TFM_SPACE is true, The field of view is adapted to fit the 
%           brain in the source space. Otherwise the new FOV will include
%           every voxel of the initial FOV
%
%       VOXEL_SIZE 
%           (vector 1*3, default same as target space) If VOXEL_SIZE is set 
%           to 0, the resolution for resampling will be the same as the 
%           target space. If VOXEL_SIZE is set to -1, the resolution will 
%           be the same as source space. Otherwise, the specified 
%           resolution will be used. If VOXEL_SIZE is a scalar, an isotropic 
%           voxel size will be used.
%
%       TRANSF_NAME
%           (string, default TRANSF) the name of the variable for affine 
%           transfomations in mat files (see comments below).
%
%       SUPPRESS_VOL
%           (string, default 0) for 4D files, the first SUPPRESS_VOL
%           volumes will be suppressed.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function prints 
%           some infos during the processing.
%
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Christian L. Dansereau, Centre de recherche de l'Institut
% universitaire de gériatrie de Montréal, 2011.
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, minc, resampling, aal, template, areas

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

flag_gb_niak_fast_gb = false;
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(files_in,'source')||isempty(files_in.source) 
    % no source template provided default AAL template 
    files_in.source      = [gb_niak_path_template 'roi_aal.mnc.gz']; 
end

if ~isfield(files_in,'target')||isempty(files_in.target)  
    % no target provided default AAL template 
    files_in.target      = [gb_niak_path_template 'roi_aal.mnc.gz'];  
end

[files_in,files_out,opt] = niak_brick_resample_vol(files_in,files_out,opt);






