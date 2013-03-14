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
%   G
%      (vector) a binarized version of the connectome
%
%   TYPE
%      (string) the type of connectome (see OPT.TYPE in NIAK_BRICK_CONNECTOME)
%
%   THRESH
%      (structure) parameters of the binarization of the connectome. See the OPT 
%      argument of NIAK_BUILD_GRAPH
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
%    (MEASURE).PARAM (type may vary) the parameters of the measure
%    (MEASURE).VAL (type may vary) the measure
%
% OPT
%   (structure) with arbitrary fields (MEASURE). Each entry has the following fields:
%
%   (MEASURE).TYPE 
%      (string) the type of measure. Available options:
%
%      'Dcentrality': as defined in Buckner et al. 2009
%      'p2p': simply extract the "point-to-point" connectivity measure between a pair of regions.
%      'clustering': the local clustering coefficient. See CLUSTERING_COEF_BU.
%      'avg_clustering': the average clustering coefficient. See CLUSTERING_COEF_BU.
%      'global_eff': the global efficiency, i.e. the average of the inverse of shortest path length. See EFFICIENCY_BIN.
%      'local_eff': the local efficiency, i.e. the inverse of shortest path length in the neighbourhood of each node. See EFFICIENCY_BIN.
%      'modularity': the network modularity. See MODULARITY_UND.
%
%   (MEASURE).PARAM
%      Options of the measure. Types/values depend on the measure:
%      'Dcentrality': (scalar) the index of the ROI that is used to measure the degree centrality.
%      'p2p' (vector) the indices of the first and second ROI that define the connection.
%      'clustering' (scalar) the index of the ROI that is used to measure the local clustering.
%      'avg_clustering' None.
%      'global_eff' None.
%      'local_eff'(scalar) the index of the ROI that is used to measure the local clustering.
%      'modularity' None.
%
%   RAND_SEED
%       (scalar, default 0) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED for each job. If left empty,
%       the generator is initialized based on the clock (the results will be
%       slightly different due to random variations in bootstrap sampling if
%       the pipeline is executed twice).
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
% NIAK_BRICK_CONNECTOME, NIAK_PIPELINE_CONNECTOME, NIAK_BUILD_GRAPH
%
% _________________________________________________________________________
% COMMENTS:
%
% The measure 'Dcentrality' is described in the following paper:
%   Buckner et al. Cortical Hubs Revealed by Intrinsic Functional Connectivity:
%   Mapping, Assessment of Stability, and Relation to
%   Alzheimer’s Disease. The Journal of Neuroscience, February 11, 2009.
%
% Some of the measures employed here depend on function from the "brain connectivity toolbox"
%   https://sites.google.com/site/bctnet/Home/functions
% This software has to be installed to generate the networks properties, and is described 
% in the following paper:
%   Rubinov, M., Sporns, O., Sep. 2010. 
%   Complex network measures of brain connectivity: Uses and interpretations. 
%   NeuroImage 52 (3), 1059-1069.
%   URL http://dx.doi.org/10.1016/j.neuroimage.2009.10.003
%
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
list_fields      = { 'rand_seed' , 'flag_test'    , 'flag_verbose' };
list_defaults    = { 0           , false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults,false);

% Measures
list_mes = fieldnames(opt);
list_mes = list_mes(~ismember(list_mes,{'rand_seed','flag_test','flag_verbose'}));
for num_m = 1:length(list_mes)
    name = list_mes{num_m};    
    opt.(name) = psom_struct_defaults(opt.(name),{'type','param'},{NaN,[]});
    switch opt.(name).type
        case 'Dcentrality'
            
        case 'p2p'
            if length(opt.(name).param)~=2
                error('Please provide two indices to generate point-2-point connectivity in measure %s',mes)
            end
        case 'clustering'
            if length(opt.(name).param)~=1
                error('Please provide an index to generate local clustering in measure %s',mes)
            end
        case 'avg_clustering'
            
        case 'global_efficiency'
            
        case 'local_efficiency'
            if length(opt.(name).param)~=1
                error('Please provide an index to generate local clustering in measure %s',mes)
            end
        case 'modularity'
        
        otherwise
            error('%s is an unknown measure',opt.(name).type)
    end
end
mes = rmfield(opt,{'rand_seed','flag_test','flag_verbose'});

if opt.flag_test == 1
    return
end

%% Thre brick starts here

%% Set the random number generator if necessary
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the connectome
if opt.flag_verbose
    fprintf('Reading connectome in file %s ...\n',files_in);
end
conn = load(files_in,'conn','G','ind_roi');
G = niak_vec2mat(conn.G,false);
ind_roi = conn.ind_roi;
conn = conn.conn;

for num_m = 1:length(list_mes)
    name = list_mes{num_m};
    if opt.flag_verbose
        fprintf('Generating measure %s (type %s) ...\n',name,opt.(name).type);
    end
    
    switch mes.(name).type
    
        case 'Dcentrality'
        
            dG = sum(G,1)/size(G,1);
            dG = (dG - mean(dG))/std(dG); % the degree centrality is simply the degree, corrected to have a zero mean, unit variance distribution across the brain
            mes.(name).val = dG(ind_roi == mes.(name).param);
            
        case 'p2p'
        
            G = niak_vec2mat(conn); % For point-to-point, the graph is the weighted connectome
            mes.(name).val = G(ind_roi == mes.(name).param(1),ind_roi == mes.(name).param(2));
            
        case 'clustering'
                        
            C = clustering_coef_bu(G);
            mes.(name).val = C(ind_roi == mes.(name).param);            
            
        case 'avg_clustering'        
            
            mes.(name).val = mean(clustering_coef_bu(G));
            
        case 'global_efficiency'            
            
            mes.(name).val = efficiency_bin(G);
            
        case 'local_efficiency'
                    
            e = efficiency_bin(G,1);
            mes.(name).val = e(ind_roi == mes.(name).param);
            
        case 'modularity'
           
            [Ci,mes.(name).val] = modularity_und(G);            
            
    end
    
end

%% Save the results
if opt.flag_verbose
    fprintf('Saving outputs in %s ...\n',files_out);
end
save(files_out,'-struct','mes')