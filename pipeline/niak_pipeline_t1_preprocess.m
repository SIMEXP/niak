function [pipeline,opt] = niak_pipeline_t1_preprocess(files_in,opt)
% Run a pipeline to preprocess a collection of T1 scans. 
% The preprocessing includes linear and non-linear coregistration in the 
% MNI stereotaxic space, along with various additional intermediate steps 
% (non-uniformity correction, intensity normalization, brain extraction) 
% and tissue classification. Also generate a summary of the coregistration 
% fit across subjects.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_T1_PREPROCESS(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN  
%       (structure) with the following fields : 
%
%       <SUBJECT>
%           (string) raw anatomical (T1-weighted MR) volume.
%
%   OPT   
%       (structure) with the following fields : 
%
%       T1_PREPROCESS
%           (structure) the options of the NIAK_BRICK_T1_PREPROCESS
%           function. Defaults should work.
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. For the 
%           actual content of folder_out, see the internet 
%           documentation :
%           http://wiki.bic.mni.mcgill.ca/index.php/NiakT1Preprocess
%
%       FLAG_TEST
%           (boolean, default false) If FLAG_TEST is true, the pipeline
%           will just produce a pipeline structure, and will not actually
%           process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%           process the data.
%
%       PSOM
%           (structure) the options of the pipeline manager. See the OPT
%           argument of PSOM_RUN_PIPELINE. Default values can be used here.
%           Note that the field PSOM.PATH_LOGS will be set up by the
%           pipeline.
%
%
% _________________________________________________________________________
% OUTPUTS: 
%
%   PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
% _________________________________________________________________________
% COMMENTS:
%
% _________________________________________________________________________
% SEE ALSO: 
% NIAK_PIPELINE_FMRI_PREPROCESS, NIAK_BRICK_T1_PREPROCESS
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI, psom, preprocessing

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

%% import NIAK global variables
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if ~exist('files_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRI_PREPROCESS(FILES_IN,OPT).\n Type ''help niak_pipeline_fmri_preprocess'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)

    error('FILES_IN should be a struture!')
    
else
   
    list_subject = fieldnames(files_in);
    nb_subject = length(list_subject);
    list_anat = cell([length(list_subject) 1]);
    
    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        data_subject = files_in.(subject);
        
        if ~ischar(data_subject)
            error('FILES_IN.%s should be a string!',upper(subject));
        end
        
        list_anat{num_s} = files_in.(subject);        
    end
    
end

%% Options
gb_name_structure = 'opt';
opt_tmp.flag_test = false;
default_psom.path_logs = '';
gb_list_fields = {'folder_out','flag_test','psom','t1_preprocess'};
gb_list_defaults = {NaN,false,default_psom,opt_tmp};
niak_set_defaults

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

%% Extension
[path_f,name_f,ext_f] = fileparts(files_in.(list_subject{1}));
if isempty(path_f)
    path_f = '.';
end
                
if strcmp(ext_f,gb_niak_zip_ext)
	[tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Brick for individual T1 preprocessing %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = [];
for num_s = 1:nb_subject

    % Names
    clear files_in_tmp files_out_tmp opt_tmp
    name_brick = 'niak_brick_t1_preprocess';    
    subject = list_subject{num_s};
    name_job = ['t1_preprocess_' subject];
    
    % Files in
    files_in_tmp = list_anat{num_s};

    % Files out
    files_out_tmp.transformation_lin = '';
    files_out_tmp.transformation_nl = '';
    files_out_tmp.transformation_nl_grid = '';
    files_out_tmp.anat_nuc = '';
    files_out_tmp.anat_nuc_stereolin = '';
    files_out_tmp.anat_nuc_stereonl = '';
    files_out_tmp.mask_stereolin = '';
    files_out_tmp.mask_stereonl = '';
    files_out_tmp.classify = '';
    
    % Opt    
    opt_tmp = opt.t1_preprocess;    
    opt_tmp.folder_out = [opt.folder_out subject filesep];
    
    % Add job
    pipeline = psom_add_job(pipeline,name_job,name_brick,files_in_tmp,files_out_tmp,opt_tmp);
    
    % get file names for quality control   
    files_in_qc_lin.mask{num_s} = pipeline.(name_job).files_out.mask_stereolin;
    files_in_qc_lin.vol{num_s}  = pipeline.(name_job).files_out.anat_nuc_stereolin;    
    files_in_qc_nl.mask{num_s}  = pipeline.(name_job).files_out.mask_stereolin;
    files_in_qc_nl.vol{num_s}   = pipeline.(name_job).files_out.anat_nuc_stereonl;    
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QC for linear coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_brick = 'niak_brick_qc_coregister';
name_job = 'qc_coregister_lin';
files_out_tmp.mask_average   = [opt.folder_out 'qc_coregister_lin' filesep 'mask_anat_average_lin' ext_f];
files_out_tmp.mask_group     = [opt.folder_out 'qc_coregister_lin' filesep 'mask_anat_group_lin' ext_f];
files_out_tmp.mean_vol       = [opt.folder_out 'qc_coregister_lin' filesep 'anat_mean_lin' ext_f];
files_out_tmp.std_vol        = [opt.folder_out 'qc_coregister_lin' filesep 'anat_std_lin' ext_f];
files_out_tmp.fig_coregister = [opt.folder_out 'qc_coregister_lin' filesep 'tab_qc_anat_coregister_lin.pdf'];
files_out_tmp.tab_coregister = [opt.folder_out 'qc_coregister_lin' filesep 'tab_qc_anat_coregister_lin.csv'];
opt_tmp.labels_subject = list_subject;
pipeline = psom_add_job(pipeline,name_job,name_brick,files_in_qc_lin,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QC for non-linear coregistration %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_brick = 'niak_brick_qc_coregister';
name_job = 'qc_coregister_nl';
files_out_tmp.mask_average   = [opt.folder_out 'qc_coregister_nl' filesep 'mask_anat_average_nl' ext_f];
files_out_tmp.mask_group     = [opt.folder_out 'qc_coregister_nl' filesep 'mask_anat_group_nl' ext_f];
files_out_tmp.mean_vol       = [opt.folder_out 'qc_coregister_nl' filesep 'anat_mean_nl' ext_f];
files_out_tmp.std_vol        = [opt.folder_out 'qc_coregister_nl' filesep 'anat_std_nl' ext_f];
files_out_tmp.fig_coregister = [opt.folder_out 'qc_coregister_nl' filesep 'tab_qc_anat_coregister_nl.pdf'];
files_out_tmp.tab_coregister = [opt.folder_out 'qc_coregister_nl' filesep 'tab_qc_anat_coregister_nl.csv'];
opt_tmp.labels_subject = list_subject;
pipeline = psom_add_job(pipeline,name_job,name_brick,files_in_qc_nl,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end