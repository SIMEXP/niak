function [files_in,files_out,opt] = niak_brick_stability_maps(files_in,files_out,opt)
% Build stability maps from a series of stability matrices and clusterings.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_MAPS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%   STABILITY
%       (string) a .mat file containing some variables STAB, NB_CLASSES.
%       STAB(:,K) is a vectorized version of the stability matrix with
%       NB_CLASSES(K) group clusters.
%
%   HIERARCHY
%       (string or cell of strings, default FILES_IN.STABILITY) a .mat file
%       containing one variable HIER. HIER{K} is the hierarchy associated
%       with the consensus clustering for STAB(:,K). If HIERARCHY is a cell
%       of strings, a new entry of HIERARCHY will be used for each row in
%       OPT.SCALES_MAPS.
%
%   ATOMS
%       (string) a 3D volume defining the ROI
%
%   THRESHOLD
%       (string) a mat file with a variable THRESHOLD_STAB and a variable NB_CLASSES
%       THRESHOLD_STAB(NB_CLASSES == SCALES_MAPS(k,2)) is the threshold to apply on the 
%       stability map derived with SCALES_MAPS(k,2) clusters. 
%       WARNING : this is only supported for pure individual or pure group studies. 
%       No mixed analysis.
%
% FILES_OUT
%   (structure) with the following fields (outputs associated with an absent
%   field will not be generated) :
%
%   PARTITION_CONSENSUS
%       (cell of strings, default <path PARTITION>/partition_consensus_scf<K>.<EXT ROIS>)
%       PARTITION_CONSENSUS{K} is a 3D volume representing the consensus partition for K final
%       clusters (see OPT.SCALES_MAPS below).
%
%   PARTITION_CORE
%       (cell of strings, default <path PARTITION>/partition_core_scf<K>.<EXT ROIS>)
%       PARTITION_CORE{K} is a 3D volume representing the cores of the consensus
%       partition for K final clusters (see OPT.SCALES_MAPS below), which is to say the
%       OPT.PERCENTILE regions of each cluster that have the highest average stability
%       with that cluster.
%
%   PARTITION_ADJUSTED
%       (cell of strings, default <path PARTITION>/partition_stab_scf<K>.<EXT ROIS>)
%       PARTITION_ADJUSTED{K} is a 3D volume where each voxel is associated with the core
%       cluster with maximal average stability with this voxel, for K final clusters
%       (see OPT.SCALES_MAPS below).
%
%   PARTITION_THRESHOLD
%       (cell of strings, default <path PARTITION>/partition_stab_scf<K>.<EXT ROIS>)
%       PARTITION_THRESHOLD{K} is a 3D volume identical to PARTITION_ADJUSTED{K}, except
%       that only those voxels with a stability score greater than OPT.THRESHOLD in
%       STABILITY_MAP_ALL{K} are assigned to a cluster. Other voxels have a value of zero.
%
%   STABILITY_MAPS
%       (cell of strings, default <path PARTITION>/stability_map_scf<K>.<EXT ROIS>)
%       STABILITY_MAPS{K} is the name of a 4D volume containing the stability
%       maps of the core consensus clusters for K final clusters
%       (see OPT.SCALES_MAPS below). The fourth dimension codes for the number of cluster
%       i.e. VOL(:,:,:,k) is the stability map of the kth cluster.
%
%   STABILITY_MAP_ALL
%       (cell of strings, default <path PARTITION>/stab_map_all_scf<K>.<EXT ROIS>)
%       STABILITY_MAP_ALL{K} is the name of a 3D volume such that each voxel is
%       associated with the value of the stability map of the cluster that contains it, with
%       K final clusters (see OPT.SCALES_MAPS below).
%
% OPT
%       (structure) with the following fields.  
%
%   SCALES_MAPS
%       (array, default []) SCALES_MAPS(K,:) is the list of scales that will
%       be used to generate stability maps:
%           SCALES_MAPS(K,1) is the number of clusters used for the stability analysis
%           SCALES_MAPS(K,2) is the number of clusters used to derive the hierarchical
%           SCALES_MAPS(K,3) is the (final) number of consensus group clusters
%       For an individual analysis, use SCALES_MAPS(K,2) = SCALES_MAPS(K,1), and both the 
%       stability and hierarchy come from the individual stability analysis.
%       For a group analysis, SCALES_MAPS(K,1) is the number of group clusters, 
%       SCALES_MAPS(K,2) is the number of group clusters and SCALES_MAPS(K,3) is the number 
%       of consensus (group) clusters.
%       FOR a mixed analysis, SCALES_MAPS(K,1) is the number of individual clusters, 
%       SCALES_MAPS(K,2) is the number of group clusters and SCALES_MAPS(K,3) is the number
%       of consensus (group) clusters.
%
%   PERCENTILE
%       (string, default 0.5) Value (0 to 1) percentile of stable
%       regions used to build stability maps.
%
%   MIN_SIZE_CORE
%       (integer, default 2) the minimum size of a stability core in terms 
%       of number of atoms (unless the cluster is smaller than the number 
%       specified)
%
%   THRESHOLD
%       (scalar, default 0.5) the threshold to be applied on the stability map to generate
%       the threshold version of the adjusted partition. This can also be specified using
%       FILES_IN.THRESHOLD (see above).
%
%   FLAG_PARCEL
%       (boolean, default false) if the flag is true, the consensus partition is broken down
%       into spatially connected parcels. The stability cores, threshold and adjusted 
%       partitions are derived from the parcels.
%
%   FOLDER_OUT
%       (string, default: path of FILES_IN.STABILITY) If present, all
%       default outputs will be created in the folder FOLDER_OUT. The folder
%       needs to be created beforehand.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%       do anything but update the default values in FILES_IN,
%       FILES_OUT and OPT.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function
%       prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_STABILITY_TSERIES, NIAK_STABILITY_FIR, NIAK_STABILITY_CONSENSUS
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : stability, maps, clustering, BASC

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
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_MAPS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_maps'' for more info.')
end

%% Files in
gb_name_structure = 'files_in';
gb_list_fields    = {'stability' , 'hierarchy' , 'atoms' , 'threshold'       };
gb_list_defaults  = {NaN         , []          , NaN     , 'gb_niak_omitted' };
niak_set_defaults

%% Files out
gb_name_structure = 'files_out';
gb_list_fields    = {'partition_consensus' , 'partition_core'  , 'partition_adjusted' , 'partition_threshold' , 'stability_maps'   ,'stability_map_all' };
gb_list_defaults  = {'gb_niak_omitted'     , 'gb_niak_omitted' , 'gb_niak_omitted'    , 'gb_niak_omitted'     , 'gb_niak_omitted'  ,'gb_niak_omitted'   };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_parcel' , 'threshold' , 'scales_maps' , 'percentile' , 'folder_out' , 'flag_verbose' , 'flag_test' , 'min_size_core' };
gb_list_defaults  = {false         , 0.5         , NaN           , 0.5          , ''           , true           , false       , 2               };
niak_set_defaults

[path_f,name_f,ext_f] = niak_fileparts(files_in.atoms);

if strcmp(opt.folder_out,'')
    path_f = niak_fileparts(files_in.stability);
    opt.folder_out = path_f;
    folder_out = opt.folder_out;
end

%% Building default output names
if isempty(files_out.stability_maps)
    files_out.stability_maps = struct();
    for num_c = 1:size(opt.scales_maps,1)
        files_out.stability_maps(num_c).cluster{num_c2} = [folder_out filesep 'stab_map_cluster_scf',num2str(opt.scales_maps(num_c,end)),'_clust',num2str(num_c2),ext_f];
    end
end

if isempty(files_out.stability_map_all)
    files_out.stability_map_all = cell([size(opt.scales_maps,1) 1]);
    for num_s = 1:size(opt.scales_maps,1)
        files_out.stability_map_all{num_s} = [folder_out filesep 'stab_map_all_scf',num2str(opt.scales_maps(num_s,end)),ext_f];
    end
end

if isempty(files_out.partition_consensus)
    files_out.partition_consensus = cell([size(opt.scales_maps,1) 1]);
    for num_s = 1:size(opt.scales_maps,1)
        files_out.partition_consensus{num_s} = [folder_out filesep 'partition_consensus_scf' num2str(opt.scales_maps(num_s,end)) ext_f];
    end
end

if isempty(files_out.partition_adjusted)
    files_out.partition_adjusted = cell([size(opt.scales_maps,1) 1]);
    for num_s = 1:size(opt.scales_maps,1)
        files_out.partition_adjusted{num_s} = [folder_out filesep 'partition_adjusted_scf' num2str(opt.scales_maps(num_s,end)) ext_f];
    end
end

if isempty(files_out.partition_core)
    files_out.partition_core = cell([size(opt.scales_maps,1) 1]);
    for num_s = 1:size(opt.scales_maps,1)
        files_out.partition_core{num_s} = [folder_out filesep 'partition_core_scf' num2str(opt.scales_maps(num_s,end)) ext_f];
    end
end

%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = sprintf('Generating consensus/adjusted brain partitions and associated stability maps');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read the threshold
if ~strcmp(files_in.threshold,'gb_niak_omitted')
    threshold_stab = load(files_in.threshold,'threshold_stab');
    threshold_stab = threshold_stab.threshold_stab;
    nb_classes_stab = load(files_in.threshold,'nb_classes');
    nb_classes_stab = nb_classes_stab.nb_classes;
end

%% Read the partition
if flag_verbose
    fprintf('   Reading the results of the stability analysis and the consensus hierarchy ...\n');
end

data = load(files_in.stability);

%% Read the atoms
if flag_verbose
    fprintf('   Reading the atoms ...\n');
end

[hdr,vol_atoms] = niak_read_vol(files_in.atoms);
vol_atoms = round(vol_atoms);
mask = vol_atoms>0;
ind_mask = find(mask);

%% generate stability maps
if flag_verbose
    fprintf('   Generating stability maps ...\n');
end
scales_ind   = opt.scales_maps(:,1);
scales_group = opt.scales_maps(:,2);
scales_final = opt.scales_maps(:,3);
nb_scales = length(scales_ind);
for num_i = 1:nb_scales
    if flag_verbose
        fprintf('    Scale %i, %i clusters ...\n',scales_ind(num_i),scales_final(num_i));
    end

    %% Read the hierarchical consensus clustering
    if (isempty(files_in.hierarchy))&&(num_i==1)
        hier = data.hier;
        nb_classes_hier = data.nb_classes;
    elseif (ischar(files_in.hierarchy))&&(num_i==1)
        data_hier = load(files_in.hierarchy,'hier','nb_classes');
        nb_classes_hier = data_hier.nb_classes;
        hier = data_hier.hier;
    elseif iscellstr(files_in.hierarchy)
        data_hier = load(files_in.hierarchy{num_i},'hier','nb_classes');
        nb_classes_hier = data_hier.nb_classes;
        hier = data_hier.hier;
    end

    %% If an adaptative threshold has been specified, use it
    if ~strcmp(files_in.threshold,'gb_niak_omitted')
        opt.threshold = threshold_stab(scales_group(num_i)==nb_classes_stab);
    end

    %% Initialize maps
    nb_clust = scales_final(num_i);
    opt_t.thresh = nb_clust;
    num_s = find(data.nb_classes==scales_ind(num_i));
    num_s_hier = find(nb_classes_hier==scales_group(num_i));
    if isempty(num_s)
        error('I could not find the specified scale (%i) in the stability results',scales_ind(num_i));
    end
    part = niak_threshold_hierarchy(hier{num_s_hier},opt_t);    % The partition associated with scale SCALES_MAPS(I,1) random clusters and SCALES_MAPS(I,2) consensus clusters.
    stab = niak_vec2mat(data.stab(:,num_s));                    % The stability matrix associated with scale SCALES_MAPS(I,1) random clusters
    vol_part_consensus = niak_part2vol(part,vol_atoms);         % A volume representing the partition
    if opt.flag_parcel % Optional: break the consensus partition into spatially connected parcels
        vol_part_consensus = niak_cluster2parcel(vol_part_consensus,true,26);
        nb_clust = max(vol_part_consensus(:));
        for num_a = 1:length(part);
            part(num_a) = min(unique(vol_part_consensus(vol_atoms==num_a)));
        end
        ind_ok = 1:max(part);
        val = unique(part(part~=0));
        ind_ok(val) = 1:length(val);
        part(part~=0) = ind_ok(part(part~=0));
        vol_part_consensus = niak_part2vol(part,vol_atoms); 
    end
    vol_part_adjusted = zeros(size(vol_part_consensus));        % A volume representing the partition derived from maximal stability
    part_core = zeros(size(part));                              % A vector representation of the stable cores of the consensus clusters
    stab_all = zeros(size(vol_part_consensus));                 % A volume representing the maximal stability of each region across all possible target core clusters
    stab_map_all = zeros([size(vol_part_consensus) nb_clust]);  % A 4D array representing the stability maps of all clusters.
    
    for num_c = 1:nb_clust
        if flag_verbose
            fprintf(' %i',num_c);
        end
        stab_vec = mean(stab(part==num_c,part==num_c),2); % Average stability within the cluster
        [tmp,order] = sort(stab_vec,'descend'); % Sort regions by decreasing average stability    
        ind_c = find(part==num_c); % Get the indices of regions
        nb_atoms_core = min(max(ceil(percentile * length(order)),min_size_core),length(order));
        ind_core = ind_c(order(1:nb_atoms_core)); % Keep a set percentage of the most stable regions
        part_core(ind_core) = num_c; % Build a vector of the core regions    
        stab_core = zeros([size(stab,1) 1]);
        stab_core(part_core~=num_c) = mean(stab(part_core~=num_c,part_core==num_c),2);
        if sum(part_core==num_c)~=1
            stab_core(part_core==num_c) = (sum(stab(part_core==num_c,part_core==num_c),2)-1)/(sum(part_core==num_c)-1);
        end
        stab_map = niak_part2vol(stab_core,vol_atoms); % Build a stability map using the core as target
        stab_map_all(:,:,:,num_c) = stab_map;
        % Update the max stability map, and associated cluster labels
        [stab_all(mask),ind_max] = max([stab_all(mask) stab_map(mask)],[],2);
        vol_part_adjusted(ind_mask(ind_max==2)) = num_c;
    end

    % Save the stability maps
    if ~ischar(files_out.stability_maps)||~strcmp(files_out.stability_maps,'gb_niak_omitted')
        hdr.file_name = files_out.stability_maps{num_i};
        niak_write_vol(hdr,stab_map_all);
    end

    %% A "threshold" version of the adjusted partition, where only stable atoms are retained in the partition
    vol_threshold = vol_part_adjusted;
    vol_threshold(stab_all<opt.threshold) = 0;
    
    if flag_verbose
        fprintf('\n');
    end
    
    %% Save the partition
    if ~ischar(files_out.partition_consensus)
        if opt.flag_verbose
            fprintf('    Saving the consensus partition ...\n')
        end
        hdr.file_name = files_out.partition_consensus{num_i};
        niak_write_vol(hdr,vol_part_consensus);
    end

    %% Save the core stable regions
    if ~ischar(files_out.partition_core)
        if opt.flag_verbose
            fprintf('    Saving the stable cores of the consensus partition ...\n')
        end    
        hdr.file_name = files_out.partition_core{num_i};
        niak_write_vol(hdr,niak_part2vol(part_core,vol_atoms));
    end

    %% Save the partition associated with the maximal stability map
    if ~ischar(files_out.partition_adjusted)
        if opt.flag_verbose
            fprintf('    Saving the partition adjusted for stability ...\n')
        end
        hdr.file_name = files_out.partition_adjusted{num_i};
        niak_write_vol(hdr,vol_part_adjusted);
    end

    %% Save the partition associated with the maximal stability map
    if ~ischar(files_out.partition_threshold)
        if opt.flag_verbose
            fprintf('    Saving the partition adjusted for stability ...\n')
        end
        hdr.file_name = files_out.partition_threshold{num_i};
        niak_write_vol(hdr,vol_threshold);
    end
    
    %% Save the max stability map
    if ~ischar(files_out.stability_map_all)
        if opt.flag_verbose
            fprintf('    Saving the compound stability maps ...\n')
        end
        hdr.file_name = files_out.stability_map_all{num_i};
        niak_write_vol(hdr,stab_all);
    end
end

if flag_verbose
    fprintf('\nDone !\n');
end
