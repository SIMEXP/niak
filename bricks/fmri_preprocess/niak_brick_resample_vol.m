function [files_in,files_out,opt] = niak_brick_resample_vol(files_in,files_out,opt)

% Apply MINCRESAMPLE to resample a volume with a transformation to a target
% space. The function allows to use source or target resolution, and to
% resample the data such that the direction cosines are x, y and z
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_RESAMPLE_VOL(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN      (structure) with the following fields :
%                 SOURCE (string) name of the file to resample (can be 3D+t).
%                 TARGET (string) name of the file defining space (can be
%                   the same as SOURCE)
%                 TRANSFORMATION (string, default identity)  name of a xfm transformation file
%                   to apply on SOURCE.
%
% FILES_OUT     (string,default <BASE_SOURCE>_res) the name of the output resampled volume.
%
% OPT           (structure, optional) has the following fields:
%
%       INTERPOLATION (string, default 'trilinear') the spatial
%          interpolation method. Available options : 'trilinear', 'tricubic',
%          'nearest_neighbour','sinc'.
%
%       FLAG_TFM_SPACE (boolean, default 0) if FLAG_TFM_SPACE is 0, the
%            transformation is applied and the volume is resampled in the 
%            target space. If FLAG_TFM_SPACE is 1, the volume is resampled 
%           in such a way that there is no rotations anymore between voxel 
%           and world space. The field of view is adapted to fit the brain
%           in the source space. In this case, the target space is only
%           used to set the resolution, unless this parameter was
%           additionally specified using OPT.VOXEL_SIZE, in which case the
%           target space could be anything.
%
%       FLAG_INVERT_TRANSF (boolean, default 0) if FLAG_INVERT_TRANSF is 1,
%           the specified transformation is inverted before being applied.
%
%       VOXEL_SIZE (vector 1*3, default same as target space) If
%            voxel_size is set to 0, the resolution for resampling
%            will be the same as the target space. If voxel_size is set to -1, 
%            the resolution will be the same as source space. Otherwise, 
%            the specified resolution will be used. Note that a change in
%            resolution will force the new space to have identity direction
%            cosines.
%
%       FOLDER_OUT (string, default: path of FILES_IN) If present,
%            all default outputs will be created in the folder FOLDER_OUT.
%            The folder needs to be created beforehand.
%
%       FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the
%            brick does not do anything but update the default
%            values in FILES_IN and FILES_OUT.
%
%       FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%            the function prints some infos during the processing.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up inputs
gb_name_structure = 'files_in';
gb_list_fields = {'source','target','transformation'};
gb_list_defaults = {NaN,NaN,''};
niak_set_defaults

% Setting up options
gb_name_structure = 'opt';
gb_list_fields = {'interpolation','flag_tfm_space','voxel_size','folder_out','flag_test','flag_invert_transf','flag_verbose'};
gb_list_defaults = {'trilinear',0,0,'',0,0,1};
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading the source space information %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n Reading source volume information %s ...\n',files_in.source);
end

hdr_source = niak_read_vol(files_in.source);
[dircos1,step1,start1] = niak_hdr_mat2minc(hdr_source.info.mat);

if min(voxel_size == -1) == 1
    voxel_size = abs(step1(:))'; % By default, the voxel size is the voxel size of target space
end

nx1 = hdr_source.info.dimensions(1);
ny1 = hdr_source.info.dimensions(2);
nz1 = hdr_source.info.dimensions(3);

if length(hdr_source.info.dimensions)>3
    nt1 = hdr_source.info.dimensions(4);
else
    nt1 = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading the target space information %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n Reading target volume information %s ...\n',files_in.target);
end

hdr_target = niak_read_vol(files_in.target);
[dircos2,step2,start2] = niak_hdr_mat2minc(hdr_target.info.mat);

if min(voxel_size == 0) == 1
    voxel_size = abs(step2(:))'; % By default, the voxel size is the voxel size of target space
end

nx2 = hdr_target.info.dimensions(1);
ny2 = hdr_target.info.dimensions(2);
nz2 = hdr_target.info.dimensions(3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample the target if necessary %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_tfm_space 
    
    if flag_verbose
        fprintf('\n Resampling target space to get rid of "voxel-to-world" transformation (except voxel size)...\n');
    end
    
    %% Extract the brain in native space 
    
    [hdr_source,vol_source] = niak_read_vol(files_in.source);
    mask_source = niak_mask_brain(mean(abs(vol_source),4));
    clear vol_source
    
    %% Convert the brain voxel coordinates in source space into world
    %% coordinates

    ind_source = find(mask_source);
    [xsource,ysource,zsource] = ind2sub(size(mask_source),ind_source);
    vox_source = [xsource'-1 ; ysource'-1 ; zsource'-1 ; ones([1 length(xsource)])];
    clear ind_source xsource ysource zsource
    if ~isempty(files_in.transformation)
        transf = niak_read_transf(files_in.transformation);        
        if opt.flag_invert_transf
            transf = transf^(-1);
        end
        coord_world = ceil(transf*hdr_source.info.mat*vox_source);            
    else
        coord_world = ceil(hdr_source.info.mat*vox_source);
    end
    min_coord = min(coord_world(1:3,:),[],2)-3*voxel_size(:);
    max_coord = max(coord_world(1:3,:),[],2)+3*voxel_size(:);
    
    %% Setting up the new number of voxels
    nx3 = ceil((max_coord(1)-min_coord(1))/voxel_size(1));
    ny3 = ceil((max_coord(2)-min_coord(2))/voxel_size(2));
    nz3 = ceil((max_coord(3)-min_coord(3))/voxel_size(3));
    
    %% Setting up new voxel to world coordinates
    start3 = min_coord;
    voxel_size = abs(voxel_size);
    dircos = [1 0 0 0 1 0 0 0 1];
    
    file_target_tmp = niak_file_tmp('_target.mnc');
    instr_target = cat(2,'mincresample ',files_in.target,' ',file_target_tmp,' -clobber -dircos ',num2str(dircos(:)'),' -step ',num2str(voxel_size),' -start ',num2str(start3'),' -trilinear -nelements ',num2str(nx3),' ',num2str(ny3),' ',num2str(nz3));
    [tmp,str_tmp] = system(instr_target);

    %% Update the target space information
    hdr_target = niak_read_vol(file_target_tmp);        
    nx2 = hdr_target.info.dimensions(1);
    ny2 = hdr_target.info.dimensions(2);
    nz2 = hdr_target.info.dimensions(3);

else
    file_target_tmp = files_in.target;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample the source on the target %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nt1 == 1

    if flag_verbose
        fprintf('\n Resampling source on target ...\n');
    end

    %% Case of a single 3D volume
    if ~isempty(files_in.transformation)
        if flag_invert_transf
            instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -transform ',files_in.transformation,' -invert_transformation -',interpolation,' -like ',file_target_tmp,' -clobber');
        else
            instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -transform ',files_in.transformation,' -',interpolation,' -like ',file_target_tmp,' -clobber');
        end
    else
        if flag_invert_transf
            instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -',interpolation,' -invert_transformation -like ',file_target_tmp,' -clobber');
        else
            instr_resample = cat(2,'mincresample ',files_in.source,' ',files_out,' -',interpolation,' -like ',file_target_tmp,' -clobber');
        end
    end
    [flag_tmp,str_tmp] = system(instr_resample);
    
    if flag_tmp~=0
        error(str_tmp);
    end

else
    
    if flag_verbose
        fprintf('\n Resampling source on target, volume : ');
    end
    
    %% Case of 3D + t data
        
    file_func_tmp = niak_file_tmp('func.mnc'); % temporary file for input
    file_func_tmp2 = niak_file_tmp('func2.mnc'); % temporary file for output
    [hdr_source,vol_source] = niak_read_vol(files_in.source); % read the source
    vol_resampled = zeros([nx2,ny2,nz2,nt1]); % initialize a resampled space
    hdr_source.file_name = file_func_tmp;
    
    for num_t = 1:nt1
        
        if flag_verbose
            fprintf('%i ',num_t)
        end

        niak_write_vol(hdr_source,vol_source(:,:,:,num_t)); % write one temporary volume
        
        %% Resample
        if ~isempty(files_in.transformation)
            if flag_invert_transf
                instr_resample = cat(2,'mincresample ',file_func_tmp,' ',file_func_tmp2,' -transform ',files_in.transformation,' -invert_transformation -',interpolation,' -like ',file_target_tmp,' -clobber');
            else
                instr_resample = cat(2,'mincresample ',file_func_tmp,' ',file_func_tmp2,' -transform ',files_in.transformation,' -',interpolation,' -like ',file_target_tmp,' -clobber');
            end
        else
            if flag_invert_transf
                instr_resample = cat(2,'mincresample ',file_func_tmp,' ',file_func_tmp2,' -invert_transformation -',interpolation,' -like ',file_target_tmp,' -clobber');
            else
                instr_resample = cat(2,'mincresample ',file_func_tmp,' ',file_func_tmp2,' -',interpolation,' -like ',file_target_tmp,' -clobber');
            end
        end
        [flag_tmp,str_tmp] = system(instr_resample);
        
        if flag_tmp~=0
            error(str_tmp);
        end
        
        [hdr_target,vol_tmp] = niak_read_vol(file_func_tmp2);
        vol_resampled(:,:,:,num_t) = vol_tmp;
        
    end

    
        
    %% write the resampled volumes in a 3D+t dataset
    if flag_verbose
        fprintf('Writing the 3D+t output\n')
    end
    
    hdr_target.file_name = files_out;
    hdr_target.info.tr = hdr_source.info.tr;
    hdr_target.details.time = hdr_source.details.time;
    niak_write_vol(hdr_target,vol_resampled);    
    
    %% clean the temporary files
    if flag_verbose
        fprintf('Cleaning temporary files\n')
    end
    
    delete(file_func_tmp);
    delete(file_func_tmp2);
end

%% Clean temporary stuff
if ~(strcmp(file_target_tmp,files_in.target))
    if flag_verbose
        fprintf('Cleaning temporary files\n')
    end
    delete(file_target_tmp)
end

if flag_verbose
    fprintf('Done!\n')
end
