function [val,ind] = niak_find_local_max_1d(sig,neigh)
%
% _________________________________________________________________________
% SUMMARY NIAK_FIND_LOCAL_MAX_1D
%
% Find local max in a 1D signal. Temporal neighbourhood is defined through
% a symmetric time window.
%
% SYNTAX:
% [VAL,IND] = NIAK_FIND_LOCAL_MAX_1D(SIG,WW)
%
% _________________________________________________________________________
% INPUTS:
%
% SIG
%       (vector, size T*1) a time series, or at least a series of
%       observation where proximity in the order list makes sense to define
%       a neighbourhood
%
%       NEIGH
%           (vector, default [0.7 1.3]) defines the local neighbourhood of
%           a number of clusters.
%
% _________________________________________________________________________
% OUTPUTS :
%
% VAL  
%       (vector) The values of the local max.
%
% IND
%       (vector) the index of the local max in SIG.
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS: 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal 
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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

nt = length(sig);

val = [];
ind = [];

for num_t = 1:length(sig)
    low = max(1,floor(neigh(1)*num_t));
    up = min(length(sig),ceil(neigh(2)*num_t));
    
    if ~any(sig(num_t) < sig(low:up))
        
        val = [val ; sig(num_t)];
        ind = [ind ; num_t];
    end
end
