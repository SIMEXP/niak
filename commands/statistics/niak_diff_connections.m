function [score_ref, score_ind] = niak_diff_connections(ref_data, ind_data, target, opt)
% Create outcome mesures for the preprocessing based on two reference DB a control poupulation and a patients population. 
%
% SYNTAX : 
% [] = NIAK_DIFF_CONNECTIONS()
%
% _________________________________________________________________________
% INPUTS :
%
%   REF_DATA      
%       (structure) a structure with R_ind representing the correlation
%       matrix for each subject 3rd dim is the subject space.
%
%   IND_DATA      
%       (2D array) this is the connectome of the individual parcelized with
%       the same scale as the ref_data.
%
%   TARGET      
%       cordinates to compute the outcome mesures. For a network2network
%       difference use first and second colum to specify wich network to
%       compare. for a specific network vs. all the other network use the
%       first colum only, if you whant to combine network add the id in the
%       rows.
% OPT       
%       (structure, optional) with the following fields:
%
%      
% _________________________________________________________________________
% OUTPUTS :
%
% SCORE_REF        
%       (vector) HF(I) is the handle of the Ith figure used.
%
% SCORE_IND        
%       (vector) HF(I) is the handle of the Ith figure used.
%
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal,
% 2012.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : matrix, difference, correlation

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

%% select the two vector or unit to compare
for i=1:size(target,1)

    
    if size(target,2) == 1
        % vector analysis
        for j=1:size(ref_data.R_ind,3)
            % reference
            score_ref(i,j) = sqrt(sum((mean(ref_data.R_ind(:,target(i),:),3) - ref_data.R_ind(:,target(i),j)).^2));
        end
        % individual
        score_ind(i) = sqrt(sum((mean(ref_data.R_ind(:,target(i),:),3) - ind_data(:,target(i))).^2));
        
    elseif size(target,2) == 2
        % p2p analysis
        for j=1:size(ref_data.R_ind,3)
            % reference
            %score_ref(i,j) = sqrt(sum((mean(ref_data.R_ind(target(i,1),target(i,2),:),3) - ref_data.R_ind(target(i,1),target(i,2),j)).^2));
            score_ref(i,j) = ref_data.R_ind(target(i,1),target(i,2),j);
        end
        % individual
        %score_ind(i) = sqrt(sum((mean(ref_data.R_ind(target(i,1),target(i,2),:),3) - ind_data(target(i,1),target(i,2))).^2));
        score_ind(i) = ind_data(target(i,1),target(i,2));

    end
    
    
end

%% Avg of all connections
score_ref = mean(score_ref,1);
score_ind = mean(score_ind);



