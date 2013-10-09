function iir = niak_build_intra_inter_r(tseries,part,flag_vec,flag_fisher)
% Compute the average correlation intra / inter clusters
%
% SYNTAX:
% IIR = NIAK_BUILD_INTRA_INTER_R(TSERIES,PART,FLAG_VEC)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%   (2D array) tseries(:,i) is the time series of the ith region
%
% PART          
%   (vector) find(part==j) is the list of region in cluster j. In other 
%   words, part(i) is the number of the cluster of region i.
%
% FLAG_VEC
%   (boolean, default false) if FLAG_VEC == true, the output matrix is
%   "vectorized" using NIAK_MAT2LVEC and the redundant elements are 
%   suppressed. Use NIAK_LVEC2MAT to unvectorize it.
%       
% FLAG_FISHER
%   (boolean, default true) if FLAG_FISHER is true, a Fisher transform is 
%   applied on the measure. See NIAK_FISHER.
%
% _________________________________________________________________________
% OUTPUTS:
%
% IIR
%   (matrix or vector) IIR(i,j) for i~=j is the correlation between the mean
%   signal of (PART==i) and (PART==j). IIR(i) is the average correlation 
%   between distinct pairs of elements within (PART==i). If a cluster has only
%   one element IIR(i) equals 0.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de 
%               Gériatrie de Montréal, Département d'informatique et de recherche 
%               opérationnelle, Université de Montréal, 2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : correlation, clusters, intra- / inter- cluster

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

if nargin < 3
    flag_vec = false;
end

if nargin < 4
    flag_fisher = true;
end

nb_netwk = max(part);
iir = zeros([nb_netwk nb_netwk]);

% Computation of the mean signal per network
opt_t.correction.type = 'mean_var';
tseries = niak_build_tseries(tseries,part(:),opt_t);
N = niak_build_size_roi(part(:));

% Build the matrix 
iir = niak_build_correlation(tseries);
ir = var(tseries,[],1)';       
mask_0 = (N==0)|(N==1);
N(mask_0) = 10;
ir = ((N.^2).*ir-N)./(N.*(N-1));
ir(mask_0) = 0;
iir(eye(size(iir))>0) = ir; % A tricky formula to add the average correlation within each network, at the voxel level, on the diagonal
if flag_vec
    iir = niak_mat2lvec(iir);
end
if flag_fisher
    iir = niak_fisher(iir);
end