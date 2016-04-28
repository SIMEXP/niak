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
% FILES_OUT
%   (string) the path where the output files are to be generated
%
% OPT
%   (structure) with the following fields:
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
           { 'data' , 'subtype' },...
           { NaN    , NaN       });

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

% Options
if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults(opt,...
      { 'flag_verbose' , 'flag_test' },...
      { true           , false       });

%% Sanity checks
% Make sure we have the same order and set of networks for data and subtype
if ~isequal(fieldnames(files_in.subtype), fieldnames(files_in.data))
    error(['The order or set of networks in files_in.subtype and '...
          'files_in.data does not match!']);
end

%% If the test flag is true, stop here !
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
    network = networks(net_id);
    % Get the network data
    tmp_data = load(files_in.data.(network));
    data = tmp_data.data;
    % Get the network subtypes
    tmp_sbt = load(files_in.subtype.(network));
    sbt = tmp_sbt.sbt_map;
    
    % If this is the first network, pre-allocate the weight matrix
    if net_id == 1
        weight_mat = zeros([size(sbt), n_networks]);
    end
    % Extract the weights and store them 
    weight_mat(:, :, net_id) = niak_corr(data', sbt');
end

% Save the weight matrix
file_name = [files_out filesep 'subtype_weights.mat'];
save(file_name, 'weight_mat');

%% Write the weight matrix for each network as a csv
for net_id = 1:n_networks
   % Retrieve the correct weight matrix
   net_weight = weight_mat(:, :, net_id);
   file_name = [files_out filesep sprintf('sbt_weights_net_%d.csv', net_id)];
   niak_write_csv(file_name, net_weight);
end

%% Visualize the weight matrix for each network as a pdf
for net_id = 1:n_networks
    % Create a hidden figure
    fig = figure('Visible', 'off');
    net_weight = weight_mat(:,:,net);
    niak_visu_matrix(net_weight, struct('limits', [-0.4, 0.4]));
    file_name = [files_out filesep sprintf('fig_sbt_weights_net_%d.pdf', net)];
    print(fig, file_name, '-dpdf');
end
