function [files_in,files_out,opt] = niak_brick_motion_correction(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MOTION_CORRECTION
%
% Perfom within-subject motion correction of fMRI data via estimation of a
% rigid-body transform and spatial resampling.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% * FILES_IN 
%       (structure) with the following fields : 
%
%       SESSIONS 
%           (structure) Each field of FILES_IN.SESSIONS is a cell of 
%           strings, where each string is the file name of a 3D+t dataset.
%           The files attached to a single field are considered to be 
%           acquired in the same session (small displacement), and files 
%           from different fields are considered to have been acquired in 
%           different sessions (potentially large displacement).
%           All files should be fMRI data of ONE subject.
%
%       MOTION_PARAMETERS 
%           (structure of cells of strings)
%           Use this field to skip the estimation of motion parameters, and
%           only perform spatial resampling of the data.
%           MOTION_PARAMETERS.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I 
%           (roll/pitch/yaw/translations in x/y/z).
%
% * FILES_OUT  
%       (structure) with the following fields. Note that if
%       a field is an empty string, a default value will be used to
%       name the outputs. If a field is ommited, the output won't be
%       saved at all (this is equivalent to setting up the output file
%       names to 'gb_niak_omitted').
%
%       If any of the following field is specified, the functional data will be
%       resampled in the space of the volume of reference of the run of
%       reference of the session of reference.
%
%       MOTION_CORRECTED_DATA 
%           (structure of cell of strings, default <BASE FILES_IN>_MC.<EXT>)
%           File names for saving the motion corrected datasets.
%           The images will be resampled at the resolution of the
%           between-run functional image of reference.
%
%       MEAN_VOLUME 
%           (string, default MEAN_<BASE_FILE_IN>) the mean volume
%           of all coregistered runs of all sessions. This volume can be
%           generated only if MOTION_CORRECTED_DATA is generated too.
%
%       MASK_VOLUME 
%           (string, default base MASK_<BASE_FILE_IN>) A mask of
%           the brain common to all runs and all sessions (after motion 
%           correction).
%           This volume can be generated only if MOTION_CORRECTED_DATA is 
%           generated too.
%
%   If a field FILES_IN.MOTION_PARAMETERS has been specified, the following
%   fields of FILES_OUT will be ignored
%
%       MOTION_PARAMETERS 
%           (structure of cells of strings, default <base MOTION_PARAMS>_<BASE_FILE_IN>.DAT)
%           MOTION_PARAMETERS.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       TRANSF_WITHIN_SESSION 
%           (structure of cells of strings, default TRANS_WS_<FILE_IN>.DAT)
%           TRANSF_WITHIN_SESSION_DAT.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated within-session motion parameters of the dataset
%           NUM_D in session NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       TRANSF_BETWEEN_SESSION 
%           (string, defaulte TRANSF_BS_<name of the first dataset of the session of reference>.DAT)
%           The first line describes the content of each column. Each subsequent
%           line I+1 is a representation of the between-session parameters
%           estimated for session I, i.e. the transformation between the mean volume
%           of the session and the mean volume of the session of reference.
%
%       FIG_MOTION  
%           (cell of strings, default base FIG_MOTION_<BASE_FILE_IN>.EPS) 
%           For each session, a figure representing the within-session 
%           motion parameters for all runs.
%
% * OPT   
%       (structure) with the following fields:
%
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes that are suppressed 
%           at the begining of the time series.
%           This is a good stage to get rid of "dummy scans"
%           necessary to reach signal stabilization (that takes
%           about 3 volumes).
%
%       VOL_REF 
%           (vector, default 1) VOL_REF(NUM) is the number of the volume 
%           that will be used as target for session NUM. 
%           If VOL_REF is a single integer, the same number will be used 
%           for all sessions.
%
%       RUN_REF 
%           (vector, default 1) RUN_REF(NUM) is the number of the run that 
%           will be used as target for each session.
%           If RUN_REF is a single integer, the same number will be used 
%           for all sessions.
%
%       SESSION_REF 
%           (string, default first session) name of the session of
%           reference. By default, it is the first field found in
%           FILES_IN.SESSIONS.
%
%       INTERPOLATION 
%           (string, default 'sinc') the spatial interpolation method. 
%           Available options : 'trilinear', 'tricubic', 
%           'nearest_neighbour', 'sinc'.
%
%       FWHM 
%           (real number, default 8 mm) the fwhm of the blurring kernel
%           applied to all volumes.
%
%       FLAG_SESSION 
%          (boolean, default 0) if FLAG_SESSION == 0, the intra-session 
%          motion parameters are included in the final transformation.
%          If FLAG_SESSION == 1, the intra-session motion parameters are 
%          still estimated for quality control, but the between-session 
%          transformation only is actually applied in the resampling.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN, FILES_OUT and OPT.
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO
%
%  NIAK_BRICK_MOTION_CORRECTION_WS, NIAK_DEMO_MOTION_CORRECTION
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1: The motion correction follows a hierachical strategy :
% Rigid-body transforms are first estimated within each session
% independently by registering all volumes to one single reference volume
% in a run of reference.
% Then, the volume of reference (of the run of reference) for each session
% is coregistered with the volume of reference (of the run of reference)
% of the session of reference.
% The within-session transformation is combined with that
% between-session transformation for each volume.
%
% NOTE 2: The final motion correction parameters are volume-specific and points to
% the volume of reference of the run of reference of the session of reference.
% The within- and between-session transformations can be saved as
% outputs for quality checking.
%
% _________________________________________________________________________
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
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_motion_correction'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'sessions','motion_parameters'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'motion_corrected_data','motion_parameters','transf_within_session','transf_between_session','mask_volume','mean_volume','fig_motion'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'suppress_vol','vol_ref','run_ref','session_ref','flag_session','flag_zip','flag_test','folder_out','interpolation','fwhm','flag_verbose'};
gb_list_defaults = {0,1,1,'',0,0,0,'','sinc',8,1};
niak_set_defaults

list_sessions = fieldnames(files_in.sessions);
nb_sessions = length(list_sessions);

if isempty(opt.session_ref)
    opt.session_ref = list_sessions{1};
    session_ref = opt.session_ref;
end

%% Building default output names

flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp = isempty(files_out.motion_parameters);
flag_def_trans_ws = isempty(files_out.transf_within_session);
flag_def_trans_bs = isempty(files_out.transf_between_session);
flag_def_fig_mp = isempty(files_out.fig_motion);

if flag_def_data
    files_out.motion_corrected_data = struct([]);
end

if flag_def_mp
    files_out.motion_parameters = struct([]);
end

if flag_def_trans_ws
    files_out.transf_within_session = struct([]);
end

if flag_def_trans_bs
    files_out.transf_between_session = cell([nb_sessions 1]);
end

for num_s = 1:length(list_sessions)

    name_session = list_sessions{num_s};
    files_name = getfield(files_in.sessions,name_session);
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

        if flag_def_trans_ws
            transf_ws{num_d} = cat(2,folder_write,filesep,'transf_ws_',name_f,'.dat');
        end
        
        if flag_def_trans_bs & strcmp(name_session,opt.session_ref)&(num_d==1)
            files_out.transf_between_session = cat(2,folder_write,filesep,'transf_bs_',name_f,'.dat');
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

    if flag_def_trans_ws
        if num_s == 1
            eval(cat(2,'files_out.transf_within_session(1).',name_session,' = transf_ws;'));
        else
            files_out.transf_within_session = setfield(files_out.transf_within_session,name_session,transf_ws);
        end
    end

    if flag_def_fig_mp
        files_out.fig_motion{num_s} = cat(2,folder_write,filesep,'fig_motion_',name_f,'_',name_session,'.eps');
    end


end % loop over sessions

if flag_test == 1
    return
end

if ischar(files_in.motion_parameters) % that means that we need to estimate the motion parameters

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Estimation of motion parameters        %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Within-session motion parameters       %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if flag_verbose
        fprintf('\n*********************\nWithin-session motion parameters estimation\n*********************\n')
    end

    files_transf_ws = files_in.sessions;
    
    for num_s = 1:length(list_sessions)

        name_session = list_sessions{num_s};
        clear files_session_in
        clear files_session_out
        
        if flag_verbose
            fprintf('\n* %s : \n',name_session)
        end

        %% Generate temporary names for within-session motion correction
        files_session_in = getfield(files_in.sessions,name_session);        
        mask_session{num_s} = niak_file_tmp(cat(2,'_',name_session,'_mask.mnc'));
        target_session{num_s} = niak_file_tmp(cat(2,'_',name_session,'_target.mnc'));

        if ~ischar(files_out.transf_within_session)
            files_session_out.motion_parameters = getfield(files_out.transf_within_session,name_session);
        else
            for num_f = 1:length(files_session_in)
                files_session_out.motion_parameters{num_f} = niak_file_tmp(cat(2,'_mp_run',num2str(num_f),'.dat'));
            end
        end
        files_session_out.mask = mask_session{num_s};
        files_session_out.target = target_session{num_s};

        if ~ischar(files_out.fig_motion)
            files_session_out.fig_motion = files_out.fig_motion{num_s};
        end

        %% Setting up options of the within-run motion correction
        opt_session.vol_ref = vol_ref;
        opt_session.run_ref = run_ref;
        opt_session.flag_verbose = flag_verbose;
        opt_session.interpolation = interpolation;
        opt_session.fwhm = fwhm;
        opt_session.flag_zip = 0;

        %% Perform estimation of within-session motion parameters estimation
        [files_session_in,files_session_out,opt_session] = niak_brick_motion_correction_ws(files_session_in,files_session_out,opt_session);
        mp_session = files_out.motion_parameters;
        files_transf_ws = setfield(files_transf_ws,name_session,files_session_out.motion_parameters);

    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Between-session motion parameters      %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if flag_verbose
        fprintf('\n*********************\n\nBetween-session motion parameters estimation...\n')
    end

    %% Extracting the session of reference from the list of sessions
    mask_tmp = niak_find_str_cell(session_ref,list_sessions);
    num_session_ref = find(mask_tmp);

    %% If requested, write the motion parameters in a log file
    if ~strcmp(files_out.transf_between_session,'gb_niak_omitted')
        hf_mp = fopen(files_out.transf_between_session,'w');
        fprintf(hf_mp,'pitch roll yaw tx ty tz XCORR_init XCORR_final session_name\n');
    end

    %% Initialization of the table of between-session motion parameters
    tab_mp_bs = zeros([length(nb_sessions) 8]);

    for num_s = 1:length(list_sessions)
        name_session = list_sessions{num_s};
        if num_s~=num_session_ref
            xfm_tmp = niak_file_tmp(cat(2,name_session,'_mp.xfm'));
            [flag,str_log] = system(cat(2,'minctracc ',target_session{num_s},' ',target_session{num_session_ref},' ',xfm_tmp,' -xcorr -source_mask ',mask_session{num_s},' -model_mask ',mask_session{num_session_ref},' -forward -clobber -lsq6 -identity -speckle 0 -est_center -tol 0.0001 -tricubic -simplex 20 -source_lattice -step 3 3 3'));

            %% Read the rigid-body transformation (lsq6)
            transf = niak_read_transf(xfm_tmp);
            delete(xfm_tmp);
            
            %% Keeping record of the objective function values before and after
            %% optimization
            cell_log = niak_string2lines(str_log);
            line_log = niak_string2words(cell_log{end-1});
            tab_mp_bs(num_s,7) = str2num(line_log{end});
            line_log = niak_string2words(cell_log{end});
            tab_mp_bs(num_s,8) = str2num(line_log{end});            
            
        else
            transf = eye(4);
        end
        
        %% Converting the xfm transformation into a roll/pitch/yaw and
        %% translation format
        [pry,tsl] = niak_transf2param(transf);
        tab_mp_bs(num_s,1:3) = pry';
        tab_mp_bs(num_s,4:6) = tsl';

        %% If requested, write the between-session motion parameters in a file
        if ~strcmp(files_out.transf_between_session,'gb_niak_omitted')
            fprintf(hf_mp,'%s',num2str(tab_mp_bs(num_s,:),12));
            fprintf(hf_mp,' %s\n',name_session);
        end
        
    end

    %% If necessary, close the between-session motion parameters file
    if ~strcmp(files_out.transf_between_session,'gb_niak_omitted')
        fclose(hf_mp);
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Combining within- and between-session motion parameters %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if flag_verbose
        fprintf('\nCombining within-session and between-session motion parameters...\n')
    end

    tab_mp = mp_session;

    for num_s = 1:length(list_sessions)

        name_session = list_sessions{num_s};
        list_runs = getfield(mp_session,name_session);
        list_ws = getfield(files_transf_ws,name_session);
        transf_bs = niak_param2transf(tab_mp_bs(num_s,1:3)',tab_mp_bs(num_s,4:6)');

        %% Get the file names to save the motion parameters
        if ~ischar(files_out.motion_parameters)
            files_mp = getfield(files_out.motion_parameters,name_session);
        end

        for num_r = 1:length(list_runs)

            %% Reading the within-run motion parameters file
            hf_ws = fopen(list_ws{num_r});
            str_mp_ws = fread(hf_ws,Inf,'uint8=>char')';
            cell_mp_ws = niak_string2lines(str_mp_ws);            
            fclose(hf_ws);

            %% If requested, write the motion parameters in a log file
            if ~ischar(files_out.motion_parameters)
                hf_mp = fopen(files_mp{num_r},'w');
                fprintf(hf_mp,'pitch roll yaw tx ty tz\n');
            end
            
            %% Combining the within- and between-sessions motion parameters
            tab_tmp = zeros([length(cell_mp_ws)-1 6]);
            for num_v = 2:length(cell_mp_ws)
                param_ws = str2num(char(niak_string2words(cell_mp_ws{num_v})));
                transf_ws = niak_param2transf(param_ws(1:3),param_ws(4:6));
                if flag_session
                    transf = transf_bs;
                else
                    transf = transf_bs*transf_ws;
                end
                [pry,tsl] = niak_transf2param(transf);
                tab_tmp(num_v-1,:) = [pry' tsl'];

                %% If requested, write the motion parameters in
                %% a file
                if ~ischar(files_out.motion_parameters)
                    fprintf(hf_mp,'%s\n',num2str(tab_tmp(num_v-1,:),12));                    
                end

            end
            eval(cat(2,'tab_mp.',name_session,'{num_r} = tab_tmp;'));

            %% If necessary, close the between-session motion parameters file
            if ~ischar(files_out.motion_parameters)
                fclose(hf_mp);
            end

        end
    end

    %% Copy the target
    file_target = niak_file_tmp('_target.mnc');
    [succ,msg] = system(cat(2,'cp ',target_session{num_session_ref},' ',file_target));
    if succ~=0
        error(msg)
    end    

    %% Clean the temporary files
    if ischar(files_out.transf_within_session)
        cell_ws = niak_files2cell(files_transf_ws);
        for num_ws = 1:length(cell_ws)
            delete(cell_ws{num_ws});
        end        
    end
    
    for num_s = 1:length(list_sessions)
        delete(mask_session{num_s})
        delete(target_session{num_s});
    end

else % if ~ischar(files_in.motion_parameter)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Reading the user-specified motion parameters %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if flag_verbose
        fprintf('\nReading the user-specified motion parameters...\n')
    end

    tab_mp = files_in.sessions;

    for num_s = 1:length(list_sessions)

        name_session = list_sessions{num_s};
        list_mp_runs = getfield(files_in.motion_parameters,name_session);        

        for num_r = 1:length(list_mp_runs)

            %% Reading the within-run motion parameters file
            hf_ws = fopen(list_mp_runs{num_r});
            str_mp_ws = fread(hf_ws,Inf,'uint8=>char')';
            cell_mp_ws = niak_string2lines(str_mp_ws);            
            fclose(hf_ws);

            %% Combining the within- and between-sessions motion parameters
            tab_tmp = zeros([length(cell_mp_ws)-1 6]);
            for num_v = 2:length(cell_mp_ws)
                param_ws = str2num(char(niak_string2words(cell_mp_ws{num_v})));
                transf = niak_param2transf(param_ws(1:3),param_ws(4:6));                
                [pry,tsl] = niak_transf2param(transf);
                tab_tmp(num_v-1,:) = [pry' tsl'];                
            end
            
            eval(cat(2,'tab_mp.',name_session,'{num_r} = tab_tmp;'));

        end
        
    end
    
    %% Create a target file
    file_target = niak_file_tmp('_target.mnc');
    
    file_target2 = niak_file_tmp('_target.mnc');
    list_runs = getfield(files_in.sessions,session_ref);
    hdr_target = niak_read_vol(list_runs{1});
    hdr_target.file_name = file_target2;
    dim_t = hdr_target.info.dimensions;
    niak_write_vol(hdr_target,zeros([dim_t(1:3)]));
    
    files_in_r.source = file_target2;
    files_in_r.target = file_target2;
    opt_r.flag_tfm_space = 1;
    files_out_r = file_target;
    niak_brick_resample_vol(files_in_r,files_out_r,opt_r);
    delete(file_target2);
    
end
        
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spatial resampling of the data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~ischar(files_out.motion_corrected_data)

    if flag_verbose
        fprintf('\nResampling data...\n')
    end

    %% Building the options for resampling
    opt_r.interpolation = opt.interpolation;
    opt_r.flag_tfm_space = 0;
    opt_r.flag_test = 0;
    opt_r.flag_verbose = 0;
    files_in_r.source = niak_file_tmp('_vol.mnc');
    files_in_r.target = file_target;
    files_in_r.transformation = niak_file_tmp('_transf.xfm');
    files_out_r = niak_file_tmp('_vol2.mnc');

    niak_resample_to_self(file_target);
    hdr_target = niak_read_vol(file_target);
    dim_t = hdr_target.info.dimensions;
    if ~strcmp(files_out.mask_volume,'gb_niak_omitted')
        mask_all = ones(dim_t(1:3));
    end
    if ~strcmp(files_out.mean_volume,'gb_niak_omitted')
        mean_all = zeros(dim_t(1:3));
    end
    nb_runs = 0;
    
    for num_s = 1:length(list_sessions)

        name_session = list_sessions{num_s};
        if flag_verbose
            fprintf('\n%s...\n',name_session)
        end

        files_session = getfield(files_in.sessions,name_session);
        mp_session = getfield(tab_mp,name_session);
        if ~ischar(files_out.motion_corrected_data)
            motion_corrected_data_session = getfield(files_out.motion_corrected_data,name_session);
        end
        
        for num_r = 1:length(files_session);

            if flag_verbose
                fprintf('\nRun %i... volume :',num_r)
            end

            %% Reading data
            [hdr,data] = niak_read_vol(files_session{num_r});
            [nx,ny,nz,nt] = size(data);
            hdr.file_name = files_in_r.source;
            hdr.flag_zip = 0;
            hdr_target.details.time = hdr.details.time;
            hdr_target.info.tr = hdr.info.tr;
            [nx,ny,nz,nt] = size(data);            
            data_r = zeros([dim_t(1) dim_t(2) dim_t(3) nt-suppress_vol]);
            
            %% Resampling each volume
            for num_v = 1+suppress_vol:size(data,4)

                if flag_verbose
                    fprintf(' %i',num_v)
                end

                transf = niak_param2transf(mp_session{num_r}(num_v,1:3)',mp_session{num_r}(num_v,4:6)');
                niak_write_transf(transf,files_in_r.transformation);
                niak_write_vol(hdr,data(:,:,:,num_v));

                niak_brick_resample_vol(files_in_r,files_out_r,opt_r);
                
                [hdr2,vol2] = niak_read_vol(files_out_r);
                data_r(:,:,:,num_v-suppress_vol) = vol2;
                
            end
            
            if ~ischar(files_out.motion_corrected_data)
                hdr_target.file_name = motion_corrected_data_session{num_r};
                hdr_target.flag_zip = flag_zip;
                niak_write_vol(hdr_target,data_r);
            end
            
            if ~strcmp(files_out.mean_volume,'gb_niak_omitted')
                mean_all = mean_all + mean(data_r,4);
                nb_runs = nb_runs+1;
            end
            
            if ~strcmp(files_out.mask_volume,'gb_niak_omitted')
                mask_tmp = niak_mask_brain(mean(abs(data_r),4));
                mask_all = mask_all & mask_tmp;                
            end
            
        end
    end
    
    if flag_verbose
        fprintf('\n')
    end
    
    %% Write the mean of all volumes
    if ~strcmp(files_out.mean_volume,'gb_niak_omitted')
        mean_all = mean_all/nb_runs;
        hdr_target.file_name = files_out.mean_volume;
        hdr_target.flag_zip = flag_zip;
        niak_write_vol(hdr_target,mean_all);
    end

    %% Write the mask of all runs
    if ~strcmp(files_out.mask_volume,'gb_niak_omitted')                
        hdr_target.file_name = files_out.mask_volume;
        hdr_target.flag_zip = flag_zip;
        niak_write_vol(hdr_target,mask_all);
    end

    %% Clean up temporary files
    delete(files_in_r.source);
    delete(files_in_r.target);
    delete(files_in_r.transformation);

end

%% Clean up temporary files
if exist(file_target)
    delete(file_target);
end