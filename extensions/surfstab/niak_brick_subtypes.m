function [in,out,opt] = niak_brick_subtypes(in,out,opt)
% BLABLABLA
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPES(FILES_IN,FILES_OUT,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   MASK
%      (string) a file name of a mask of the brain (filled with 1s, 0 is for the 
%      background). The analysis will be done on the voxels inside the mask.
%
%   STAB_MAPS.(SUBJECT).(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> and <RUN> can be 
%      any arbitrary string. 
%
% FILES_OUT.MAPS
%    (cell of strings) FILES_OUT.MAPS{I} is the mean stability of network I.
%
% FILES_OUT.MAPS_DEMEANED
%    (cell of strings) FILES_OUT.MAPS_DEMEANED{I} is the mean stability of network I,
%    minus the grand average of all stability maps.
%
% FILES_OUT.WEIGHTS
%    (string) a .mat file with 
%
% OPT
%   (structure) with the following fields : 
%   NB_CLUSTER
%      (integer, default ...)
%
%   FLAG_TEST
%      (boolean, default false) If FLAG_TEST is true, the pipeline will
%      just produce a pipeline structure, and will not actually process
%      the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%      data.
%
%   FLAG_VERBOSE
%      (boolean, default true) Print some advancement infos.
%
% _________________________________________________________________________
% Copyright (c) Pierre Orban, Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2015
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : cluster analysis, fMRI

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
if ~exist('in','var') || ~exist('out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtypes'' for more info.')
end

% FILES_IN
in = psom_struct_defaults(in, ...
           { 'stab_maps' , 'mask' }, ...
           { NaN         , NaN    });

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
      { 'type_center' , 'nb_iter' , 'folder_out' , 'thresh' , 'rand_seed' , 'nb_samps' , 'sampling' , 'ext'             , 'flag_focus' , 'flag_target' , 'flag_deal' , 'flag_verbose' , 'flag_test' } , ...
      { 'median'      , 1         , ''           , 0.5      , []          , 100        , struct()   , 'gb_niak_omitted' , false        , false         , false       , true           , false       });
opt.sampling = psom_struct_defaults(opt.sampling, ...
      { 'type' , 'opt'    }, ...
      { 'CBB'  , struct() });
  
% FILES_OUT
out = psom_struct_defaults(out, ...
           { 'maps' , 'maps_demeaned' , 'weights' }, ...
           { NaN    , NaN             , NaN       });

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end


for ind_net = 1:length(list_net)
    num_net = list_net(ind_net);
    path_res = [path_data 'cluster_' num2str(num_net) 'R_diff' filesep];

    %% Load data
    file_stack = [path_data,'netstack_net',num2str(num_net),'.nii.gz'];

    [hdr,stab] = niak_read_vol(file_stack);
    [hdr,mask] = niak_read_vol([path_data 'mask.nii.gz']);
    tseries = niak_vol2tseries(stab,mask);

    %% correct for the mean
    tseries_ga = niak_normalize_tseries(tseries,'mean');
    
    %% Run an ica on the demeaned maps
    opt_sica.type_nb_comp = 0;
    opt_sica.param_nb_comp = opt.nb_clust;
    res_ica = niak_sica( tseries_ga , opt_sica);
    vol_sica = niak_tseries2vol(res_ica.composantes',mask);
    weights = res_ica.poids;
end