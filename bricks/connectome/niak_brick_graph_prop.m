function [files_in,files_out,opt] = niak_brick_graph_prop(files_in,files_out,opt)
% Generate graph properties from a connectome
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GRAPH_PROP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (string) a .mat file  with the following variables:
%
%   CONN 
%      (vector) a vectorized version of the connectome
%
%   TYPE
%      (string) the type of connectome (see OPT.TYPE in NIAK_BRICK_CONNECTOME)
%
%   IND_ROI
%      (vector) the Nth row/column of CONN corresponds to the region IND_ROI(n) 
%      in the mask.
%
% FILES_OUT
%    (string) the name of a .mat file with all the measures stored in indiviual 
%    variables called (MEASURE) (with MEASURE being the name of the measure):
%
%    (MEASURE).TYPE (string) the type of measure
%    (MEASURE).PARAM (structure) the options of the measure
%    (MEASURE).VAL (type may vary) the measure
%
% OPT
%   (structure) with arbitrary fields (MEASURE). Each entry has the following fields:
%
%   (MEASURE).TYPE 
%      (string) the type of measure. Available options:
%
%      'degree_centrality': as defined in Buckner et al. 2009
%      'pairwise': simply extract the connectivity measure between a pair of regions
%      'clustering': the local clustering coefficient. See CLUSTERING_COEF_BU
%      'avg_clustering': the average clustering coefficient. See CLUSTERING_COEF_BU
%      'global_efficiency': the average of the inverse of shortest path length. See EFFICIENCY_BIN
%      'local_efficiency': same as 'global_efficiency' but restricted to the neighbourhood of each node. See EFFICIENCY_BIN
%
%   (MEASURE).PARAM (structure) the options of the measure. 
%
%      case 'degree_centrality':
%         THRESH (scalar, default 0.25) the threshold on connections
%         IND_ROI (scalar) the index of the ROI that is used to measure the degree centrality
%         FLAG_MEAN (boolean, default true) correct the mean of all connections to 0.
%
%      case 'pairwise'
%         IND_ROI1 (scalar) the index of the first ROI that defines the connection
%         IND_ROI2 (scalar) the index of second ROI that defines the connection
%
%      case 'clustering' 
%         SPARSITY (scalar, default 0.3) the proportion of connectivity to retain in 
%            each connectome.
%         IND_ROI (scalar) the index of the ROI that is used to measure the local clustering
%
%      case 'avg_clustering' 
%         SPARSITY (scalar, default 0.3) the proportion of connectivity to retain in 
%            each connectome.
%
%      case 'global_efficiency'
%         SPARSITY (scalar, default 0.3) the proportion of connectivity to retain in 
%            each connectome.
%
%      case 'local_efficiency'
%         SPARSITY (scalar, default 0.3) the proportion of connectivity to retain in 
%            each connectome.
%         IND_ROI (scalar) the index of the ROI that is used to measure the local clustering
%
%   FLAG_TEST
%       (boolean, default: 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
%   FLAG_VERBOSE
%       (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%       indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_CONNECTOME, NIAK_PIPELINE_CONNECTOME, CLUSTERING_COEF_BU
%
% _________________________________________________________________________
% COMMENTS:
%
% The measure 'degree_centrality' is described in the following paper:
%   Buckner et al. Cortical Hubs Revealed by Intrinsic Functional Connectivity:
%   Mapping, Assessment of Stability, and Relation to
%   Alzheimer’s Disease. The Journal of Neuroscience, February 11, 2009.
%
% The functional connectivity is thresholded at 0.25 in that work, but the 
% preprocessing used in this work included the regression of the global 
% signal. For this reason, the function by default correct the average of all connections 
% to zero. If the global average was actually regressed out, this flag can be turned off.
%
% Some of the measures employed here depend on function from the "brain connectivity toolbox"
%  https://sites.google.com/site/bctnet/Home/functions
% This software has to be installed to generate the networks properties. 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, connectome, atoms, fMRI
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

%% Defaults

% FILES_IN
if ~ischar(files_in)
    error('FILES_IN should be a string')
end

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

% OPTIONS
list_fields      = { 'flag_test'    , 'flag_verbose' };
list_defaults    = { false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults,false);

% Measures
list_mes = fieldnames(opt);
list_mes = list_mes(~ismember(list_mes,{'flag_test','flag_verbose'}));
for num_m = 1:length(list_mes)
    name = list_mes{num_m};
    opt.(name) = psom_struct_defaults(opt.(name),{'type','param'},{NaN,NaN});
    switch opt.(name).type
        case 'degree_centrality'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'thresh','ind_roi','flag_mean'},{0.25,NaN,true});
        case 'pairwise'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'ind_roi1','ind_roi2'},{NaN,NaN});
        case 'clustering'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'sparsity','ind_roi'},{0.3,NaN});
        case 'avg_clustering'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'sparsity'},{0.3});
        case 'global_efficiency'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'sparsity'},{0.3});            
        case 'local_efficiency'
            opt.(name).param = psom_struct_defaults(opt.(name).param,{'sparsity','ind_roi'},{0.3,NaN});
        otherwise
            error('%s is an unknown measure',opt.(name).type)
    end
end
mes = rmfield(opt,{'flag_test','flag_verbose'});

if opt.flag_test == 1
    return
end

%% Thre brick starts here

%% Read the connectome
if opt.flag_verbose
    fprintf('Reading connectome in file %s ...\n',files_in);
end
conn = load(files_in);

for num_m = 1:length(list_mes)
    name = list_mes{num_m};
    if opt.flag_verbose
        fprintf('Generating measure %s (type %s) ...\n',name,opt.(name).type);
    end
    
    switch mes.(name).type
    
        case 'degree_centrality'
        
            if opt.(name).param.flag_mean
                conn.conn = conn.conn - mean(conn.conn);
            end
            G = niak_vec2mat(conn.conn>=mes.(name).param.thresh);
            dG = sum(G,1)/size(G,1);
            dG = (dG - mean(dG))/std(dG);
            mes.(name).val = dG(conn.ind_roi == mes.(name).param.ind_roi);
            
        case 'pairwise'
        
            G = niak_vec2mat(conn.conn);
            mes.(name).val = G(conn.ind_roi == mes.(name).param.ind_roi1,conn.ind_roi == mes.(name).param.ind_roi2);
            
        case 'clustering'
            
            [G,order] = sort(conn.conn,'descend');
            G(min(ceil(mes.(name).param.sparsity * length(G)),length(G))+1:end) = 0;            
            G = G>0;
            G = niak_vec2mat(G(order),0);
            neigh = G(conn.ind_roi == mes.(name).param.ind_roi,:)>0;
            k = sum(neigh);
            if k<2
                 mes.(name).val = 0;
            else 
                 V = G(neigh,neigh);                 
                 mes.(name).val = sum(V(:))/(k^2-k);
            end
            
        case 'avg_clustering'
        
            [G,order] = sort(conn.conn,'descend');
            G(min(ceil(mes.(name).param.sparsity * length(G)),length(G))+1:end) = 0;
            G = G>0;
            G = niak_vec2mat(G(order),0);
            C = clustering_coef_bu(G);
            mes.(name).val = mean(C);
            
        case 'global_efficiency'
            
            [G,order] = sort(conn.conn,'descend');
            G(min(ceil(mes.(name).param.sparsity * length(G)),length(G))+1:end) = 0;
            G = G>0;
            G = niak_vec2mat(G(order),0);
            mes.(name).val = efficiency_bin(G);
            
        case 'local_efficiency'
        
            [G,order] = sort(conn.conn,'descend');
            G(min(ceil(mes.(name).param.sparsity * length(G)),length(G))+1:end) = 0;
            G = G>0;
            G = niak_vec2mat(G(order),0);
            e = efficiency_bin(G,1);
            mes.(name).val = e(conn.ind_roi == mes.(name).param.ind_roi);
            
    end
    
end

%% Save the results
if opt.flag_verbose
    fprintf('Saving outputs in %s ...\n',files_out);
end
save(files_out,'-struct','mes')