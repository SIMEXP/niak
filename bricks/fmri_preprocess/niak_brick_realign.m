function [files_in,files_out,opt] = niak_brick_realign(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_REALIGN                                          
%
% Perfom within-subject and within-session motion correction of fMRI data 
% via estimation of a rigid-body transform (lsq6) and spatial resampling.
%
% _________________________________________________________________________
% SYNTAX
%
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_REALIGN(FILES_IN,FILES_OUT,OPT)
%                                                              
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN (structure)
%      Each field of FILES_IN is a cell of strings, where each string
%      is the file name of a 3D+t dataset (see NIAK_READ_VOL for supported 
%      formats).
%
%      The files attached to a single field are considered to be acquired in
%      the same session (small displacement), and files from different 
%      fields are considered to have been acquired in different sessions 
%      (potentially large displacement).
%
%      All files should be fMRI data of ONE subject.
%
%  * FILES_OUT  (structure) with the following fields. Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%       MOTION_CORRECTED_DATA 
%           (structure of cell of strings, default base
%           name <BASE FILES_IN>_mc.<EXT>)
%           File names for saving the motion corrected datasets.
%           The images will be resampled at the resolution of the
%           between-run functional image of reference.
%
%       MOTION_PARAMETERS 
%           (structure of cells of strings, default base 
%           MOTION_PARAMS_<BASE_FILE_IN>.DAT)
%           MOTION_PARAMETERS.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       FIG_MOTION  
%       	(cell of strings, default base FIG_MOTION_<BASE_FILE_IN>.EPS) 
%           For each session, a figure representing the motion parameters 
%           for all runs in that session.
%
%       MEAN_VOLUME (string, default MEAN_<BASE FILE_IN>.<EXT>) the mean volume
%           of all coregistered runs of all sessions. This volume can be
%           generated only if MOTION_CORRECTED_DATA is generated too.
%
%       MASK_VOLUME (string, default base MASK_<BASEFILE_IN>.<EXT>) A mask of
%           the brain common to all runs and all sessions (after motion correction).
%           This volume can be generated only if MOTION_CORRECTED_DATA is 
%           generated too.
%
%  * OPT   (structure) with the following fields:
%
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes
%           that are suppressed at the begining of the time series.
%           This is a good stage to get rid of "dummy scans"
%           necessary to reach signal stabilization (that takes
%           about 10 seconds).
%
%       QUALITY 
%           (real value, 0<.<1, default 0.9) Quality versus speed 
%           trade-off.  Highest quality (1) gives most precise results, 
%           whereas lower qualities gives faster realignment.
%           The idea is that some voxels contribute little to the 
%           estimation of the realignment parameters.
%           This parameter is involved in selecting the number of voxels 
%           that are used.
%
%       FWHM 
%           (real number, default 6 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       SEP 
%           (real number, default 4) the default separation (mm) to sample 
%           the images.
%
%       FLAG_RTM 
%           (boolean, default 0) if FLAG_RTM is 1, then a two pass
%           procedure is to be used in order to register the
%           images to the mean of the images after the first realignment.
%
%       DEGREE_BSPLINE 
%          (integer, default 2) The B-spline degree used for
%          interpolation in the motion parameter estimation procedure
%
%       INTERPOLATION
%          (integer, deafult Inf) the B-spline interpolation method. 
%          Non-finite values result in Fourier interpolation.  Note that
%          Fourier interpolation only works for purely rigid body
%          transformations.  Voxel sizes must all be identical and
%          isotropic.
%
%       FLAG_MASK
%          (boolean, default 1) mask output images (1 for yes, 0 for no)
%          To avoid artifactual movement-related variance the realigned
%          set of images can be internally masked, within the set (i.e.
%          if any image has a zero value at a voxel than all images have
%          zero values at that voxel).  Zero values occur when regions
%          'outside' the image are moved 'inside' the image during
%          realignment.
%
%       SESSION_REF (string, default first session) 
%           name of the session of reference. By default, it is the first 
%           field found in FILES_IN.
%
%       RUN_REF 
%           (vector, default 1) RUN_REF(NUM) is the number of the run that 
%           will be used as target for session NUM.
%           If RUN_REF is a single integer, the same number will be
%           used for all sessions.
%
%       VOL_REF 
%           (vector, default 1) VOL_REF(NUM) is the number of the volume 
%           that will be used as target for session NUM. 
%           If VOL_REF is a single integer, the same number will be
%           used for all sessions.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_OUT and OPT.
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
% _________________________________________________________________________
% OUTPUTS                                                             
%
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO                                                            
%
%  NIAK_DEMO_REALIGN
%
% _________________________________________________________________________
% COMMENTS                                                            
%
% NOTE 1
% This brick is a "NIAKized" overlay of SPM_REALIGN distributed as part
% of the SPM5 package. You need SPM5 installed in the path for the brick to
% work correctly. Because some mex files are used in SPM_REALIGN, this
% brick unfortunately does not work with octave.
%
% NOTE 2
% The motion correction follows a hierachical strategy :
% Rigid-body transforms are first estimated within each session
% independently by registering all volumes to one single reference volume
% in a run of reference.
% Then, the volume of reference (of the run of reference) for each session
% is coregistered with the volume of reference (of the run of reference)
% of the session of reference.
% The within-session transformation is combined with that
% between-session transformation for each volume.
%
% NOTE 3
% The motion correction parameters are volume-specific and point to
% the volume of reference of the run of reference of the session of
% reference.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, motion correction, fMRI

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

niak_gb_vars
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_REALIGN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_realign'' for more info.')
end

%% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a structure !');
end
list_sessions = fieldnames(files_in);
nb_sessions = length(list_sessions);

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'motion_corrected_data','motion_parameters','fig_motion','mean_volume','mask_volume'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_mask','suppress_vol','quality','fwhm','sep','flag_rtm','degree_bspline','interpolation','vol_ref','run_ref','session_ref','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {1,0,0.9,6,4,0,2,Inf,1,1,'',0,'',1};
niak_set_defaults

if isempty(opt.session_ref)
    opt.session_ref = list_sessions{1};
    session_ref = opt.session_ref;
end

if length(opt.run_ref) == 1
    opt.run_ref = opt.run_ref * ones([nb_sessions 1]);
end

if length(opt.vol_ref) == 1
    opt.vol_ref = opt.vol_ref * ones([nb_sessions 1]);
end

%% Building default output names

flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp = isempty(files_out.motion_parameters);
flag_def_fig_mp = isempty(files_out.fig_motion);

if flag_def_data
    files_out.motion_corrected_data = struct([]);
end

if flag_def_mp
    files_out.motion_parameters = struct([]);
end

for num_s = 1:length(list_sessions)

    name_session = list_sessions{num_s};
    files_name = getfield(files_in,name_session);
    nb_files = length(files_name);

    motion_corrected_data = cell([nb_files 1]);
    motion_parameters = cell([nb_files 1]);
    transf_within_session = cell([nb_files 1]);

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
            motion_parameters{num_d} = cat(2,folder_write,filesep,'motion_params_',name_f,'.dat');
        end

        if isempty(files_out.mask_volume)& strcmp(name_session,opt.session_ref)&(num_d==1)
            files_out.mask_volume = cat(2,folder_write,filesep,'mask_',name_f,ext_f);
        end

        if isempty(files_out.mean_volume)& strcmp(name_session,opt.session_ref)&(num_d==1)
            files_out.mean_volume = cat(2,folder_write,filesep,'mean_',name_f,ext_f);
        end


    end %loop over datasets

    if flag_def_data
        if num_s == 1
            eval(cat(2,'files_out.motion_corrected_data(1).',name_session,' = motion_corrected_data;'));
        else
            files_out.motion_corrected_data = setfield(files_out.motion_corrected_data,name_session,motion_corrected_data);
        end
    end

    if flag_def_mp
        if num_s == 1
            eval(cat(2,'files_out.motion_parameters(1).',name_session,' = motion_parameters;'));
        else
            files_out.motion_parameters = setfield(files_out.motion_parameters,name_session,motion_parameters);
        end
    end

    if flag_def_fig_mp
        if strcmp(name_session,opt.session_ref)
            files_out.fig_motion = cat(2,folder_write,filesep,'fig_motion_',name_f,'.eps');
        end
    end

end % loop over sessions

if flag_test == 1
    return
end

if flag_verbose
    fprintf('\n*************\nMotion correction, the following parameters will be used\n*************')
    opt
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Converting the data into temporary analyze files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nConverting the data into temporary 3D analyze files ...\n');
end

path_tmp = niak_path_tmp('_motion_correction');

for num_s = 1:length(list_sessions) % Loop over sessions
    list_run = getfield(files_in,list_sessions{num_s});
    nb_run = length(list_run);

    for num_r = 1:nb_run % Loop over runs

        [hdr,vol] = niak_read_vol(list_run{num_r});
        file_tmp{num_s,num_r} = [];

        if strcmp(hdr.type,'minc1')|strcmp(hdr.type,'minc2')

            %% The data is in minc format
            %% Convert everything back to nifti img/hdr
            
            for num_t = 1:size(vol,4); % loop over time frame
                
                if num_t == 1;
                    file_tmp_mnc{num_s,num_r} = cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.mnc');
                    file_tmp{num_s,num_r} = cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img');
                    file_out{num_s,num_r} = cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img');
                    file_out_mnc{num_s,num_r} = cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.mnc');
                else                    
                    file_tmp_mnc{num_s,num_r} = char(file_tmp_mnc{num_s,num_r},cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.mnc'));
                    file_tmp{num_s,num_r} = char(file_tmp{num_s,num_r},cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img'));
                    file_out{num_s,num_r} = char(file_out{num_s,num_r},cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img'));
                    file_out_mnc{num_s,num_r} = char(file_out_mnc{num_s,num_r},cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.mnc'));
                end
                    
                hdr.file_name = file_tmp_mnc{num_s,num_r}(num_t,:);
                niak_write_vol(hdr,vol(:,:,:,num_t));

                if strcmp(list_sessions{num_s},opt.session_ref)&(num_r==opt.run_ref(num_s))&(num_t == opt.vol_ref(num_s));
                    opt_res.interpolation = 'sinc';
                    opt_res.flag_verbose = 0;
                    niak_resample_to_self(file_tmp_mnc{num_s,num_r}(num_t,:),opt_res);
                end
                
                str_convert = cat(2,'mnc2nii -dual ',file_tmp_mnc{num_s,num_r}(num_t,:),' ',file_tmp{num_s,num_r}(num_t,:));
                [succ,msg] = system(str_convert);

                if succ~=0
                    error(cat(2,'Something went wrong in the mnc2nii conversion :',msg));
                end

            end
        else

            %% The data is in nifti
            %% Just write it in a bunch of 3D volume so SPM can understand
            %% (this step is just equivalent to a copy if the data was
            %% already a bunch of 3D volumes, but splits data in case of a
            %% 4D dataset.

            for num_t = 1:size(vol,4); % loop over time frame

                if num_t == 1
                    file_tmp{num_s,num_r} = cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img');
                    file_out{num_s,num_r} = cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img');
                else
                    file_tmp{num_s,num_r} = char(file_tmp{num_s,num_r},cat(2,path_tmp,'func_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img'));
                    file_out{num_s,num_r} = char(file_out{num_s,num_r},cat(2,path_tmp,'rfunc_',num2str(num_s),'_',num2str(num_r),'_',num2str(num_t),'.img'));
                end
                
                hdr.file_name = deblank(file_tmp{num_s,num_r}(num_t,:));
                niak_write_vol(hdr,vol(:,:,:,num_t));
                
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running spm_realign %%
%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nRunning spm_realign ...\n');
end

%% Options

flag.quality = opt.quality;
flag.fwhm = opt.fwhm;
flag.sep = opt.sep;
if opt.flag_rtm
    flag.rtm = 1;
end
flag.interp = opt.degree_bspline;

%% Time to build the file names !
%% The files need to be reorganized in order to have the session of
%% reference at the begining of the cell, and the volume of reference of
%% the run of reference at the begining of each cell entry....

num_session_ref = find(niak_find_str_cell(list_sessions,opt.session_ref));
list_num_session = 1:nb_sessions;
list_num_session = [num_session_ref list_num_session(list_num_session~=num_session_ref)];

for num_s = list_num_session
    
    list_run = getfield(files_in,list_sessions{num_s});
    nb_run = length(list_run);
    
    if length(opt.run_ref) == 1
        num_run_ref = opt.run_ref;
    else
        num_run_ref = opt.run_ref(num_s);
    end
    
    if length(opt.vol_ref) == 1
        num_vol_ref = opt.vol_ref;
    else
        num_vol_ref = opt.vol_ref(num_s);
    end
    
    list_num_run = 1:nb_run;
    list_num_run = [num_run_ref list_num_run(list_num_run~=num_run_ref)];    
    
    for num_r = list_num_run
        nb_vol = size(file_tmp{num_s,num_r},1);
        list_num_vol = 1:nb_vol;
        list_num_vol = [num_vol_ref list_num_vol(list_num_vol~=num_vol_ref)];
        if num_r == list_num_run(1)
            list_files{num_s} = file_tmp{num_s,num_r}(list_num_vol,:);
        else
            list_files{num_s} = char(list_files{num_s},file_tmp{num_s,num_r}(list_num_vol,:));    
        end
    end
end

spm_realign(list_files,flag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Moving the outputs to the right place and format %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\nMoving the outputs to the right place and format ...\n');
end

%% Saving the figure
hfig = gcf;
saveas(hfig,files_out.fig_motion,'epsc')
close(hfig)

%% Saving the motion parameters 
%% ... There is one file per session, and the motion parameters appear in
%% the same order as the volumes in list_files
if ~ischar(files_out.fig_motion)
    
end


%% Reading the resampled data and writting them in the proper format
if ~ischar(files_out.motion_corrected_data)

    if flag_verbose
        fprintf('\nResampling the functional data ...\n');        
    end
    
    flag_res.mask = opt.flag_mask;
    flag_res.mean = 0;
    flag_res.interp = opt.interpolation;
    flag_res.which = 1;
    
    for num_s = list_num_session % Loop over sessions
        spm_reslice(char(list_files{list_num_session}(1,:),list_files{num_s}),flag_res);
    end
    
    for num_s = 1:length(list_sessions) % Loop over sessions

        list_run = getfield(files_in,list_sessions{num_s});
        list_run_write = getfield(files_out,'motion_corrected_data',list_sessions{num_s});
        nb_run = length(list_run);

        for num_r = 1:nb_run % Loop over runs

            hdr = niak_read_vol(list_run{num_r});
            file_tmp{num_s,num_r} = [];
            nb_t = size(file_out{num_s,num_r},1);

            for num_t = 1:nb_t; % loop over time frame

                str_convert = cat(2,'nii2mnc ',deblank(file_out{num_s,num_r}(num_t,:)),' ',deblank(file_out_mnc{num_s,num_r}(num_t,:)));
                [succ,msg] = system(str_convert);

                if succ~=0
                    error(cat(2,'Something went wrong in the nii2mnc conversion :',msg));
                end

                [hdr_tmp,vol_tmp] = niak_read_vol(file_out_mnc{num_s,num_r}(num_t,:));
                if num_t == 1
                    hdr = hdr_tmp;
                    vol_r = zeros(hdr.info.dimensions);
                    hdr.info.mat = hdr_tmp.info.mat;
                end
                vol_r(:,:,:,num_t) = vol_tmp;
            end

            hdr.file_name = list_run_write{num_r};
            niak_write_vol(hdr,vol_r);
        end
    end
end

%% Time for cleaning !!
instr_clean = cat(2,'rm -rf ',path_tmp);
system(instr_clean)