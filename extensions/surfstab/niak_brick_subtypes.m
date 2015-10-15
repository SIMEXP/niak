function [in,out,opt] = niak_brick_subtypes(in,out,opt)
% Identify population subtypes based on individual brain maps
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPES(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN.(SUBJECT).(SESSION).(RUN)
%   (string) a .mat file with the following variables:
%   NETWORK_NN (vector) with NN=1,...,N. The (vectorized) map 
%      for network NN. All subject need to have an identical number of networks. 
%   MASK (3D array) the binary mask of the brain used for vectorization. 
%   HDR (structure) the header of the mask (see NIAK_READ_VOL). 
% 
% FILES_OUT.SUBTYPES_AVERAGE
%    (cell of strings) the NN entry corresponds to the NETWORK_NN input. 
%    The name of a nii/mnc file which contains the average map for 
%    each subtype, coded along the fourth dimension. 
%    Warning: the extension of the file need to correspond to the HDR variable above.
% FILES_OUT.SUBTYPES_STD
%    (cell of strings) the NN entry corresponds to the NETWORK_NN input. 
%    The name of a nii/mnc file which contains the std map for 
%    each subtype, coded along the fourth dimension. 
%    Warning: the extension of the file need to correspond to the HDR variable above.
% FILES_OUT.SUBTYPES_DEMEANED
%    (cell of strings) same as FILES_OUT.SUBTYPES, except that each map 
%    is the difference between the subtype average, and the grand average.
% FILES_OUT.GRAND_AVERAGE
%    (string) same as SUBTYPES_AVERAGE, but the average over the full population, rather 
%    than just a subtype. 
% FILES_OUT.GRAND_STD
%    (string) same as SUBTYPES_STD, but the average over the full population, rather than
%    just a subtype. 
% FILES_OUT.WEIGHTS
%    (string) a .mat file with the following variables:
%    WEIGHTS (array) WEIGHTS(NN,SS,II) is the similarity of network NN for subject SS 
%       with subtype II.
%    SIM (array) SIM(:,:,NN) is the inter-subject similarity matrix, for network NN.
%    HIER (array) HIER(:,:,NN) is the hierarchy between subjects, for network NN.
%    PART (array) PART(:,NN) is the partition of the subjects into subtypes, 
%       for network NN. 
%
% OPT
%   (structure) with the following fields : 
%   NB_CLUSTER
%      (integer, default 5) the number of subtypes. 
%   LABELS_NETWORK
%      (cell of strings, default {'NETWORK1',...}) LABELS_NETWORK{NN} is the label 
%      of network NN (these labels will be used to name the outputs).
%   FOLDER_OUT
%      (string, default pwd) where to save the results by default.
%   FLAG_TEST 
%      (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%      do anything but update the default values in FILES_IN, 
%      FILES_OUT and OPT.s
%   FLAG_VERBOSE
%      (boolean, default true) Print some progress info.
%
% COMMENT:
% 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de geriatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2015
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
if ~istruct(in)
    error('FILES_IN should be a structure')
end
[list_maps,labels] = niak_fmri2cell(in);

% FILES_OUT
opt = psom_struct_defaults(out, ...
      { 'subtypes_average' , 'subtypes_demeaned' , 'subtypes_std' , 'subtypes_std' , 'grand_average' , 'grand_std' , 'weights' , 'flag_verbose' , 'flag_test' } , ...
      { 'gb_niak_omitted'  , 1         , ''           , 0.5      , []          , 100        , struct()   , 'gb_niak_omitted' , false        , false         , false       , true           , false       });

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
           { 'list_net' , 'maps' , 'maps_demeaned' , 'weights' }, ...
           { []         , NaN    , NaN             , NaN       });

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% reorganize inputs
[files,labels] = niak_fmri2cell(in.fmri);
list_subject = unique({labels.subject});

%% If list_net is empty check the number of networks and iterate on all of them
hdr = niak_read_vol({1});
if isempty(opt.list_net)    
    opt.list_net = 1:hdr.info.dimensions(4);
end
vol = zeros([hdr.dimensions(1:3) length(list_subject)]);

for ind_net = 1:length(opt.list_net)
    num_net = opt.list_net(ind_net);
    path_res = [path_data 'cluster_' num2str(num_net) 'R_diff' filesep];

    %% Load maps
    for ss = 1:length(list_subject)
        subject = list_subject{ss};
        list_ind = find(ismember({labels.subject},subject));
        for ii = 1:length(list_ind)
            [hdr,vol_ii] = niak_read_vol(files{ii});
            vol(:,:,:,ss) = vol(:,:,:,ss)+vol_ii(:,:,:,num_net);
        end
        vol(:,:,:,ss) = vol(:,:,:,ss)/length(list_ind);
    end
    
    [hdr,mask] = niak_read_vol([path_data 'mask.nii.gz']);
    tseries = niak_vol2tseries(vol,mask);

    %% correct for the mean
    tseries_ga = niak_normalize_tseries(tseries,'mean');
    
    %% Run an ica on the demeaned maps
    opt_sica.type_nb_comp = 0;
    opt_sica.param_nb_comp = opt.nb_clust;
    res_ica = niak_sica( tseries_ga , opt_sica);
    vol_sica = niak_tseries2vol(res_ica.composantes',mask);
    weights = res_ica.poids;
end