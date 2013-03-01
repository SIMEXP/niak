function c = niak_hot_cold(n,per);
% Hot-col color map
%
% SYNTAX:
% C = NIAK_HOT_COLD(N,PER)
%
% INPUTS:
%   N (integer, default 256) number of colors in the map
%   PER (scalar, default 0.5) the proportion of hot colors
%
% OUTPUTS:
%   C (matrix Nx3) each row is the red/green/blue intensity in the color (from 0 to 1) 

% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : 
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

if nargin < 1
    n = 256;
end
if nargin < 2
    per = 0.5;
end

c1 = hot(ceil(1.28*n*per));
if ~isempty(c1)
    c1 = c1(1:ceil(n*per),:);
end
c2 = hot(ceil(1.28*n*(1-per)));
if ~isempty(c2)
    c2 = c2(1:(n-length(c1)),:);
    c2 = c2(:,[3 2 1]);
    c2(size(c2,1):-1:1,:);
end
c = [c2(size(c2,1):-1:1,:) ; c1];

