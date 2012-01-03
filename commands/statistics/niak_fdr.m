function fdr = niak_fdr(pce,method)
% Estimate the false-discovery rate in a family of tests with known per-comparison error
%
% SYNTAX:
% FDR = NIAK_FDR( PCE , [METHOD] )
%
% _________________________________________________________________________
% INPUTS:
%
% PCE
%   (array) A set of family of tests. PCE(i,j) is the per-comparison error of the 
%   ith test in the j-th family (aka the uncorrected p-value).
%
% METHOD
%   (string, default 'BY') the method to estimate the false-discovery rate.
%   Available options:
%       'BY' : The Benjamini-Yekutieli procedure, appropriate for dependent tests
%       'BH' : The Benjamini-Hochberg procedure, appropriate for independent tests 
%              (or positively correlated tests).
%
% _________________________________________________________________________
% OUTPUTS:
%
% FDR
%   (array) FDR(i,j) is the false-discovery rate associated with a threshold of 
%   PCE(i,j) in the j-th family.
%
% _________________________________________________________________________
% REFERENCES:
%
% On the estimation of the false-discovery rate for independent tests (BH):
%   Benjamini, Y., Hochberg, Y., 1995. Controlling the false-discovery rate: 
%   a practical and powerful approach to multiple testing. 
%   J. Roy. Statist. Soc. Ser. B 57, 289-300.
%
% On the estimation of the false-discovery rate for dependent tests (BY):
%   Benjamini, Y., Yekutieli, D., 2001. The control of the false discovery 
%   rate in multiple testing under dependency. 
%   The Annals of Statistics 29 (4), 1165-1188.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : false-discovery rate, false-positive rate

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
if nargin < 2
    method = 'BY';
end

[val,order] = sort(pce,1,'ascend');
n = size(pce,1);
fdr = zeros(size(pce));
ind = n./(1:n)';
w = sum((1:n).^(-1));
for num_c = 1:size(pce,2)
    switch method
        case 'BY'
           fdr(order(:,num_c),num_c) = w * ind.*val(:,num_c);
        case 'BH'
           fdr(order(:,num_c),num_c) = ind.*val(:,num_c);
        otherwise
            error('%s is an unkown procedure for FDR estimation')
    end
end