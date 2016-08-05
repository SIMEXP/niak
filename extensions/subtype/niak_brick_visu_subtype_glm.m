function [files_in,files_out,opt] = niak_brick_visu_subtype_glm(files_in, files_out, opt)
% Generating graphs to visualize results of subtype association tests
%
% SYNTAX: [FILE_IN,FILE_OUT,OPT] =
% NIAK_BRICK_association_test(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   WEIGHT
%       (string) path to a weight matrix. First column expected to be
%       subjects ordered the same way as in the MODEL_RAW.LABELS_X variable
%       in the ASSOCIATION mat file
%
%   ASSOCIATION
%       (string) path to a .mat file containing variables MODEL_RAW and
%       MODEL_NORM that contain information, including variables of
%       interest, for each subject
%
% FILES_OUT
%   (structure) with the following field:
%
%   FIGURES
%       (cell array,  default 'fig_association_<NETWORK>.pdf') path to the
%       figures illustrating GLM results
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   CONTRAST
%      (structure, with fields <NAME>, which needs to correspond
%      to the label of one column in the file FILES_IN.MODEL) The fields
%      found in CONTRAST will determine which covariates enter the model:
%
%      <NAME>
%         (scalar) the weight of the covariate NAME in the contrast.
%
%   DATA_TYPE
%       (string, either 'continuous' or 'categorical') the kind of data in
%       OPT.CONTRAST.<NAME>
%
%   SCALE
%       (integer) the scale of the network solutions
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_VISU_SUBTYPE_GLM(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_visu_subtype_glm'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'weight' , 'association' },...
           { NaN      , NaN     });

% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults(opt,...
      { 'folder_out', 'scale' , 'contrast' , 'data_type', 'flag_verbose' , 'flag_test' },...
      { ''          , NaN     , NaN        , NaN        , true           , false       });

% FILES_OUT
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'figures'                                                       },...
                { make_paths(path_out, 'fig_association_net_%d.pdf', 1:opt.scale) });
else
    files_out = psom_struct_defaults(files_out,...
                { 'figures'         },...
                { 'gb_niak_omitted' });
end

%% Sanity Checks
% Since we don't know which optional parameters were set, we'll remove the
% empty default values again so they don't cause trouble downstream

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
temp = load(files_in.association);
model_raw = temp.model_raw;
model_norm = temp.model_norm;

%% Read the weights
% Read the weight data
if opt.flag_verbose
    fprintf('Reading the weight data ...\n');
end
% Load the weights
tmp = load(files_in.weight);
weights = tmp.weight_mat;
% Figure out how many cases we are dealing with
[n_sub, n_sbt, n_net] = size(weights);

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
    % Determine whether the coi is categorical or continuous
    if strcmp(opt.data_type, 'continuous')
        coi_cat = false;
    else
        coi_cat = true;
    end

    % Determine the number of rows and columns for the subyptes
    n_cols = floor(sqrt(n_sbt));
    n_rows = ceil(n_sbt/n_cols);
    
    %% Work around the incompatibilities between Matlab and Octave 
    is_octave = logical(exist('OCTAVE_VERSION', 'builtin') ~= 0);

    % Make a figure for each network
    for net_id = 1:opt.scale
        % Start with the figure
        fh = figure('Visible', 'off');
        % Go through the subtypes
        for sbt_id = 1:n_sbt
            % Get the subtype weights
            sbt_weights = weights(:, sbt_id, net_id);
            % Create the subplot
            subplot(n_rows, n_cols, sbt_id);
            ax = gca;
            % Chose whether to plot categorical or dimensional data
            if coi_cat
                coi_unique = unique(coi); % find unique grouping values
                n_unique = length(coi_unique); % the number of unique grouping values
                % Generate the boxplots
                if is_octave
                    % The groups are supposed to go in a cell
                    for cc = 1:n_unique
                        sbt_cell{cc} = sbt_weights(coi == coi_unique(cc)); 
                    end
                    boxplot(sbt_cell);
                else
                    % The groups can be in a vector
                    boxplot(sbt_weights, coi);
                end
                % Set the x axis ticks and labels
                nan_coi = find(isnan(coi_unique));
                coi_unique(nan_coi) = []; % remove the NaN values from grouping values
                set(ax,'xtick', 1:length(coi_unique'), 'xticklabel', cellstr(num2str(coi_unique)));
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
            title(sprintf('Subtype %d', sbt_id));
        end
        xlabel(ax, coi_name);
        ylabel(ax, 'Weight');
        if opt.flag_verbose
            fprintf('Saving association plot to %s\n', files_out.figures{net_id});
        end
        subtitle(sprintf('Network %d, Association w %s', net_id, coi_name));
        print(fh, files_out.figures{net_id}, '-dpdf');
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

function [ax,h] = subtitle(text)

% Centers a title over a group of subplots.
% Returns a handle to the title and the handle to an axis.
%   [ax,h] = subtitle(text)
%           returns handles to both the axis and the title.
%   ax = subtitle(text)
%           returns a handle to the axis only.
%   Input variable TEXT must be a string.

ax = axes('Units','Normal','Position',[.1 0.1 .85 .85],'Visible','Off');
set(get(ax,'Title'),'Visible','on')
title(text);
if (nargout < 2)
    return
end
h = get(ax,'Title');
end
