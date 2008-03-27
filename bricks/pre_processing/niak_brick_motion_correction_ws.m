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
%     names to 'gb_niak_omitted').
%
%       MOTION_CORRECTED_DATA (cell of strings, default base
%           name <BASE_FILES_IN>_MC)
%           File names for saving the motion corrected datasets.
%           The images will be resampled at the resolution of the
%           functional run of reference.
%
%       MOTION_PARAMETERS (cells of string,
%           default base MOTION_PARAMS_<BASE_FILE_IN>.LOG)
%           MOTION_PARAMETERS.{NUM_R} is the file name for
%           the estimated motion parameters of the functional run NUM_R.
%           The first line describes the content of each column.
%           Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       MEAN_VOLUME (string, default base MEAN_<BASE_FILE_IN>) the mean volume
%           of all coregistered runs.
%
%       MASK_VOLUME (string, default base MASK_<BASE_FILE_IN>) A mask of
%           the brain common to all runs (after motion correction).
%
%       FIG_MOTION  (string, default base FIG_MOTION_<BASE_FILE_IN>.JPG) A figure
%          representing the motion parameters.
%
%   OPT   (structure) with the following fields:
%
%       VOL_REF (vector, default 1) VOL_REF is the number of the volume
%           that will be used as reference. If VOL_REF is a string, the
%           median volume of the run of reference will be used rather than
%           an arbitrary volume.
%
%       RUN_REF (vector, default 1) RUN_REF is
%           the number of the run that will be used as target.
%
%       FWHM (real number, default 8 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       INTERPOLATION (string, default 'linear') the spatial
%          interpolation method. Available options : 'linear', 'cubic',
%          'spline'.
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
% All images of all datasets are coregistered with one volume of the
% run of reference. The motion parameters are actually estimated on the
% basis of smoothed oversampled gradient volumes.
%
% The core of the function is a MINC tool called MINCTRACC which performs
% rigid-body coregistration.
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
gb_list_fields = {'motion_corrected_data','motion_parameters','mean_volume','mask_volume','fig_motion'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'vol_ref','run_ref','flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm'};
gb_list_defaults = {1,1,0,0,'','linear',1,8};
niak_set_defaults

%% Building default output names
flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp= isempty(files_out.motion_parameters);
flag_def_fm = isempty(files_out.fig_motion);

files_name = files_in.runs;
nb_files = length(files_name);

motion_corrected_data = cell([nb_files 1]);
motion_parameters = cell([nb_files 1]);

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

    if flag_def_mp
        motion_parameters{num_d} = cat(2,folder_write,filesep,'motion_params_',name_f,'.log');
    end
    
    if flag_def_fm
        files_out.fig_motion{num_d} = cat(2,folder_write,filesep,'fig_motion_',name_f,'.jpg');
    end

end %loop over datasets

if flag_def_data
    files_out.motion_corrected_data = motion_corrected_data;
end

if flag_def_mp
    files_out.motion_parameters = motion_parameters;
end

if isempty(files_out.mask_volume)
    files_out.mask_volume = cat(2,folder_write,filesep,'mask_',name_f,ext_f);
end

if isempty(files_out.mean_volume)
    files_out.mean_volume = cat(2,folder_write,filesep,'mean_',name_f,ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimation of motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

    %% Writting the mask of the target
    file_mask_source = niak_file_tmp('_mask_source.mnc');
    hdr.file_name = file_mask_source;
    niak_write_vol(hdr,mask);

    if num_r == 1

        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Generating the target %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% This is the run of reference... time to generate the target !

        if flag_verbose
            fprintf('Generating the target...\n');
        end

        hdr_ref = hdr;

        if ischar(vol_ref)
            vol_target = median(data,4);
        else
            vol_target = data(:,:,:,vol_ref); % Extracting median volume
        end
        
        %% Smoothing
        opt_s.step = hdr.info.voxel_size;
        vol_target = niak_smooth_vol(vol_target,opt_s);        
        
        %% writting the target
        file_target = niak_file_tmp('_target.mnc');
        hdr.file_name = file_target;
        niak_write_vol(hdr,vol_target);

        %% Writting the mask of the target
        file_mask_target = niak_file_tmp('_mask_target.mnc');
        hdr.file_name = file_mask_target;
        niak_write_vol(hdr,mask);

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

    tab_parameters = zeros([nb_vol(num_r) 8]);

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')
        hf_mp = fopen(files_out.motion_parameters{num_r},'w');
        fprintf(hf_mp,'pitch roll yaw tx ty tz XCORR_init XCORR_final\n');
    end

    for num_v = 1:nb_vol(num_r)    
    %for num_v = [1 11 12];    
        
        if flag_verbose
            fprintf('%i ',num_v);
        end

        %% Generating file names
        file_vol = niak_file_tmp(cat(2,'_func',num2str(num_v),'_run',num2str(num_r),'.mnc'));
        xfm_tmp = niak_file_tmp(cat(2,'_func',num2str(num_v),'_run',num2str(num_r),'.xfm'));
        hdr.file_name = file_vol;
        
        %% Smoothing        
        vol_source = niak_smooth_vol(data(:,:,:,num_v),opt_s);

        %% writting the source
        hdr.file_name = file_vol;
        niak_write_vol(hdr,vol_source);

        if max(num_v == vol_ref)

            transf = eye(4);
            [flag,str_log] = system(cat(2,'param2xfm ',xfm_tmp,' -translation 0 0 0 -rotations 0 0 0'));

        else

            if num_v == 1               
                [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -clobber -debug -lsq6 -identity -speckle 0 -tol 1.2 -est_center -tol 0.05 -tricubic -simplex 3 -source_lattice -step 6 6 6'));
            else                                
                [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr  -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -transformation ',xfm_tmp_old,' -clobber -debug -lsq6 -identity -speckle 0 -est_center -tol 0.05 -tricubic -simplex 3 -source_lattice -step 6 6 6'));
            end

            %% Converting the xfm transformation into a roll/pitch/yaw and
            %% translation format
            hf = fopen(xfm_tmp);
            xfm_info = fread(hf,Inf,'uint8=>char')';
            cell_info = niak_string2lines(xfm_info);
            transf = eye(4);
            transf(1,:) = str2num(cell_info{end-2});
            transf(2,:) = str2num(cell_info{end-1});
            transf(3,:) = str2num(cell_info{end}(1:end-1));
            fclose(hf);

            %% Keeping record of the objective function values before and after
            %% optimization
            cell_log = niak_string2lines(str_log);
            line_log = niak_string2words(cell_log{end-1});
            tab_parameters(num_v,7) = str2num(line_log{end});
            line_log = niak_string2words(cell_log{end});
            tab_parameters(num_v,8) = str2num(line_log{end});
            
        end

        [pry,tsl] = niak_transf2param(transf);

        tab_parameters(num_v,1:3) = pry';
        tab_parameters(num_v,4:6) = tsl';

        
        % Cleaning temporary files
        if num_v > 1
            delete(xfm_tmp_old);
        end

        delete(file_vol);
        xfm_tmp_old = xfm_tmp;

        %% If resampling data has been requested (or deriving the resampled
        %% mean or mask), perform linear interpolation
        if ~strcmp(files_out.motion_corrected_data,'gb_niak_omitted')|~strcmp(files_out.mask_volume,'gb_niak_omitted')|~strcmp(files_out.mean_volume,'gb_niak_omitted')
            hdr_r2 = hdr;
            opt_r2.voxel_size = hdr_ref.info.voxel_size; % The resampling is done at the same resolution as the run of reference
            opt_r2.interpolation = interpolation;
            opt_r2.mat = transf; % The transformation estimated by MINCTRACC is applied
            data(:,:,:,num_v) = niak_resample_vol(data(:,:,:,num_v),hdr_r2,opt_r2); % The resampling per say
        end

        %% If requested, write the motion parameters in a log file
        if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')            
            fprintf(hf_mp,'%s\n',num2str(tab_parameters(num_v,:),12));
        end

    end
    delete(xfm_tmp); % Delete the last temporary file...
    fprintf('\n')
    hdr.flag_zip = flag_zip;

    %% If requested, write out the resampled data
    if flag_verbose
        fprintf('Resampling functional data...\n');
    end

    if ~strcmp(files_out.motion_corrected_data,'gb_niak_omitted')
        hdr_ref.file_name = files_out.motion_corrected_data{num_r};
        niak_write_vol(hdr_ref,data);
    end

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')
        fclose(hf_mp);
    end

    %% If requested, write the figure of motion parameters
    if ~strcmp(files_out.fig_motion,'gb_niak_omitted')
        if exist('saveas') % octave do not have the saveas command, it won't be possible to generate the pretty graphic...
            hfig = figure;
            subplot(2,1,1);
            plot(tab_parameters(:,4:6));
            title(sprintf('Estimated translation parameters, file %s',file_name));
            legend('x','y','z');
            subplot(2,1,2);
            plot(tab_parameters(:,[2 1 3]));
            title(sprintf('Estimated rotation parameters, file %s',file_name));
            legend('pitch','roll','yaw');
            saveas(hfig,files_out.fig_motion{num_r},'jpg')
            close(hfig)
        end
    end
        
    %% If requested, keep track of the functional mean
    if ~strcmp(files_out.mean_volume,'gb_niak_omitted')
        mean_vol{num_r} = mean(data,4);
    end

    %% If requested, keep track of the functional mask
    if ~strcmp(files_out.mask_volume,'gb_niak_omitted')
        mask_vol{num_r} = mask;
    end

    % Cleaning temporary files
    delete(file_mask_source);

end

%% If requested, write the mean volume
if ~strcmp(files_out.mean_volume,'gb_niak_omitted')

    mean_vol_all = zeros(size(mean_vol{1}));

    for num_r = 1:nb_run
        mean_vol_all = mean_vol_all + mean_vol{num_r};
    end

    mean_vol_all = mean_vol_all/nb_run;
    hdr_ref.file_name = files_out.mean_volume;
    niak_write_vol(hdr_ref,mean_vol_all);

end

%% If requested, write the mask volume
if ~strcmp(files_out.mask_volume,'gb_niak_omitted')

    mask_vol_all = mask_vol{num_r};

    for num_r = 1:nb_run
        mask_vol_all = mask_vol_all & mask_vol{num_r};
    end

    hdr_ref.file_name = files_out.mask_volume;
    niak_write_vol(hdr_ref,mask_vol_all);

end

% Cleaning temporary files
delete(file_mask_target);
delete(file_target);