function [pipeline,opt] = niak_pipeline_glm_connectome(files_in,opt)
% General linear model analysis of connectomes
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_GLM_CONNECTOME(FILES_IN,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   FMRI.(SUBJECT).(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields (SUBJECT), (SESSION) and (RUN) are 
%      arbitrary.
%
%   NETWORKS.(NETWORK)
%      (string) a file name of a mask of brain networks (network I is filled 
%      with Is, 0 is for the background). The analysis will be done at the level 
%      of these networks.
%
%   MODEL.INDIVIDUAL.(SUBJECT).INTRA_RUN.(SESSION).(RUN)
%      (structure, optional) with the following fields : 
%
%      COVARIATE
%         (string, optional) the name of a CSV file describing the covariates at the 
%         intra-run level. Example:
%         MOTION_X , MOTION_Y , MOTION_Z
%         0.03     , 0.02     , 0.8
%         0.05     , 0.9      , 0.6
%         Note that the labels of each column will be used as the names of the coavariates 
%         in the model. Each row corresponds to one time frames in the time series. When the 
%         fMRI time series have been scrubbed (i.e. some time frames are missing), missing 
%         time frames should be specified anyway.If some initial volumes have been suppressed, 
%         missing time frames should also be specified and OPT.SUPPRESS_VOL should be specified. 
%
%      EVENT
%         (string, optional) the name of a CSV file describing
%         the event model. Example :
%                  , TIMES , DURATION , AMPLITUDE 
%         'motor'  , 12    , 5        , 1  
%         'visual' , 12    , 5        , 1  
%         The first column defines the names of the condition that can be used as covariates in 
%         the model. The times have to be specified in seconds, with the beginning of the acquisition
%         starting at 0. 
%       
%   MODEL.INDIVIDUAL.(SUBJECT).INTER_RUN
%      (string, default intercept) the name of a CSV file describing the  
%      covariates for intra-subject inter-run analysis. Example:
%                      , DAY 
%      <SESSION>_<RUN> , 1   
%      <SESSION>_<RUN> , 2   
%      This type of file can be generated with Excel (save under CSV).
%      Each column defines a covariate that can be used in a linear model.
%      The labels <RUN> have to be consistent with MODEL.INTRA_RUN and FMRI
%
%   MODEL.GROUP
%      (string, optional) the name of a CSV file describing the covariates at the level of group. 
%      Example :
%                , SEX , HANDENESS
%      <SUBJECT> , 0   , 0
%      This type of file can be generated with Excel (save under CSV).
%      Each column defines a covariate that can be used in a linear model.
%      The labels (SUBJECT) have to be consistent with FILES_IN.FMRI       
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
%      (string, default 'LSL_sym') how the FDR is controled. 
%      See the TYPE argument of NIAK_GLM_FDR.
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
%   MIN_NB_VOL
%       (integer, default 10) the minimal number of volumes in a run allowed to estimate a connectome. 
%       This is assessed after the SELECT field of OPT.TEST.RUN is applied. 
%       Subjects who have a run that does not meet this criterion are automatically excluded
%       from the analysis. 
%
%   TEST.(LABEL).GROUP
%      (structure, optional) By default the contrast is on the intercept (average of all connectomes 
%      across all subjects). The following fields are supported:
%
%      CONTRAST.(NAME)
%         (structure, the fields (NAME) need to correspond to a column in FILES_IN.MODEL.GROUP)
%         The fields found in CONTRAST will determine which covariates enter the model. 
%         CONTRAST.(NAME) is the weight of the covariate NAME in the contrast.
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
%         file FILES_IN.MODEL.GROUP, and the normalization will only be applied to the listed 
%         variables.
%
%      NORMALIZE_Y
%         (boolean, default false) If true, the data is corrected to a zero mean and unit variance,
%         in this case across subjects.
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
%   TEST.(LABEL).INTER_RUN
%      (structure, optional) The same fields as TEST.(LABEL).GROUP are supported, except that 
%      the name of the covariates must be the same as those used in 
%      FILES_IN.MODEL.INDIVIDUAL.(SUBJECT).INTER_RUN. By default the contrast is on the intercept 
%      (average of the connectomes across all runs). 
%
%   TEST.(LABEL).INTRA_RUN
%      (structure, optional) with the following fields:
%
%      TYPE
%         (string, default 'correlation') The other fields depend on this parameter. 
%         Available options:
%         'correlation' : simple Pearson's correlation coefficient. 
%         'glm' : run a general linear model estimation
%
%         case 'correlation'
%
%            FLAG_FISHER
%               (boolean, default true) if the flag is on, the correlation values are normalized
%               using a Fisher's transform. 
%
%            PROJECTION
%               (cell of strings) a list of the covariates that will be regressed out from the 
%               time series (an intercept will be automatically added).
%
%            SELECT
%               (structure, optional) The correlation will be derived only on the selected volumes. 
%               By default all the volumes are used. See OPT.TEST.<LABEL>.GROUP.SELECT above.
%
%            SELECT_DIFF
%               (structure, optional) If SELECT_DIFF is specified has two entries, the 
%               measure will be the difference in correlations between the two subsets of time frames 
%               SELECT_DIFF-SELECT, instead a single correlation coefficient. 
%               See OPT.TEST.<LABEL>.GROUP.SELECT above.
%
%         case 'glm'
%
%            same as OPT.MODEL.GROUP except that (1) there is a covariate called 'seed' in the model_group
%            which will be iterated over all possible seeds; and (2) the default test is a contrast on the 
%            seed. Note that the default for the NORMALIZE_Y parameter is true at the run level.
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
% The statistics on the overall probability to find the observed volume of 
% discoveries is only meaningfull for non-trivial group-level contasts (i.e.
% when the contrast is not on the intercept). Additional (optional) permutation 
% tests for within-run and within-subject contrasts in on the list of features 
% for future implementation. 
%
% Copyright (c) Pierre Bellec, Jalloul Bouchkara
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, GLM, fMRI, connectome, PPI.

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
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_GLM_CONNECTOME(FILES_IN,OPT).\n Type ''help niak_pipeline_glm_connectome'' for more info.')
end

%% Checking that FILES_IN is in the correct format
list_fields   = { 'networks' , 'model' , 'fmri' };
list_defaults = { NaN        , NaN     , NaN    };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
list_fields   = { 'min_nb_vol' , 'nb_samps' , 'nb_batch' , 'fdr' , 'type_fdr' , 'flag_rand' , 'flag_maps' , 'fwe'  , 'psom'   , 'folder_out' , 'test' , 'flag_verbose' , 'flag_test' };
list_defaults = { 10           , 1000       , 10         , 0.05  , 'LSL_sym'  , false       , true        , 0.05   , struct() , NaN           , NaN   ,    true        , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

%% Generate individual connectomes
pipeline = struct();
list_subject = fieldnames(files_in.fmri);
list_test = fieldnames(opt.test);
list_network = fieldnames(files_in.networks);
for ss = 1:length(list_subject)
    clear in out jopt
    subject = list_subject{ss};
    in.fmri = files_in.fmri.(subject);
    in.networks = files_in.networks;
    if isfield(files_in.model,'individual')&&isfield(files_in.model.individual,subject)
        in.model = files_in.model.individual.(subject);
    end
    for nn = 1:length(list_network)
        network = list_network{nn};
        out.(network) = [folder_out network filesep 'individual' filesep 'connectome_' subject '_' network '.mat'];
    end
    for tt = 1:length(list_test)
        test = list_test{tt};
        if isfield(opt.test.(test),'group')
            jopt.param.(test) = rmfield(opt.test.(test),'group');
        else
            jopt.param.(test) = opt.test.(test);
        end
    end
    jopt.min_nb_vol   = opt.min_nb_vol;
    jopt.flag_verbose = opt.flag_verbose;
    pipeline = psom_add_job(pipeline,['connectome_' subject],'niak_brick_connectome_multiscale',in,out,jopt);
end

%% Copy the networks
for nn = 1:length(list_network)
    network = list_network{nn};            
    [path_f,name_f,ext_f] = niak_fileparts(files_in.networks.(network));
    pipeline.(['networks_' network]).command   = 'system([''cp '' files_in '' '' files_out]);';
    pipeline.(['networks_' network]).files_in  = files_in.networks.(network);
    pipeline.(['networks_' network]).files_out = [folder_out network filesep 'networks_' network ext_f];
end

%% Run GLM estimation 
for nn = 1:length(list_network)    
    clear job_in 
    network = list_network{nn};
    for ss = 1:length(list_subject)
        subject = list_subject{ss};
        job_in.connectome.(subject) = pipeline.(['connectome_' subject]).files_out.(network);
    end
    if isfield(files_in.model,'group')
        job_in.model = files_in.model.group;
    end
    job_in.networks = pipeline.(['networks_' network]).files_out;
    for tt = 1:length(list_test)
        clear job_out job_opt
        test = list_test{tt};
        job_opt.fdr = opt.fdr;
        job_opt.min_nb_vol = opt.min_nb_vol;
        job_opt.type_fdr = opt.type_fdr;
        if isfield(opt.test.(test),'group')
            job_opt.test.(test) = opt.test.(test).group;
        end
        job_out.results = [folder_out network filesep test filesep 'glm_' test '_' network '.mat' ];
        if opt.flag_maps
            job_out.ttest          = [folder_out network filesep test filesep 'ttest_'     test '_' network ext_f  ];
            job_out.fdr            = [folder_out network filesep test filesep 'fdr_'       test '_' network ext_f  ];
            job_out.effect         = [folder_out network filesep test filesep 'effect_'    test '_' network ext_f  ];
            job_out.std_effect     = [folder_out network filesep test filesep 'std_'       test '_' network ext_f  ];
            job_out.perc_discovery = [folder_out network filesep test filesep 'perc_disc_' test '_' network ext_f  ];
        end
        pipeline = psom_add_job(pipeline,[network '_glm_' test],'niak_brick_glm_connectome',job_in,job_out,job_opt);
    end    
end

%% Permutation test on the volume of findings
clear job_in job_out job_opt
job_opt.fdr = opt.fdr;
job_opt.type_fdr = opt.type_fdr;
job_opt.nb_samps = opt.nb_samps;

for num_b = 1:opt.nb_batch
    for tt = 1:length(list_test)
        test = list_test{tt};            
        job_in = cell(length(list_network),1);
        for num_n = 1:length(list_network)
            network = list_network{num_n};
            job_in{num_n} = pipeline.([network '_glm_' test]).files_out.results;
        end
        name_job = sprintf('permutation_%s_batch_%i',test,num_b);
        job_out = [folder_out 'permutation_test' filesep name_job '.mat'];
        if ~opt.flag_rand
            job_opt.rand_seed = double(niak_datahash(test));
            job_opt.rand_seed = job_opt.rand_seed(1:min(length(job_opt.rand_seed),625));
            job_opt.rand_seed = job_opt.rand_seed + num_b;
        end
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_glm_connectome_perm',job_in,job_out,job_opt);
    end
end

%% Build summary of findings
clear job_in job_out job_opt
for tt = 1:length(list_test)
    test = list_test{tt};
    for num_b = 1:opt.nb_batch
        name_job_in = sprintf('permutation_%s_batch_%i',test,num_b);
        job_in.(test){num_b} = pipeline.(name_job_in).files_out;
    end
    job_out = [folder_out 'summary_findings.csv'];
    job_opt.p = opt.fwe;       
    job_opt.label_network = list_network;
end
pipeline = psom_add_job(pipeline,['summary_findings'],'niak_brick_summary_glm_connectome',job_in,job_out,job_opt); 
    
%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%
function [files_tseries,flag_net] = sub_input(files_in,network);

if isfield(files_in.networks.(network),'tseries')
    files_tseries  = files_in.networks.(network).tseries;
    flag_net = true;
else
    if strcmp(files_in.fmri,'gb_niak_omitted')
        error('Specify either FILES_IN.FMRI or FILES_IN.NETWORKS.<NETWORK>.TIME_SERIES')
    end
    files_tseries = files_in.fmri;
    flag_net = false;
end

list_subject = fieldnames(files_tseries);
for num_s = 1:length(list_subject)
    subject  = list_subject{num_s};
    files_subject = files_tseries.(subject);
    if ~isstruct(files_subject)
        if ~iscellstr(files_subject)
            error('FILES_IN.FMRI (or FILES_IN.NETWORKS.<NETWORK>.TIME_SERIES) should be either a structure or a cell of strings')
        end
        nb_run = length(files_subject);
        files_tmp = struct;
        for num_r = 1:nb_run
            files_tmp.(sprintf('run%i',num_r)) = files_subject{num_r};
        end
        files_tseries.(subject) = files_tmp;
    else
        list_session = fieldnames(files_subject);       
        if isstruct(files_subject.(list_session{1}))
            files_tmp = struct;
            for num_sess = 1:length(list_session)
                list_run = fieldnames(files_subject.(list_session{num_sess}));
                for num_r = 1:length(list_run)
                     files_tmp.([list_session{num_sess} '_' list_run{num_r}]) = files_subject.(list_session{num_sess}).(list_run{num_r});
                end
            end
            files_tseries.(subject) = files_tmp;
        end
    end
end
