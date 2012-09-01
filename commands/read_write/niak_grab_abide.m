function files = niak_grab_abide(path_data)
% Grab the T1+fMRI datasets of the ABIDE database to process with the 
% NIAK fMRI preprocessing.
%
% SYNTAX:
% FILES = NIAK_GRAB_ABIDE(PATH_DATA,FILTER)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to one site of 
%   the ABIDE dataset
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
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" is designed to work with the ABIDE database:
% 
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2012.
% Maintainer : pbellec@criugm.qc.ca
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

if (nargin < 1)||isempty(path_data)
    path_data = [pwd filesep];
end
if ~strcmp(path_data(end),filesep);
    path_data = [path_data filesep];
end

list_files = dir([path_data]);
for num_f = 1:length(list_files)
    if list_files(num_f).isdir
        path_subj = [path_data list_files(num_f).name filesep];
        subject = list_files(num_f).name;
        if ~isempty(regexp(subject,'^\d'))
            subject = ['X' subject];
        end
        list_sessions = dir([path_subj]);
        for num_s = 1:length(list_sessions)
            if list_sessions(num_s).isdir&&~isempty(regexp(list_sessions(num_s).name,'^session'))
                session = list_sessions(num_s).name;
                path_session = [path_subj session filesep];
                files_anat = {[path_session filesep 'anat_1' filesep 'mprage_noface.mnc.gz'],[path_session filesep 'anat_1' filesep 'mprage_noface.mnc'],[path_session filesep 'anat_1' filesep 'mprage_noface.nii.gz'],[path_session filesep 'anat_1' filesep 'mprage_noface.nii'],[path_session filesep 'anat_1' filesep 'mprage.mnc.gz'],[path_session filesep 'anat_1' filesep 'mprage.mnc'],[path_session filesep 'anat_1' filesep 'mprage.nii'],[path_session filesep 'anat_1' filesep 'mprage.nii.gz']};
                flag_exist = false;
		for num_a = 1:length(files_anat)
                    if psom_exist(files_anat{num_a})
                        file_anat = files_anat{num_a};
                        flag_exist = true;
                    end
                end 
                if ~flag_exist
                    warning('Subject %s was excluded because no anatomical file could not be found',subject);
                end
                
                if flag_exist
                    files.(subject).anat = file_anat;
                
                list_runs = dir(path_session);
                nb_runs = 0;
                for num_r = 1:length(list_runs)
                    if list_runs(num_r).isdir&&~isempty(regexp(list_runs(num_r).name,'^rest'))
                        nb_runs = nb_runs+1;
                        file_rest = [path_session list_runs(num_r).name filesep 'rest.mnc.gz'];
                        flag_exist = true;
                        if ~psom_exist(file_rest)
                            file_rest = [path_session list_runs(num_r).name filesep 'rest.nii.gz'];
                            if ~psom_exist(file_rest)
                                warning('Subject %s session %s run %s was excluded because the resting-state file could not be found',subject,session,list_runs(num_r).name);
                                flag_exist = false;                        
                            end
                        end
                        if flag_exist
                            files.(subject).fmri.(session){nb_runs} = file_rest;
                        end
                    end
                end
            end
        end
    end
end
end