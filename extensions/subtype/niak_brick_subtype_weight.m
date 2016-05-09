function [files_in,files_out,opt] = niak_brick_subtype_weight(files_in, files_out, opt)
% Extract individual subtype weights for predefined subtypes across a range
% of networks
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPE_WEIGHT(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   DATA.<NETWORK>
%       (string) path to the network stack with the preprocessed individual 
%       brain maps for each network
%
%   SUBTYPE.<NETWORK>
%       (string) path to the subtype maps for that network
%
%   SIM_MATRIX.<NETWORK>
%       (string) path to the similarity matrix and hierarchical clustering
%       of subjects for that network
%
% FILES_OUT
%   (structure) structure with the following fields:
%
%   WEIGHTS
%       (string, default 'subtype_weights.mat') path to ...
%
%   WEIGHTS_CSV
%       (cell array, default 'sbt_weights_net_<NETWORK>.csv') path to ...
%
%   WEIGHTS_PDF
%       (cell array, default 'fig_sbt_weights_net_<NETWORK>.pdf') path to ...
%
% OPT
%   (structure) with the following fields:
%
%   SCALES
%       (array, default 1:<# of inputs in FILES_IN.DATA>) the array of
%       networks in the same order as inputs in FILES_IN.DATA. If left
%       unspecified, the inputs in FILES_IN.DATA are expected to be
%       continuous network numbers, starting with 1.
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do 
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
% Centre de recherche de l'institut de Gériatrie de Montréal, 
% Département d'informatique et de recherche opérationnelle, 
% Université de Montréal, 2010-2016.
% Maintainer : sebastian.urchs@mail.mcgill.ca
% See licensing information in the code.
% Keywords : subtype, weights, clustering

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

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPE_WEIGHT(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtype_weight'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'data' , 'subtype' , 'sim_matrix' },...
           { NaN    , NaN       , NaN});

% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults(opt,...
      { 'scales'                             , 'folder_out' , 'flag_verbose' , 'flag_test' },...
      { 1:length(fieldnames(files_in.data)) , ''           , true           , false       });

% FILES_OUT
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'weights'                , 'weights_csv'                                              , 'weights_pdf'                                                  },...
                { [path_out 'subtype_weights.mat'] , make_paths([path_out 'sbt_weights_net_%d.csv'], opt.scales) , make_paths([path_out 'fig_sbt_weights_net_%d.pdf'], opt.scales) });
else
    files_out = psom_struct_defaults(files_out,...
                { 'weights'         , 'weights_csv'     , 'weights_pdf' },...
                { 'gb_niak_omitted' , {}                , {}            });
end
  
  
% Make sure we have the same order and set of networks for data and subtype
if ~isequal(fieldnames(files_in.subtype), fieldnames(files_in.data))
    error(['The order or set of networks in files_in.subtype and '...
          'files_in.data does not match!']);
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Brick begins here
% Get the set of networks
networks = fieldnames(files_in.data);
% Get the number of networks
n_networks = length(networks);
% Set up the weight matrix with empty dimensions since we don't yet know
% how many subjects to expect
weight_mat = [];

% Iterate over the networks and extract the weights
for net_id = 1:n_networks
    network = networks{net_id};
    % Get the network stack data
    tmp_data = load(files_in.data.(network));
    data = tmp_data.stack;
    % Get the network subtype maps (i.e. for each subtype one)
    tmp_sbt = load(files_in.subtype.(network));
    sbt = tmp_sbt.sub.map;
    
    % If this is the first network, pre-allocate the weight matrix
    if net_id == 1
        % Get the number of subtypes
        n_sbt = size(sbt, 1);
        % Get the number of subjects
        n_sub = size(data, 1);
        weight_mat = zeros(n_sub, n_sbt, n_networks);
    end
    % Extract the weights and store them 
    weight_mat(:, :, net_id) = niak_corr(data', sbt');
end

% Save the weight matrix
save(files_out.weights, 'weight_mat');

%% Write the weight matrix for each network as a csv

for net_id = 1:n_networks
    network = networks{net_id};
    % Get the subject list
    tmp_list_sub = load(files_in.data.(network));
    list_sub = tmp_list_sub.provenance.subjects(:,1);
    % Retrieve the correct weight matrix
    net_weight = weight_mat(:, :, net_id);
    file_name = files_out.weights_csv{net_id, 1};
    % Labels for the csv
    name_clus = {}; % empty cell array for cluster lables because we don't know how many subtypes there are yet
    tmp_sbt = load(files_in.subtype.(network));
    sbt = tmp_sbt.sub.map;
    n_sbt = size(sbt, 1); % get number of subtypes from files_in.subtype.(network)
    for cc = 1:n_sbt
        name_clus{cc} = ['sub' num2str(cc)]; % store the subtype labels
    end
    opt_w.labels_y = name_clus;
    opt_w.labels_x = list_sub;
    opt_w.precision = 3;
    niak_write_csv(file_name, net_weight, opt_w); % Write the csv
end

%% Visualize the weight matrix for each network as a pdf

for net_id = 1:n_networks
    network = networks{net_id};
    
    % Get the subject order from files_in.sim_matrix
    sim_matrix = load(files_in.sim_matrix.(network));
    subj_order = sim_matrix.subj_order;
    
    % Create a hidden figure
    fig = figure('Visible', 'off');
    net_weight = weight_mat(:, :, net_id);
    niak_visu_matrix(net_weight(subj_order,:), struct('limits', [-0.4, 0.4]));
    ax = gca;
    set(ax, 'XTick', 1:n_sbt, 'YTick', []);
    xlabel('Subtypes');
    file_name = files_out.weights_pdf{net_id, 1};
    print(fig, file_name, '-dpdf');
end

function path_array = make_paths(template, scales)
    % Get the number of networks
    n_networks = length(scales);
    path_array = cell(n_networks, 1);
    for sc_id = 1:n_networks
        sc = scales(sc_id);
        path = sprintf(template, sc);
        path_array{sc_id, 1} = path;
    end
return