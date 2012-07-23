function [sil_max,scales_max] = niak_build_max_sil(sil,scales,ww,method)
% Estimate the maximal silhouette for a neighbourhood in the scale space.
% 
% Let SIL(S,K) be the silhouette with SCALES(K,:) scale parameters, and S 
% final clusters. The neighbourhood of S is defined as :
% 
%   N(S) = {K : (1-WW)*S <= SCALES(K,L) <= (1+WW)*S for all L}
%
% The maximal silhouette (as a function of S, method 1) is then defined as: 
%
%   SIL_MAX(S) = max_{K in N(S)} ( SIL(S,K) )
%
%   SCALES_MAX(S) = SCALES(K*,:), where K* = argmax_{K in N(S)} ( SIL(S,K) )
%
% The maximal silhouette (as a function of K, method 2) is then defined as
% follows. Let I be the Ith unique element of SCALES(:,end).
%
%   SIL_MAX(I) = max_{S,K: I in N(S), SCALES(K,end) == I} ( SIL(S,K) )
%
%   SCALES_MAX(I) = (S*,K*), where 
%
%       (S*,K*) = argmax_{S,K: I in N(S), SCALES(K,end) == I} ( SIL(S,K) )
% 
% SYNTAX:
% [SIL_MAX,SCALES_MAX] = NIAK_BUILD_MAX_SIL(SIL,SCALES,WW,[METHOD])
%
% _________________________________________________________________________
% INPUTS:
%
% SIL
%       (array) SIL(L,K) is the silhouette with effective scale L and other 
%       scale parameters K
%
% SCALES
%       (array) SCALES(K,:) are the scale parameters in configuration K.
%
% WW
%       (scalar) it is a percentage used to set the window search around
%       each effective scale L. If WW is a vector, the first and last
%       element will be used to set the percentages.
%
% METHOD
%       (integer, default 1) the method to derive the maximal silhouette
%       (see a description above). Available choices : 
%           1: the maximal silhouette is defined as a function of S
%           2: the maximal silhouette is defined as a function of the last 
%		parameter in K
%
% _________________________________________________________________________
% OUTPUTS :
%
% SIL_MAX
%       (vector) the maximum silhouette, see description above.
%
% SCALES_MAX
%       (vector or array) optimal scales parameters, see description above.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_SUMMARY_IND, NIAK_BRICK_STABILITY_SUMMARY_GROUP
%
% _________________________________________________________________________
% REFERENCES:
%
% P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benalib; A.C. Evans,
% Multi-level bootstrap analysis of stable clusters in resting-State fMRI. 
% Neuroimage 51 (2010), pp. 1126-1139
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, silhouette
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

%% Syntax
if ~exist('sil','var')||~exist('scales','var')||~exist('ww','var')
    error('Syntax : [SIL_MAX,SCALES_MAX] = NIAK_BUILD_MAX_SIL(SIL,SCALES,WW,[METHOD]) ; for more infos, type ''help niak_build_max_sil''.')
end

if length(ww)==1
    ww_min = 1-ww;
    ww_max = 1+ww;
else
    ww_min = ww(1);
    ww_max = ww(end);
end

if nargin < 4
    method = 1;
end

S = size(sil,1);
nb_dim = size(scales,2);

switch method
    case 1
        sil_max = zeros([S 1]);
        scales_max = zeros([S,nb_dim]);
        for num_s = 1:S            
            Lmin = floor(ww_min*num_s);
            Lmax = ceil(ww_max*num_s);            
            mask = min((scales<=Lmax) & (scales>=Lmin),[],2)>0;
            [val,ind] = max(sil(num_s,mask));
            ind_mask = find(mask);
            if ~isempty(ind)
                sil_max(num_s) = val;
                scales_max(num_s,:) = scales(ind_mask(ind),:);
            else
                sil_max(num_s) = NaN;
                scales_max(num_s,:) = NaN;
            end
        end
    case 2
        scales_unique = unique(scales(:,end));
        nb_scales = length(scales_unique);
        sil_max = zeros([nb_scales 1]);
        scales_max = zeros([nb_scales size(scales,2)+1]);
        for num_m = 1:nb_scales
            Smin = scales_unique(num_m)/ww_max;
            Smax = scales_unique(num_m)/ww_min;
            maskS = ((1:S)<=Smax) & ((1:S)>=Smin);
            maskK = scales(:,end)==scales_unique(num_m);
            [valK,numK] = max(sil(maskS,maskK),[],2);
            [valS,numS] = max(valK);
            indS = find(maskS);
            indK = find(maskK);
            if ~isempty(numS)&&~isempty(numK)
                sil_max(num_m) = valS;
                scales_max(num_m,:) = [scales(indK(numK(numS)),:) indS(numS)];
            else
                sil_max(num_m) = 0;
                scales_max(num_m,:) = [scales_unique(num_m) repmat(S,[1 size(scales_max,2)-1])];
            end
        end
end
