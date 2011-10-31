function order = niak_hier2order(hier);
% Order objects based on a hierarchy.
% 
% SYNTAX :
% ORDER = NIAK_HIER2ORDER(HIER)
% 
% _________________________________________________________________________
% INPUTS :
%
% HIER      
%       (2D array) defines a hierarchy (see NIAK_HIERARCHICAL_CLUSTERING)
%
% _________________________________________________________________________
% OUTPUTS :
%
% ORDER     
%       (vector) defines a permutation on the objects as defined by HIER 
%       when splitting the objects backward.
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : hierarchical clustering

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

n = size(hier,1);
if size(hier,2) == 3
    hier = [hier(:,3) hier(:,1) hier(:,2) ((n+2):(2*n+1))'];
end

order = hier(n,4);

i = n;
for i = n:-1:1
    ind = find(order==hier(i,4));
    order2 = [];
    if ind > 1
        order2 = order(1:ind-1);
    end
    order2 = [order2 ; hier(i,2:3)'];
    if ind <length(order)
        order2 = [order2 ; order(ind+1:length(order))];
    end
    order = order2;
    i = i-1;
end
