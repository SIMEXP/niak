function [files_in,files_out,opt] = niak_brick_motion_correction_ws(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MOTION_CORRECTION_WS
%
% Perfom within-session and within-subject motion correction of fMRI data
% via estimation of a rigid-body transform and spatial resampling.
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN 
%       (cell of strings, where each string is the file name of a 3D+t 
%       dataset) All files should be fMRI data of ONE subject acquired in a
%       single session (small movements).
%
%   FILES_OUT  
%       (structure) with the following fields. Note that if a field is an 
%       empty string, a default value will be used to name the outputs. If 
%       a field is ommited, the output won't be saved at all (this is 
%       equivalent to setting up the output file names to 
%       'gb_niak_omitted').
%
%       MOTION_CORRECTED_DATA 
%           (cell of strings, default base  name <BASE_FILES_IN>_MC.<EXT_FILES_IN>)
%           File names for saving the motion corrected datasets. The images 
%           will be resampled at the resolution of the functional run of 
%           reference.
%
%       MOTION_PARAMETERS 
%           (cells of string, default base MOTION_PARAMS_WS_<BASE_FILE_IN>.DAT)
%           MOTION_PARAMETERS.{NUM_R} is the file name for the estimated 
%           motion parameters of the functional run NUM_R. The first line 
%           describes the content of each column. Each subsequent line I+1 
%           is a representation of the motion parameters estimated for 
%           session I.
%
%       TARGET 
%           (string, default TARGET_<BASE_FILE_IN>.<EXT_FILES_IN>) the 
%           target for coregistration (smoothed volume of reference of the 
%           run of reference).
%
%       MASK 
%           (string, default MASK_<BASE_FILE_IN>.<EXT_FILES_IN>) the mask 
%           used for coregistration.
%
%       FIG_MOTION  
%           (string, default base FIG_MOTION_<BASE_FILE_IN>.PDF) A figure
%           representing the motion parameters. 
%
%   OPT   
%       (structure) with the following fields:
%
%       VOL_REF 
%           (vector, default 'median') VOL_REF is the number of the volume
%           that will be used as reference. If VOL_REF is a string, the
%           median volume of the run of reference will be used rather than
%           an arbitrary volume.
%
%       RUN_REF 
%           (vector, default 1) RUN_REF is
%           the number of the run that will be used as target.
%
%       FWHM 
%           (real number, default 8 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       INTERPOLATION 
%           (string, default 'sinc') the spatial interpolation method. 
%           Available options : 'trilinear', 'tricubic', 
%           'nearest_neighbour','sinc'.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_TFM_SPACE 
%           (boolean, default: 0) if FLAG_TFM_SPACE equals 1, the 
%           functional target space will be resampled to get rid of the
%           voxel-to-world coordinates transformation. This means that a
%           new field of view fitting the brain will have to be derived.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%           indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
%
%  NIAK_BRICK_MOTION_CORRECTION, NIAK_DEMO_MOTION_CORRECTION
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% All images of all datasets are coregistered with one volume of the
% run of reference. The motion parameters are actually estimated on the
% basis of smoothed oversampled gradient volumes.
%
% NOTE 2:
% The core of the function is a MINC tool called MINCTRACC which performs
% rigid-body coregistration.
%
% NOTE 3:
% This function was based on a PERL script written by Richard D. Hoge,
% McConnell Brain Imaging Centre, Montreal Neurological Institute, McGill
% University, 1996.
% A gradient image of each volume is extracted after applying a Gaussian 
% isotropic smoothing. The gradient images are coregistered to the one of 
% a volume of reference using MINCTRACC (xcorr similarity function).
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, motion, fMRI

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

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION_WS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_motion_correction_ws'' for more info.')
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'motion_corrected_data','motion_parameters','fig_motion','target','mask'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'vol_ref','run_ref','flag_zip','flag_test','folder_out','interpolation','flag_verbose','fwhm','flag_tfm_space'};
gb_list_defaults = {1,1,0,0,'','sinc',1,8,0};
niak_set_defaults

%% Building default output names
flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp= isempty(files_out.motion_parameters);
flag_def_fm = isempty(files_out.fig_motion);

files_name = files_in;
nb_files = length(files_name);

motion_corrected_data = cell([nb_files 1]);
motion_parameters = cell([nb_files 1]);

for num_d = 1:length(files_name)

    [path_f,name_f,ext_f] = fileparts(files_name{num_d});

    if isempty(path_f)
        path_f = '.';
    end

    if strcmp(ext_f,gb_niak_zip_ext)
        [tmp,name_f,ext_f] = fileparts(name_f);
        ext_f = cat(2,ext_f,gb_niak_zip_ext);
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
        motion_parameters{num_d} = cat(2,folder_write,filesep,'motion_params_ws_',name_f,'.dat');
    end
    
    if (flag_def_fm)&(num_d==run_ref)
        files_out.fig_motion = cat(2,folder_write,filesep,'fig_motion_',name_f,'.pdf');
    end

end %loop over datasets

if flag_def_data
    files_out.motion_corrected_data = motion_corrected_data;
end

if flag_def_mp
    files_out.motion_parameters = motion_parameters;
end

if isempty(files_out.target)
    files_out.target = cat(2,folder_write,filesep,'target_',name_f,ext_f);
end

if isempty(files_out.mask)
    files_out.target = cat(2,folder_write,filesep,'mask_',name_f,ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimation of motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nb_run = length(files_in);
nb_vol = zeros([nb_run 1]);
hdr = niak_read_vol(files_in{1});
list_run = 1:nb_files;
list_run = [run_ref list_run(list_run~=run_ref)];
opt_s.fwhm = fwhm;
hfig = figure;

for num_r = list_run

    file_name = files_in{list_run(num_r)};

    if flag_verbose
        fprintf('\n********\nrun %s\n********\n',file_name);
    end

    [hdr,data] = niak_read_vol(file_name);
    hdr.flag_zip = 0;

    %% Generating brain mask
    vol_abs = mean(abs(data),4);
    mask = niak_mask_brain(vol_abs);
    mask = niak_dilate_mask(mask);
    mask(:,:,1) = 0;
    %mask = niak_dilate_mask(mask);

    %% Writting the mask of the target
    file_mask_source = niak_file_tmp('_mask_source.mnc');
    hdr.file_name = file_mask_source;
    niak_write_vol(hdr,mask);

    if num_r == run_ref

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
            vol_ref = 0;
        else
            vol_target = data(:,:,:,vol_ref); % Extracting median volume
        end
                
        %% Getting rid of voxel outside the mask
        vol_target(mask==0) = 0;
        
        %% writting the target
        file_target = niak_file_tmp('_target_dxyz.mnc');
        file_target_tmp = niak_file_tmp('_target_tmp.mnc');
        hdr.file_name = file_target_tmp;
        niak_write_vol(hdr,vol_target);
        [succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' -gradient ',file_target_tmp,' ',file_target(1:end-9)));        
        if succ ~= 0
            error(mesg);
        end
        
        delete(cat(2,file_target(1:end-9),'_blur.mnc'));        
        delete(file_target_tmp);
        
        %% Resample the target in its own space
        file_target_native = niak_file_tmp('_target_native.mnc');       
        if exist('files_in_res')
            clear files_in_res
        end
        files_in_res.source = file_target;
        files_in_res.target = file_target;        
        files_out_res = file_target_native;
        opt_res.flag_tfm_space = opt.flag_tfm_space;                 
        niak_brick_resample_vol(files_in_res,files_out_res,opt_res);

        %% Writting the mask of the target
        file_mask_target = niak_file_tmp('_mask_target.mnc');
        hdr.file_name = file_mask_target;
        niak_write_vol(hdr,mask);

        %% Initiliazing the resampled data
        hdr_target = niak_read_vol(file_target_native);
        if ~ischar(files_out.motion_corrected_data)
            data_r = zeros(hdr_target.info.dimensions(1:3));
        end
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

    opt_s.voxel_size = hdr.info.voxel_size;

    tab_parameters = zeros([nb_vol(num_r) 8]);

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')
        hf_mp = fopen(files_out.motion_parameters{num_r},'w');
        fprintf(hf_mp,'pitch roll yaw tx ty tz XCORR_init XCORR_final\n');
    end

    list_vols = 1:nb_vol(num_r);

    %% Generating file names
    file_vol = niak_file_tmp(cat(2,'_func_run',num2str(num_r),'_dxyz.mnc'));
    file_vol_tmp = niak_file_tmp(cat(2,'_func_run',num2str(num_r),'_tmp.mnc'));
    xfm_tmp = niak_file_tmp(cat(2,'_func_run',num2str(num_r),'.xfm'));
    hdr.file_name = file_vol;

    for num_v = list_vols
        
        if flag_verbose
            fprintf('%i ',num_v);
        end
        
        vol_source = data(:,:,:,num_v);

        %% Getting rid of voxels outside the mask        
        vol_source(mask==0) = 0;
        
        %% writting the source                
        hdr.file_name = file_vol_tmp;
        niak_write_vol(hdr,vol_source);

        [succ,mesg] = system(cat(2,'mincblur -clobber -no_apodize -quiet -fwhm ',num2str(opt.fwhm),' -gradient ',file_vol_tmp,' ',file_vol(1:end-9)));
        if succ ~= 0
            error(mesg);
        end
         
        delete(cat(2,file_vol(1:end-9),'_blur.mnc'));             
        delete(file_vol_tmp);        

        if (num_v == vol_ref) & (num_r == run_ref)

            transf = eye(4);
            [flag,str_log] = system(cat(2,'param2xfm ',xfm_tmp,' -translation 0 0 0 -rotations 0 0 0 -clobber'));

        else

            if num_v == list_vols(1)               
                [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -clobber -debug -lsq6 -identity -speckle 0 -est_center -tol 0.0005 -tricubic -simplex 10 -model_lattice -step 7 7 7'));
            else                                
                [flag,str_log] = system(cat(2,'minctracc ',file_vol,' ',file_target,' ',xfm_tmp,' -xcorr  -source_mask ',file_mask_source,' -model_mask ',file_mask_target,' -forward -transformation ',xfm_tmp,' -clobber -debug -lsq6 -speckle 0 -est_center -tol 0.0005 -tricubic -simplex 10 -model_lattice -step 7 7 7'));
            end

            %% Reading the transformation
            transf = niak_read_transf(xfm_tmp);

            %% Keeping record of the objective function values before and after
            %% optimization
            cell_log = niak_string2lines(str_log);
            line_log = niak_string2words(cell_log{end-1});
            tab_parameters(num_v,7) = str2num(line_log{end});
            line_log = niak_string2words(cell_log{end});
            tab_parameters(num_v,8) = str2num(line_log{end});
            
        end

        %% Converting the xfm transformation into a roll/pitch/yaw and
        %% translation format
        [pry,tsl] = niak_transf2param(transf);

        tab_parameters(num_v,1:3) = pry';
        tab_parameters(num_v,4:6) = tsl';                

        %% If resampling data has been requested (or deriving the resampled
        %% mean or mask), perform spatial interpolation
        if ~ischar(files_out.motion_corrected_data)
            
            files_in_res.source = niak_file_tmp('_vol_orig.mnc');
            files_in_res.target = file_target_native;
            files_in_res.transformation = xfm_tmp;
            files_out_res = niak_file_tmp('_vol_r.mnc');
            opt_res.flag_tfm_space = 0;
            opt_res.voxel_size = [];
            opt_res.flag_verbose = 0;
            hdr.file_name = files_in_res.source;            
            niak_write_vol(hdr,data(:,:,:,num_v));            
            niak_brick_resample_vol(files_in_res,files_out_res,opt_res);            
            [hdr_r,vol_r] = niak_read_vol(files_out_res);
            delete(files_out_res);
            delete(files_in_res.source);            
            data_r(:,:,:,num_v) = vol_r;
            
        end

        %% If requested, write the motion parameters in a log file
        if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')            
            fprintf(hf_mp,'%s\n',num2str(tab_parameters(num_v,:),12));
        end
        
        delete(file_vol);       
        
    end
    
    delete(xfm_tmp); % Delete the last temporary file...
    fprintf('\n')
    hdr.flag_zip = flag_zip;

    %% If requested, write out the resampled data    
    if ~strcmp(files_out.motion_corrected_data,'gb_niak_omitted')
        if flag_verbose
            fprintf('Writting the resampled functional data...\n');
        end
        hdr_r.file_name = files_out.motion_corrected_data{num_r};
        niak_write_vol(hdr_r,data_r);
    end

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.motion_parameters,'gb_niak_omitted')
        fclose(hf_mp);
    end

    %% If requested, create a figure of motion parameters
    if ~strcmp(files_out.fig_motion,'gb_niak_omitted')
        
        subplot(max(list_run),2,1+(num_r-1)*2)
        par_t = tab_parameters(:,4:6);
        plot(par_t);
        title(sprintf('translation (mm, bgr/xyz) %s',name_f),'interpreter','none');
        subplot(max(list_run),2,2+(num_r-1)*2)
        par_rot = tab_parameters(:,1:3);
        plot(par_rot);
        title(sprintf('rotation (deg, bgr/rpy) %s ',name_f),'interpreter','none');
        
    end

    % Cleaning temporary files
    delete(file_mask_source);

end

%% If requested, save a figure of motion parameters
if ~strcmp(files_out.fig_motion,'gb_niak_omitted')
        figure(hfig)
        if exist('OCTAVE_VERSION','builtin')
            %% In octave 3.0.4 the pdf distiller does not work
            %% Using ps2pdf instead
            file_tmp_eps = niak_file_tmp('_fig.eps');
            print(file_tmp_eps,'-depsc');
            system(['ps2pdf -dEPSCrop ',file_tmp_eps,' ',files_out.fig_motion]);
            delete(file_tmp_eps)
        else
            print(files_out.fig_motion,'-dpdf');
        end
        close(hfig)
end

%% If requested, write the target volume
if ~strcmp(files_out.target,'gb_niak_omitted')
    [succ,msg] = system(cat(2,'cp ',file_target,' ',files_out.target));
    if succ~=0
        error(msg)
    end

    %% If necessary, zip outputs
    if strcmp(files_out.target(end-length(gb_niak_zip_ext):end),gb_niak_zip_ext)
        instr_zip = cat(2,gb_niak_zip,' ',files_out.target);
        [succ,msg] = system(instr_zip);
        if succ ~= 0
            error(msg);
        end
    end

end

%% If requested, write the mask
if ~strcmp(files_out.mask,'gb_niak_omitted')
    [succ,msg] = system(cat(2,'cp ',file_mask_target,' ',files_out.mask));
    if succ~=0
        error(msg)
    end

    %% If necessary, zip outputs
    if strcmp(files_out.mask(end-length(gb_niak_zip_ext):end),gb_niak_zip_ext)
        instr_zip = cat(2,gb_niak_zip,' ',files_out.mask);
        [succ,msg] = system(instr_zip);
        if succ ~= 0
            error(msg);
        end
    end

end

% Cleaning temporary files
delete(file_mask_target);
delete(file_target);
delete(file_target_native);