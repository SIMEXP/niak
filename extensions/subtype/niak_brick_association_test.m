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
%   FIGURES
%       (cell array,  default 'fig_association_<NETWORK>.pdf') path to the ...
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
                { 'stats'                            , 'csv'                             , 'figures'                                                       },...
                { [path_out 'association_stats.mat'] , [path_out 'results_overview.csv'] , make_paths(path_out, 'fig_association_net_%d.png', 1:opt.scale) });
else
    files_out = psom_struct_defaults(files_out,...
                { 'stats'           , 'csv'             , 'figures'         },...
                { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' });
end
  
%% Sanity Checks
% Since we don't know which optional parameters were set, we'll remove the
% empty default values again so they don't cause trouble downstream
if ~isstruct(opt.interaction)
    error('if specified, OPT.INTERACTION has to be a structure!');
elseif isempty(fieldnames(opt.interaction))
    % Option is empty, remove it
    opt = rmfield(opt, 'interaction');
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

% Check that we have an output name for every figure
if ~strcmp(files_out.figures, 'gb_niak_omitted')
    if ~length(files_out.figures) == opt.scale
        error('I have %d networks from FILES_IN.WEIGHTS but %d specified output files for FILES_OUT.FIGURES', opt.scale, length(files_out.figures));
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
    [results, ~] = niak_glm(model_norm, opt_glm);
    pvals(net_id, :) = results.pce;
    glm_results.(net_name) = results;
end

% Run FDR on the p-values
[fdr,fdr_test] = niak_fdr(pvals, opt.type_fdr, opt.fdr);

% Save the model and FDR test
if ~strcmp(files_out.stats, 'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Saving stats to %s\n', files_out.stats);
    end
    save(files_out.stats, 'model_norm', 'model_raw', 'fdr', 'fdr_test', 'results');
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

%% Visualize the weights and covariate of interest
if ~strcmp(files_out.figures, 'gb_niak_omitted')
    % First, get the covariate of interest. 
    contrasts = fieldnames(opt.contrast);
    n_contrasts = length(contrasts);
    coi_name = '';
    for con_id = 1:n_contrasts
        contrast_name = contrasts{con_id};
        if opt.contrast.(contrast_name) ~= 0 && isempty(coi_name)
            coi_name = contrast_name;
        elseif opt.contrast.(contrast_name) ~= 0 && ~isempty(coi_name)
            error('Contrast %s is nonzero but contrast %s is also nonzero. I can only deal with one contrast', contrast_name, coi_name);
        end
    end
    % Determine whether the coi is an interaction
    if ismember(coi_name, model_raw.labels_y)
        % This was specified in the original model, we can take it from there. Find
        % the index of the column
        coi_col = find(strcmp(coi_name, model_raw.labels_y));
        coi = model_raw.x(:, coi_col);
    else
        % This was not in the original model, we need to retrieve it from the
        % normalized, contstrained model
        coi_col = find(strcmp(coi_name, model_norm.labels_y));
        coi = model_norm.x(:, coi_col);
    end
    % Determine whether the coi is categorical
    coi_unique = unique(coi);
    n_unique = length(coi_unique);
    if n_unique > 2
        coi_cat = false;
    else
        coi_cat = true;
        coi_ind = coi==coi_unique(1);
    end

    % Determine the number of rows and columns for the subyptes
    n_cols = floor(sqrt(n_sbt));
    n_rows = ceil(n_sbt/n_cols);

    % Make a figure for each network
    for net_id = 1:opt.scale
        % Start with the figure
        fh = figure('Visible', 'off');
        title(sprintf('Network %d, Association w %s', net_id, coi_name));
        % Go through the subtypes
        for sbt_id = 1:n_sbt
            % Get the subtype weights
            sbt_weights = weights(:, sbt_id, net_id);
            % Create the subplot
            subplot(n_rows, n_cols, sbt_id);
            ax = gca;
            % Chose whether to plot categorical or dimensional data
            if coi_cat
                % Work around the incompatibilities between Matlab and Octave for
                % the boxplot
                is_octave = logical(exist('OCTAVE_VERSION', 'builtin') ~= 0);
                % Generate the boxplots
                if is_octave
                    % The groups are supposed to go in a cell
                    boxplot({sbt_weights(coi_ind), sbt_weights(~coi_ind)}); 
                else
                    % The groups can be in a vector
                    boxplot(sbt_weights, coi_ind);
                end
                % Set the x axis ticks and labels
                ax.XTickLabel = cellstr(num2str(coi_unique));
            else
                % This is a dimensional variable
                % Fit a regression line between the weights and the covariate
                plot_model.x = [ones(size(coi)), coi];
                plot_model.y = sbt_weights;
                [res, ~] = niak_glm(plot_model, struct('flag_beta', true));
                x_fit = linspace(min(coi),max(coi),10);
                y_fit = res.beta(1) + x_fit.*res.beta(2);
                % Make the scatterplot
                hold on;
                plot(coi, sbt_weights, '.k');
                plot(x_fit, y_fit, 'r');
                hold off;
                disp('done');
            end
            xlabel(ax, coi_name);
            title(sprintf('Subtype %d', sbt_id));
        end
        if opt.flag_verbose
            fprintf('Saving association plot to %s\n', files_out.figures{net_id});
        end
        print(fh, files_out.figures{net_id}, '-dpng');
    end
end
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
        out_str = 'No results passed FDR';
    else
        out_str = 'Network,Subtype,Association,T_value,P_value,FDR\n';
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