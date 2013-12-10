function R = niak_corr_model_homogeneous(afc,nb_rois);
%
% _________________________________________________________________________
% SUMMARY NIAK_CORR_MODEL_HOMOGENEOUS
%
% Generates a spatial correlation matrix following an homogeneous model.
% The regions are grouped into disjoints clusters C_I. Let C_K and C_L be 
% the clusters containing regions I and J, with I ~= J. 
% The correlation between I and J is :
%
% R_(I,J) = afc_(K,L)
%
% SYNTAX:
% R = NIAK_CORR_MODEL_HOMOGENEOUS(AFC,NB_ROIS)
%
% _________________________________________________________________________
% INPUTS:
%
% AFC
%       (matrix K*K) list of clusters-to-clusters average functional
%       connectivity.
%
% NB_ROIS
%       (integer) NB_ROIS(K) is the number of regions in cluster K.
%
% _________________________________________________________________________
% OUTPUTS:
%
% R
%       (vector) R(I,J) is the spatial correlation between regions I and J
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_SAMPLE_GSST
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : homogeneous

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

nb_systs = size(afc,1);
if nb_systs ~= length(nb_rois);;
    if length(nb_rois) == 1
        nb_rois = ones([nb_systs 1])*nb_rois;
    else
        fprintf('nb_rois is a vector whose ith element is the number of regions of interest in system i, so size(afc,1) == length(nb_rois) !')
        return
    end
end

part = zeros([sum(nb_rois) 1]);

num_r = 1;
for num_s = 1:nb_systs
    part(num_r:num_r+nb_rois(num_s)-1) = num_s;
    num_r = num_r + nb_rois(num_s);
end

R = zeros([sum(nb_rois) sum(nb_rois)]);

for num_s = 1:nb_systs
    for num_s2 = 1:num_s
        R(part == num_s,part == num_s2) = afc(num_s,num_s2)*ones([nb_rois(num_s),nb_rois(num_s2)]);
        if num_s ~= num_s2
            R(part == num_s2,part == num_s) = afc(num_s,num_s2)*ones([nb_rois(num_s2),nb_rois(num_s)]);
        end
    end
end

R(eye(size(R))>0) = 1;