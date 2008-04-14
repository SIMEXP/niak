function [files_in,files_out,opt] = niak_resample_self(files_in,files_out,opt)

% Apply MINCRESAMPLE to resample a volume with a transformation to a target
% space. The function allows to use source or target resolution, and to
% resample the data such that the direction cosines are x, y and z
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_RESAMPLE_SELF(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN      (structure) with the following fields :
%                 SOURCE (string) name of the file to resample.
%                 TARGET (string) name of the file defining space (can be
%                   the same as SOURCE)
%                 TRANSFORMATION (string, default identity)  name of a xfm transformation file
%                   to apply on SOURCE.
%
% FILES_OUT     (string,default <BASE_SOURCE>_res) the name of the output resampled volume.
%
% OPT           (structure, optional) has the following fields:
%
%       INTERPOLATION (string, default 'sinc') the spatial
%          interpolation method. Available options : 'trilinear', 'tricubic',
%          'nearest_neighbour','sinc'.
%
%         FLAG_TFM_SPACE (boolean, default 1) if FLAG_TFM_SPACE is 0, the
%            transformation is applied and the volume is resampled in the 
%            target space. If FLAG_TFM_SPACE is 1, the volume is resampled 
%           in such a way that there is no rotations anymore between voxel 
%           and world space.
%
%         VOXEL_SIZE (vector 1*3, default same as target space) If
%            voxel_size is set to 0, the resolution for resampling
%            will be the same as the source space. Otherwise, the specified
%            resolution will be used.
%
%         FOLDER_OUT (string, default: path of FILES_IN) If present,
%            all default outputs will be created in the folder FOLDER_OUT.
%            The folder needs to be created beforehand.
%
%         FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the
%            brick does not do anything but update the default
%            values in FILES_IN and FILES_OUT.
%
%
% OUTPUTS:
% The resampled volume.
%
% COMMENTS:
% This is a simple wrapper of MINCRESAMPLE.
% This function will work only for images in axial convention. Apply
% MINCRESHAPE to the images beforehand if it is not the case.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, minc

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

% Setting up inputs
gb_name_structure = 'files_in';
gb_list_fields = {'source','target','transformation'};
gb_list_defaults = {NaN,NaN,''};
niak_set_defaults

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'interpolation','flag_tfm_space','voxel_size','folder_out','flag_test'};
gb_list_defaults = {'sinc',1,[],'',0};
niak_set_defaults

%% Generating default ouputs
[path_f,name_f,ext_f] = fileparts(files_in.source);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_write = path_f;
else
    folder_write = opt.folder_out;
end

if isempty(files_out)
    files_out = cat(2,folder_write,filesep,name_f,'_res',ext_f);
end

if flag_test == 1
    return
end

%% Reading the source/target space information
hdr_source = niak_read_vol(files_in.source);
[dircos1,step1,start1] = niak_hdr_mat2minc(hdr_source.info.mat);
if min(voxel_size == 0) == 1
    voxel_size = abs(step1(:))';
end
nx1 = hdr_source.info.dimensions(1);
ny1 = hdr_source.info.dimensions(2);
nz1 = hdr_source.info.dimensions(3);

hdr_target = niak_read_vol(files_in.target);
[dircos2,step2,start2] = niak_hdr_mat2minc(hdr_target.info.mat);
if isempty(voxel_size)
    voxel_size = abs(step2(:))';
end
nx2 = hdr_target.info.dimensions(1);
ny2 = hdr_target.info.dimensions(2);
nz2 = hdr_target.info.dimensions(3);

%% Resample the target if necessary
if flag_tfm_space | (min(voxel_size(:) == step2(:))<1)
    nx3 = ceil(abs(step2(1)./voxel_size(1))*nx2);
    ny3 = ceil(abs(step2(2)./voxel_size(2))*ny2);
    nz3 = ceil(abs(step2(3)./voxel_size(3))*nz2);
    
    if step2(1) < 0
        start2(1) = start2(1) + step2(1)*nx2;
        step2(1) = abs(step2(1));
    end
   
    if step2(2) < 0
        start2(2) = start2(2) + step2(2)*nx2;
        step2(2) = abs(step2(2));
    end
    
    if step2(3) < 0
        start2(3) = start2(1) + step2(3)*nx2;
        step2(3) = abs(step2(3));
    end

    if flag_tfm_space
        dircos = [1 0 0 0 1 0 0 0 1];
    else
        dircos = dircos2;
    end
    
    file_target_tmp = niak_file_tmp('_target.mnc');
    instr_target = cat(2,'mincresample ',files_in.target,' ',file_target_tmp,' -clobber -dircos ',num2str(dircos),' -step ',num2str(voxel_size),' -start ',num2str(start2'),' -trilinear -nelements ',num2str(nx3),' ',num2str(ny3),' ',num2str(nz3));
    [tmp,str_tmp] = system(instr_target);
else
    file_target_tmp = files_in.target;
end

%% Resample the source on the target
if ~isempty(files_in.transformation)
    instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -transform ',files_in.transformation,' -',interpolation,' -like ',file_target_tmp);
else
    instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -',interpolation,' -like ',file_target_tmp);
end
[tmp,str_tmp] = system(instr_resample);

%% Clean temporary stuff
if ~(strcmp(file_target_tmp,files_in.target))
    delete(file_target_tmp)
end


