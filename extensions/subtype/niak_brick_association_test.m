function [files_in,files_out,opt] = niak_brick_association_test(files_in, files_out, opt)
% Statistical tests for the significance of associations between subtype
% weights and variables of interest
%
% SYNTAX: [FILE_IN,FILE_OUT,OPT] =
% NIAK_BRICK_ASSOCIATION_TEST(FILE_IN,FILE_OUT,OPT)
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
% FILES_OUT
%   (structure) with the following fields:
%
%   STATS
%       (string) path to the .mat file containing the fitted GLM and FDR results
%
%   CSV
%       (string, default 'results_overview.csv') path to the .csv file
%       containing the overview of significant results passing FDR
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   SCALE
%       (integer) the scale of the network solutions
%
%   NETWORK
%       (int array, default all networks) A list of networks number in
%       individual maps
%
%   FDR
%      (scalar, default 0.05) the level of acceptable false-discovery rate
%      for the t-maps.
%
%   TYPE_FDR
%      (string, default 'BH') how the FDR is controled. See the METHOD
%      argument of NIAK_FDR.
%
%   CONTRAST
%      (structure, with fields <NAME>, which needs to correspond
%      to the label of one column in the file FILES_IN.MODEL) The fields
%      found in CONTRAST will determine which covariates enter the model:
%
%      <NAME>
%         (scalar) the weight of the covariate NAME in the contrast.
%
%   INTERACTION
%      (structure array, optional) with multiple entries and the following
%      fields:
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

% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'scale' , 'network' , 'fdr' , 'type_fdr' , 'contrast' , 'interaction' , 'normalize_x' , 'normalize_y' , 'normalize_type' , 'select' , 'flag_intercept' , 'flag_filter_nan' , 'flag_verbose' , 'flag_test' },...
      { ''           , NaN     , []        , 0.05  , 'BH'       , NaN        , struct        , true          , false         ,  'mean'          , struct   , true             , true              , true           , false       });

% FILES_OUT
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'stats'                            , 'csv'                             },...
                { [path_out 'association_stats.mat'] , [path_out 'results_overview.csv'] });
else
    files_out = psom_struct_defaults(files_out,...
                { 'stats'           , 'csv'             },...
                { 'gb_niak_omitted' , 'gb_niak_omitted' });
end

%% Sanity Checks
% Since we don't know which optional parameters were set, we'll remove the
% empty default values again so they don't cause trouble downstream
if ~isstruct(opt.interaction)
    error('if specified, OPT.INTERACTION has to be a structure!');
elseif isempty(fieldnames(opt.interaction))
    % Option is empty, remove it
    opt = rmfield(opt, 'interaction');
    n_interactions = 0;
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

% Check if covariates are specified
if ~isstruct(opt.contrast)
    %misspecified contrasts
    error('OPT.CONTRAST has to be a structure');
end

% Make sure the main effects of the requested interactions are also requested as
% contrasts
contrasts = fieldnames(opt.contrast);
if isfield(opt, 'interaction')
    for n_inter = 1:n_interactions
        % Get the factors for this interaction
        int_facs = length(opt.interaction(n_inter).factor);
        n_facs = length(int_facs);
        for ifac = 1:n_facs
            fac_name = opt.interaction(n_inter).factor{ifac};
            if ~ismember(fac_name, contrasts)
                % One of the factors for this interaction is not a contrast. We need
                % to change that
                warning('The interaction %s is based on factor %s but there is no contrast for this factor. I will add a zero contrast.\n', interactions{n_inter}, fac_name);
                opt.contrast.(fac_name) = 0;
            end
        end
    end
end


%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read and prepare the group model
% Read the model data
if opt.flag_verbose
    fprintf('Reading the model data ...\n');
end
[model_data, labels_x, labels_y] = niak_read_csv(files_in.model);

% Store the model in the internal structure
model_raw.x = model_data;
model_raw.labels_x = labels_x;
model_raw.labels_y = labels_y;

% Read the weight data
if opt.flag_verbose
    fprintf('Reading the weight data ...\n');
end

% Read the weights file
tmp = load(files_in.weight);
weights = tmp.weight_mat;
% Figure out how many cases we are dealing with
[n_sub, n_sbt, n_net] = size(weights);

% Prepare the variable for the p-value storage
pvals = zeros(opt.scale, n_sbt);
% The GLM results will be stored in a structure with the network names as
% subfield labels
glm_results = struct;
net_names = cell(opt.scale);

% Iterate over each network and perform the normalization and fitting
for net_id = 1:opt.scale
    % Specify the name of the current network
    net_name = sprintf('net_%d', net_id);
    net_names{net_id} = net_name;
    % Select the weight matrix for the current network
    model_raw.y = weights(:, :, net_id);
    % Perform the model selection, adding the intercept and interaction,
    % and normalization - all in one step. This step is partly redundant
    % since the model will be the same for each network. However, since we
    % also want select and potentially normalize the data, we do this every
    % time.
    opt_model = rmfield(opt, {'folder_out', 'network', 'flag_verbose', ...
                              'flag_test', 'fdr', 'type_fdr', 'scale'});
    [model_norm, ~] = niak_normalize_model(model_raw, opt_model);
    % Fit the model
    opt_glm = struct;
    opt_glm.test  = 'ttest';
    opt_glm.flag_beta = true;
    opt_glm.flag_residuals = true;
    opt_glm.flag_rsquare = true;
    [results, ~] = niak_glm(model_norm, opt_glm);
    pvals(net_id, :) = results.pce;
    glm_results.(net_name) = results;
end

% Run FDR on the p-values
[fdr_vec,fdr_test_vec] = niak_fdr(pvals(:), opt.type_fdr, opt.fdr);
% Reshape FDR results to network by subtype array
fdr = reshape(fdr_vec, n_net, n_sbt);
fdr_test = reshape(fdr_test_vec, n_net, n_sbt);

% Save the model and FDR test
if ~strcmp(files_out.stats, 'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Saving stats to %s\n', files_out.stats);
    end
    save(files_out.stats, 'model_norm', 'model_raw', 'fdr', 'fdr_test', 'glm_results');
end

%% Create result summaries
if ~strcmp(files_out.csv, 'gb_niak_omitted')
    % Summarize the results
    out_str = summarize_results(fdr_test, glm_results, pvals, fdr)

    % Save the string to file
    if opt.flag_verbose
        fprintf('Saving results overview to %s\n', files_out.csv);
    end
    fid = fopen(files_out.csv,'wt');
    fprintf(fid, out_str);
    fclose(fid);
end

function path_array = make_paths(out_path, template, scales)
    % Get the number of networks
    n_networks = length(scales);
    path_array = cell(n_networks, 1);
    for sc_id = 1:n_networks
        sc = scales(sc_id);
        path = fullfile(out_path, sprintf(template, sc));
        path_array{sc_id, 1} = path;
    end
return
end

function out_str = summarize_results(fdr_test, glm_results, pvals, fdr)

    [net_ids, sbt_ids] = find(fdr_test);
    % Sort the subtypes by the network IDs
    [~, ind] = sort(net_ids);
    net_ids = net_ids(ind);
    sbt_ids = sbt_ids(ind);
    % Check if any results passed FDR
    if isempty(net_ids)
        warning('No results passed FDR');
        out_str = ' ,Results\n';
        out_str = [out_str sprintf(' ,No results passed FDR')];
    else
        out_str = ' ,Subtype,Association,T_value,P_value,FDR\n';
        % Iterate over the significant findings
        for res_id = 1:length(net_ids)
            net_id = net_ids(res_id);
            sbt_id = sbt_ids(res_id);
            net_name = net_names{net_id};
            % Get the corresponding T-, p-, and FDR-values
            t_val = glm_results.(net_name).ttest(sbt_id);
            p_val = pvals(net_id, sbt_id);
            fdr_val = fdr(net_id, sbt_id);
            % Determine the direction of the association
            if t_val > 0
                direction = 'positive';
            else
                direction = 'negative';
            end
            % Assemble the out string
            out_str = [out_str sprintf('%s,%d,%s,%d,%d,%d\n', net_name, sbt_id,...
                                                             direction, t_val,...
                                                             p_val,fdr_val)];
        end
    end
end
end
