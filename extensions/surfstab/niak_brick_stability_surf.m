function [files_in,files_out,opt] = niak_brick_stability_surf(files_in,files_out,opt)
% Build stability_maps at the voxel level based on clustering replications
% and a target cluster
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   DATA
%       (string) the surface data. A .mat file with one variable called
%       OPT.NAME_DATA, which is a NxV array, with N the number of subjects
%       and V the number of vertices (both hemispheres combined, left then
%       right).
%
%   PART
%       (string, optional, default 'gb_niak_omitted') path to .mat file that
%       contains a matrix of VxK where V is the number of verteces on the
%       surface and K is the number of scales to be computed. Thus, line K(i)
%       corresponds to OPT.SCALE(i).
%
%   NEIGH
%       (string, optional) the name of a .mat file, with a variable called 
%       OPT.NAME_NEIGH. This is a VxW matrix, where each the v-th row 
%       is the list of neighbours of vertex v (potentially paded with zeros). 
%       If unspecified, the neighbourhood matrix is generated for the standard
%       MNI surface with ~80k vertices. 
%
% FILES_OUT
%   (string)
%
% OPT
%   (structure) with the following fields:
%
%   SCALE
%      (vector of K integers, default same as FILES_IN.PART, if specified) the target
%      scales (i.e. number of final clusters).
%
%   NB_SAMPS
%      (integer, default 100) the number of replications.
%
%   REGION_GROWING
%      (structure, optional) the options of NIAK_REGION_GROWING. The most
%      useful parameter is:
%
%      THRE_SIZE
%         (integer,default 80) threshold on the maximum region size
%         before merging (measured in number of vertices).
%
%   CLUSTERING
%      (structure, optional) with the following fields :
%
%      TYPE
%         (string, default 'hierarchical') the clustering algorithm
%         Available options :
%            'hierarchical': a HAC based on correlation.
%            'kcores'      : kmeans cores
%
%      OPT
%         (structure, optional) options that will be  sent to the
%         clustering command. The exact list of options depends on
%         CLUSTERING.TYPE:
%         'hierarchical' : see OPT in NIAK_HIERARCHICAL_CLUSTERING
%
%   SAMPLING
%
%       TYPE
%           (string, default 'bootstrap') how to resample the time series.
%           Available options : 'bootstrap' , 'jacknife'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE :
%               bootstrap : None.
%               jacknife  : OPT.PERC is the percentage of observations
%                         retained in each sample (default 60%)
%
%   NAME_NEIGH
%       (string, default 'neigh') if FILES_IN.NEIGH is specified, the name 
%       of the variable coding for the neighbour matrix. 
%
%   NAME_DATA
%       (string, default 'data') the name of the variable that contains
%       the data.
%
%   NAME_PART
%       (string, default 'part' or 'core_part' if opt.flag_core is set to true) 
%       the name of the fieldname in FILE_IN.PART that contains the partition.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do 
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec,
%   Centre de recherche de l'institut de GÃ©riatrie de MontrÃ©al
%   DÃ©partement d'informatique et de recherche opÃ©rationnelle
%   UniversitÃ© de MontrÃ©al, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, surface analysis, cortical thickness, stability
% analysis, bootstrap, jacknife.

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
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf'' for more info.')
end

% FILES_IN
list_fields   = { 'data' , 'part' , 'neigh'       };
list_defaults = { NaN    , NaN    , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');    
end

% Options
if nargin < 3
    opt = struct;
end

if isfield(opt, 'flag_cores')
    if opt.flag_cores
        opt.name_part = 'core_part';
    end
end
        

list_fields   = { 'sampling' , 'nb_samps' , 'flag_verbose' , 'name_data' , 'name_neigh' , 'name_part' ,  'scale' , 'region_growing' , 'clustering' , 'rand_seed' , 'flag_test' };
list_defaults = { struct     , 100        , true           , 'data'      , 'neigh'      , 'part'      , []       , struct           , struct       , []          , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if ~isfield(opt.region_growing,'thre_size')
    opt.region_growing.thre_size = 80;
end
opt.region_growing.flag_verbose = false;
opt.clustering.opt.flag_verbose = opt.flag_verbose;

opt.clustering = psom_struct_defaults(opt.clustering,{'type','opt'},{'hierarchical',struct()});
opt.sampling   = psom_struct_defaults(opt.sampling,{'type','opt'},{'jacknife',struct()});

switch opt.sampling.type
    case 'bootstrap'
    case 'jacknife'
        opt.sampling.opt = psom_struct_defaults(opt.sampling.opt,{'perc'},{60});
    case 'scenario'
    otherwise
        error('%s is an unknown method of sampling',opt.sampling.type)
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the data
data = load(files_in.data);

if ~isfield(data,opt.name_data)
    error('I could not find the variable called %s in the file IN.DATA',opt.name_data)
else
    data = data.(opt.name_data);
end
[N,V] = size(data);

%% Load the neighbourhood matrix
if opt.flag_verbose
    fprintf('Building the neighbourhood matrix for the surface ...\n')
end
if strcmp(files_in.neigh,'gb_niak_omitted')
    ssurf = niak_read_surf('',true,opt.flag_verbose);    
else
    in_neigh = load(files_in.neigh,opt.name_neigh);
    ssurf.neigh = in_neigh.(opt.name_neigh);
end
if size(ssurf.neigh,1)~=V
    error('The data does not have the expected number of vertices (%i)',size(ssurf.neigh,1))
end

%% Load the target cluster
opt_m.flag_verbose = false;

% Get the partition
part_file = load(files_in.part);
part = part_file.(opt.name_part);
[pV, num_part] = size(part);

% Checks
if ~pV == V
    % Something is wrong
    error('Partition at %s does not have the expected number of verteces:\n    # verteces: %d (expected %d)\n',files_in.part, pV, V);
% See if a scale was supplied
elseif isempty(opt.scale)
    % The supplied scale is empty, see if the partition file has a scale
    % field
    if isfield(part_file, 'scale')
        % Take the scale field from the partition and use it for the
        % replication
        opt.scale = part_file.scale;
        warning('No scales were supplied. But I found a scales field in %s and will use these.\n', files_in.part);
    else
        % Just use the scales inside the partition for the replications
        opt.scale = max(part,[],1);
        warning('No scales were supplied. Using the scales of the partitions in %s now.\n', files_in.part);
    end
end

num_scale = length(opt.scale);

if ~num_scale == num_part
    % The number of scales doesn't match the number of partitions. Since we
    % only work by order at this point, this is a problem
    error('I got %d scales but %d partitions from %s. I need the same number of scales and partitions in the same order.\n', num_scale, num_part, files_in.part);
end

if opt.flag_verbose
    fprintf('This analysis has %d scale(s):\n', num_scale);
    disp(opt.scale);
end

% Prepare storage variables for the main partition and the stability
boot_store = cell(opt.nb_samps,1);

% Now draw the specified number of sub-samples and perform clustering on them
for rr = 1:opt.nb_samps
    tmp_store = struct;
    if opt.flag_verbose
        niak_progress(rr,opt.nb_samps);
    end

    % Generate a data sample
    switch opt.sampling.type
        case 'bootstrap'
            ind = ceil(N*rand(N,1));
            data_s = data(ind,:);
        case 'jacknife'
            ind = randperm(N);
            ind = ind(1:max(min(floor(opt.sampling.opt.perc*N/100),N),1));
            data_s = data(ind,:);
        case 'scenario'
            data_s = niak_simus_scenario (opt.sampling.opt);
    end

    switch opt.clustering.type
        case 'hierarchical'
            % Generate a replication of the partition
            part_roi_s = niak_region_growing(data_s,ssurf.neigh,opt.region_growing);
            % See that we have enough regions to meaningfully continue
            if length(unique(part_roi_s)) == 1
                error('Region growing for subsample #%d resulted in only one region.\nPossibly this is due to your region growing threshold of %d. Consider changing the threshold!\n', rr, opt.region_growing.thre_size);
            elseif length(unique(part_roi_s)) < 4
                warning('Region growing for subsample #%d resulted in only %d regions.\nIf this is not enough, consider changing your region growing threshold of currently %d to something else.\n', rr, length(unique(part_roi_s)), opt.region_growing.thre_size);
            end

            data_roi_s = niak_build_tseries(data_s,part_roi_s);

            % Store things
            tmp_store.part_roi_s = part_roi_s;
            % Build the hierarchy
            R = niak_build_correlation(data_roi_s);
            hier_s = niak_hierarchical_clustering(R,opt_m);
            opt_t.thresh = opt.scale;
            % Store more things
            tmp_store.hier = hier_s;
            
        case 'kcores'
            tmp_store.data_s = data_s;

        otherwise
            error('%s is an unimplemented type of clustering',opt.clustering.type)

    end
    % Store the whole tmp storage
    boot_store{rr} = tmp_store;
end

% Store scale information in the output file ahead of the replications
out = struct;
out.scale_rep = opt.scale;
out.scale_tar = max(part,[],1);

out.scale_name = cell(num_scale,1);
for sc_id = 1:num_scale
    out.scale_name{sc_id} = sprintf('sc%d', out.scale_tar(sc_id));
end

if opt.flag_verbose
        fprintf('Populating output file ...\n     %s\n', files_out);
end
save(files_out,'-struct','out');

% Randomize the scale order so two batches won't run the same scale at the
% same time
rand_inds = randperm(num_scale);

% Loop through the scales
for scale_id = rand_inds
    % Reset the output structre
    out = struct;
    scale_rep = opt.scale(scale_id);

    % Get the vertex level target partition for the current scale
    part_t = part(:, scale_id);
    size_part_t = niak_build_size_roi(part_t);
    scale_tar = max(part_t);

    scale_name = sprintf('sc%d', scale_tar);

    % Threshold the replication data on the replication scale
    opt_t.thresh = scale_rep;
    if opt.flag_verbose
        fprintf('Computing stability for scale %d\n',scale_rep);
    end

    % loop through the bootstrap samples
    out.(scale_name) = zeros(scale_tar,V);
    for b_id = 1:opt.nb_samps
        tmp = boot_store{b_id};
        
        switch opt.clustering.type
            case 'hierarchical'
                part_s = niak_threshold_hierarchy(tmp.hier,opt_t);
                part_s_sc = niak_part2vol(part_s,tmp.part_roi_s);
                
            case 'kcores'
                data_bs = tmp.data_s;

        end

        % Loop through the clusters in the target partition
        for ss = 1:scale_tar
            switch opt.clustering.type
                case 'hierarchical'
                    % Find the clusters in the replication-partition that lie in the target cluster
                    list_inter = unique(part_s_sc(part_t==ss));
                    val_inter = zeros(scale_rep,1);
                    % Loop through the overlapping clusters and see how much they overlap
                    for num_i = 1:length(list_inter)
                        val_inter(list_inter(num_i)) = sum((part_s_sc==list_inter(num_i))&(part_t==ss))/size_part_t(ss);
                    end
                    % store the stability scores for all verteces for the current
                    % cluster
                    out.(scale_name)(ss,:) = (out.(scale_name)(ss,:) + niak_part2vol(val_inter,part_s_sc'));
                
                case 'kcores'
                    % Correlate the timeseries in the target cluster with
                    % the data time series
                    t_seed_glob = mean(data_bs(:, part_t==ss),2);
                    corr_map_glob = corr(t_seed_glob, data_bs);
                    % Build the core of the correlation map with a 3 kmeans
                    % clustering
                    k_ind = kmeans(corr_map_glob, 3);
                    % Find the cluster with the highest average
                    % connectivity
                    k_mean = zeros(3,1);
                    for i = 1:3
                        k_mean(i,1) = mean(corr_map_glob(k_ind == i));
                    end
                    k_tar = find(k_mean==max(k_mean));
                    % Seed again on the individual core
                    t_seed_ind = mean(data_bs(:, k_ind==k_tar),2);
                    corr_map_ind = corr(t_seed_ind, data_bs);
                    % Store the vectorized map
                    store[ss,:] = corr_map_ind;
            end
        end
        % If we are running the kmeans cores, find overlap here
        if strcmp(opt.clustering.type, 'kcores')
            % Find the target cluster that has the maximal correlation map
            % with each location and assign the location to it
            [~, part_s] = max(store);
            % Now compute the overlap again
            for ss = 1:scale_tar
                list_inter = unique(part_s_sc(part_t==ss));
                val_inter = zeros(scale_rep,1);
                % Loop through the overlapping clusters and see how much they overlap
                for num_i = 1:length(list_inter)
                    val_inter(list_inter(num_i)) = sum((part_s_sc==list_inter(num_i))&(part_t==ss))/size_part_t(ss);
                end
                % store the stability scores for all verteces for the current
                % cluster
                out.(scale_name)(ss,:) = (out.(scale_name)(ss,:) + niak_part2vol(val_inter,part_s_sc'));
            end
        end
    end
    % Average
    out.(scale_name) = out.(scale_name) / opt.nb_samps;
    % Done with scale
    if opt.flag_verbose
        fprintf('Updating stab.%s results ...\n     %s\n',scale_name, files_out);
    end
    save(files_out,'-append','-struct','out');
end