function [pipeline] = niak_pipeline_stability_estimate(files_in, opt)
% Estimate the stability of a stochastic clustering on time series.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_STABILITY_ESTIMATE(FILES_IN, OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
% (struct)
%   TSERIES
%       (string or cell of strings) the name(s) of one or multiple .mat file, 
%       which contains one variable TS (OPT.NAME_DATA). TS(:,I) is the time 
%       series of region I.
%
%   PART_REF
%       (string, optional) path to a .mat file containing a variable called
%       PART which is the reference partition. If kcores is used to generate 
%       the atom level stability maps, part_ref has to be set as the 
%       reference partition.
%
%   PART_ROI
%       (string, optional) path to a .mat file containing the region
%       growing results for the current dataset. This is needed to bring
%       the reference partition in FILES_IN.PART_REF into atom space so we
%       can use it if kcores is selected in OPT.CLUSTERING.TYPE
%
% OPT
%   (structure) with the following fields.
%
%   FOLDER_OUT
%       (string, must be set) where to write the default outputs.
%
%   ESTIMATION
%       (structure)
%
%       SCALE_GRID
%           (vector) The vector of scales for which stability shall be
%           estimated.
%
%       NAME_DATA
%           (string, default 'data') the name of the variable in the input
%           file that contains the timeseries.
%
%       NB_SAMPS
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%       NB_BATCH
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%   SAMPLING
%      (structure)
%
%      TYPE
%          (string, default 'bootstrap') how to resample the time series.
%          Available options : 'bootstrap' , 'jacknife'
%
%      OPT
%          (structure, default empty) the options of the sampling. Depends 
%          on OPT.SAMPLING.TYPE:
%               bootstrap : None.
%               jacknife  : OPT.PERC is the percentage of observations
%                           retained in each sample (default 60%)
%
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 
%               'kmeans': k-means (euclidian distance)
%               'kcores' : k-means cores
%               'hierarchical_e2': a HAC based on the eta-square distance
%                   (see NIAK_BUILD_ETA2)
%               'hierarchical' : a HAC based on a squared
%                   euclidian distance.
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'kmeans' : see OPT in NIAK_KMEANS_CLUSTERING
%               'hierarchical' or 'hierarchical_e2': see OPT in 
%               NIAK_HIERARCHICAL_CLUSTERING
%
%   AVERAGE
%       (structure)
%
%       NAME_JOB
%           (string, default 'average') the name given to the job that averages
%           the stability estimates
%
%       NAME_SCALE_IN
%           (string, default 'scale_grid') the name of the variable in the
%           stability estimate outputs that contains the scale vector
%
%       NAME_DATA
%           (string, default 'stab') the name of the variable in the
%           stability estimate outputs that contains the stability matrix
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT 
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS : 
%
%	PIPELINE 
%       (structure) describe all jobs that need to be performed in the
%       pipeline.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_TSERIES, NIAK_STABILITY_TSERIES
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series, consensus
%
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
if ~exist('files_in','var')
    error('niak:pipeline','syntax: [PIPELINE] = NIAK_PIPELINE_STABILITY_ESTIMATE(FILES_IN, OPT).\n Type ''help niak_pipeline_stability_estimate'' for more info.')
end

%% Files in
list_fields   = { 'data' , 'part_ref'        , 'part_roi'        };
list_defaults = { NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in, list_fields, list_defaults);

%% Options
list_fields   = { 'folder_out' , 'estimation' , 'sampling' , 'clustering' , 'average' , 'psom'   , 'flag_verbose' , 'flag_test' };
list_defaults = { NaN          , struct()     , struct()   , struct()     , struct()  , struct() , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
opt.psom.path_logs = [opt.folder_out 'logs'];

% Setup Sampling Defaults
opt.sampling = psom_struct_defaults(opt.sampling,...
               { 'type'      , 'opt'    },...
               { 'jacknife'  , struct() });

% Setup Clustering Defaults
opt.clustering = psom_struct_defaults(opt.clustering,...
                 { 'type'         , 'opt'    },...
                 { 'hierarchical' , struct() });

% Setup Estimation Defaults
opt.estimation = psom_struct_defaults(opt.estimation,...
                 { 'scale_grid' , 'name_data' ,  'nb_samps' , 'nb_batch' , 'clustering'   , 'sampling'   },...
                 { NaN          , 'data'      ,  100        , 100        , opt.clustering , opt.sampling });

% Setup Average Defaults
opt.average = psom_struct_defaults(opt.average,...
              { 'name_job' , 'name_scale_in' , 'name_data' },...
              { 'average'  , 'scale_grid'    , 'stab'      });
opt.average.case = 2;

%% Sanity checks
if strcmp(opt.clustering.type, 'kcores')
    % User wants to run atom level stability estimation with kcores. We
    % need to have both the reference partition and the region growing
    % input
    if (strcmp(files_in.part_ref, 'gb_niak_omitted') || ...
        strcmp(files_in.part_roi, 'gb_niak_omitted'))
        % The user has not specified the necessary reference partition
        error(['When running k-cores for atom level stability estimation, '...
               'FILES_IN.PART_REF and FILES_IN.PART_ROI must be defined!']);
    end
end

%% The pipeline starts here
pipeline = struct;
stab_files = cell(opt.estimation.nb_batch,1);

% See if we need to load the reference partition
if strcmp(opt.clustering.type, 'kcores')
    pipeline.get_ref.command = sprintf(['part_f = load(files_in.part);'...
                                        'roi_f = load(files_in.roi);'...
                                        'part = part_f.part;'...
                                        'roi = roi_f.part_roi;'...
                                        'part = niak_vol2part(part, roi, opt);'...
                                        'if isfield(part_f, ''scale_tar'');'...
                                        'scale_tar = part_f.scale_tar;'...
                                        'else;'...
                                        'scale_tar = max(part);'...
                                        'end;'...
                                        'save(files_out, ''part'', ''scale_tar'');']);
    pipeline.get_ref.opt.metric = 'mode';
    pipeline.get_ref.files_in = struct('part', files_in.part_ref,...
                                       'roi', files_in.part_roi);
    pipeline.get_ref.files_out = [opt.folder_out 'ref_part_roi.mat'];
end

% Checking the contents of the file
for stab_batch_id = 1:opt.estimation.nb_batch
    % Set the inputs for the brick
    stab_batch_in = struct('data', files_in.data,...
                           'part_ref', pipeline.get_ref.files_out);
    stab_batch_out = [opt.folder_out...
                      sprintf('stability_atom_%d.mat',stab_batch_id)];

    stab_batch_opt = rmfield(opt.estimation, 'nb_batch');
    stab_batch_opt.rand_seed = stab_batch_id;
    stab_batch_name = sprintf('stab_atom_%d',stab_batch_id);
    stab_batch_clean = sprintf('clean_%s', stab_batch_name);

    pipeline = psom_add_job(pipeline, stab_batch_name, ...
                            'niak_brick_stability_tseries',stab_batch_in,...
                            stab_batch_out, stab_batch_opt);
    pipeline = psom_add_clean(pipeline, stab_batch_clean,...
                              pipeline.(stab_batch_name).files_out);
    stab_files{stab_batch_id} = stab_batch_out;
end

% Hand the individual estimated stability matrices to the averaging brick
avg_in = stab_files;
avg_out = [opt.folder_out 'stability_estimate.mat'];
avg_name = opt.average.name_job;
avg_opt = rmfield(opt.average, 'name_job');
avg_opt.name_scale_out = 'scale_grid';

pipeline = psom_add_job(pipeline, avg_name, 'niak_brick_stability_average', ...
           avg_in, avg_out, avg_opt);

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end