function [files_in,files_out,opt] = niak_brick_qc_motion_correction_group(files_in,files_out,opt)
% Derive group measures of quality control for fMRI motion correction.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_MOTION_CORRECTION_GROUP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields : 
%
%   FILES_IN.<SUBJECT>.TAB_COREGISTER_IND
%       (string) a CSV file with "xcorr" and "perc_overlap" measures of
%       between-runs coregistration. All these measures should correspond
%       to one subject (label <SUBJECT>). 
%
%   FILES_IN.<SUBJECT>.MOTION_PARAMETERS_IND
%       (cell of string) multiple file names of .mat files including one
%       variable TRANSF, such that TRANSF(:,:,I) is an estimated rigid-body
%       motion. All these parameters should correspond to one subject 
%       (label <SUBJECT>). 
%
% FILES_OUT
%   (structure) with the following fields :
%
%   TAB_COREGISTER_GROUP
%       (string) A CSV file with a summary of minimal xcorr and relative
%       overlap scores for each subject.
%
%   FIG_COREGISTER_GROUP
%       (string) A pdf "bar" representation of TAB_COREGISTER_GROUP.
%
%   TAB_MOTION_GROUP
%       (string) a CSV file with maximal displacement in rotation or
%       translation parameters for each subject.
%
%   FIG_MOTION_GROUP
%       (string) A pdf "bar" representation of TAB_MOTION_GROUP.
%
% OPT
%   (structure) with the following fields.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_MOTION_CORRECTION, NIAK_BRICK_QC_MOTION_CORRECTION_IND,
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : quality control, fMRI, pipeline.

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
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_COREGISTER(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_qc_coregister'' for more info.')
end

%% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a structure');
end
list_subject = fieldnames(files_in);
nb_subject = length(list_subject);
for num_s = 1:nb_subject
    subject = list_subject{num_s};
    if ~isfield(files_in.(subject),'tab_coregister_ind')
        error(sprintf('FILES_IN.%s is missing the TAB_COREGISTER_IND field',subject));
    end
    if ~isfield(files_in.(subject),'motion_parameters_ind')
        error(sprintf('FILES_IN.%s is missing the MOTION_PARAMETERS_IND field',subject));
    end
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields    = {'tab_coregister_group' , 'fig_coregister_group' , 'tab_motion_group' , 'fig_motion_group' };
gb_list_defaults  = {NaN                    , NaN                    , NaN                , NaN                };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_verbose' , 'flag_test' };
gb_list_defaults  = {true           , false       };
niak_set_defaults

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group coregistration table %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Building a summary table of between-runs coregistration quality measures ...\n     ')
end

tab_group = zeros([nb_subject 2]);
for num_s = 1:nb_subject
    subject = list_subject{num_s};
    if flag_verbose
        fprintf('%s - ',subject);
    end
    tab_ind = niak_read_csv(files_in.(subject).tab_coregister_ind);
    tab_group(num_s,:) = min(tab_ind,[],1);
end
if flag_verbose
    fprintf('\n');
end
opt_csv.labels_x = list_subject;
opt_csv.labels_y = {'perc_overlap_mask','xcorr_vol'};
niak_write_csv(files_out.tab_coregister_group,tab_group,opt_csv);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group coregistration figure %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Saving the group between-run coregistration quality measures as a figure.\n     %s\n',files_out.fig_coregister_group);
end
file_fig = niak_file_tmp('.eps');
hf = figure;
ha = gca;
barh(tab_group);
axis([min(tab_group(:)) max(min(tab_group(:))+0.01,max(tab_group(:))) 0 max(length(list_subject),2)+1]);
set(ha,'yticklabel',list_subject)
legend({'perc_overlap_mask','xcorr_vol'});
print(file_fig,'-depsc2');

instr_ps2pdf = cat(2,'ps2pdf -dEPSCrop ',file_fig,' ',files_out.fig_coregister_group);
[succ,msg] = system(instr_ps2pdf);
if succ~=0
    warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf : ',msg));
end
delete(file_fig)
close(hf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group motion parameters table %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Building a summary table of within-run maximal motion ...\n     ')
end
tab_group = zeros([nb_subject 2]);
for num_s = 1:nb_subject
    subject = list_subject{num_s};
    if flag_verbose
        fprintf('%s - ',subject);
    end
    nb_run = length(files_in.(subject).motion_parameters_ind);
    for num_r = 1:nb_run
        data = load(files_in.(subject).motion_parameters_ind{num_r});
        rot = zeros([size(data.transf,3) 3]);
        tsl = zeros([size(data.transf,3) 3]);
        for num_v = 1:size(data.transf,3);
            [rot(num_v,:),tsl(num_v,:)] = niak_transf2param(data.transf(:,:,num_v));
        end
        rot = diff(rot);
        tsl = diff(tsl);
        tab_group(num_s,:) = max(tab_group(num_s,:),[max(abs(rot(:))) max(abs(tsl(:)))]);
    end
end

if flag_verbose
    fprintf('\n');
end
opt_csv.labels_x = list_subject;
opt_csv.labels_y = {'max_rotation','max_translation'};
niak_write_csv(files_out.tab_motion_group,tab_group,opt_csv);

%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group motion figure %%
%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Saving the group maximal motion quality measures as a figure %s ...\n',files_out.fig_motion_group);
end
file_fig = niak_file_tmp('.eps');
hf = figure;
ha = gca;
barh(tab_group);
axis([min(tab_group(:)) max(min(tab_group(:))+0.01,max(tab_group(:))) 0 max(length(list_subject),2)+1]);
set(ha,'ytick',1:length(list_subject));
set(ha,'yticklabel',list_subject)
legend({'max transition in rotation (degree)','max transition in translation (mm)'});
print(file_fig,'-depsc2');

instr_ps2pdf = cat(2,'ps2pdf -dEPSCrop ',file_fig,' ',files_out.fig_motion_group);
[succ,msg] = system(instr_ps2pdf);
if succ~=0
    warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf : ',msg));
end
delete(file_fig)
close(hf);