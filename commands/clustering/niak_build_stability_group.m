function [stab_ind,stab_group,stab_plugin] = niak_build_stability_group(mat_stab,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_STABILITY_GROUP
%
% Estimate the stablity matrix of a stochastic clustering on the mean of
% multiple stability matrices.
%
% The stability matrices are modeled as multiple realizations from a 
% random variable Y following a stratified i.i.d. distribution.
%
% Let I and J be two regions, the stability of the 2-ensemble {I,J} is
% by definition the probability that these two regions fall in the same
% cluster:
% 
%         S_{I,J} = Pr(exist C(S(y)) such that I,J \in C(S(y)) | P -> S(Y))  
%
% where P -> Y is the sampling of one subject and S(Y) is the individual 
% stability matrix of that subject.
%
% The data-generating process is approximated by a stratified i.i.d. 
% bootstrap  (y1,...,yN) -> y*, and is used to estimate the stability :
%
%     Schap_{I,J} = Pr(exist C(S_chap(y*)) such that I,J \in C(y*) | (y1,..,nN) -> y*) 
%  
% where S_chap(y*) is the bootstrap estimate of the individual stability
% matrix.
%
% SYNTAX:
% [STAB_IND,STAB_GROUP] = NIAK_BUILD_STABILITY_GROUP(MAT_STAB,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% MAT_STAB 
%       (array size S*N) MAT_STAB(:,I) is the vectorized individual stability
%       matrix associated with subject I.
%
% OPT
%       (structure) describe the parameters of the clustering and the
%       bootstrap resampling scheme.
%
%       DATA
%           (structure, default empty) with N entries. DATA can have 
%           arbitrary fields, except 'stability' that will be used 
%           internally . This structure will be used to bootstrap the 
%           data, see NIAK_BOOTSTRAP_DATA.
%       
%       CLUSTERING
%           (structure) with the following fields :
%
%           TYPE_CLUST
%               (string, default 'hierarchical') the clustering algorithm 
%               Available options : 'hierarchical'
%
%           OPT_CLUST
%               (structure) options that will be sent to the clustering
%               command. The exact list of options depends o
%               OPT.TYPE_CLUST:
%                   'hierarchical' : 
%                       two fields HIER and THRESH, see
%                       NIAK_HIERARCHICAL_CLUSTERING and
%                       NIAK_THRESHOLD_HIERARCHY.
%
%       BOOTSTRAP
%           (structure, default iid bootstrap) specify how to bootstrap 
%           the group data, see NIAK_BOOTSTRAP_DATA. Note that additional 
%           resampling stages will be added to the scheme in order to 
%           impose the null hypothesis to the group stability coefficients.
%
%       NB_SAMPS
%           (integer, default 100) the number of samples to use in the 
%           bootstrap Monte-Carlo approximation. 
%
%       FLAG_VERBOSE 
%           (boolean, default true) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
%       FLAG_VEC
%           (boolean, default true) if FLAG_VEC == true, the matrix is
%           "vectorized" and the redundant elements are suppressed. Use
%           NIAK_VEC2MAT to unvectorize it.
%
% _________________________________________________________________________
% OUTPUTS :
%
% STAB_IND  
%       (vector or matrix) STAB_IND(I,J) is the expected stability of the 
%       association between region I and J at the individual level. 
%       Note that the (2-)stability matrix is symmetric with ones on the 
%       diagonal. 
%       If OPT.FLAG_VEC == 1, the matrix has been vectorized using 
%       NIAK_MAT2VEC to save space. Use NIAK_VEC2MAT to get back the 
%       square form.
%
% STAB_GROUP
%       (vector or matrix) STAB_GROUP(I,J) is the expected stability of the 
%       association between region I and J at the group level. 
%       Note that the (2-)stability matrix is symmetric with ones on the 
%       diagonal. 
%       If OPT.FLAG_VEC == 1, the matrix has been vectorized using 
%       NIAK_MAT2VEC to save space. Use NIAK_VEC2MAT to get back the 
%       square form.
%
% STAB_PLUGIN
%       (vector or matrix) STAB_PLUGIN(I,J) is 1 if the region I and J are
%       in the same cluster derived directly from the average individual
%       stability matrix.
%       If OPT.FLAG_VEC == 1, the matrix has been vectorized using 
%       NIAK_MAT2VEC to save space. Use NIAK_VEC2MAT to get back the 
%       square form.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_PIPELINE_BASC, NIAK_CLUSTERING, NIAK_BOOTSTRAP_DATA,
% NIAK_BRICK_STABILITY_GROUP.
%
% _________________________________________________________________________
% COMMENTS: 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal 
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('mat_stab','var')||~exist('opt','var')
    error('Syntax : STAB = NIAK_BUILD_STABILITY_GROUP(MAT_STAB,OPT) ; for more infos, type ''help niak_build_stability_group''.')
end

%% Setting up default values for OPT
gb_name_structure = 'opt';
gb_list_fields = {'data','nb_samps','clustering','bootstrap','flag_vec','flag_verbose'};
gb_list_defaults = {[],100,NaN,[],true,true};
niak_set_defaults

%% Setting up default values for OPT.CLUSTERING
gb_name_structure = 'opt.clustering';
gb_list_fields = {'type_clust','opt_clust'};
gb_list_defaults = {'hierarchical',NaN};
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The bootstrap stability analysis starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Bootstrap estimation of the group-level clustering stability ...\n');
end

[S,N] = size(mat_stab);

%% Set up the data for bootstrap
if isempty(data);
    clear data    
end
for num_e = 1:N
    data(num_e).stability = mat_stab(:,num_e);
end

if isempty(bootstrap)
    clear bootstrap
    bootstrap.type = 'SB';
    bootstrap.strata = {};
end
    
%% The actual estimation starts here
opt.clustering.opt_clust.hier.flag_verbose = false;
stab_group = zeros([S 1]); % The group stability matrix
stab_ind = sub_mean_stab(data); % The individual stability_matrix
hier = niak_hierarchical_clustering(niak_vec2mat(stab_ind),opt.clustering.opt_clust.hier);
part = niak_threshold_hierarchy(hier,opt.clustering.opt_clust.thresh);
stab_plugin = niak_mat2vec((part(:)*ones([1 length(part)])-ones([length(part) 1])*(part(:)'))==0);

if flag_verbose
    fprintf('     Percentage done : 0');        
    curr_perc = -1;
end

if ~isfield(opt.clustering.opt_clust,'flag_verbose');
    opt.clustering.opt_clust.flag_verbose = false;
end

for num_s = 1:opt.nb_samps

    if flag_verbose
        new_perc = 5*floor(20*num_s/nb_samps);
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
    
    data_boot = niak_bootstrap_data(data,bootstrap);
    samp_stab = sub_mean_stab(data_boot);
       
    switch opt.clustering.type_clust

        case 'hierarchical'

            hier = niak_hierarchical_clustering(niak_vec2mat(samp_stab),opt.clustering.opt_clust.hier);
            part = niak_threshold_hierarchy(hier,opt.clustering.opt_clust.thresh);           
            stab_group = stab_group + niak_mat2vec((part(:)*ones([1 length(part)])-ones([length(part) 1])*(part(:)'))==0);

        otherwise

            error(cat(2,opt.clustering.type_clustering,': unknown type of clustering'));

    end

end

stab_group = stab_group / nb_samps;

if ~flag_vec
    stab_group = niak_vec2mat(stab_group);
    stab_ind = niak_vec2mat(stab_ind);   
    stab_plugin = niak_vec2mat(stab_plugin);
end

if flag_verbose
    fprintf('\n');
end 

%%%%%%%%%%%%%%%%%%
%% Subfunctions %%
%%%%%%%%%%%%%%%%%%

function mean_stab = sub_mean_stab(data)

mean_stab = zeros(size(data(1).stability));
for num_e = 1:length(data)
    mean_stab = mean_stab + data(num_e).stability;
end
mean_stab = mean_stab/length(data);
