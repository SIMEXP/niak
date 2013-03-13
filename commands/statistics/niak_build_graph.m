function G = niak_build_graph(conn,opt);
% Binarize a connectivity matrix to generate an undirected graph
%
% SYNTAX:
% G = NIAK_BUILD_GRAPH(CONN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% CONN (vector) a vectorized connectivity matrix (see NIAK_MAT2VEC)
% OPT.TYPE (string) type of binarization applied to the connectome to generate 
%   an undirected graph. Available options:
%   'sparsity' keep a proportion of the largest connection (in absolute value)
%   'sparsity_pos' keep a proportion of the largest connection (positive only)
%   'cut_off' a cut-off on connectivity (in absolute value)
%   'cut_off_pos' a cut-off on connectivity (only positive)
% OPT.PARAM (depends on OPT.TYPE) the parameter of the 
%   optolding. The actual definition depends of THRESH.TYPE:
%   'sparsity' (scalar) percentage of connections
%   'sparsity_pos' (scalar) percentage of connections
%   'cut_off' (scalar) the cut-off
%   'cut_off_pos' (scalar) the cut-off
%
% _________________________________________________________________________
% OUTPUTS:
%
% G (vector, boolean) a vectorized and binarized version of the graph
%   See NIAK_VEC2MAT to get back the squared form. 
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : statistics, undirected graph

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

opt = psom_struct_defaults(opt,{'type','param'},{NaN,NaN});

switch opt.type
        case 'sparsity'            
            [val,order] = sort(abs(conn),'descend');
            G = false(size(conn));
            G(order(1:min(ceil(opt.param * length(G)),length(G)))) = true;            
        case 'sparsity_pos'
            [val,order] = sort(conn,'descend');
            G = false(size(conn));
            G(order(1:min(ceil(opt.param * length(G)),length(G)))) = true;            
        case 'cut_off'
            G = abs(conn)>=opt.param;
        case 'cut_off_pos'
            G = conn>=opt.param;
        otherwise
            error('%s is an unkown type of binarization method',opt.type);
    end