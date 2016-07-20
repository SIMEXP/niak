function files = niak_grab_bids(path_data,opt)
% Grab the T1+fMRI datasets of BIDS (http://bids.neuroimaging.io/) database to process with the 
% NIAK fMRI preprocessing.
%
% SYNTAX:
% FILES = NIAK_GRAB_BIDS(PATH_DATA,FILTER)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to one site of 
%   a BIDS dataset
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%   (structure) with the following fields, ready to feed into 
%   NIAK_PIPELINE_FMRI_PREPROCESS :
%
%   FILES_IN  
%      (structure) with the following fields : 
%
%       <SUBJECT>.FMRI.<SESSION>   
%          (cell of strings) a list of fMRI datasets, acquired in the 
%          same session (small displacements). 
%          The field names <SUBJECT> and <SESSION> can be any arbitrary 
%          strings.
%
%      <SUBJECT>.ANAT 
%          (string) anatomical volume, from the same subject as in 
%          FILES_IN.<SUBJECT>.FMRI
% OPT 
%   (structure) grabber options
%    
%   FMRI_HINT
%       (string) A hint to pick one out of many fmri input for exemple 
%       if the fmri study includes "sub-XX_task-rest-somthing_bold.nii.gz" 
%       and "sub-XX_task-rest-a_thing_bold.nii.gz" and the somthing flavor 
%       needs to be selected, FMRI_HINT = 'somthing', would do the trick.
%       Note that FMRI_HINT needs to be a string somewhere between 
%       "task-rest" and the extention (.nii or .mnc)
%
%   ANAT_HINT
%       (string) A hint to pick one out of many anat input. I only one file
%       is present it will be used by default. If no hint is give an on file
%       with T1 is given this file will be picked. If two file are present,
%       "sub-11_T1.nii.gz" and "sub-11_T1w.nii.gz" and you need to select the
%       "sub-11_T1.nii.gz" then the hint "T1."  will do the trick. 
%   TASK_TYPE
%       (string, default = rest) The type of task, explicitely name in bids 
%       file name
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" is designed to work with the ABIDE database:
% 
% Copyright (c) Pierre Bellec, P-O Quirion
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2012.
% Maintainer : poq@criugm.qc.ca
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

% If no path given, search local dir
if (nargin < 1)||isempty(path_data)
    path_data = [pwd filesep];
elseif nargin < 2
    opt = struct;
end

if ~isdir(path_data)
    error('Bid directory does not exist: %s', path_data)
end


if ~strcmp(path_data(end),filesep);
    path_data = [path_data filesep];
end

if ~isfield(opt,'fmri_hint')
    fmri_hint = ''
else
    fmri_hint = regexptranslate('escape', opt.fmri_hint)
end

if ~isfield(opt,'anat_hint')
    anat_hint = ''
else
    anat_hint = regexptranslate('escape', opt.anat_hint)
end

if ~isfield(opt,'task_type')
    task_type = "rest"
else
    task_type = opt.task_type
end


list_dir = dir(path_data);
file_in = struct;
for num_f = 1:length(list_dir)

    if list_dir(num_f).isdir && ~strcmpi(list_dir(num_f).name, '.') ...
       && ~strcmpi(list_dir(num_f).name, '..')
        subject_dir = list_dir(num_f).name;
        dir_name = regexpi(subject_dir,"(sub-(.*))", 'tokens');
        if ~isempty(dir_name)
            sub_id = dir_name{1}{1,2};
        else
            continue   
        end   

        list_sub_dir = dir([path_data, subject_dir]);
        all_sessions = {}
        for n_ses = 1:length(list_sub_dir)
            subdir_name = regexp(list_sub_dir(n_ses).name,"(ses-(.*))", 'tokens');
            if ~isempty(subdir_name)
                all_sessions = [all_sessions; (subdir_name{1})];
            end
        end

        if isempty(all_sessions);
            % no session dir means only one session
            all_sessions = {'0'};
        end

%        add session and sub numbers   a 
        for n_ses = 1:length(all_sessions)
            if all_sessions{1} == '0'
                session_path = strcat(path_data, subject_dir)
                session_id = "1"
                no_session = true
            else
                ses_name = all_sessions(n_ses,1){1}            
                session_id = all_sessions(n_ses,2){1}
                session_path = strcat(path_data, subject_dir, filesep, ses_name)
                no_session = false
            end

            anat_path = strcat(session_path, filesep, 'anat')
            fmri_path = strcat(session_path, filesep, 'func')
            fmri_regex = [ "(", subject_dir ".*task-", task_type ,".*" "\.(nii|mnc).*)"]
            anat_regex = ['(', subject_dir, '_.*', anat_hint, '.*\.(nii|mnc).*)']
            list_anat_dir = dir(anat_path) ;
            list_fmri_dir = dir(fmri_path) ;
            
            anat_match = {}
            for n_f = 1:length(list_anat_dir)
                m = regexpi(list_anat_dir(n_f).name, anat_regex, 'tokens')
                if ~isempty(m)
                    anat_match = [ anat_match; m{1}];
                end
            end
            fmri_match = {}
            for n_f = 1:length(list_fmri_dir)
                m = regexpi(list_fmri_dir(n_f).name, fmri_regex, 'tokens')
                if ~isempty(m)
                    fmri_match = [fmri_match; m{1}];
                end
            end

            if length(fmri_match)
                fmri.(session_id) = fmri_match{1}            
            end
                                                                
        end      

        if length(anat_match)             
            anat= anat_match{1}
        end

        %% fiters 
        % only resurt subject is anat and one func is found        
        for n_ses = 1:length(all_sessions)
            if no_session
                session_id = "1"
            else
                session_id = all_sessions(n_ses,2){1}
            end

            if exist('anat') && exist('fmri')
                file_in.(subject_dir).anat = anat
                file_in.(subject_dir).fmri.(session_id) = fmri.(session_id)
            end 
        end
    end
end
       
files.file_in = file_in


#    path_subj = [path_data list_files(num_f).name filesep];
#        subject = list_files(num_f).name;
#        if ~isempty(regexp(subject,'^\d'));
#            subject = ['X' subject];
#        end
#        list_sessions = dir([path_subj]);
#        for num_s = 1:length(list_sessions)
#            if list_sessions(num_s).isdir&&~isempty(regexp(list_sessions(num_s).name,'^session'))
#                session = list_sessions(num_s).name;
#                path_session = [path_subj session filesep];
#                files_anat = {[path_session filesep 'anat_1' filesep 'mprage_noface.mnc.gz'],[path_session filesep 'anat_1' filesep 'mprage_noface.mnc'],[path_session filesep 'anat_1' filesep 'mprage_noface.nii.gz'],[path_session filesep 'anat_1' filesep 'mprage_noface.nii'],[path_session filesep 'anat_1' filesep 'mprage.mnc.gz'],[path_session filesep 'anat_1' filesep 'mprage.mnc'],[path_session filesep 'anat_1' filesep 'mprage.nii'],[path_session filesep 'anat_1' filesep 'mprage.nii.gz']};
#                flag_exist = false;
#		for num_a = 1:length(files_anat)
#                    if psom_exist(files_anat{num_a})
#                        file_anat = files_anat{num_a};
#                        flag_exist = true;
#                    end
#                end 
#                if ~flag_exist
#                    warning('Subject %s was excluded because no anatomical file could not be found',subject);
#                end
                
#                if flag_exist
#                    files.(subject).anat = file_anat;
                
#                list_runs = dir(path_session);
#                nb_runs = 0;
#                for num_r = 1:length(list_runs)
#                    if list_runs(num_r).isdir&&~isempty(regexp(list_runs(num_r).name,'^rest'))
#                        nb_runs = nb_runs+1;
#                        file_rest = [path_session list_runs(num_r).name filesep 'rest.mnc.gz'];
#                        flag_exist = true;
#                        if ~psom_exist(file_rest)
#                            file_rest = [path_session list_runs(num_r).name filesep 'rest.nii.gz'];
#                            if ~psom_exist(file_rest)
#                                warning('Subject %s session %s run %s was excluded because the resting-state file could not be found',subject,session,list_runs(num_r).name);
#                                flag_exist = false;                        
#                            end
#                        end
#                        if flag_exist
#                            files.(subject).fmri.(session){nb_runs} = file_rest;
#                        end
#                    end
#                end
#            end
#        end
#    end
#end
#end