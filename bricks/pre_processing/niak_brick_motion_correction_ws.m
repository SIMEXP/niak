function [files_in,files_out,opt] = niak_brick_motion_correction_ws(files_in,files_out,opt)

% Perfom within-session and within-subject motion correction of fMRI data
% via estimation of a rigid-body transform and spatial resampling.
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%   FILES_IN
%
%       RUNS (cell of strings, where each string is the file name of a
%           3D+t dataset)
%           All files should be fMRI data of ONE subject acquired in a
%           single session (small movements).
%
%   FILES_OUT  (structure) with the following fields. Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted'.
%
%       MOTION_CORRECTED_DATA (structure of cell of strings, default base
%           name <BASE_FILES_IN>_MC)
%           File names for saving the motion corrected datasets.
%           The images will be resampled at the resolution of the
%           between-run functional image of reference.
%
%       MEAN_VOLUME (string) the mean volume of all coregistered runs.
%
%       MASK_VOLUME (string) A mask of the brain common to all runs (after 
%           motion correction).
%
%     If a field MOTION_PARAMETERS is specified in FILES_IN, the
%     following fields will be ignored  and no transformation will actually be
%     estimated (the one specified by the user is used).
%
%       MOTION_PARAMETERS (structure of cells of strings,
%           default base MOTION_PARAMS_<BASE_FILE_IN>.LOG)
%           MOTION_PARAMETERS.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%   OPT   (structure) with the following fields:
%
%       RUN_REF (vector, default 1) RUN_REF(NUM) is
%           the number of the run that will be used as target.
%
%       FWHM (real number, default 3 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       INTERPOLATION (string, default 'trilinear') the spatial
%          interpolation method. Available options : 'trilinear', 'tricubic',
%          'nearest_neighbour', 'sinc'.
%
%       FLAG_ZIP   (boolean, default: 0) if FLAG_ZIP equals 1, an
%           attempt will be made to zip the outputs.
%
%       FOLDER_OUT (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN and FILES_OUT.
%
%       FLAG_VERBOSE (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
% OUTPUTS:
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% SEE ALSO:
%  NIAK_BRICK_MOTION_CORRECTION, NIAK_DEMO_MOTION_CORRECTION
%
% COMMENTS
% All images of all datasets are coregistered with one volume of reference.
%
% The function is based on MINCTRAC
%
% This function is an adaptation of a PERL script written by Richard D. Hoge,
% McConnell Brain Imaging Centre, Montreal Neurological Institute, McGill
% University, 1996.
% It also includes modifications of the original script made by Leili
% Torab, McConnell Brain Imaging Centre, Montreal Neurological Institute, McGill
% University, 2004.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, filtering, fMRI

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

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_time_filter'' for more info.')
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'motion_corrected_data','motion_parameters_dat','motion_parameters_xfm'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'run_ref','flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm'};
gb_list_defaults = {1,0,0,'','trilinear',1,3};
niak_set_defaults

%% Building default output names
flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp_dat = isempty(files_out.motion_parameters_dat);
flag_def_mp_xfm = isempty(files_out.motion_parameters_xfm);

files_name = files_in.runs;
nb_files = length(files_name);

motion_corrected_data = cell([nb_files 1]);
motion_parameters_dat = cell([nb_files 1]);
motion_parameters_xfm = cell([nb_files 1]);

for num_d = 1:length(files_name)

    [path_f,name_f,ext_f] = fileparts(files_name{num_d});

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

    if flag_def_data
        motion_corrected_data{num_d} = cat(2,folder_write,filesep,name_f,'_mc',ext_f);
    end

    if flag_def_mp_dat
        motion_parameters_dat{num_d} = cat(2,folder_write,filesep,'motion_params_',name_f,'.dat');
    end

    if flag_def_mp_xfm
        hdr = niak_read_vol(files_name{num_d});

        if length(hdr.info.dimensions)<4
            nt = 1;
        else
            nt = hdr.info.dimensions(4);
        end

        nb_digits = max(length(num2str(nt)),4);

        for num_t = 1:nt

            strt = num2str(num_t);
            strt = [repmat('0',1,nb_digits-length(strt)) strt];

            if num_t == 1
                motion_parameters_xfm{num_d} = cat(2,folder_write,filesep,'motion_params_',name_f,'_',strt,'.xfm');
            else
                motion_parameters_xfm{num_d} = char(motion_parameters_xfm{num_d},cat(2,folder_write,filesep,'motion_params_',name_f,'_',strt,'.xfm'));
            end

        end
    end % if flag_def_mp_xfm

end %loop over datasets

if flag_def_data
    files_out.motion_corrected_data = motion_corrected_data;
end

if flag_def_mp_dat
    files_out.motion_parameters_dat = motion_parameters_dat;
end

if flag_def_mp_xfm
    files_out.motion_parameters_xfm = motion_parameters_xfm;
end

if flag_test == 1
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Splitting up the 3D+t data into independent smoothed volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nb_run = length(files_in.runs);
nb_vol = zeros([nb_run 1]);
hdr = niak_read_vol(files_in.runs{1});
list_run = 1:nb_files;
list_run = [run_ref list_run(list_run~=run_ref)];
opt_s.fwhm = fwhm;

for num_r = list_run        

    file_name = files_in.runs{list_run(num_r)};  

    if flag_verbose
        fprintf('\n********\nrun %s\n********\n',file_name);
    end
    
    [hdr,data] = niak_read_vol(file_name);
    hdr.flag_zip = 0;
    
    %% Generating brain mask
    vol_abs = mean(abs(data),4);
    mask = niak_mask_brain(vol_abs);
    
    %% resampling the mask at isotropic 1.17 resolution
    opt_r.voxel_size = 1.17*ones([1 3]);
    opt_r.interpolation = 'nearest';
    [mask_r,hdr_r] = niak_resample_vol(mask,hdr,opt_r);
    
    %% Writting the mask of the target
    file_mask_source = niak_file_tmp('_mask_source.mnc');
    hdr_r.file_name = file_mask_source;
    niak_write_vol(hdr_r,mask_r);

    if num_r == 1
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Generating the target %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% This is the run of reference... time to generate the target !        
        
        if flag_verbose
            fprintf('Generating the target...\n');
        end        

        vol_target = median(data,4); % Extracting median volume
        
        %% Smoothing
        opt_s.step = hdr.info.voxel_size;
        vol_target = niak_smooth_vol(vol_target,opt_s);
        
        %% Extracting gradient image
        opt_grad.mask = mask;
        vol_target = niak_gradient_vol(vol_target,opt_grad);
        
        %% resampling the target at isotropic 1.17 resolution
        opt_r.voxel_size = 1.17*ones([1 3]);        
        opt_r.interpolation = 'linear';
        [vol_target,hdr_r] = niak_resample_vol(vol_target,hdr,opt_r);                

        %% writting the target
        file_target = niak_file_tmp('_target.mnc');
        hdr_r.file_name = file_target;                
        niak_write_vol(hdr_r,vol_target);
        
        %% Writting the mask of the target
        file_mask_target = niak_file_tmp('_mask_target.mnc');
        hdr_r.file_name = file_mask_target;
        niak_write_vol(hdr_r,mask_r);
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Looping over every volume to perform motion parameters estimation %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    if flag_verbose
        fprintf('Performing motion correction estimation on volume :');
    end

    if length(hdr.info.dimensions)==4
        nb_vol(num_r) = hdr.info.dimensions(4);
    else
        nb_vol(num_r) = 1;
    end

    opt_s.step = hdr.info.voxel_size;   
    
    for num_v = 1:nb_vol(num_r)

        if flag_verbose
            fprintf('%i ',num_v);
        end

        %% Generating file names 
        file_vol = niak_file_tmp(cat(2,'_func',num2str(num_v),'_run',num2str(num_r),'.mnc'));        
        xfm_tmp = niak_file_tmp(cat(2,'_func',num2str(num_v),'_run',num2str(num_r),'.xfm'));        
        
        if num_v == 1
                    
            motion_parameters_tmp{num_r} = xfm_tmp;
            
        else

            motion_parameters_tmp{num_r} = char(motion_parameters_tmp{num_r},xfm_tmp);
            
        end
        
        hdr.file_name = file_vol;
        
        %% Smoothing        
        vol_source = niak_smooth_vol(data(:,:,:,num_v),opt_s);
        
        %% Extracting gradient image
        opt_grad.mask = mask;
        vol_source = niak_gradient_vol(vol_source,opt_grad);
        
        %% resampling the source volume at isotropic 1.17 resolution
        opt_r.voxel_size = 1.17*ones([1 3]);        
        opt_r.interpolation = 'linear';
        [vol_source,hdr_r] = niak_resample_vol(vol_source,hdr,opt_r);
                
        %% writting the source        
        hdr_r.file_name = file_vol;                
        niak_write_vol(hdr_r,vol_source);
        
        if num_v == 1
            [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',motion_parameters_tmp{num_r},' -mi -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -clobber -debug -lsq6'));
        else
            [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',motion_parameters_tmp{num_r},' -mi -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -transformation ',deblank(motion_parameters_tmp{num_r}(num_v,:)),' -clobber -debug -lsq6'));
        end                
        
       
        
    end

    fprintf('\n')

end
