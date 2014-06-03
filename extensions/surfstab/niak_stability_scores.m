function res = niak_stability_scores(data,part,opt)
% Build stable cores and stability maps based on an a priori partition
%
% SYNTAX: RES = NIAK_STABILITY_SCORES(DATA,PART,OPT)
%
% DATA
%   (string) A .mat file with one variable called OPT.NAME_DATA, which is a 
%   NxV array, with N the number of features and V the number of units.
%
% PART
%   (string) path to .mat file that contains a matrix of VxK where V is the 
%   number of units and K is the number of clusters.
%
% OPT
%   (structure) with the following fields:
%   NB_SAMPS (integer, default 100) the number of replications to 
%      generate stability cores & maps.
%   SAMPLING.TYPE (string, default 'bootstrap') how to resample the features.
%      Available options : 'bootstrap' , 'jacknife', 'window', 'CBB'
%   SAMPLING.OPT (structure) the options of the sampling. 
%      bootstrap : None.
%      jacknife  : OPT.PERC is the percentage of observations
%                  retained in each sample (default 60%)
%      CBB       : OPT.BLOCK_LENGTH is the length of the block for bootstrap. See 
%                  NIAK_BOOTSTRAP_TSERIES for default options.
%      window    : OPT.LENGTH is the length of the window, expressed in time points
%                  (default 60% of the # of features).
%   FLAG_VERBOSE
%      (boolean, default true) turn on/off the verbose.
%
% RES
%   (structure) with the following fields:
%   STAB_MAPS (array VxK) STAB_MAPS(:,k) is the stability map of the k-th cluster.
%   STAB_CORES (array VxK) STAB_CORES(:,k) is the stability map of the k-th core.
%   PART_CORES (vector Vx1) PART_CORES==k is the k-th cluter based on stable cores.
%   STAB_INTRA (array Vx1) STAB_INTRA(v) is the intra-cluster stability for 
%      voxel v. 
%   STAB_INTER (array Vx1) STAB_INTRA(v) is the inter-cluster stability for 
%      voxel v. 
%   STAB_CONTRAST (array Vx1) STAB_CONTRAST(v) is the stability contrast for 
%      voxel v. 
% _________________________________________________________________________
% COMMENTS:
% For "window" sampling, the OPT.NB_SAMPS argument is ignored, 
% and all possible sliding windows are generated.
%
% Copyright (c) Pierre Bellec,
%   Centre de recherche de l'institut de Geriatrie de Montreal
%   Departement d'informatique et de recherche operationnelle
%   Universite de MontrÃ©al, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability analysis, bootstrap, jacknife, cores.

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

%% Initialization and syntax checks

% Syntax
if ~exist('data','var')||~exist('part','var')
    error('niak','syntax: res = niak_stability_scores(data,part,opt).\n Type ''help niak_stability_scores'' for more info.')
end

if nargin < 3
   opt = struct();
end
opt = psom_struct_defaults(opt, ...
      { 'nb_samps' , 'sampling' , 'flag_verbose' } , ...
      { 100        , struct()   , true           });
opt.sampling = psom_struct_defaults(opt.sampling, ...
      { 'type'      , 'opt'    }, ...
      { 'bootstrap' , struct() });

[nt,nn] = size(data);
switch opt.sampling.type
    case 'bootstrap'
    case 'jacknife'
        opt.sampling.opt = psom_struct_defaults(opt.sampling.opt, ...
            { 'perc' }, ...
            { 0.6    });
    case 'CBB'
        opt.sampling.opt = psom_struct_defaults(opt.sampling.opt, ...
            { 'block_length' }, ...
            { []             });
    case 'window'
        opt.sampling.opt = psom_struct_defaults(opt.sampling.opt, ...
            { 'length'     }, ...
            { ceil(0.6*nt) });
end

if length(part)~=nn
    error('the length of PART should be equal to the size of the second dimension of DATA');
end
nk = max(part);
if strcmp(opt.sampling.type,'window')    
    opt.nb_samps  = max(nt - opt.sampling.opt.length + 1,1);    
end    

%% Set up resampling options
switch opt.sampling.type
    case 'bootstrap'
        opt_r.dgp = 'CBB';
        opt_r.block_length = 1;
    case 'CBB'
        opt_r.dgp = 'CBB';
        opt_r.block_length = opt.sampling.opt.block_length;
    case 'jacknife'
        perc = opt.sampling.opt.perc;
    case 'window'
        lw = opt.sampling.opt.length;
end
        
%% Build maps of stable cores
opt_k.nb_classes = 3;
res.stab_cores = zeros(nn,nk);
if opt.flag_verbose 
    fprintf('Estimation of stable cores ...\n   ')
end
for ss = 1:opt.nb_samps
    if opt.flag_verbose
        niak_progress(ss,opt.nb_samps);
    end
    % resample data    
    switch opt.sampling.type
        case {'bootstrap','CBB'}
            data_r = niak_bootstrap_tseries(data,opt_r);
        case 'jacknife'
            ind = randperm(nt);
            ind = ind(1:min(floor(perc*nt),nt));
            data_r = data(ind,:);
        case 'window'
            ind = ss:min(ss+lw-1,nt);
            data_r = data(ind,:);
    end
    
    % Build correlation maps
    tseed = niak_build_tseries(data_r,part);
    rmap = corr(data_r,tseed);
    
    % Build cores
    cores = false(nn,nk);
    for kk = 1:nk
        [part_k,gi] = niak_kmeans_clustering(rmap(:,kk)',opt_k);
        [val,ind_max] = max(gi);
        cores(:,kk) = part_k == ind_max;
    end
    res.stab_cores = res.stab_cores + double(cores);
end
res.stab_cores = res.stab_cores / opt.nb_samps;

%% Now build stability maps for full brain clusters, based on the stable cores
res.stab_maps = zeros(nn,nk);
if opt.flag_verbose 
    fprintf('Estimation of stability_maps ...\n   ')
end

for ss = 1:opt.nb_samps
    if opt.flag_verbose
        niak_progress(ss,opt.nb_samps);
    end
    % resample data    
    switch opt.sampling.type
        case {'bootstrap','CBB'}
            data_r = niak_bootstrap_tseries(data,opt_r);
        case 'jacknife'
            ind = randperm(nt);
            ind = ind(1:min(floor(perc*nt),nt));
            data_r = data(ind,:);
        case 'window'
            ind = ss:min(ss+lw-1,nt);
            data_r = data(ind,:);
    end
    
    % Build correlation maps    
    tcores = data_r * res.stab_cores;
    rmap = corr(data_r,tcores);
    rmap(isnan(rmap)) = -Inf;
    
    % build stability maps
    [val,part_r] = max(rmap,[],2);   
    for kk = 1:nk                
        res.stab_maps(:,kk) = res.stab_maps(:,kk) + double(part_r==kk);
    end
end
res.stab_maps = res.stab_maps / opt.nb_samps;

%% Generate final outputs (intra- and inter- cluster stability, stability contrast as well as partition based on cores)
[res.stab_intra,res.part_cores] = max(res.stab_maps,[],2);
res.stab_inter = zeros(size(res.stab_intra));
for kk = 1:nk
    mask = true (1,nk);
    mask(kk) = false;
    val = max(res.stab_maps(:,mask),[],2);
    res.stab_inter(res.part_cores==kk) = val(res.part_cores==kk);
end
res.stab_contrast = res.stab_intra - res.stab_inter;