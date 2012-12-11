function [pipeline,opt] = niak_pipeline_fcon(files_in,opt)
% Run a pipeline to generate fonctional connectivity outcome mesures for a group of subjects.
% The flowchart of the pipeline is flexible (steps can be skipped using 
% flags), and the analysis can be further customized by changing the 
% parameters of any step.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_FCON(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%	FILES_IN 
%       (structure) 
%
%       FMRI 
%           (structure) all the functional runs to be analysed
%
%       REF_PARAM 
%           (string) path for the .mat file containing the reference data
%           and the seeds for the functional outcome mesures.
%
%
% _________________________________________________________________________
% OUTPUTS : 
%
%	PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
%	OPT
%       (structure) describe all options that need to be performed in the
%       pipeline.
%
%       FLAG_TEST
%           (boolean, default false) If FLAG_TEST is false, the pipeline
%           will just produce a pipeline structure, and will not actually
%           process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%           process the data.
%
%       FOLDER_OUT 
%           (string) where to write the results of the pipeline. 
%
% _________________________________________________________________________
% COMMENTS:
%
% _________________________________________________________________________
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal,
% 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI, psom

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, label to the following conditions:
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

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FCON(FILES_IN,OPT).\n Type ''help niak_pipeline_fcon'' for more info.')
end

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

%% OPTIONS
gb_name_structure   = 'opt';
gb_list_fields      = {  'flag_test'    , 'folder_out'   , 'flag_verbose' , 'scale'};
gb_list_defaults    = {  false          , ''             , true           , NaN     };
niak_set_defaults

%% FILES_IN
[fmri_c,label] = niak_fmri2cell(files_in.fmri); % Convert FILES_IN into a cell of string form
[path_f,name_f,ext_f] = niak_fileparts(fmri_c{1}); % Get the extension of outputs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The pipeline starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct();

%% FCON 
if opt.flag_verbose
    t1 = clock;
    fprintf('Generating pipeline for fcon ; ');
end

for num_e = 1:length(fmri_c)
    
    clear job_in job_out job_opt
    
    %% Opt
    job_opt.flag_test  = true;
    job_opt.flag_verbose = true;
    job_opt.folder_out = [opt.folder_out filesep 'outcome_' label(num_e).subject '_' label(num_e).session];
    job_opt.scale  = opt.scale;

    %% Input
    job_in.ref_param = files_in.ref_param;
    job_in.subj_fmri = fmri_c{num_e}; % the path of the fmri preprocessed subject

    %% Output
    job_out.p2p = [job_opt.folder_out filesep 'boxplot_P2P_' job_opt.scale '_' label(num_e).subject '.pdf'];
    job_out.dm_map     = [job_opt.folder_out filesep 'DM_map_' job_opt.scale '_' label(num_e).subject '.mnc.gz'];
    job_out.seedcon    = [job_opt.folder_out filesep 'boxplot_seedconnection_' job_opt.scale '_' label(num_e).subject '.pdf'];
    job_out.seedconp2p = [job_opt.folder_out filesep 'boxplot_seedconnectionp2p_' job_opt.scale '_' label(num_e).subject '.pdf'];
    job_out.connectome = [job_opt.folder_out filesep 'boxplot_connectome_' job_opt.scale '_' label(num_e).subject '.pdf'];
    job_out.csv = [job_opt.folder_out filesep 'tab_outcome_' job_opt.scale '_' label(num_e).subject '.csv'];
    pipeline = psom_add_job(pipeline,['fcon_' label(num_e).subject '_' label(num_e).session],'niak_brick_fcon',job_in,job_out,job_opt);
    
end

if opt.flag_verbose        
    fprintf('%1.2f sec\n',etime(clock,t1));
end

%% Run the pipeline 

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
