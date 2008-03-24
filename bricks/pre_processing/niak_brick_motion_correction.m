function [files_in,files_out,opt] = niak_brick_motion_correction(files_in,files_out,opt)

% Perfom within-subject motion correction of fMRI data via estimation of a
% rigid-body transform and spatial resampling.
%
% SYNTAX:
%   [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%   FILES_IN
%       SESSIONS (structure)
%           Each field of SESSIONS is a cell of strings, where each string
%           is the file name of a 3D+t dataset.
%           The files attached to a single field are considered to be acquired in
%           the same session, and files from different fields are considered
%           to have been acquired in different sessions. All files should be
%           fMRI data of ONE subject.
%
%       T1 (string)
%           This is a file name for an anatomical image of the subject. If
%           such an image is provided, all the estimated transformations
%           will be pointing to that space.
%
%       MOTION_PARAMETERS_XFM (structure of cell of array of strings)
%           File name for the estimated parameters. A different file needs
%           to be specified for each volume of each dataset within a session.
%           MOTION_PARAMETERS_XFM.<NAME_SESSION>{NUM_D}(NUM_VOL,:) is the
%           transformation file of the dataset NUM_D in session NAME_SESSION
%           and volume NUM_VOL. The transformation is expected in XFM format.
%           If MOTION_PARAMETERS_XFM is specified, this transformation will
%           be used for resampling and no transformation will be estimated.
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
%     If a field MOTION_PARAMETERS_XFM is specified in FILES_IN, the
%     following fields will be ignored  and no transformation will actually be
%     estimated (the one specified by the user is used).
%
%       MOTION_PARAMETERS_XFM (structure of cells of array of strings, default
%           base MOTION_PARAMS_<FILES_IN>_<000I>.XFM)
%           MOTION_PARAMETERS_XFM.<NAME_SESSION>{NUM_D}(NUM_V,:) is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION and volume NUM_VOL. The (rigid-body) transformation
%           is saved in XFM format.
%
%       MOTION_PARAMETERS_DAT (structure of cells of strings,
%           default base MOTION_PARAMS_<BASE_FILE_IN>.DAT)
%           MOTION_PARAMETERS_DAT.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated motion parameters of the dataset NUM_D in session
%           NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       TRANSF_WITHIN_SESSION_DAT (structure of cells of strings,
%           default base TRANS_WS_<FILE_IN>.DAT)
%           TRANSF_WITHIN_SESSION_DAT.<NAME_SESSION>{NUM_D} is the file name for
%           the estimated within-session motion parameters of the dataset
%           NUM_D in session NAME_SESSION. The first line describes the content
%           of each column. Each subsequent line I+1 is a representation
%           of the motion parameters estimated for session I.
%
%       TRANSF_WITHIN_SESSION_XFM (structure of cells of arrays of strings,
%           default base TRANSF_WS_<FILES_IN>_<000I>.XFM).
%           TRANSF_WITHIN_SESSION_XFM.<NAME_SESSION>{NUM_D}(NUM_V,:) is the
%           file name for the estimated within-session motion parameters
%           of the dataset NUM_D in session NAME_SESSION and volume
%           NUM_VOL. Each file is a spatial (rigid-body) transformation in
%           XFM format.
%
%       TRANSF_BETWEEN_SESSION_DAT (cell of strings, default
%           base TRANSF_BS_<name of the first dataset of the session of reference>.DAT)
%           The first line describes the content of each column. Each subsequent
%           line I+1 is a representation of the between-session parameters
%           estimated for session I, i.e. the transformation between the mean volume
%           of the session and the mean volume of the session of reference.
%
%       TRANSF_BETWEEN_SESSION_XFM (cell of strings, default
%           base TRANSF_BS_<name of the first dataset of the session>.DAT)
%           For each session, this is the transformation between the mean volume
%           of the session and the mean volume of the session of reference.
%
%       TRANSF_FUNC2T1  (string, default
%           TRANSF_FUNC2T1_<base of the first dataset in SESSION_REF>.XFM)
%           The transformation between the mean image of the session of
%           reference and the T1 image of the same subject.
%
%   OPT   (structure) with the following fields:
%
%       VOL_REF (vector, default 1) VOL_REF(NUM) is
%           the number of the volume that will be used as target for
%           session NUM. If VOL_REF is a single integer, the same number will be
%           used for all sessions.
%
%       RUN_REF (vector, default 1) RUN_REF(NUM) is
%           the number of the run that will be used as target for
%           each session. Currently, the same number has to be used for 
%           all sessions.
%
%       SESSION_REF (string, default first session) name of the session of
%           reference. By default, it is the first field of
%           FILES_IN.SESSIONS.
%
%       INTERPOLATION (string, default 'trilinear') the spatial
%          interpolation method. Available options : 'trilinear', 'tricubic',
%          'nearest_neighbour', 'sinc'.
%
%       FLAG_SESSION (boolean, default 1) if FLAG_SESSION == 1, the
%          intra-session motion parameters are included in the final transformation.
%          If FLAG_RUN == 0, the intra-session motion parameters are still estimated
%          for quality check, but only the between-session and T1 to fMRI
%           transform only are actually included in the motion parameters.
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
% OUTPUTS:
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% SEE ALSO:
%  NIAK_BRICK_MOTION_CORRECTION, NIAK_DEMO_MOTION_CORRECTION
%
% COMMENTS
% The motion correction follows a hierachical strategy :
% Rigid-body transforms are first estimated within each session
% independently by registering all volumes to one single reference volume.
% Then, the mean image of each session is coregistered with the mean image
% of the session of reference, and the within-session transformation is combined with that
% between-session transformation for each volume. If an anatomical image is
% specified, the mean functional image of the run of reference is co-registered with
% this image, and this additional transformation is added to each volume.
%
% The final motion correction parameters are volume-specific and points to
% the mean volume of reference or the T1 space if specified. The
% intra-session transformations, the transformation between the mean volume
% of each session and the run of reference and the transformation
% between the mean functional of reference and the T1 image can be saved as
% outputs for quality checking.
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
    error('niak_brick_motion_correction, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MOTION_CORRECTION(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_time_filter'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'sessions','t1','motion_parameters_xfm'};
gb_list_defaults = {NaN,'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'motion_corrected_data','motion_parameters_dat','motion_parameters_xfm','transf_within_session_dat','transf_within_session_xfm','transf_between_session_dat','transf_between_session_xfm','transf_func2t1_xfm'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'vol_ref','run_ref','session_ref','flag_session','flag_zip','flag_test','folder_out','interpolation'};
gb_list_defaults = {1,1,'',0,0,0,'','trilinear'};
niak_set_defaults

list_sessions = fieldnames(files_in.sessions);
nb_sessions = length(list_sessions);

if isempty(opt.session_ref)
    opt.session_ref = list_sessions{1};
end

%% Building default output names

flag_def_data = isempty(files_out.motion_corrected_data);
flag_def_mp_dat = isempty(files_out.motion_parameters_dat);
flag_def_mp_xfm = isempty(files_out.motion_parameters_xfm);
flag_def_trans_ws_dat = isempty(files_out.transf_within_session_dat);
flag_def_trans_ws_xfm = isempty(files_out.transf_within_session_xfm);
flag_def_trans_bs_dat = isempty(files_out.transf_between_session_dat);
flag_def_trans_bs_xfm = isempty(files_out.transf_between_session_xfm);
flag_def_trans_func2t1_xfm = isempty(files_out.transf_func2t1_xfm);

if flag_def_data
    files_out.motion_corrected_data = struct([]);
end

if flag_def_mp_dat
    files_out.motion_parameters_dat = struct([]);
end

if flag_def_mp_xfm
    files_out.motion_parameters_xfm = struct([]);
end

if flag_def_trans_ws_dat
    files_out.transf_within_session_dat = struct([]);
end

if flag_def_trans_ws_xfm
    files_out.transf_within_session_xfm = struct([]);
end

if flag_def_trans_bs_dat
    files_out.transf_between_session_dat = cell([nb_sessions 1]);
end

if flag_def_trans_bs_dat
    files_out.transf_between_session_xfm =  cell([nb_sessions 1]);
end

for num_s = 1:length(list_sessions)

    name_session = list_sessions{num_s};
    files_name = getfield(files_in.sessions,name_session);
    nb_files = length(files_name);

    motion_corrected_data = cell([nb_files 1]);
    motion_parameters_dat = cell([nb_files 1]);
    motion_parameters_xfm = cell([nb_files 1]);
    transf_within_session_dat = cell([nb_files 1]);
    transf_within_session_xfm = cell([nb_files 1]);

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

        if flag_def_trans_ws_dat
            transf_ws_dat{num_d} = cat(2,folder_write,filesep,'transf_ws_',name_f,'.dat');
        end

        if flag_def_trans_ws_xfm
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
                    transf_ws_xfm{num_d} = cat(2,folder_write,filesep,'transf_ws_',name_f,'_',strt,'.xfm');
                else
                    transf_ws_xfm{num_d} = char(transf_ws_xfm{num_d},cat(2,folder_write,filesep,'transf_ws_',name_f,'_',strt,'.xfm'));
                end

            end
        end % if flag_def_trans_ws_xfm

        if (flag_def_trans_func2t1_xfm)&strcmp(name_session,opt.session_ref)&(num_d==1)
            files_out.transf_func2t1_xfm = cat(2,folder_write,filesep,'trans_func2t1_',name_f,'.xfm');
        end

        if flag_def_trans_bs_dat&strcmp(name_session,opt.session_ref)&(num_d==1)
            files_out.transf_between_session_dat = cat(2,folder_write,filesep,'transf_bs_',name_f,'.dat');
        end

        if flag_def_trans_bs_xfm&(num_d==1)
            files_out.transf_between_session_xfm{num_s} = cat(2,folder_write,filesep,'transf_bs_',name_f,'.xfm');
        end

    end %loop over datasets

    if flag_def_data
        if num_s == 1
            eval(cat(2,'files_out.motion_corrected_data(1).',name_session,' = motion_corrected_data;'));
        else
            setfield(files_out.motion_corrected_data,name_session,motion_corrected_data);
        end
    end

    if flag_def_mp_dat
        if num_s == 1
            eval(cat(2,'files_out.motion_parameters_dat(1).',name_session,' = motion_parameters_dat;'));
        else
            setfield(files_out.motion_parameters_dat,name_session,motion_parameters_dat);
        end
    end

    if flag_def_mp_xfm
        if num_s == 1
            eval(cat(2,'files_out.motion_parameters_xfm(1).',name_session,' = motion_parameters_xfm;'));
        else
            setfield(files_out.motion_parameters_xfm,name_session,motion_parameters_xfm);
        end
    end

    if flag_def_trans_ws_dat
        if num_s == 1
            eval(cat(2,'files_out.transf_within_session_dat(1).',name_session,' = transf_ws_dat;'));
        else
            setfield(files_out.transf_within_session_dat,name_session,transf_ws_dat);
        end
    end

    if flag_def_trans_ws_xfm
        if num_s == 1
            eval(cat(2,'files_out.transf_within_session_xfm(1).',name_session,' = transf_ws_xfm;'));
        else
            setfield(files_out.transf_within_session_xfm,name_session,transf_ws_xfm);
        end
    end


end % loop over sessions

if flag_test == 1
    return
end

