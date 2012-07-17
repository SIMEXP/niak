function [stab_i,w] = niak_interpolate_stability(stab,list_scales,list_scales_i,flag_verbose,N)
% Interpolate stability matrices on a grid of scales based on a few scales
%
% SYNTAX:
% [STAB_I,W] =
% NIAK_INTERPOLATE_STABILITY(STAB,LIST_SCALES,LIST_SCALES_I,[FLAG_VERBOSE])
%
% _________________________________________________________________________
% INPUTS :
%
% STAB
%   (matrix) STAB(:,M) is a vectorized stability matrix associated with
%   the scale (number of clusters) LIST_SCALES(M)
%
% LIST_SCALES
%   (vector of integers) see description of STAB.
%
% LIST_SCALES_I
%   (vector of integers) the grid of scales on which the
%   interpolation/extrapolation will be performed.
%
% FLAG_VERBOSE
%   (boolean, default true) if this flag is true, verbose some infos.
%
% _________________________________________________________________________
% OUTPUTS :
%
% STAB_I
%   (matrix) STAB_I(:,K) is the interpolated/extrapolated vectorized
%   stability matrix corresponding to LIST_SCALES_I(K)
%
% W
%   (matrix) W(K,M) is the contribution of STAB(:,M) to the
%   interpolation/extrapolation of STAB_I(:,K)
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MSTEPS, MSTEPS_DEMO
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 2011
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : stability, clustering, interpolation, MSTEPS

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

if nargin < 4
	flag_verbose = false;
end

if nargin < 5
    tmp = niak_vec2mat(stab(:,1));
    N = size(tmp,1);
    clear tmp
end

[val,order] = sort(list_scales);
stab = stab(:,order);
list_scales = val;

%% Interpolate the stability matrices
if flag_verbose
    fprintf('Generation of interpolation coefficients ...\n');
end
w = zeros([length(list_scales_i) length(list_scales)]);
for num_sc = 1:length(list_scales_i)
    sci = list_scales_i(num_sc);
    ind1 = find(list_scales<=sci);
    ind2 = find(list_scales>sci);
    if isempty(ind1)
        ind2 = ind2(1);             
        w(num_sc,ind2) = 1;        
    elseif isempty(ind2)
        ind1 = ind1(end);        
        sc1 = list_scales(ind1);
        sc2 = list_scales_i(num_sc);        
        w(num_sc,ind1) = (1-(sc1^(1/4))/(N^(1/4)))^(-1)*max( (sc1.^(1/4))/((sc2)^(1/4)) - ((sc1)^(1/4))/((N)^(1/4)) , 0);
    else
        ind1 = ind1(end);
        ind2 = ind2(1);
        sc1 = list_scales(ind1);
        sc2 = list_scales(ind2);
        alpha = (sci-sc1)/(sc2-sc1);        
        w(num_sc,ind1) = 1-alpha;
        w(num_sc,ind2) = alpha;
    end
end
if flag_verbose
    fprintf('Interpolation of stability matrices on a grid of scales ...\n');
end
stab_i = stab*(w');