function [in, out, opt] = niak_brick_scores_fmri(in, out, opt)
% Build stability maps using an a priori partition
%
% SYNTAX:
% [IN,FILES_OUT,OPT] = NIAK_BRICK_SCORES_FMRI(IN,FILES_OUT,OPT)
%
% IN.FMRI
%   (string or cell of strings) One or multiple 3D+t datasets.
% IN.PART
%   (string) A 3D volume with a "target" partition. The Ith cluster
%   is filled with Is.
% IN.MASK
%   (string) A 3D volume with non-zero values in all voxels that should be
%   included in the analysis. The partition in IN.PART should be a
%   subset of these voxels.
%
% FILES_OUT.STABILITY_MAPS
%   (string) a 4D volume, where the k-th volume is the stability map of the k-th cluster.
% FILES_OUT.PARTITION_CORES
%   (string) a 3D volume where the k-th cluster based on stable cores is filled with k's.
% FILES_OUT.STABILITY_INTRA
%   (string) a 3D volume where each voxel is filled with the stability in its own cluster.
% FILES_OUT.STABILITY_INTRA
%   (string) a 3D volume where each voxel is filled with the stability with the closest cluster
%   outside of its own.
% FILES_OUT.STABILITY_CONTRAST
%   (string) the difference between the intra- and inter- cluster stability.
% FILES_OUT.PARTITION_THRESH
%   (string) same as PARTITION_CORES, but only voxels with stability contrast > OPT.THRESH appear
%   in a cluster.
% FILES_OUT.RMAP_PART
%   (string) correlation maps using the partition IN.PART as seeds.
% FILES_OUT.RMAP_CORES
%   (string) correlation maps using the partition FILES_OUT.PARTITION_CORES as seeds.
% FILES_OUT.DUAL_REGRESSION
%   (string) the "dual regression" maps using IN.PART as seeds.
% FILES_OUT.EXTRA
%   (string) extra info in a .mat file.
% FILES_OUT.PART_ORDER
%   (string) a csv file containing the list of numerical partition labels on the left and the 
%   order of the corresponding output volume on the right. Unless the template partition supplied
%   in IN.PART has non-continuous partition values or doesn't start with 1, the left and the 
%   right column will be identical.
%
% OPT.FOLDER_OUT (string, default empty) if non-empty, use that to generate default results.
% OPT.NB_SAMPS (integer, default 100) the number of replications to 
%      generate stability cores & maps.
% OPT.THRESH (scalar, default 0.5) the threshold applied on stability contrast to 
%      generate PARTITION_THRESH.
% OPT.SAMPLING.TYPE (string, default 'CBB') how to resample the features.
%      Available options : 'bootstrap' , 'jacknife', 'window', 'CBB'
% OPT.SAMPLING.OPT (structure) the options of the sampling. 
%      bootstrap : None.
%      jacknife  : OPT.PERC is the percentage of observations
%                  retained in each sample (default 60%)
%      CBB       : OPT.BLOCK_LENGTH is the length of the block for bootstrap. See 
%                  NIAK_BOOTSTRAP_TSERIES for default options.
%      window    : OPT.LENGTH is the length of the window, expressed in time points
%                  (default 60% of the # of features).
% OPT.RAND_SEED (scalar, default []) The specified value is used to seed the random
%   number generator with PSOM_SET_RAND_SEED. If left empty, no action is taken.
% OPT.FLAG_VERBOSE (boolean, default true) turn on/off the verbose.
% OPT.FLAG_TARGET (boolean, default false)
%       If IN.PART has a second column, then this column is used as a binary mask to define 
%       a "target": clusters are defined based on the similarity of the connectivity profile 
%       in the target regions, rather than the similarity of time series.
%       If IN.PART has a third column, this is used as a parcellation to reduce the space 
%       before computing connectivity maps, which are then used to generate seed-based 
%       correlation maps (at full available resolution).
% OPT.FLAG_DEAL
%       If the partition supplied by the user does not have the appropriate
%       number of columns, this flag can force the brick to duplicate the
%       first column. This may be useful if you want to use the same mask
%       for the OPT.FLAG_TARGET flag as you use in the cluster partition.
%       Use with care.
% OPT.FLAG_FOCUS (boolean, default false)
%       If IN.PART has a two additional columns (three in total) then the
%       second column is treated as a binary mask of an ROI that should be
%       clustered and the third column is treated as a binary mask of a
%       reference region. The ROI will be clustered based on the similarity
%       of its connectivity profile with the prior partition in column 1 to
%       the connectivity profile of the reference.
% OPT.FLAG_VOL (boolean, default false)
%       If true, the output for the designated types will be generated as 3D or 4D volumes
%       (e.g. minc or nifti). If false, only the .mat file will be generated
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does not do anything
%       but update IN, FILES_OUT and OPT.
% _________________________________________________________________________
% COMMENTS:
% For "window" sampling, the OPT.NB_SAMPS argument is ignored, 
% and all possible sliding windows are generated.
%
% If OPT.FOLDER_OUT is specified, by default all outputs are generated. 
% Otherwise, no output is generated. Individual outputs can be turned on/off
% by assigning the output the value 'gb_niak_omitted'
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Geriatrie de Montreal
%   Departement d'informatique et de recherche operationnelle
%   Universite de Montreal, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability analysis, bootstrap, jacknife.

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
if ~exist('in','var')||~exist('out','var')
    error('niak:brick','syntax: [IN,FILES_OUT,OPT] = NIAK_BRICK_SCORES_FMRI(IN,FILES_OUT,OPT).\n Type ''help niak_brick_scores_fmri'' for more info.')
end

% IN
in = psom_struct_defaults(in, ...
           { 'fmri' , 'part' , 'mask' }, ...
           { NaN    , NaN    , NaN    });

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      { 'type_center' , 'nb_iter' , 'folder_out' , 'thresh' , 'rand_seed' , 'nb_samps' , 'sampling' , 'flag_focus' , 'flag_target' , 'flag_deal' , 'flag_verbose' , 'flag_test' } , ...
      { 'median'      , 1         , ''           , 0.5      , []          , 100        , struct()   , false        , false         , false       , true           , false       });
opt.sampling = psom_struct_defaults(opt.sampling, ...
      { 'type' , 'opt'    }, ...
      { 'CBB'  , struct() });

% FILES_OUT
if ~iscell(in.fmri)
    error('IN.FMRI must be a cell of strings and not %s', class(in.fmri))
end
[~,~,ext] = niak_fileparts(in.fmri{1});

if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    oname = { 'stability_maps'                , 'stability_intra'                , 'stability_inter'                , 'stability_contrast'                , 'partition_cores'                , 'partition_thresh'                 , 'rmap_part'                , 'rmap_cores'                , 'dual_regression'                , 'extra'                , 'part_order'                };
    oval =  { [path_out 'stability_maps' ext] , [path_out 'stability_intra' ext] , [path_out 'stability_inter' ext] , [path_out 'stability_contrast' ext] , [path_out 'partition_cores' ext] ,  [path_out 'partition_thresh' ext] , [path_out 'rmap_part' ext] , [path_out 'rmap_cores' ext] , [path_out 'dual_regression' ext] , [path_out 'extra.mat'] , [path_out 'part_order.csv'] };
    out = psom_struct_defaults(out, oname, oval);
else
    oname = { 'stability_maps'  , 'stability_intra' , 'stability_inter' , 'stability_contrast' , 'partition_cores' , 'partition_thresh' , 'rmap_part'       , 'rmap_cores'      , 'dual_regression' , 'extra'           , 'part_order'      };
    oval =  { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted'    , 'gb_niak_omitted' , 'gb_niak_omitted'  , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
    out = psom_struct_defaults(out, oname, oval);
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

% Make header for 3D files
[FDhdr,vol] = niak_read_vol(in.fmri{1});
TDhdr = FDhdr;
tmp = size(vol);
td_size = tmp(1:3);
% See if we have a nifti or a minc
if ~isempty(findstr(ext, 'mnc'))
    warning('This is a minc file, I won''t do anything');
elseif ~isempty(findstr(ext, 'nii'))
    dim = ones(1,8);
    dim(2:4) = td_size;
    TDhdr.details.dim = dim;
else
    error('I do not recognize the input file type');
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

% Get the partition
[~,part] = niak_read_vol(in.part);
% Round it in case the values are not integers
part = round(part);
% Check if the partition has continuous values and starts with 1
un_part = unique(part(part~=0));
reference = 1:numel(un_part);
part_order = [reference(:), un_part(:)];
if ~isequal(un_part(:), reference(:))
    % The values are non continuous or don't start at 1
    warning('The values in %s are non continuous or don''t start at 1! I will remap them.', in.part);
    % Reset the partition values to continuous values starting with 1
    part = remap_partition(part, part_order);
end
% Get the mask
[~, mask] = niak_read_vol(in.mask);
fprintf('I am loading the mask at %s now.\n', in.mask);
mask = logical(mask);

%% Check quickly if the partition covers the entire mask
non_overlap = sum(part(mask)==0);
if non_overlap > 0
    % Some parts of the mask have no partition. Constrain the mask to the partition raise a warning
    warning('There are values inside the mask that do not have a partition. I will use the union of mask and partition.');
    mask = logical(logical(part) .* mask);
    if strcmp(out.part_order,'gb_niak_omitted')
        warning('OUT.PART_ORDER is not defined. There will be no .csv file with the partition order!');
    end
end

%% Flag Checks
if opt.flag_target || opt.flag_focus
    % We expect the partition to be 4D
    if size(part,4) > 1
        % We do have a 4D partition, take the first one
        add_part = part(:,:,:,2:end);
        part = part(:,:,:,1);
    elseif opt.flag_deal
        warning(['Your partition only has 3 dimensions but needs 4. ',...
                 'I will repeat the first dimension for you because ',...
                 'OPT.FLAG_DEAL is true.']);
        % Run Region Growing if there are too many voxels
        add_part = part;
        % See if the number of voxels exceeds 5000. If so, make an ROI
        % partition
        if sum(logical(part(:)))>5000
            warning(['The number of voxels in your partition exceeds 5000. ',...
                     'This will lead to very big correlation matrices. ',...
                     'I will generate a region growing partition to ',...
                     'dimensionality.']);
            sz = size(vol);
            [neigh, ~] = niak_build_neighbour(mask, struct);
            % Loop through time and mask the volume
            mask_vol = zeros(sum(mask(:)), sz(end));
            for t = 1:sz(end)
                tmp_vol = vol(:,:,:,t);
                mask_vol(:, t) = tmp_vol(mask);
            end
            mask_vol = mask_vol';
            roi_part = niak_region_growing(mask_vol, neigh, struct('thre_size', 100));
            % Shape it back into 3D space
            tmp = zeros(size(mask));
            tmp(mask) = roi_part;
            roi_part = tmp;
            add_part = cat(4, add_part, roi_part);
        end

    else
        error('You need to supply a 4D partition file because of your choice of flags.');
    end
end

if any(size(vol(:,:,:,1))~=size(part))
    error('the fMRI dataset and the partition should have the same spatial dimensions')
end

part_v = part(mask);
for rr = 1:length(in.fmri)
    if rr>1
        [FDhdr,vol] = niak_read_vol(in.fmri{rr});
    end        
    if rr == 1
         tseries = niak_normalize_tseries(niak_vol2tseries(vol,mask));
    else
         tseries = [tseries ; niak_normalize_tseries(niak_vol2tseries(vol,mask))];
    end
end

if opt.flag_target || opt.flag_focus
    % We still need to mask the other bits of the partition
    part_run = part_v;
    for part_id = 1:size(add_part,4)
        part_tmp = add_part(:,:,:,part_id);
        part_tmp_v = part_tmp(mask);
        part_run = cat(2, part_run, part_tmp_v);
    end
else
    part_run = part_v;
end 

%% Run the stability estimation
opt_score = rmfield(opt,{'folder_out', 'thresh', 'rand_seed', 'flag_test', 'flag_deal'});
res = niak_scores(tseries,part_run,opt_score);

if ~strcmp(out.stability_maps,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing stability maps as a volume\n')
    end
    % Write the output as a volume
    stab_maps = niak_part2vol(res.stab_maps',mask);
    FDhdr.file_name = out.stability_maps;
    niak_write_vol(FDhdr,stab_maps);
end

% Stability Intra
if ~strcmp(out.stability_intra,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing intra-cluster stability as a volume\n');
    end
    % Write the output as a volume
    stab_intra = niak_part2vol(res.stab_intra',mask);
    TDhdr.file_name = out.stability_intra;
    niak_write_vol(TDhdr,stab_intra);
end

% Stability Inter
if ~strcmp(out.stability_inter,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing inter-cluster stability as a volume\n');
    end
    % Write the output as a volume
    stab_inter = niak_part2vol(res.stab_inter',mask);
    TDhdr.file_name = out.stability_inter;
    niak_write_vol(TDhdr,stab_inter);
end

% Silhouette
if ~strcmp(out.stability_contrast,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing stability contrast as a volume\n')
    end
    % Write the output as a volume
    stab_contrast = niak_part2vol(res.stab_contrast',mask);
    TDhdr.file_name = out.stability_contrast;
    niak_write_vol(TDhdr,stab_contrast);
end

% Partition Cores
if ~strcmp(out.partition_cores,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing partition based on cores as a volume\n')
    end
    % Write the output as a volume
    part_cores = niak_part2vol(res.part_cores',mask);
    FDhdr.file_name = out.partition_cores;
    niak_write_vol(FDhdr,part_cores);
end

% Partition Thresholded
if ~strcmp(out.partition_thresh,'gb_niak_omitted')
    stab_contrast = niak_part2vol(res.stab_contrast',mask);
    part_cores = niak_part2vol(res.part_cores',mask);
    part_cores(stab_contrast<opt.thresh) = 0;

    if opt.flag_verbose
        fprintf('Writing partition based on cores, thresholded on stability as a volume\n')
    end
    % Write the output as a volume
    FDhdr.file_name = out.partition_thresh;
    niak_write_vol(FDhdr,part_cores);
end
 
% Seed based on the partition
if ~strcmp(out.rmap_part,'gb_niak_omitted')
    opt_t.type_center = 'mean';
    opt_t.correction = 'mean_var';
    tseed = niak_build_tseries(tseries,part_v,opt_t);
    rmap_vec = niak_fisher(niak_corr(tseries,tseed));

    if opt.flag_verbose
        fprintf('Writing correlation maps (seed: initial partition) as a volume\n')
    end
    % Write the output as a volume
    rmap = niak_part2vol(rmap_vec',mask);
    FDhdr.file_name = out.rmap_part;
    niak_write_vol(FDhdr,rmap);
end

% Seed based on the cores of the partition
if ~strcmp(out.rmap_cores,'gb_niak_omitted')
    opt_t.type_center = 'mean';
    opt_t.correction = 'mean_var';
    tseed = niak_build_tseries(tseries,res.part_cores,opt_t);
    rmap_vec = niak_fisher(niak_corr(tseries,tseed));
    if opt.flag_verbose
        fprintf('Writing correlation maps (seed: cores) as a volume\n')
    end
    % Write the output as a volume
    rmap = niak_part2vol(rmap_vec',mask);
    FDhdr.file_name = out.rmap_cores;
    niak_write_vol(FDhdr,rmap);
end

% Dual Regression
if ~strcmp(out.dual_regression,'gb_niak_omitted')
    opt_t.type_center = 'mean';
    opt_t.correction = 'mean_var';
    tseed = niak_build_tseries(tseries,part_v,opt_t);
    tseed = niak_normalize_tseries(tseed);
    tseries = niak_normalize_tseries(tseries);
    try
        beta = niak_lse(tseries,tseed);
    catch 
        warning('Dual regression was ill-conditioned')
        beta = zeros(size(tseries,1),max(part_v));
    end

    if opt.flag_verbose
        fprintf('Writing dual regression maps as a volume\n')
    end
    % Write the output as a volume
    beta = niak_part2vol(beta,mask);
    FDhdr.file_name = out.dual_regression;
    niak_write_vol(FDhdr,beta);
end

% Extra
if ~strcmp(out.extra,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing extra info as a .mat file\n')
    end
    % Write the output as a mat file
    nb_iter = res.nb_iter;
    changes = res.changes;
    save(out.extra,'nb_iter','changes');
end

% Part Order
if ~strcmp(out.part_order,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Writing part order info as a .csv file\n')
    end
    % Write the output as a mat file
    nb_iter = res.nb_iter;
    changes = res.changes;
    csvwrite(out.part_order, part_order);
end

function new_part = remap_partition(in_part,part_order)
    % This function replaces the values in in_part according
    % to the correspondence established in part_order
    % The values in in_part are in the right column and the 
    % values they are replaced by are in the left column.
    
    % Get the number of values that need to be remapped
    n_val = size(part_order,1);
    new_part = zeros(size(in_part));
    for val_id = 1:n_val
        new_val = part_order(val_id,1);
        old_val = part_order(val_id,2);
        new_part(in_part==old_val) = new_val;
    end


