function [files_in,files_out,opt] = niak_brick_resample_vol(files_in,files_out,opt)
% Resample a volume or a 4D volume with a transformation to a target space. 
% The function allows to change the target resolution, and to resample the 
% data such that the direction cosines are exactly x, y and z.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_RESAMPLE_VOL(FILES_IN,FILES_OUT,OPT)
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
% NOTE 1:
% This is a simple wrapper of MINCRESAMPLE, but it has a couple of
% additional features (i.e. the possibility to change the resolution or to
% get rid of the direction cosines). More importantly it works for 4D
% images, i.e. fMRI datasets, while MINCRESAMPLE works only on 3D volumes.
%
% NOTE 2:
% The TRANSF variables are standard 4*4 matrix array representation of 
% an affine transformation [M T ; 0 0 0 1] for (y=M*x+T) 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, minc, resampling

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

flag_gb_niak_fast_gb = true;
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up inputs
gb_name_structure = 'files_in';
gb_list_fields    = {'source', 'target' , 'transformation' };
gb_list_defaults  = {NaN     , NaN      , ''               };
niak_set_defaults

% Setting up options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_skip' , 'suppress_vol' ,'transf_name' ,'interpolation' ,'flag_tfm_space' ,'voxel_size' ,'folder_out' ,'flag_test' ,'flag_invert_transf' ,'flag_verbose' ,'flag_adjust_fov' ,'flag_keep_range'};
gb_list_defaults  = {0           , 0              ,'transf'      ,'tricubic'      ,0                ,0            ,''           ,0           ,0                    ,1              ,0                 ,0};
niak_set_defaults

if (length(voxel_size)==1)&&(voxel_size~=0)&&(voxel_size~=1)
    voxel_size = repmat(voxel_size,[1 3]);
end

if flag_keep_range
    instr_range = '-keep_real_range ';
else
    instr_range = '-nokeep_real_range ';
end
    
%% Generating default ouputs
[path_f,name_f,ext_f] = niak_fileparts(files_in.source);

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

if flag_skip
    instr_copy = cat(2,'cp ',files_in.source,' ',files_out);
    
    [status,msg] = system(instr_copy);
    if status~=0
        error(msg)
    end
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert the transformation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

folder_tmp = niak_path_tmp('_res');

if ~isempty(files_in.transformation)
    [path_t,name_t,ext_t] = niak_fileparts(files_in.transformation);
    
    if strcmp(ext_t,'.mat')
        if flag_verbose
            fprintf('\n Converting transformation %s into XFM format ...\n',files_in.transformation);
        end
        
        data = load(files_in.transformation);
        transf = data.(transf_name);
        nb_transf = size(transf,3);
        file_transf = cell([nb_transf 1]);
        for num_t = 1:nb_transf
            file_transf{num_t} = [folder_tmp 'tranf_num' num2str(num_t) '.xfm'];
            niak_write_transf(transf(:,:,num_t),file_transf{num_t});
        end
        files_in.transformation = file_transf;
    end
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
    voxel_size = abs(step1(:))'; % use the same voxel size as the source space
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

if isempty(voxel_size)
    voxel_size = 0;
end

if min(voxel_size == 0) == 1
    voxel_size = abs(step2(:))'; % By default, the voxel size is the voxel size of target space
end

nx2 = hdr_target.info.dimensions(1);
ny2 = hdr_target.info.dimensions(2);
nz2 = hdr_target.info.dimensions(3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample the target if necessary %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if min(voxel_size(:)==abs(step2(:)))==0
    
    if ~flag_tfm_space % If a change of resolution occurs, but there is no resample-to-self
         
        %% Setting up the new number of voxels
        nx3 = ceil((abs(step2(1))/voxel_size(1))*nx2);
        ny3 = ceil((abs(step2(2))/voxel_size(2))*ny2);
        nz3 = ceil((abs(step2(3))/voxel_size(3))*nz2);
        
        %% Creating new header
        hdr_target2 = hdr_target;
        hdr_target2.info.mat = niak_hdr_minc2mat(dircos2,(sign(step2(:)).*voxel_size(:))',start2);
        hdr_target2.info.dimensions = [nx3,ny3,nz3];        

        %% Creating a new target
        file_target_tmp = [folder_tmp 'target.mnc'];
        hdr_target2.file_name = file_target_tmp;
        niak_write_vol(hdr_target2,zeros([nx3,ny3,nz3]));

        %% Update the target space information
        hdr_target = niak_read_vol(file_target_tmp);
        nx2 = hdr_target.info.dimensions(1);
        ny2 = hdr_target.info.dimensions(2);
        nz2 = hdr_target.info.dimensions(3);

    end
end

if flag_tfm_space 
    
    if flag_verbose
        fprintf('\n Resampling target space to get rid of "voxel-to-world" transformation (except voxel size)...\n');
    end
    
    %% Extract the brain in native space 
    
    [hdr_source,vol_source] = niak_read_vol(files_in.source);
    if flag_adjust_fov
        mask_source = niak_mask_brain(mean(abs(vol_source),4));
    else
        mask_source = true(size(vol_source));
    end
        
    clear vol_source
    
    %% Convert the brain voxel coordinates in source space into world
    %% coordinates

    ind_source = find(mask_source);
    [xsource,ysource,zsource] = ind2sub(size(mask_source),ind_source);
    vox_source = [xsource'-1 ; ysource'-1 ; zsource'-1 ; ones([1 length(xsource)])];
    clear ind_source xsource ysource zsource
    if ~isempty(files_in.transformation)
        if ischar(files_in.transformation)
            transf = niak_read_transf(files_in.transformation);        
        else
            transf = niak_read_transf(files_in.transformation{1});        
        end
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
    
    file_target_tmp = [folder_tmp 'target.mnc'];   
    instr_target = cat(2,'mincresample ',files_in.target,' ',file_target_tmp,' -clobber -dircos ',num2str(dircos(:)'),' -step ',num2str(voxel_size),' -start ',num2str(start3'),' -trilinear -nelements ',num2str(nx3),' ',num2str(ny3),' ',num2str(nz3));
    [tmp,str_tmp] = system(instr_target);

    %% Update the target space information
    hdr_target = niak_read_vol(file_target_tmp);        
    nx2 = hdr_target.info.dimensions(1);
    ny2 = hdr_target.info.dimensions(2);
    nz2 = hdr_target.info.dimensions(3);

else
    if ~exist('file_target_tmp','var')
        file_target_tmp = files_in.target;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample the source on the target %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nt1 == 1

    %% Case of a single 3D volume    
    if flag_verbose
        fprintf('\n Resampling source on target ...\n');
    end

    [path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(files_out);        
    files_out = [path_f,filesep,name_f,ext_short];
        
    instr_resample = ['mincresample ',instr_range,files_in.source,' ',files_out];    
    if ~isempty(files_in.transformation)
        if ischar(files_in.transformation)
            instr_resample = [instr_resample ' -transform ',files_in.transformation];
        else
            instr_resample = [instr_resample ' -transform ',files_in.transformation{1}];
        end
    end
    if flag_invert_transf
        instr_resample = [instr_resample ' -invert_transformation'];
    end
    instr_resample = [instr_resample ' -',interpolation,' -like ',file_target_tmp,' -clobber'];        
    [status,msg] = system(instr_resample);    
    if status~=0
        error(msg);
    end
    
    if flag_zip
        system([gb_niak_zip ' ' files_out]);
    end

else
    
    %% Case of 3D + t data
    if flag_verbose
        fprintf('\n Resampling source on target, volume : ');
    end        
        
    file_func_tmp = [folder_tmp 'func.mnc']; % temporary file for input
    file_func_tmp2 = [folder_tmp 'func2.mnc']; % temporary file for output
    [hdr_source,vol_source] = niak_read_vol(files_in.source); % read the source
    vol_resampled = zeros([nx2,ny2,nz2,nt1-suppress_vol]); % initialize a resampled space
    hdr_source.file_name = file_func_tmp;
    
    for num_t = min(suppress_vol+1,nt1):nt1
        
        if flag_verbose
            fprintf('%i ',num_t)
        end

        niak_write_vol(hdr_source,vol_source(:,:,:,num_t)); % write one temporary volume
        
        %% Resample
        instr_resample = ['mincresample ',instr_range,file_func_tmp,' ',file_func_tmp2];
        if ~isempty(files_in.transformation)
            if ischar(files_in.transformation)
                instr_resample = [instr_resample ' -transform ',files_in.transformation];
            else
                instr_resample = [instr_resample ' -transform ',files_in.transformation{num_t}];
            end
        end
        if flag_invert_transf
            instr_resample = [instr_resample ' -invert_transformation'];
        end
        instr_resample = [instr_resample ' -',interpolation,' -like ',file_target_tmp,' -clobber'];
        [status,msg] = system(instr_resample);
        if status~=0
            error(msg);
        end
        
        [hdr_target,vol_tmp] = niak_read_vol(file_func_tmp2);
        vol_resampled(:,:,:,num_t-suppress_vol) = vol_tmp;
        
    end
    clear vol_source
    
        
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
    
end

%% Clean temporary stuff
if flag_verbose
    fprintf('Cleaning temporary files\n')
end
instr_clean = sprintf('rm -rf %s',folder_tmp);
[status,msg] = system(instr_clean);
if status ~= 0
    error(msg);
end

if flag_verbose
    fprintf('Done!\n')
end
