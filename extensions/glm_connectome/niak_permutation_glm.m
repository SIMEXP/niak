function glm_perm = niak_permutation_glm(glm,flag_null);
% Permutation of a GLM under the null hypothesis of no interaction with a trait 
%
% SYNTAX:
% DATA_PERM = NIAK_PERMUTATION_GLM(DATA,FLAG_NULL)
%
% _________________________________________________________________________
% INPUTS:
%
% GLM
%   (structure) with the following fields:
%
%   X
%      (array N*P) N observations, K predicting variables
%
%   Y
%      (array N*S) N observations, S units
%
%   C 
%      (vector P*1) a contrast vector. It has to have exactly
%      one 1 and otherwise 0s. Contrast with multiple covariates
%      are not supported.
%
% FLAG_NULL
%   (boolean, default true) turn on/off the null hypothesis (when it's off, 
%   the function can be used to build confidence intervals rather than hypothesis 
%   testing). 
%
% _________________________________________________________________________
% OUTPUTS:
%
% GLM_PERM
%    (structure) same as GLM after permutation under the null.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_GLM_CONNECTOME_PERM, NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% REFERENCE:
% 
% Anderson M (2001) Permutation tests for univariate or multivariate analysis 
% of variance and regression. 
% Canadian Journal of Fisheries and Aquatic Sciences 58: 626–639. 
%
% _________________________________________________________________________
% COMMENTS:
%
% If FLAG_NULL is off, the estimated effects are added back to the data sample
% after permutation of the residuals. This can be used to bootstrap the data 
% and build confidence intervals. 
%
% If FLAG_NULL is on and the contrast is on the intercept, the sign of the data
% is randomly reassigned, such that the samples will have a zero mean on average.
%
% Copyright (c) Pierre Bellec
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2011-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : statistics, correlation

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
    flag_null = true;
end

ind = find(glm(1).c);
if length(ind)~=1
    error('The contrast vector should have exactly one 1')
end
perm_obs = randperm(size(glm(1).y,1));
for num_e = 1:length(glm)
    if flag_null
        if any(~glm(num_e).c)
            [beta,E] = niak_lse(glm(num_e).y,glm(num_e).x(:,~glm(num_e).c));
            glm_perm(num_e).y = glm(num_e).x(:,~glm(num_e).c)*beta + E(perm_obs,:);
        else 
            glm_perm(num_e).y = glm(num_e).y(perm_obs,:);
        end
        if length(unique(glm(num_e).x(:,glm(num_e).c==1)))==1 % the contrast is on the intercept
            glm_perm(num_e).y = (glm_perm(num_e).y).*(2*(rand(size(glm_perm(num_e).y))>=0.5) - 1);
        end
    else
        [beta,E] = niak_lse(glm(num_e).y,glm(num_e).x);
        glm_perm(num_e).y = glm(num_e).x*beta + E(perm_obs,:);
    end
    glm_perm(num_e).x = glm(num_e).x;
    glm_perm(num_e).c = glm(num_e).c;
end