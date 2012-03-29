function tseries_m = niak_mean_tseries(tseries,clusters,atoms)
% Average time series within clusters
%
% SYNTAX:
% TSERIES_M = NIAK_MEAN_TSERIES(TSERIES,CLUSTERS,ATOMS)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES
%   (2D array) TSERIES is a 2D array where each column of TSERIES is 
%   a time series.
%
% CLUSTERS
%   (3D array or vector) cluster #I is equal to (CLUSTERS==I).
%
% ATOMS
%   (same size as clusters) the Kth time series is associated with (ATOMS==K).
% _________________________________________________________________________
% OUTPUTS :
%
% TSERIES_M
%       (2D array) TSERIES_M(:,I) is the average of all time series such 
%       that (CLUSTERS==I) has an overlap with the associated ATOMS.
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de geriatrie 
% de Montreal, Departement d'informatique et de recherche operationnelle, 
% Universite de Montreal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : 

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax 
if ~exist('tseries','var')||~exist('clusters','var')||~exist('clusters','var')
    error('Syntax : TSERIES_N = NIAK_MEAN_TSERIES(TSERIES,CLUSTERS,ATOMS) ; for more infos, type ''help niak_mean_tseries''.')
end
[nt,na] = size(tseries);
nc = max(clusters(:));
tseries_m = zeros([nt nc]);
[size_atoms_tmp,list_atoms] = niak_build_size_roi(atoms);
size_atoms = zeros(max(atoms(:)),1);
size_atoms(list_atoms) = size_atoms_tmp;
for num_c = 1:nc
    ind = unique(atoms(clusters==num_c));
    ind = ind(ind~=0);
    vec_size = size_atoms(ind);
    if ~isempty(ind)
        tseries_m(:,num_c) = (tseries(:,ind)*(vec_size(:)))/sum(vec_size);
    else
        tseries_m(:,num_c) = NaN;
    end
end