function [in,out,opt] = niak_brick_scores_fmri_v2(in,out,opt)
% Build stability maps using stable cores of an a priori partition
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SCORES_FMRI(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN.FMRI
%   (string or cell of strings) One or multiple 3D+t dataset.
% FILES_IN.PART
%   (string) A 3D volume with a "target" partition. The Ith cluster
%   is filled with Is.
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
% FILES_OUT.EXTRA
%   (string) extra info in a .mat file.
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
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does not do anything
%      but update FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% COMMENTS:
% For "window" sampling, the OPT.NB_SAMPS argument is ignored, 
% and all possible sliding windows are generated.
%
% Copyright (c) Pierre Bellec,
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SCORES_FMRI(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_scores_fmri'' for more info.')
end

% FILES_IN
in = psom_struct_defaults(in, ...
           { 'fmri' , 'part' }, ...
           { NaN    , NaN    });

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      { 'type_center' , 'nb_iter' , 'folder_out' , 'thresh' , 'rand_seed' , 'nb_samps' , 'sampling' , 'flag_verbose' , 'flag_test' } , ...
      { 'median'      , 1         , ''           , 0.5      , []          , 100        , struct()   , true           , false       });
opt.sampling = psom_struct_defaults(opt.sampling, ...
      { 'type' , 'opt'    }, ...
      { 'CBB'  , struct() });

% FILES_OUT
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    [~,~,ext] = niak_fileparts(in.fmri);
    out = psom_struct_defaults(out, ...
            { 'partition_cores'                , 'stability_maps'                , 'stability_intra'                , 'stability_inter'                , 'stability_contrast'                , 'partition_thresh'                , 'extra'                }, ...
            { [path_out 'partition_cores' ext] , [path_out 'stability_maps' ext] , [path_out 'stability_intra' ext] , [path_out 'stability_inter' ext] , [path_out 'stability_contrast' ext] , [path_out 'partition_thresh' ext] , [path_out 'extra.mat'] });
else
    out = psom_struct_defaults(out, ...
            { 'partition_cores' , 'stability_maps' , 'stability_intra' , 'stability_inter' , 'stability_contrast' , 'partition_thresh' , 'extra' }, ...
            { NaN               , NaN              , NaN               , NaN               , NaN                  , NaN                , NaN     });
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
if ischar(in.fmri)
    in.fmri = {in.fmri};
end
[hdr,vol] = niak_read_vol(in.fmri{1});
[hdr2,part] = niak_read_vol(in.part);
part = round(part);
if any(size(vol(:,:,:,1))~=size(part))
    error('the fMRI dataset and the partition should have the same spatial dimensions')
end
mask = part>0;
part_v = part(mask);
for rr = 1:length(in.fmri)
    if rr>1
        [hdr,vol] = niak_read_vol(in.fmri{rr});
    end    
    tseries_r = niak_vol2tseries(vol,mask);
    if rr == 1
         tseries = niak_normalize_tseries(niak_vol2tseries(vol,mask));
    else
         tseries = [tseries ; niak_normalize_tseries(niak_vol2tseries(vol,mask))];
    end
end

%% Run the stability estimation
opt_score = rmfield(opt,{'folder_out','thresh','rand_seed','flag_test'});
res = niak_stability_scores_v2(tseries,part_v,opt_score);

if opt.flag_verbose
    fprintf('Writing stability maps\n')
end
stab_maps = niak_part2vol(res.stab_maps',mask);
hdr.file_name = out.stability_maps;
niak_write_vol(hdr,stab_maps);

if opt.flag_verbose
    fprintf('Writing intra-cluster stability\n')
end
stab_intra = niak_part2vol(res.stab_intra',mask);
hdr.file_name = out.stability_intra;
niak_write_vol(hdr,stab_intra);

if opt.flag_verbose
    fprintf('Writing inter-cluster stability\n')
end
stab_inter = niak_part2vol(res.stab_inter',mask);
hdr.file_name = out.stability_inter;
niak_write_vol(hdr,stab_inter);

if opt.flag_verbose
    fprintf('Writing stability contrast\n')
end
stab_contrast = niak_part2vol(res.stab_contrast',mask);
hdr.file_name = out.stability_contrast;
niak_write_vol(hdr,stab_contrast);

if opt.flag_verbose
    fprintf('Writing partition based on cores\n')
end
part_cores = niak_part2vol(res.part_cores',mask);
hdr.file_name = out.partition_cores;
niak_write_vol(hdr,part_cores);

if opt.flag_verbose
    fprintf('Writing partition based on cores, thresholded on stability\n')
end
hdr.file_name = out.partition_thresh;
part_cores(stab_contrast<opt.thresh) = 0;
niak_write_vol(hdr,part_cores);

if opt.flag_verbose
    fprintf('Writing extra info\n')
end
nb_iter = res.nb_iter;
changes = res.changes;
save(out.extra,'nb_iter','changes')