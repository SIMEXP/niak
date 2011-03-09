function afc = niak_build_afc(tseries,part,flag_vec)
%
% _________________________________________________________________________
% SUMMARY OF NIAK_BUILD_AFC
%
% Compute the average functional connectivity (AFC) within and between 
% networks given a set of regional time series and a partition of regions 
% into networks. Functional connectivity simply refers to the linear
% Pearson's correlation coefficient between time series.
%
% SYNTAX:
% AFC = NIAK_BUILD_AFC(TSERIES,PART,FLAG_VEC)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (2D array) tseries(:,i) is the time series of the ith region
%
% PART          
%       (vector) find(part==j) is the list of region in network j. In other 
%       words, part(i) is the number of the network of region i.
%
% FLAG_VEC
%       (boolean, default false) if FLAG_VEC == true, the output matrix is
%       "vectorized" and the redundant elements are suppressed. Use
%       NIAK_VEC2MAT to unvectorize it.
%       
% _________________________________________________________________________
% OUTPUTS:
%
% AFC
%       (matrix or vector) is the vectorized matrix of intra/inter networks 
%       average functional connectivity. See NIAK_MAT2LVEC and DNM_LVEC2MAT 
%       for going from vectorized to matrix form.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_BUILD_MEASURE
%
% _________________________________________________________________________
% COMMENTS:
%
% Computational details on average functional connectivity can be found in 
% the following publication:
% P. Bellec; G. Marrelec; H. Benali, 
% A bootstrap test to investigate changes in brain connectivity for 
% functional MRI. 
% Statistica Sinica, special issue on Statistical Challenges and Advances 
% in Brain Science.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : correlation, functional connectivity, time series

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

nb_netwk = max(part);
afc = zeros([nb_netwk nb_netwk]);

% Computation of the mean signal per network
siz_netwk = zeros([1 nb_netwk]);
tseries_moy = zeros([size(tseries,1) nb_netwk]);
for num_n = 1:nb_netwk
    tseries_moy(:,num_n) = mean(niak_correct_mean_var(tseries(:,part==num_n),'mean_var'),2);
    siz_netwk(num_n) = sum(part==num_n);
end

% The simple definition of afc is not applied here. There is a
% relationship between the afc intra- and inter-networks and the 
% variance/covariance of mean time series within networks after a 
% correction of regional time series for zero mean and unit variance has 
% been performed. This way of computing the AFC, which is much less 
% computationally demanding, is implented here.

afc = (1/(size(tseries_moy,1)-1))*tseries_moy'*tseries_moy;
ind_diag = sub2ind(size(afc),1:size(afc,1),1:size(afc,1));
afc(ind_diag) = (afc(ind_diag) - 1./siz_netwk).*siz_netwk./(siz_netwk-1);
if flag_vec
    afc = niak_mat2lvec(afc);
end