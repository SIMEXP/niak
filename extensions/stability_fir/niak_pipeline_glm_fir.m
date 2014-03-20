function [pipeline,opt] = niak_pipeline_glm_fir(files_in,opt)
% General linear model analysis of finite-impulse response estimation
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_GLM_FIR(FILES_IN,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   NETWORKS.(LABEL_NETWORK)     
%      (string) a file name of a mask of brain networks (network I is filled 
%      with Is, 0 is for the background). The analysis will be done at the level 
%      of these networks.
%
%   FMRI.(SUBJECT).(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields (SUBJECT), (SESSION) and (RUN) can be any arbitrary 
%      string. 
%
%   MODEL
%      (structure, optional) with the following fields : 
%       
%      GROUP
%         (string, optional) the name of a CSV file describing the covariates at the level of group. 
%         Example :
%                   , SEX , HANDENESS
%         <SUBJECT> , 0   , 0
%         This type of file can be generated with Excel (save under CSV).
%         Each column defines a covariate that can be used in a linear model.
%         The labels <SUBJECT> have to be consistent with MODEL.SUBJECT and NETWORKS.TSERIES/FMRI
%         If omitted, the group model will only include the intercept.
%       
%      INDIVIDUAL.(SUBJECT).(SESSION).(RUN)
%         (string) the name of a CSV file describing the event times (with possibly multiple 
%         conditions). The first column contains (string) condition labels and a first line with 
%         column labels. OPT.TEST.NAME_CONDITION can be used to specify the name of the condition 
%         of interest (by default the first one is used). OPT.TEST.NAME_BASELINE can be used to 
%         specify the name of the condition used as baseline (by default the first one is used).
%         If a string is passed in MODEL.INDIVIDUAL, the same model is used for all subjects/runs.
%  
% OPT
%   (structure) with the following fields : 
%
%   FOLDER_OUT 
%      (string) where to write the results of the pipeline. 
%
%   FWE
%      (scalar, default 0.05) the overall family-wise error, i.e. the probablity to have the observed
%      number of discoveries, agregated across all scales, under the global null hypothesis of no association.
%
%   FDR
%      (scalar, default 0.05) the level of acceptable false-discovery rate 
%      for the t-maps.
%
%   TYPE_FDR
%      (string, default 'LSL') how the FDR is controled. Families correspond to all the FIR time points for 
%      one region. See the TYPE argument of NIAK_FDR.
%
%   NB_SAMPS
%      (integer, default 1000) the number of samples under the null hypothesis
%      used to test the significance of the number of discoveries.
%
%   NB_BATCH
%      (integer, default 10) the number of batches to perform the permutation tests. The actual number of 
%      permutation samples is NB_SAMPS*NB_BATCH.
%
%   FLAG_RAND
%      (boolean, default false) if the flag is false, the pipeline is 
%      deterministic. Otherwise, the random number generator is initialized
%      based on the clock for each job.
%
%   TEST.<LABEL>
%      (structure, optional) By default the contrast is on the intercept 
%      (average of all FIR across all subjects). The following 
%      fields are supported:
%
%      CONTRAST
%         (structure, with arbitray fields <NAME>, which needs to correspond to the 
%         label of one column in the file FILES_IN.MODEL.GROUP) The fields found in 
%         CONTRAST will determine which covariates enter the model:
%
%         <NAME>
%             (scalar) the weight of the covariate NAME in the contrast.
%
%      INTERACTION
%         (structure, optional) with multiple entries and the following fields :
%          
%         LABEL
%            (string) a label for the interaction covariate.
%
%         FACTOR
%            (cell of string) covariates that are being multiplied together to build the
%            interaction covariate. 
%
%         FLAG_NORMALIZE_INTER
%            (boolean,default true) if FLAG_NORMALIZE_INTER is true, the factor of interaction 
%            will be normalized to a zero mean and unit variance before the interaction is 
%            derived (independently of OPT.<LABEL>.GROUP.NORMALIZE below.
%
%      PROJECTION
%         (structure, optional) with multiple entries and the following fields :
%
%         SPACE
%            (cell of strings) a list of the covariates that define the space to project 
%            out from (i.e. the covariates in ORTHO, see below, will be projected 
%            in the space orthogonal to SPACE).
%
%         ORTHO
%            (cell of strings, default all the covariates except those in space) a list of 
%            the covariates to project in the space orthogonal to SPACE (see above).
%
%         FLAG_INTERCEPT
%            (boolean, default true) if the flag is true, add an intercept in SPACE (even 
%            when the model does not have an intercept).
%
%      NORMALIZE_X
%         (structure or boolean, default false) If a boolean and true, all covariates of the 
%         model are normalized to a zero mean and unit variance. If a structure, the 
%         fields <NAME> need to correspond to the label of a column in the 
%         file FILES_IN.MODEL.GROUP):
%
%         <NAME>
%             (arbitrary value) if <NAME> is present, then the covariate is normalized
%             to a zero mean and a unit variance. 
%
%      NORMALIZE_Y
%          (boolean, default false) If true, the data is corrected to a zero mean and unit variance,
%          in this case across subjects.
%
%      FLAG_INTERCEPT
%         (boolean, default true) if FLAG_INTERCEPT is true, a constant covariate will be
%         added to the model.
%
%      SELECT
%         (structure, optional) with multiple entries and the following fields:           
%
%         LABEL
%            (string) the covariate used to select entries *before normalization*
%
%         VALUES
%            (vector, default []) a list of values to select (if empty, all entries are retained).
%
%         MIN
%            (scalar, default []) only values higher (strictly) than MIN are retained.
%
%         MAX
%            (scalar, default []) only values lower (strictly) than MAX are retained. 
%
%         OPERATION
%            (string, default 'or') the operation that is applied to select the frames.
%            Available options:
%            'or' : merge the current selection SELECT(E) with the result of the previous one.
%            'and' : intersect the current selection SELECT(E) with the result of the previous one.
%
%   FIR
%       (structure) see the OPT argument of NIAK_BRICK_FIR_TSERIES. The default
%       parameters may work. 
% 
%   FLAG_MAPS
%      (boolean, default true) if the flag is true, all sorts of maps are 
%      generated. Otherwise, the results of the tests are only saved in 
%      the form of a .mat file.
%
%   PSOM
%      (structure, optional) the options of the pipeline manager. See the
%      OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%      (boolean, default false) If FLAG_TEST is true, the pipeline will
%      just produce a pipeline structure, and will not actually process
%      the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%      data.
%
%   FLAG_VERBOSE
%      (boolean, default true) Print some advancement infos.
%
% _________________________________________________________________________
% OUTPUTS : 
%
% PIPELINE 
%   (structure) describe all jobs that need to be performed in the 
%   pipeline. This structure is meant to be use in the function
%   PSOM_RUN_PIPELINE.
%
% OPT
%   (structure) same as input, but updated for default values.
%
% _________________________________________________________________________
% COMMENTS:
%
%   Networks specifically tailored to the spatial distribution of FIR estimates 
%   can be generated with the NIAK_PIPELINE_STABILITY_FIR pipeline.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, GLM, fMRI, FIR

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

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_GLM_FIR(FILES_IN,OPT).\n Type ''help niak_pipeline_glm_fir'' for more info.')
end

%% Checking that FILES_IN is in the correct format
list_fields   = { 'networks' , 'model' , 'fmri' };
list_defaults = { NaN        , NaN     , NaN    };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

files_in.model = psom_struct_defaults(files_in.model,{'group','individual'},{'gb_niak_omitted',NaN});

%% Reformat the inputs
[cell_fmri,labels] = niak_fmri2cell(files_in.fmri);
all_file = {labels(:).name};
list_subject = fieldnames(files_in.fmri);
list_network = fieldnames(files_in.networks);

if ischar(files_in.model.individual)
    cell_timing = repmat({files_in.model.individual},size(cell_fmri));
else
    [cell_timing,labels_timing] = niak_fmri2cell(files_in.model.individual);
    [mask_model,order_model] = ismember(all_file,{labels_timing.name});
    if any(~mask_model)
        labels(~mask_model).name
        error('the above entries are missing in the individual models');
    end
    cell_timing = cell_timing(order_model);
end

%% Options
list_fields   = { 'fir'  , 'nb_samps' , 'nb_batch' , 'fdr' , 'type_fdr' , 'flag_rand' , 'flag_maps' , 'fwe'  , 'psom'   , 'folder_out' , 'test' , 'flag_verbose' , 'flag_test' };
list_defaults = { struct , 1000       , 10         , 0.05  , 'LSL'      , false       , true        , 0.05   , struct() , NaN           , NaN   ,    true        , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

%% copy the networks
pipeline = struct();
[path_f,name_f,ext_f] = niak_fileparts(files_in.networks.(list_network{1}));
for num_n = 1:length(list_network)
    network = list_network{num_n};    
    pipeline.(['networks_' network]).command   = 'system([''cp '' files_in '' '' files_out]);';
    pipeline.(['networks_' network]).files_in  = files_in.networks.(network);
    pipeline.(['networks_' network]).files_out = [folder_out network filesep 'networks_' network ext_f];
end

%% Run the estimation of FIR response at the run level
list_test = fieldnames(opt.test);
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    mask_subject = ismember({labels.subject},subject);    
    for num_c = 1:length(list_test)
        clear job_in job_out job_opt                
        job_in.fmri    = cell_fmri(mask_subject);
        job_in.mask    = files_in.networks;
        job_in.timing  = cell_timing(mask_subject);
        job_out = [opt.folder_out 'fir' filesep 'fir_' subject '.mat'];       
        job_opt = opt.fir;        
        files_fir.(subject) = job_out;        
        pipeline = psom_add_job(pipeline,['fir_' subject],'niak_brick_fir_tseries',job_in,job_out,job_opt);
    end
end

%% Run GLM estimation 
for num_c = 1:length(list_test)
    clear job_in job_out job_opt
    label_test = list_test{num_c};
    job_in.fir   = files_fir;
    job_in.model = files_in.model.group;
    job_in.mask = files_in.networks;
    job_opt.fdr = opt.fdr;    
    job_opt.type_fdr = opt.type_fdr;
    job_opt.test.(label_test) = opt.test.(label_test);
    for nn = 1:length(list_network)
        network = list_network{nn};
        job_out.(network).results = [folder_out network filesep label_test filesep 'glm_' label_test '_' network '.mat' ];
        if opt.flag_maps
            job_out.(network).ttest          = [folder_out network filesep label_test filesep 'ttest_'     label_test '_' network ext_f  ];
            job_out.(network).fdr            = [folder_out network filesep label_test filesep 'fdr_'       label_test '_' network ext_f  ];
            job_out.(network).effect         = [folder_out network filesep label_test filesep 'effect_'    label_test '_' network ext_f  ];
            job_out.(network).std_effect     = [folder_out network filesep label_test filesep 'std_'       label_test '_' network ext_f  ];
            job_out.(network).perc_discovery = [folder_out network filesep label_test filesep 'perc_disc_' label_test '_' network ext_f  ];
        end
    end
    pipeline = psom_add_job(pipeline,['glm_' label_test],'niak_brick_glm_fir',job_in,job_out,job_opt);
end    

%% Permutation test on the volume of findings
clear job_in job_out job_opt
job_opt.fdr = opt.fdr;
job_opt.type_fdr = opt.type_fdr;
job_opt.nb_samps = opt.nb_samps;
for num_b = 1:opt.nb_batch
    for num_c = 1:length(list_test)
        test = list_test{num_c};            
        job_in = cell(length(list_network),1);
        for num_n = 1:length(list_network)
            network = list_network{num_n};
            job_in{num_n} = pipeline.(['glm_' test]).files_out.(network).results;
        end
        name_job = sprintf('permutation_%s_batch_%i',test,num_b);
        job_out = [folder_out 'permutation_test' filesep name_job '.mat'];
        if ~opt.flag_rand
            job_opt.rand_seed = double(niak_datahash(test));
            job_opt.rand_seed = job_opt.rand_seed(1:min(length(job_opt.rand_seed),625));
            job_opt.rand_seed = job_opt.rand_seed + num_b;
        end
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_glm_fir_perm',job_in,job_out,job_opt);
    end
end

%% Build summary of findings
clear job_in job_out job_opt
for num_c = 1:length(list_test)
    test = list_test{num_c};
    for num_b = 1:opt.nb_batch
        name_job_in = sprintf('permutation_%s_batch_%i',test,num_b);
        job_in.(test){num_b} = pipeline.(name_job_in).files_out;
    end
    job_out = [folder_out 'summary_findings.csv'];
    job_opt.p = opt.fwe;       
    job_opt.label_network = list_network;
    pipeline = psom_add_job(pipeline,['summary_findings'],'niak_brick_summary_glm_fir',job_in,job_out,job_opt); 
end
    
%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end