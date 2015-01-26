function [res,opt] = niak_stability_cores(data,part,opt)
% Build stable cores and stability maps based on an a priori partition
%
% SYNTAX: RES = NIAK_STABILITY_CORES(DATA,PART,OPT)
%
% DATA (array NxV) with N the number of features and V the number of units.
% PART (array Vx1) where V is the number of units and K is the number of clusters.
%    PART==k defines the k-th cluster. 
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
%      scenario  : OPT.TYPE is the type of simulation. Refer to
%                  niak_simus_scenario for details on the options
%   TYPE_CENTER (string, default 'median') how to extract cluster signal. Available
%      options: 'mean' and 'median'
%   NB_ITER (scalar, default 1) Number of max iterations. The algorithm stops as soon
%      as there is no change in the cluster maps.
%   FLAG_VERBOSE (boolean, default true) turn on/off the verbose.
%   FLAG_TARGET (boolean, default false)
%       If PART has a second column, then this column is used as a binary mask to define 
%       a "target": clusters are defined based on the similarity of the connectivity profile 
%       in the target regions, rather than the similarity of time series.
%       If PART has a third column, this is used as a parcellation to reduce the space 
%       before computing connectivity maps, which are then used to generate seed-based 
%       correlation maps (at full available resolution).
%   FLAG_FOCUS (boolean, default false)
%       If PART has two additional columns (three in total) then the
%       second column is treated as a binary mask of an ROI that should be
%       clustered and the third column is treated as a binary mask of a
%       reference region. The ROI will be clustered based on the similarity
%       of its connectivity profile with the prior partition in column 1 to
%       the connectivity profile of the reference.
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
% The similarity between time series or maps are measured using correlation.
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
    error('niak','syntax: res = niak_stability_cores(data,part,opt).\n Type ''help niak_stability_cores'' for more info.')
end

if nargin < 3
   opt = struct();
end
opt = psom_struct_defaults(opt, ...
      { 'type_center' , 'nb_iter' , 'nb_samps' , 'sampling' , 'flag_verbose' , 'flag_target' , 'flag_focus' } , ...
      { 'median'      , 1         , 100        , struct()   , true           , false         , false        });
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
    case 'scenario'
    otherwise
        error('%s is not an implemented method of sampling',opt.sampling.type)
end

% See if choices make sense
if opt.flag_target
    if (size(part,1)>1)&&(size(part,2)>1)
        mask_target = part(:,2)>0;
        if size(part,2) > 2
            mask_rois = part(:,3);
            mask_target_rois = niak_match_part (mask_target,mask_rois);
            mask_target_rois = mask_target_rois.part2_to_1;
            mask_target_rois = niak_build_tseries(mask_target_rois(:)',mask_rois)>0;        
            flag_rois = true;
        else 
            flag_rois = false;
        end
        part = part(:,1);
    else
        % There is a problem
        error(['You want to run the flag_target option but did not supply ',...
               'the correct number of columns in part. There need to be 2 ',...
               'columns in part or 3 if you want the ROI option as well!']);
    end
elseif opt.flag_focus
    if (size(part,1)>1)&&(size(part,2)==3)
        mask_roi = logical(part(:,2));
        mask_reference = logical(part(:,3));
        template = zeros(size(part,1),1);
        template(mask_roi) = 1;
        part = part(:,1);
        % Constrain the partition to the ROI
        part = part(mask_roi);
        % Remap the partition into continuous values
        clus = unique(part);
        n_clus = length(clus);
        tmp = part;
        for clus_id = 1:n_clus
            clus_num = clus(clus_id);
            part(part==clus_num) = clus_id;
        end
    else
        % There is a problem
        error(['You want to run the flag_focus option but did not supply ',...
               'the correct number of columns in part. There need to be 3',...
               'columns in part!']);
    end
elseif (size(part,1)>1)&&(size(part,2)>1)
    part = part(:,1);
else
    part = part(:);
end

if length(part)~=nn && ~opt.flag_focus
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
        opt_r = opt.sampling.opt.perc;
    case 'window'
        opt_r = opt.sampling.opt.length;
end
        
%% Build stability maps
if opt.flag_verbose 
    fprintf('Estimation of stable cores ...\n   ')
end

res.stab_maps = zeros(nn,nk);
if opt.flag_verbose 
    fprintf('Estimation of stability_maps ...\n   ')
end
opt_t.type_center = opt.type_center;
opt_t.correction = 'mean_var';
nb_iter = zeros(opt.nb_samps,1);
changes = zeros(opt.nb_samps,opt.nb_iter);
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
            ind = ind(1:min(floor(opt_r*nt),nt));
            data_r = data(ind,:);
        case 'window'
            ind = ss:min(ss+opt_r-1,nt);
            data_r = data(ind,:);
        case 'scenario'
            data_r = niak_simus_scenario(opt.sampling.opt);
    end
    
    % Build correlation maps    
    part_r = part;
    for ii = 1:opt.nb_iter
        nb_iter(ss) = nb_iter(ss) + 1;
        if opt.flag_focus
            tseed = niak_build_tseries(data_r(:,mask_roi),part_r,opt_t);
        else
            tseed = niak_build_tseries(data_r,part_r,opt_t);
        end
        if opt.flag_target
            if flag_rois
                ttarget = niak_build_tseries(data_r,mask_rois,opt_t);
                maps_seed = niak_fisher(corr(ttarget(:,mask_target_rois),tseed));
                maps_all = niak_fisher(corr(ttarget(:,mask_target_rois),data_r));
                rmap = niak_fisher(corr(maps_all,maps_seed));
            else
                maps_seed = niak_fisher(corr(data_r(:,mask_target),tseed));
                maps_all = niak_fisher(corr(data_r(:,mask_target),data_r));
                rmap = niak_fisher(corr(maps_all,maps_seed));
                rmap(isnan(rmap)) = -Inf;
            end
        elseif opt.flag_focus
            maps_seed = niak_fisher(corr(data_r(:,mask_reference), tseed));
            maps_reference = niak_fisher(corr(data_r(:,mask_reference), data_r(:,mask_roi)));
            rmap = niak_fisher(corr(maps_reference,maps_seed));
        else
            rmap = niak_fisher(corr(data_r,tseed));
            rmap(isnan(rmap)) = -Inf;
        end
        [val,part_r2] = max(rmap,[],2);
        changes(ss,ii) = sum(part_r~=part_r2)/length(part_r);
        if changes(ss,ii)==0
            continue
        end
        part_r = part_r2;        
    end
    if opt.flag_focus
        % Map back the results into data space
        tmp = template;
        tmp(tmp==1) = part_r;
        part_r = tmp;
    end
    for kk = 1:nk               
        res.stab_maps(:,kk) = res.stab_maps(:,kk) + double(part_r==kk);
    end
end
res.stab_maps = res.stab_maps / opt.nb_samps;

%% Generate final outputs (intra- and inter- cluster stability, stability contrast as well as partition based on cores)
[res.stab_intra,res.part_cores] = max(res.stab_maps,[],2);
if opt.flag_focus
    res.part_cores(~mask_roi) = 0;
end
res.stab_inter = zeros(size(res.stab_intra));
for kk = 1:nk
    mask = true (1,nk);
    mask(kk) = false;
    val = max(res.stab_maps(:,mask),[],2);
    res.stab_inter(res.part_cores==kk) = val(res.part_cores==kk);
end
res.stab_contrast = res.stab_intra - res.stab_inter;
res.nb_iter = nb_iter;
res.changes = changes;