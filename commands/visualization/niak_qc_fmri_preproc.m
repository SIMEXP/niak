function [] = niak_qc_fmri_preproc(opt)
% Quality control of the results of the fMRI preprocessing pipeline
%
% SYNTAX:
% [] = NIAK_QC_FMRI_PREPROC( OPT )
%
% _________________________________________________________________________
% INPUTS:
%
% OPT
%   (structure) with the following fields:
%
%   PATH_QC
%      (string, default current folder) the folder where the results of the 
%      fMRI preprocessing pipeline are located
%
%   LIST_SUBJECT
%      (string or cell of strings, default all subjects) the ID of the subject
%
%   TYPE_ORDER
%      (string, default 'xcorr_func') the metric that is used to order subjects
%      Available options:
%      'xcorr_func' : the spatial correlation between the individual average 
%         functional volume and the group average
%      'xcorr_anat' : the spatial correlation between the individual structural
%         volume and the group average
%      'alpha' : the alphabetical order
%
%   FLAG_RESTART
%      (boolean, default false) restart the QC of subjects which have already
%      a complete entry in the QC report. 
%
%   TEMPLATE_ASYM
%      (boolean, default false) select betewen symetric(false) or asymetric(true)
%      anatomical template (mni_icbm152_t1_tal_nlin)
%   TAG_FILE
%      (string, Default 'template_qc_tag.tag') sepcifie the MNI tags point file 
%       that list a word coordinate of tag brain regions
%
%   FLAG_LINEAR
%      (boolean, default false) option to grab the linear files when the 
%      preprocessing is executed with the option for target output at linear 
%      instead of non-linear.
%
% _________________________________________________________________________
% OUTPUTS:
%
% None
%           
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% This tool for quality control depends on the "register" visualization tool,
% which is part of the MINC tools. This will work only with images in the 
% MINC format. The following coregistration are presented for each subject:
%    * T1 scan in stereotaxic space vs the anatomical template
%    * T1 scan in stereotaxic space vs average functional scan in stereotaxic space
% Scans are co-registered with a non-linear transformation. 
%
% The function interactively asks for feedback in the command line. The results 
% are stored in a file "qc_report.csv" in PATH_QC. Unless OPT.FLAG_RESTART is 
% specified, subjects for which the QC has been completed will not be
% re-assessed.
%
% _________________________________________________________________________
% Copyright (c) Yassine Benhajali, Pierre Bellec
% Centre de recherche de l'institut de griatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qbec, Canada, 2013-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI preprocessing, quality control

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

%% Set default options
list_fields   = { 'type_order' , 'path_qc' , 'list_subject' , 'flag_restart' , 'template_asym'  , 'tag_file', 'flag_linear'};
list_defaults = { 'xcorr_func' , pwd       , {}             , false          , false            , ''        , false};
if nargin == 0
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Set default for the path for QC
path_qc = niak_full_path(opt.path_qc);

%% Grab the results of the fMRI preprocessing pipeline
files = niak_grab_all_preprocess(path_qc);

% set the tag file
niak_gb_vars
if isempty(opt.tag_file) && exist([ gb_niak_path_template 'qc_tag_template.tag' ] )
    opt.tag_file =  ( [ gb_niak_path_template 'qc_tag_template.tag' ] );
elseif ~exist( opt.tag_file)
    error('The tag files %s does not exist' , opt.tag_file)
else
    error('No tag file found')    
end

%% Set default for the list of subjects
list_subject = opt.list_subject;

if ischar(list_subject)
   list_subject = {list_subject};
end

if isempty(list_subject)
    list_subject = fieldnames(files.fmri.vol);
end

%% Look for an existing QC report
file_qc = [path_qc 'qc_report.csv'];
if psom_exist(file_qc)
    qc_report = niak_read_csv_cell(file_qc);  
    if size(qc_report,1) < size(list_subject,1)+1 
       % add new subjects to the current qc_report
       new_qc_report = sub_init_report(list_subject);
       for i = 2:size(new_qc_report,1)
           idx = find(ismember(qc_report(:,1),new_qc_report(i)));
           if ~isempty(idx)	
              new_qc_report(i,:) = qc_report(idx,:);
           end
       end
    qc_report = new_qc_report;
    end
else         
    qc_report = sub_init_report(list_subject);
end

%% Sort subjects by selected option
if opt.flag_linear==true                                                                                                                                                         
    [xcorr_func,lxf,lyf] = niak_read_csv(files.quality_control.group_coregistration.func.stereolin.csv);
else
    [xcorr_func,lxf,lyf] = niak_read_csv(files.quality_control.group_coregistration.func.csv);
end
xcorr_func = xcorr_func(:,2);
if opt.flag_linear==true
    [xcorr_anat,lxa,lya] = niak_read_csv(files.quality_control.group_coregistration.anat.stereolin.csv);
else
    [xcorr_anat,lxa,lya] = niak_read_csv(files.quality_control.group_coregistration.anat.stereonl.csv);
end
xcorr_anat = xcorr_anat(:,2);
switch opt.type_order
case 'xcorr_func'
    [mask_sub,ind_sub] = ismember(list_subject,lxf);
    if any(~mask_sub)
        ind = find(~mask_sub);        
        error('Some subjects (e.g. %s) could not be found in the xcorr_func file %s',list_subject{ind(1)},files.quality_control.group_coregistration.func.csv)
    end
    xcorr_func = xcorr_func(ind_sub);
    [val,order] = sort(xcorr_func);
    order = order(:)';
case 'xcorr_anat'
    [mask_sub,ind_sub] = ismember(list_subject,lxa);
    if any(~mask_sub)
        ind = find(~mask_sub);        
        error('Some subjects (e.g. %s) could not be found in the xcorr_func file %s',list_subject{ind(1)},files.quality_control.group_coregistration.func.csv)
    end
    xcorr_anat = xcorr_anat(ind_sub);
    [val,order] = sort(xcorr_anat); 
    order = order(:)';
case 'alpha'
    order = (1:length(list_subject))';
otherwise
    error('%s is not a supported ordering of subjects', opt.type_order);
end
    
%% The template file 
niak_gb_vars
if ~opt.template_asym
  file_template = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a.mnc.gz'];
else
  file_template = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_asym_09a.mnc.gz'];
end
   
%% Loop over subjects 
for num_s = order

    % Initialize the report    
    subject = list_subject{num_s};           
    fprintf('\nQuality control of Subject %s, xcorr anat = %1.3f, xcorr func = %1.3f\n' ,subject,xcorr_anat(num_s),xcorr_func(num_s))
    if ~opt.flag_restart && ~isempty(qc_report{num_s+1,2})
        fprintf('    Skipping, QC report already completed\n',subject)            
        continue
    end        
    
    if isempty(qc_report{num_s+1,2})
        qc_tmp = { 'OK' , 'OK' , 'None' , 'OK' , 'None' };
    else
        qc_tmp = qc_report(num_s+1,2:end);
    end    
    
    %% Coregister T1 with template
    if ~isfield(files.anat,subject)
        error('I could not find subject %s in the preprocessing',subject)
    end
    if opt.flag_linear==true                                                                                                                                                     
        file_anat = files.anat.(subject).t1.nuc_stereolin; % The individual T1 scan in (linear) stereotaxic space
    else
        file_anat = files.anat.(subject).t1.nuc_stereonl; % The individual T1 scan in (non-linear) stereotaxic space
    end
    if ~psom_exist(file_anat)
        error('I could not find the anatomical scan %s in stereotaxic space for subject %s',file_anat,subject)
    end    
    if opt.flag_linear==true                                                                                                                                                     
        fprintf('    Individual T1 scan in stereotaxic (linear) space, against the MNI template\n')
    else
        fprintf('    Individual T1 scan in stereotaxic (non-linear) space, against the MNI template\n')
    end
    [status,msg] = niak_register(file_template , file_anat , [opt.tag_file  ' -global Initial_volumes_synced True']);   
    
    if status ~=0
        error('There was an error calling register. The call was: %s ; The error message was: %s',call_ref,msg)
    end
    
    % Get the input from the user
    flag_ok = false;
    while ~flag_ok
        qc_input = input(sprintf('        ([O]K / [M]aybe / [F]ail / e[X]it), Default "%s": ',qc_tmp{2}),'s');
        flag_ok = ismember(qc_input,{'OK','O','Maybe','M','Fail','F','X',''});
        if ~flag_ok
            fprintf('        The status should be O , M , F or X\n')
        end
    end
    switch qc_input
        case {'OK','O'}
            qc_report{num_s+1,3} = 'OK';
        case {'Maybe','M'}
            qc_report{num_s+1,3} = 'Maybe';
        case {'Fail','F'}
            qc_report{num_s+1,3} = 'Fail';        
        case {'X'}
            return
        case ''
            qc_report{num_s+1,3} = qc_tmp{2};
    end
    flag_ok = false;
    while ~flag_ok
        qc_comment = input(sprintf('        Comment, Default "%s": ',qc_tmp{3}),'s');
        flag_ok = isempty(findstr(qc_comment,','));
        if ~flag_ok
            fprintf('        No comma allowed\n')
        end
    end
    if isempty(qc_comment)
        qc_report{num_s+1,4} = qc_tmp{3};
    else
        qc_report{num_s+1,4} = qc_comment;
    end    
    
    % Coregister T1 with functional image
    if opt.flag_linear==true                                                                                                                                                     
        file_func = files.anat.(subject).func.mean_stereolin;
    else
        file_func = files.anat.(subject).func.mean_stereonl;
    end
    if ~psom_exist(file_func)
        error('I could not find the mean functional scan %s in stereotaxic space for subject %s',file_func,subject)
    end
    
    [status,msg] = niak_register(file_func , file_anat , [opt.tag_file  ' -global Initial_volumes_synced True']); 
    if status ~=0
        error('There was an error calling register. The call was: %s ; The error message was: %s',call_ref,msg)
    end
    
    % Get the input from the user
    flag_ok = false;
    while ~flag_ok
        qc_input = input(sprintf('        ([O]K / [M]aybe / [F]ail / e[X]it), Default "%s": ',qc_tmp{4}),'s');
        flag_ok = ismember(qc_input,{'OK','O','Maybe','M','Fail','F','X',''});
        if ~flag_ok
            fprintf('        The status should be O , M , F or X\n')
        end
    end
    switch qc_input
        case {'OK','O'}
            qc_report{num_s+1,5} = 'OK';
        case {'Maybe','M'}
            qc_report{num_s+1,5} = 'Maybe';
        case {'Fail','F'}
            qc_report{num_s+1,5} = 'Fail';   
        case {'X'}
            return
        case ''
            qc_report{num_s+1,5} = qc_tmp{4};
    end
    flag_ok = false;
    while ~flag_ok
        qc_comment = input(sprintf('        Comment, Default "%s": ',qc_tmp{5}),'s');
        flag_ok = isempty(findstr(qc_comment,','));
        if ~flag_ok
            fprintf('        No comma allowed\n')
        end
    end
    if isempty(qc_comment)
        qc_report{num_s+1,6} = qc_tmp{5};
    else
        qc_report{num_s+1,6} = qc_comment;
    end
    
    % Final status
    if strcmp(qc_report{num_s+1,3},'Fail')||strcmp(qc_report{num_s+1,5},'Fail')
        qc_report{num_s+1,2} = 'Fail';
    elseif strcmp(qc_report{num_s+1,3},'Maybe')||strcmp(qc_report{num_s+1,5},'Maybe')
        qc_report{num_s+1,2} = 'Maybe';
    else 
        qc_report{num_s+1,2} = 'OK';
    end
    
    %% Save the report
    niak_write_csv_cell(file_qc,qc_report);
end
    
function qc_report = sub_init_report(list_subject)
    %% Initialize the QC report
    qc_report = cell(length(list_subject)+1,6);
    qc_report(2:end,1) = list_subject;
    qc_report(1) = 'id_subject';
    qc_report(1,2) = 'status';
    qc_report(1,3) = 'anat';
    qc_report(1,4) = 'comment_anat';
    qc_report(1,5) = 'func';
    qc_report(1,6) = 'comment_func';
    qc_report(2:end,2:end) = repmat({''},[length(list_subject),5]);
