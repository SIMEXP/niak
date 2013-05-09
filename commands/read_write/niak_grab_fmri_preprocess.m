 function files = niak_grab_fmri_preprocess(path_data,opt)
% Grab files created by NIAK_PIPELINE_FMRI_PREPROCESS
%
% SYNTAX:
% FILES = NIAK_GRAB_FMRI_PREPROCESS(PATH_DATA,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_FMRI_PREPROCESS. 
%
% OPT
%   (structure, optional) with the following fields :
%
%   FLAG_AREAS
%       (boolean, default true) if the flag is true, include the AAL template
%       in FILES_IN.AREAS
%
%   MAX_TRANSLATION
%       (scalar, default Inf) the maximal transition (difference between two
%       adjacent volumes) in translation motion parameters within-run (in 
%       mm). The Inf parameter result in selecting all subjects. Motion is 
%       usually addressed by scrubbing (see MIN_NB_VOL below). 
%
%   MAX_ROTATION
%       (scalar, default Inf) the maximal transition (difference between two
%       adjacent volumes) in rotation motion parameters within-run (in 
%       degrees). The Inf parameter result in selecting all subjects. Motion is 
%       usually addressed by scrubbing (see MIN_NB_VOL below). 
%
%   MIN_NB_VOL
%       (scalar, default 100) the minimum number of volumes to enter a dataset
%       in the analysis. The scrubbing (see NIAK_BRICK_REGRESS_CONFOUNDS) 
%       excludes all time frames that show signs of exccessive motion for all 
%       subjects, yet some subjects may not have enough time points left to 
%       carry on further analysis. 
%
%   MIN_XCORR_FUNC
%       (scalar, default 0.5) the minimal accceptable XCORR measure of
%       spatial correlation between the individual mean functional volume 
%       in non-linear stereotaxic space and the population average.
%
%   MIN_XCORR_ANAT
%       (scalar, default 0.5) the minimal accceptable XCORR measure of
%       spatial correlation between the individual anatomical volume in
%       non-linear stereotaxic space and the population average.
%
%   EXCLUDE_SUBJECT
%       (cell of string, default {}) A list of labels of subjects that will
%       be excluded from the analysis.
%
%   INCLUDE_SUBJECT
%       (cell of string, default {}) if non-empty, a list of the labels of
%       subjects that will be included in the analysis. Ignored if empty.
%
%   FILTER
%       (structure) with the following fields:
%
%       SESSION
%           (cell of strings) a list of session IDs. Only those sessions will
%           be grabbed.
%
%       RUN
%           (cell of strings) a list of RUN IDs. Only those runs will be grabbed.
%
%   TYPE_FILES
%       (string, default 'rest') how to format FILES. This depends of the
%       purpose of subsequent analysis. Available options :
%
%           'rest' : FILES is ready to feed into
%              NIAK_PIPELINE_STABILITY_REST.
%      
%           'roi' : FILES is ready to feed into 
%              NIAK_PIPELINE_REGION_GROWING.
%
%           'fir' : FILES is ready to feed into 
%              NIAK_PIPELINE_STABILITY_FIR
%
%           'glm_connectome' : FILES is ready to feed into 
%              NIAK_PIPELINE_GLM_CONNECTOME.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%   (structure) the exact fields depend on OPT.TYPE_FILES. 
%
%   case 'rest' :
%
%       DATA.(SUBJECT).(SESSION).(RUN)
%           (string) preprocessed fMRI datasets. 
%
%       MASK
%           (string) a file name of a binary mask common 
%           to all subjects and runs. The mask is the file located in 
%           quality_control/group_coregistration/anat_mask_group_stereonl.<
%           ext>
%
%       AREAS
%           (string) a file name of an AAL parcelation into anatomical regions
%           resampled at the same resolution as the fMRI datasets. 
%
%   case {'roi','fir'}: 
%
%       FMRI.(SUBJECT).(SESSION).(RUN)
%           (string) the preprocessed fMRI dataset for subject SUBJECT, session SESSION
%           and run RUN
%
%       MASK, AREAS: same as for 'rest'
%
%   case 'glm_connectome'
%   
%       same as for 'roi', but without MASK and AREAS
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY_REST, NIAK_PIPELINE_REGION_GROWING
% NIAK_PIPELINE_STABILITY_FIR, NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" is designed to work with the pipelines mentioned in
% the "SEE ALSO" section, based on the output folder of 
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series

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

%% Default path for the database
if (nargin<1)||isempty(path_data)
    path_data = [pwd filesep];
end

if ~strcmp(path_data(end),filesep)
    path_data = [path_data filesep];
end

%% Default options
list_fields   = { 'filter' , 'flag_areas' , 'min_nb_vol' , 'max_translation' , 'max_rotation' , 'min_xcorr_func' , 'min_xcorr_anat' , 'exclude_subject' , 'include_subject' , 'type_files' };
list_defaults = { struct   , true         , 100          , Inf               , Inf            , 0.5              , 0.5              , {}                , {}                , 'rest'       };
if nargin > 1
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end

%% Default filters
list_fields   = { 'session' , 'run' };
list_defaults = { {}        , {}    };
opt.filter = psom_struct_defaults(opt.filter,list_fields,list_defaults);

%% Grab the list of subjects
path_qc = [path_data 'quality_control' filesep];
list_qc = dir(path_qc);
nb_subject = 0;
for num_q = 1:length(list_qc)
    if ~ismember(list_qc(num_q).name,{'group_motion','group_coregistration','group_confounds','group_corsica','.','..'})&&list_qc(num_q).isdir
        nb_subject = nb_subject + 1;
        list_subject{nb_subject} = list_qc(num_q).name;
    end
end
mask_keep = false([nb_subject 1]);

%% check max motion
file_motion = [path_qc 'group_motion' filesep 'qc_motion_group.csv'];
[tab_motion,labx,laby] = niak_read_csv(file_motion);
mask_keep = true(nb_subject,1);
if (opt.max_translation<Inf)||(opt.max_rotation<Inf)
for num_s = 1:nb_subject
    ind_s = find(ismember(labx,list_subject{num_s}));
    if ~isempty(ind_s)
    	tsl   = tab_motion(ind_s,2);
    	rot   = tab_motion(ind_s,1);
    	flag_keep = (tsl<opt.max_translation)&&(rot<opt.max_rotation)||ismember(list_subject{num_s},opt.include_subject);
    	if ~flag_keep
            fprintf('Subject %s was excluded because of excessive motion\n',list_subject{num_s});
    	end
    	mask_keep(num_s) = flag_keep;
    else
	fprintf('I could not find subject %s for quality control of max motion (rotation)\n',list_subject{num_s});
    end    
end
end

%% Check the amount of time frames
file_scrub = [path_qc 'group_motion' filesep 'qc_scrubbing_group.csv'];
[tab_scrub,labx_scrub,laby_scrub] = niak_read_csv(file_scrub);
for num_s = 1:nb_subject
    ind_r = regexp(labx_scrub,['^' list_subject{num_s} '_']);
    ind_r = find(cellfun(@length,ind_r,'UniformOutput',true)>0);
    mask_scrub.(list_subject{num_s}) = struct();
    if ~isempty(ind_r)
        for num_r = 1:length(ind_r)
            flag_keep = (tab_scrub(ind_r(num_r),2)>=opt.min_nb_vol)||ismember(list_subject{num_s},opt.include_subject);
    	    if ~flag_keep
                fprintf('Dataset %s was excluded because there were not enough time samples (%i) \n',labx_scrub{ind_r(num_r)},tab_scrub(ind_r(num_r),2));
            else
                mask_scrub.(list_subject{num_s}).(labx_scrub{ind_r(num_r)}) = true;
    	    end
        end
    else
	fprintf('I could not find subject %s for quality control of number of time frames\n',list_subject{num_s});
    end    
end

%% Check functional coregistration
file_regf = [path_qc 'group_coregistration' filesep 'func_tab_qc_coregister_stereonl.csv'];
[tab_regf,labx,laby] = niak_read_csv(file_regf);
for num_s = 1:nb_subject
    ind_s = find(ismember(labx,list_subject{num_s}));
    corrf = tab_regf(ind_s,2);   
    flag_keep = (corrf>opt.min_xcorr_func);
    if ~flag_keep&&isempty(opt.include_subject)
        fprintf('Subject %s was excluded because of poor functional coregistration\n',list_subject{num_s});
    end
    if ~isempty(flag_keep)
        mask_keep(num_s) = mask_keep(num_s) & flag_keep;
    else
        fprintf('I could not find subject %s for quality control of functional coregisration \n',list_subject{num_s});
    end
end

%% Check anatomical coregistration
file_rega = [path_qc 'group_coregistration' filesep 'anat_tab_qc_coregister_stereonl.csv'];
[tab_rega,labx,laby] = niak_read_csv(file_rega);
for num_s = 1:nb_subject
    ind_s = find(ismember(labx,list_subject{num_s}));
    corrf = tab_rega(ind_s,2);    
    flag_keep = (corrf>opt.min_xcorr_anat);
    if ~flag_keep&&isempty(opt.include_subject)
        fprintf('Subject %s was excluded because of poor anatomical coregistration\n',list_subject{num_s});
    end
    if ~isempty(flag_keep)
        mask_keep(num_s) = mask_keep(num_s) & flag_keep;
    else
        fprintf('I could not find subject %s for quality control of anatomical coregisration \n',list_subject{num_s});
    end
end

%% User forces removing of a list of subject
mask_keep(ismember(list_subject,opt.exclude_subject)) = false;
for num_s = 1:length(opt.exclude_subject)
    fprintf('User manually forced the exclusion of subject %s \n',opt.exclude_subject{num_s});
end

%% Select the subjects
if ~isempty(opt.include_subject)
    list_subject = opt.include_subject;
else
    list_subject = list_subject(mask_keep);    
end
nb_subject = length(list_subject);

%% generate file names
path_fmri = [path_data 'fmri' filesep];
files_fmri = dir(path_fmri);
files_fmri = {files_fmri.name};
for num_s = 1:nb_subject
    list_files_s = fieldnames(mask_scrub.(list_subject{num_s}));
    if isempty(list_files_s)
        continue
    end
    nb_f = 0;
    for num_f = 1:length(list_files_s)
        mask_s = ~cellfun('isempty',regexp(files_fmri,['^fmri_' list_files_s{num_f} '.']));    
        if any(mask_s)
            files_tmp = files_fmri(mask_s);
            [path_f,name_f,ext_f] = niak_fileparts(files_tmp{1});
            name_f = name_f((7+length(list_subject{num_s})):end);
            pos_sep = strfind(name_f,'_');
            run = name_f((pos_sep(end)+1):end);
            session = name_f(1:(pos_sep(end)-1));
            if ~isempty(opt.filter.session) && ~ismember(session,opt.filter.session)
                continue
            end
            if ~isempty(opt.filter.run) && ~ismember(run,opt.filter.run)
                continue
            end
            nb_f = nb_f+1;
            if ismember(opt.type_files,{'roi','glm_connectome','fir'})
                files.fmri.(list_subject{num_s}).(session).(run) = [path_fmri files_tmp{1}];
            elseif strcmp(opt.type_files,'rest')
                files.data.(list_subject{num_s}).(session).(run) = [path_fmri files_tmp{1}];            
            else
                error('%s is an unsupported type of output format for the files structure')            
            end
        else
            error('I could not find any fMRI preprocessed datasets for subject %s',list_subject{num_s});        
        end
    end
end
if ~strcmp(opt.type_files,'glm_connectome')
    files.mask = dir([path_qc 'group_coregistration' filesep 'func_mask_group_stereonl.*']);
    if isempty(files.mask)
        error('Could not find the group-level mask for functional data')
    end
    files.mask = [path_qc 'group_coregistration' filesep files.mask(1).name];
    if opt.flag_areas
        files.areas = dir([path_data 'anat' filesep 'template_aal.*']);
        if isempty(files.mask)
            error('Could not find the AAL parcelation for functional data')
        end
        files.areas = [path_data 'anat' filesep files.areas(1).name];
    end
end