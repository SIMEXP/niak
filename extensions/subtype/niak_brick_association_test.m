function [files_in,files_out,opt] = niak_brick_association_test(files_in, files_out, opt)
% Create network, mean and std stack 4D maps from individual functional
% maps
%
% SYNTAX: [FILE_IN,FILE_OUT,OPT] =
% NIAK_BRICK_network_stack(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   WEIGHT
%       (string) path to a weight matrix. First column expected to be
%       subjects ordered the same way as in the MODEL
%
%   MODEL
%       (string) a .csv files coding for the pheno data. Is expected to
%       have a header and a first column specifying the case IDs/names
%       corresponding to the data in FILES_IN.DATA
%
%
% FILES_OUT
%   (string) absolute path to the output .mat
%   file containing the association results.
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   NETWORK
%       (int array, default all networks) A list of networks number in
%       individual maps
%
%   TEST_NAME
%       (string) the name of the current analysis
%
%   FDR
%      (scalar, default 0.05) the level of acceptable false-discovery rate
%      for the t-maps.
%
%   TYPE_FDR
%      (string, default 'BH') how the FDR is controled. See the METHOD
%      argument of NIAK_FDR.
%
%   COV
%       (cell array, default {}) the covariates that will enter the linear
%       model as predictors of the weight matrix. If empty, all covariates 
%       in FILES_IN.MODEL and all requested interactions from OPT.INTERACTION
%       will be used.
%       ***
%       NOTE: Unless empty, the names of all interactions that you 
%       request in OPT.INTERACTION have to be specified here as well 
%       or they will not be added to the model!
%       ***
%
%   COI
%       (string) the Covariate of Interest. One covariate that is also a
%       member of OPT.COV for which the association with the weight matrix
%       will be investigated. Results and figures will be based on the
%       association of this covariate of interest and the weight matrix.
% 
%   INTERACTION
%      (structure array, optional) with multiple entries and the following fields:
%          
%      LABEL
%         (string) a label for the interaction covariate.
%
%      FACTOR
%         (cell of string) covariates that are being multiplied together to
%         build the interaction covariate.  There should be only one
%         covariate associated with each label.
%
%      FLAG_NORMALIZE_INTER
%         (boolean,default true) if FLAG_NORMALIZE_INTER is true, the
%         factor of interaction will be normalized to a zero mean and unit
%         variance before the interaction is derived (independently of
%         OPT.<LABEL>.GROUP.NORMALIZE below).
%
%   NORMALIZE_X
%      (structure or boolean, default true) If a boolean and true, all
%      covariates of the model are normalized (see NORMALIZE_TYPE below).
%      If a structure, the fields <NAME> need to correspond to the label of
%      a column in the file FILES_IN.MODEL):
%
%      <NAME>
%         (arbitrary value) if <NAME> is present, then the covariate is
%         normalized (see NORMALIZE_TYPE below).
%
%   NORMALIZE_Y
%      (boolean, default false) If true, the data is normalized (see
%      NORMALIZE_TYPE below).
%
%   NORMALIZE_TYPE
%      (string, default 'mean') Available options:
%         'mean': correction to a zero mean (for each column) 'mean_var':
%         correction to a zero mean and unit variance (for each column)
%
%   SELECT
%      (structure, optional) with multiple entries and the following
%      fields:
%
%      LABEL
%         (string) the covariate used to select entries *before
%         normalization*
%
%      VALUES
%         (vector, default []) a list of values to select (if empty, all
%         entries are retained).
%
%      MIN
%         (scalar, default []) only values higher (strictly) than MIN are
%         retained.
%
%      MAX
%         (scalar, default []) only values lower (strictly) than MAX are
%         retained.
%
%      OPERATION
%         (string, default 'or') the operation that is applied to select
%         the frames. Available options: 'or' : merge the current selection
%         SELECT(E) with the result of the previous one. 'and' : intersect
%         the current selection SELECT(E) with the result of the previous
%         one.
%
%   FLAG_INTERCEPT
%      (boolean, default true) if FLAG_INTERCEPT is true, a constant
%      covariate will be added to the model.
%
%   FLAG_FILTER_NAN
%      (boolean, default true) if the flag is true, any observation
%      associated with a NaN in MODEL.X is removed from the model.
%   
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT (structure)with the following fields:
%
%   STACK
%       (double array) SxVxN array where S is the number of subjects, V is
%       the number of voxels and N the number of networks (if N=1, Matlab
%       displays the array as 2 dimensional, i.e. the last dimension gets
%       squeezed)
%
%   PROVENANCE
%       (structure) with the following fields:
%
%       SUBJECTS
%           (cell array) Sx2 cell array containing the names/IDs of
%           subjects in the same order as they are supplied in
%           FILES_IN.DATA and FILES_OUT.STACK. The first column contains
%           the names as they are suppiled in FILES_IN.DATA whereas the
%           second column contains the (optional) names that are taken from
%           the model file in FILES_IN.MODEL
%
%       MODEL
%           (structure, optional) Only available if OPT.FLAG_CONF is set to
%           true and a correct model was supplied. Contains the following
%           fields:
%
%           MATRIX
%               (double array, optional) Contains the model matrix that was
%               used to perform the confound regression.
%
%           CONFOUNDS
%               (cell array, optional) Contains the names of the covariates
%               in the model that are regressed from the input data
%
%       VOLUME
%           (structure) with the following fields:
%
%           NETWORK
%               (double array) Contains the network ID or IDs in the same
%               order that they appear in FILES_OUT.STACK
%
%           SCALE
%               (double) The scale of the network solution of the input
%               data (i.e. how many networks were available in the input
%               data).
%
%           MASK
%               (boolean array) The binary brain mask that can be used to
%               map the vectorized data in FILES_OUT.STACK back into volume
%               space.
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.


%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ASSOCIATION_TEST(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_association_test'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'weight' , 'model' },...
           { NaN      , NaN     });

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'network' , 'test_name' , 'fdr' , 'type_fdr' , 'cov' , 'coi' , 'interaction' , 'normalize_x' , 'normalize_y' , 'normalize_type' , 'select' , 'flag_intercept' , 'flag_filter_nan' , 'flag_verbose' , 'flag_test' },...
      { ''           , []        , NaN         , 0.05  , 'BH'       , {}    , NaN   , struct        , true          , false         ,  'mean'          , struct   , true             , true              , true           , false       });

% Since we don't know which optional parameters were set, we'll remove the
% empty default values again so they don't cause trouble downstream
if ~isstruct(opt.interaction)
    error('if specified, OPT.INTERACTION has to be a structure!');
elseif isempty(fieldnames(opt.interaction))
    % Option is empty, remove it
    opt = rmfield(opt, 'interaction');
    n_interactions = 0;
    interactions = {};
else
    n_interactions = size(opt.interaction,2);
    interactions = cell(n_interactions, 1);
    % Get the names of the interactions
    for n_inter = 1:n_interactions
        name_inter = opt.interaction(n_inter).label;
        interactions{n_inter} = name_inter;
    end 
end

if ~isstruct(opt.select)
    error('if specified, OPT.SELECT has to be a structure!');
elseif isempty(fieldnames(opt.select))
    % Option is empty, remove it
    opt = rmfield(opt, 'select');
end

% Load the model and check that the covariates and interactions are
% correctly specified
[model_data, labels_x, labels_y] = niak_read_csv(files_in.model);
% Check if covariates are specified
if isempty(opt.cov)
    % No covariates specified, take all covariates from the model
    opt.cov = labels_y;
    % Add all requested interactions, if there are any
    if n_interactions > 0
        opt.cov = [opt.cov, interactions];
    end
else
    % Make sure all the specified covariates exist
    n_cov = length(opt.cov);
    for cov_id = 1:n_cov
        % check if the covariate is available in the model or interactions
        if ~ismember(opt.cov{cov_id}, labels_y) && ~ismember(opt.cov{cov_id}, interactions)
            error('The requested covariate %s is not in FILES_IN.MODEL or designated as an interaction', opt.cov{cov_id});
        end
    end
end
% Check if all the specified interactions are also selected as covariates
for n_inter = 1:n_interactions
    if ~ismember(interactions{n_inter}, opt.cov)
        warning('The interaction %s is requested but not specified in OPT.COV and will therefore not be added to the model', interactions{n_inter});
    end
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read and prepare the group model
% Store the model in the internal structure
model_raw.x = model_data;
model_raw.labels_x = labels_x;
model_raw.labels_y = labels_y;

% Read the weight data
if opt.flag_verbose
    fprintf('Reading the weigfht data ...\n');
end

% Read the weights file
tmp = load(files_in.weight);
weights = tmp.weight_mat;
% Figure out how many cases we are dealing with
[n_sub, n_sbt, n_net] = size(weights);

% Prepare the variable for the p-value storage
pvals = zeros(n_net, n_sbt);
% The GLM results will be stored in a structure with the network names as
% subfield labels
glm_results = struct;

% Iterate over each network and perform the normalization and fitting
for net_id = 1:n_net
    % Specify the name of the current network
    net_name = sprintf('net_%d', net_id);
    % Select the weight matrix for the current network
    model_raw.y = weights(:, :, net_id);
    % Perform the model selection, adding the intercept and interaction,
    % and normalization - all in one step. This step is partly redundant
    % since the model will be the same for each network. However, since we
    % also want select and potentially normalize the data, we do this every
    % time.
    opt_model = struct;
    opt_model = rmfield(opt, {'folder_out', 'network', 'test_name',...
                              'flag_verbose', 'flag_test', 'fdr', 'type_fdr'});
    [model_norm, opt_model] = niak_normalize_model(model_raw, opt_model);
    % Fit the model
    opt_glm = struct;
    opt_glm.test  = 'ttest';
    opt_glm.flag_beta = true; 
    opt_glm.flag_residuals = true;
    [results, opt_glm] = niak_glm(model_norm, opt_glm);
    pvals(net_id, :) = results.pce;
    glm_results.(net_name) = results;
end

% Run FDR on the p-values
[fdr,test] = niak_fdr(pvals, opt.type_fdr, opt.fdr);

%% Create figures of the results
