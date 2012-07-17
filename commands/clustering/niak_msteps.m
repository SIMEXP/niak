function [scales,score,scales_final] = niak_msteps(stab,list_scales,opt)
% Selection of a subset of scales in a multiscale clustering stability analysis
%
% SYNTAX : 
% [SCALES,SCORE_MODEL,SCALES_FINAL] = NIAK_MSTEPS(STAB,LIST_SCALES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% STAB
%   (matrix) STAB(:,S) is the vectorized stability matrix associated with
%   clustering parameters LIST_SCALES(S,:).
%
% LIST_SCALES
%   (vector or matrix) LIST_SCALES(S) is the clustering parameter 
%   associated with STAB(:,S).
%
% OPT
%   (optional, structure) with the following fields :
%
%   WEIGHTS
%       (vector) WEIGHTS(I) is a weight to give to region I when performing
%       the least-squares fitting.
%
%   SCALES_MAX
%       (vector, default []) SCALES_MAX(S) is the number of clusters that 
%       optimize the stability contrast in STAB(:,S). This is used to 
%       define SCALES_FINAL. If unspecified, SCALES_FINAL is filled 
%       with NaN.
%
%   PARAM
%       (scalar, default 0.5) if PARAM is comprised between 0 and 1, it is 
%       the percentage of squares that need to be explained by the model. 
%       If PARAM is larger than 1, it is assumed to be an integer, which is 
%       used directly to set the number of components of the model.
%
%   NB_INIT
%       (integer, default 100) the number of random model selection before
%       componentwise optimization is performed.
%
%   FLAG_VERBOSE
%       (boolean, default true) if FLAG_VERBOSE is true, verbose 
%       progression information.
%
% _________________________________________________________________________
% OUTPUTS:
%
% SCALES
%   (array) SCALES(R,:) is the Rth "optimal" scale selected (SCALES_R is
%   one of the elements in LIST_SCALES).
%
% SCORE
%   (scalar) SCORE is the percentage of weighted sum-of-squares explained
%   by the selected scales.
%
% SCALES_FINAL
%   (array) SCALES_FINAL(R) is the number of clusters that optimize the
%   stability contrast in the matrix associated with SCALES(R,:).
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : multiscale, clustering, selection of the number of clusters

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

%% Set up default arguments
list_fields   = {'scales_max' , 'nb_init' , 'weights' , 'param' , 'flag_verbose' };
list_defaults = {[]           , 100       , []        , 0.05    , true           };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end
opt.weights = opt.weights(:);
if isempty(opt.weights)
    opt.weights = ones([length(list_scales) 1]);
end
opt.weights(opt.weights<0) = 0;

%% Correct weights for an uncomplete grid of scales
list_scales_all = 2:max(list_scales);
dist_scales = abs(repmat(list_scales(:),[1 length(list_scales_all)]) - repmat(list_scales_all+0.1,[length(list_scales) 1]));
size_bins = zeros(size(opt.weights));
for num_s = 1:length(list_scales);
    size_bins(num_s) = sum(dist_scales(num_s,:)==min(dist_scales,[],1));
end
opt.weights = opt.weights.*size_bins;

%% Normalize stability
stab = niak_normalize_stability(stab,list_scales);
A = stab'*stab;
N = round((1+sqrt(1+8*size(stab,1)))/2);

%% If a percentage of squares was specified to set the number of
%% components, use a stepwise forward selection to find an appropriate
%% number
if opt.param < 1
    scales_f = sub_msteps_forward(list_scales,opt.param,A,opt.weights,N,opt.flag_verbose);
    nb_scales = sum(scales_f~=0);
else
    nb_scales = opt.param;
end

%% Random search of "good" models
[scales_init,score_init] = sub_msteps_init(list_scales,nb_scales,A,opt.weights,N,opt.nb_init,opt.flag_verbose);

%% Component-wise optimization of the best random model
[scales,score] = sub_msteps_optim(list_scales,scales_init,A,opt.weights,N,score_init,opt.flag_verbose);

%% Final scales
if ~isempty(opt.scales_max)
    scales_final = opt.scales_max(ismember(list_scales,scales),:);
    if opt.flag_verbose
        fprintf('Final model : ')
        fprintf(' %i',scales_final);
        fprintf('\n')
    end       
else
    scales_final = repmat(NaN,size(scales));
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the residual sum of squares %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ss = sub_residuals(scales_test,list_scales,M,weights,N)

[scales_test,order] = sort(scales_test);
[tmp,ind_test] = ismember(scales_test,list_scales);
ss = zeros([length(list_scales) 1]);
for num_sc = 1:length(list_scales)
    sci = list_scales(num_sc);
    if sci<=scales_test(1)
        ss(num_sc) = M(num_sc,num_sc) + M(ind_test(1),ind_test(1)) - 2*M(num_sc,ind_test(1));        
    elseif sci>=scales_test(end)
        sc = scales_test(end);
        alpha = (1-(sc^(1/4))/(N^(1/4)))^(-1)*((sc.^(1/4))/((sci)^(1/4))-((sc)^(1/4))/((N)^(1/4)));
        ss(num_sc) = M(num_sc,num_sc) + alpha^2*M(ind_test(end),ind_test(end)) - 2*alpha*M(num_sc,ind_test(end));
    else
        ind1 = find(scales_test<=sci);
        ind2 = find(scales_test>sci);
        ind1 = ind1(end);
        ind2 = ind2(1);
        sc1 = scales_test(ind1);
        sc2 = scales_test(ind2);
        beta = (sci-sc1)/(sc2-sc1);
        alpha = 1-beta;
        ss(num_sc) = M(num_sc,num_sc) + alpha^2*M(ind_test(ind1),ind_test(ind1)) + beta^2*M(ind_test(ind2),ind_test(ind2)) + 2*alpha*beta*M(ind_test(ind1),ind_test(ind2)) - 2*alpha*M(num_sc,ind_test(ind1)) - 2*beta*M(num_sc,ind_test(ind2));
    end
end
ss = ss.*weights;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Forward stepwise selection %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [scales,score] = sub_msteps_forward(list_scales,perc_var,M,weights,N,flag_verbose)

if perc_var>=1
    flag_perc = false;
    perc_var = -perc_var;
    var_res = 0;
else    
    flag_perc = true;    
    var_res = 1;
end
ss_tot = sum(M(eye(size(M))>0).*weights);
mask_scales = true([1 length(list_scales)]);
score = zeros([1 length(list_scales)]);
scales = zeros([length(list_scales) 1]);
num_s = 1;
if flag_verbose
    if flag_perc
        fprintf('Forward scale selection : number of components (percentage of residual variance) - ');
    else
        fprintf('Forward scale selection, number of components : selected/total - ');
    end
end

while var_res>perc_var
    ind_scales = find(mask_scales);
    score_tmp = zeros([length(ind_scales) 1]);
    for num_s2 = 1:length(ind_scales)
        ind = ind_scales(num_s2);
        scales(num_s) = list_scales(ind);
        score_tmp(num_s2) = sum(sub_residuals(scales(1:num_s),list_scales,M,weights,N)); 
    end
    score_min = min(score_tmp);
    ind_min = find(score_tmp==score_min);
    ind_min = ind_min(end);
    scales(num_s) = list_scales(ind_scales(ind_min));
    score(num_s) = score_min(1);
    mask_scales(ind_scales(ind_min)) = false;
    if flag_perc
        var_res = score(num_s)/ss_tot;
    else
        var_res = var_res-1;
    end    
    if flag_verbose
        if flag_perc
            fprintf('%i (%1.3f) - ',num_s,var_res)
        else
            fprintf('%i/%i - ',-var_res,-perc_var)
        end
    end
    num_s = num_s+1;
end
score = score/ss_tot;
mask_sig = scales>0;
scales = scales(mask_sig);
score = score(mask_sig);
if flag_verbose
    fprintf('Done\n    Best model found (score %1.6f) : ',score(num_s-1))
    fprintf('%i ',scales(1:(num_s-1)))    
    fprintf('\n')
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Random search for a good model %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scales_init,score_init,model_init] = sub_msteps_init(list_scales,nb_comps,M,weights,N,nb_samps,flag_verbose)

if flag_verbose
    fprintf('Random search of initial model ...\n    Percentage done : ');    
    curr_perc = -1;
end

score_init = Inf;
ss0 = M(eye(size(M))>0).*weights;
ss_tot = sum(ss0);
scales_init = zeros([nb_comps 1]);
for num_s = 1:nb_samps
    if flag_verbose
        new_perc = 5*floor(20*num_s/nb_samps);
        if curr_perc~=new_perc
            fprintf(' %1.0f -',new_perc);
            curr_perc = new_perc;
        end
    end

    scales = zeros([nb_comps 1]);
    ss = ss0;
    for num_s2 = 1:nb_comps
        [prob,order] = sort(ss);
        prob = cumsum(prob)/sum(prob);
        prob = [0 ; prob(:)];
        num_comp = order(find(prob>=rand(1),1,'first')-1);
        scales(num_s2) = list_scales(num_comp);
        ss = sub_residuals(scales(1:num_s2),list_scales,M,weights,N);
    end
    score = sum(ss);
    if score <= score_init
        scales_init = scales;
        score_init  = score;
    end     
end
score_init = score_init/ss_tot;
if flag_verbose
    fprintf(' Done\n    Best model found (score %1.6f) : ',score_init)
    fprintf('%i ',scales_init)    
    fprintf('\n')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Component-wise optimization of the model %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scales,score] = sub_msteps_optim(list_scales,scales,M,weights,N,score,flag_verbose)

scales = sort(scales);
mask_scales = true([1 length(list_scales)]);
mask_scales(ismember(list_scales,scales)) = 0;
nb_scales = length(scales);
flag_rep = true;
ss_tot = sum(M(eye(size(M))>0).*weights);

if flag_verbose
    fprintf('Component-wise model optimization ...\n')
end
while flag_rep
    scales_rep = zeros([nb_scales 1]);
    score_rep  = zeros([nb_scales 1]);
    
    for num_s_rep = 1:nb_scales
        
        scales_test = scales;
        ind_scales = find(mask_scales);
        score_tmp = zeros([length(ind_scales) 1]);
        
        for num_s2 = 1:length(ind_scales)            
            ind = ind_scales(num_s2);
            scales_test(num_s_rep) = list_scales(ind);
            score_tmp(num_s2) = sum(sub_residuals(scales_test,list_scales,M,weights,N))/ss_tot;            
        end
        score_min = min(score_tmp);        
        ind_min = find(score_tmp==score_min);
        scales_rep(num_s_rep) = list_scales(ind_scales(ind_min(end)));
        score_rep(num_s_rep) = score_min(end);
    end
    score_min_rep = min(score_rep);
    ind_min_rep = find(score_rep==score_min_rep);
    ind_min_rep = ind_min_rep(end);    
    flag_rep = (score_min_rep < score)|((score_min_rep == score)&(scales(ind_min_rep)<scales_rep(ind_min_rep)));
    if flag_rep        
        if flag_verbose
           fprintf('    Replaced scale %i by %i (score %1.6f -> %1.6f)\n',scales(ind_min_rep),scales_rep(ind_min_rep),score,score_min_rep) 
        end        
        mask_scales(list_scales==scales(ind_min_rep)) = true;
        scales(ind_min_rep) = scales_rep(ind_min_rep);
        score = score_min_rep(1);
        mask_scales(list_scales==scales(ind_min_rep)) = false;        
    end
end

if flag_verbose
    fprintf('    Best model found (score %1.6f) : ',score)
    fprintf('%i ',scales)    
    fprintf('\n')
end
