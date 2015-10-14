function r = niak_corr(x,y);
% Correlation between two set of time series
% SYNTAX: R = NIAK_CORR(X,Y)
% X (matrix TxM) random samples (each column is a variable)
% Y (matrix TxN) random samples (each column is a variable)
% R (matrix MxN) R(i,j) is the correlation between X(:,i) and Y(:,j)
%
% This function does simply call corr. Correlation values larger than 1
% (resp smaller than -1) are then set to 1 (resp. -1), due to numerical errors. 
% See licensing information in the code.

% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Geriatrie de Montral, Departement d'informatique et de recherche 
% operationnelle, Universite de Montreal, 2015.
% Maintainer : pierre.bellec@criugm.qc.ca

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
r = corr(x,y);
r(r>1) = 1;
r(r<-1) = -1;
