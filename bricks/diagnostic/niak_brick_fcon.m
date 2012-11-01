function [files_in,files_out,opt] = niak_brick_fcon(files_in,files_out,opt)
% Generate the outcome mesures based on the connectome at the defined scale
%
% [R_IND] = NIAK_BRICK_OUTCOME(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN       
%   (3D+t array) the fMRI data. 
%
% FILES_OUT      
%   (3D volume) mask or ROI coded with integers. ROI #I is defined by 
%   MASK==I
%
%   P2P      
%       (3D volume) mask or ROI coded with integers. ROI #I is defined by 
%       MASK==I
%
%   SEEDCON      
%       (3D volume) mask or ROI coded with integers. ROI #I is defined by 
%       MASK==I
%
%   CONNECTOME      
%       (3D volume) mask or ROI coded with integers. ROI #I is defined by 
%       MASK==I
%
% FILES_OUT       
%   (optional) the order of eahc index of the connectome index
%
% _________________________________________________________________________
% OUTPUTS:
%
% R_IND   
%   (array) The connectome of the 3D+t dataset
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal,
% 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : connectome, fMRI

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flag_gb_niak_fast_gb = true;
niak_gb_vars

%% SYNTAX
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak_brick_fcon, SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FCON(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_fcon'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields    = {'ref_param' , 'subj_fmri' };
gb_list_defaults  = {NaN         , NaN         };
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields    = {'p2p'              , 'seedcon'         , 'seedconp2p'      , 'connectome'      , 'csv'             , 'dm_map'};
gb_list_defaults  = {'gb_niak_omitted'  , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure   = 'opt';
gb_list_fields      = { 'arg_nu_correct' , 'flag_invert_transf_init' , 'flag_test'    , 'folder_out'   , 'flag_verbose' };
gb_list_defaults    = { '-distance 200'  , false                     , false          , ''             , true           };
niak_set_defaults

%% Building default output names

%% to do ...

if flag_test == true
    return
end

%%%%%%%%%%%%%%%
%% Read data %%
%%%%%%%%%%%%%%%
glob_param = load(files_in.ref_param);
[h,vol_sub] = niak_read_vol(files_in.subj_fmri);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Individual connectome computation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R_ind = niak_gen_connectome(vol_sub,glob_param.brain_partition);

tab_csv = zeros(size(glob_param.p2p.seed,2),4);
%%%%%%%%%%%%%%%%%%%%%
%% p2p connections %%
%%%%%%%%%%%%%%%%%%%%%
for i=1:size(glob_param.p2p.seed,2)
    [score_ref(i,:),score_ind(i)] = niak_diff_connections(glob_param, R_ind, glob_param.p2p.seed{i}, opt);

end

opt_csv.labels_x = glob_param.p2p.name;
% boxplot 
f_handle = figure;
boxplot([score_ref]','labels',glob_param.p2p.name)
title(cat(2,'Similarity index'))
ylabel('R_r_e_f-R_i_n_d')
hold on
plot(score_ind,'r*')
hold off
print(f_handle,files_out.p2p,'-dpdf');
%close(f_handle);

tab_csv(:,1) = score_ind;

%%%%%%%%%%%%%%%%%%%%%%
%% Seed connections %%
%%%%%%%%%%%%%%%%%%%%%%
[score_ref,score_ind] = niak_diff_connections(glob_param, R_ind, glob_param.connections.seed{1}, opt);

% boxplot 
f_handle = figure;
boxplot([score_ref]','labels',glob_param.connections.name{1})
title(cat(2,'Similarity index'))
ylabel('R_r_e_f-R_i_n_d')
hold on
plot(score_ind,'r*')
hold off
print(f_handle,files_out.seedcon,'-dpdf');
%close(f_handle);

%% save the volume of the seed map
values_corr = R_ind(:,glob_param.connections.seed{1});
connect_map = zeros(size(glob_param.brain_partition));

for i=1:size(values_corr,1)
    connect_map = connect_map + (glob_param.brain_partition == i).*values_corr(i);
end

h.file_name = files_out.dm_map;
niak_write_vol(h,connect_map);
tab_csv(1,2) = score_ind;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seed connections for all P2P %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
param = [];
for i=1:size(glob_param.p2p.seed,2)
    param = [param ; glob_param.p2p.seed{i}];
end

[score_ref,score_ind] = niak_diff_connections(glob_param, R_ind, unique(param(:)), opt);

% boxplot 
f_handle = figure;
boxplot([score_ref]','labels','Seed all P2P')
title(cat(2,'Similarity index'))
ylabel('R_r_e_f-R_i_n_d')
hold on
plot(score_ind,'r*')
hold off
print(f_handle,files_out.seedconp2p,'-dpdf');
%close(f_handle);

tab_csv(1,3) = score_ind;

%%%%%%%%%%%%%%%%%
%% Connectomes %%
%%%%%%%%%%%%%%%%%
[score_ref,score_ind] = niak_diff_connections(glob_param, R_ind, [1:size(R_ind,1)]', opt);

% boxplot 
f_handle = figure;
boxplot([score_ref]','labels','Connectome')
title(cat(2,'Similarity index'))
ylabel('R_r_e_f-R_i_n_d')
hold on
plot(score_ind,'r*')
hold off
print(f_handle,files_out.connectome,'-dpdf');
%close(f_handle);

tab_csv(1,4) = score_ind;

%%%%%%%%%%%%%%%
%% Write CSV %%
%%%%%%%%%%%%%%%
opt_csv.labels_y = {'P2P','DM','Seed all P2P','Connectome'}
niak_write_csv(files_out.csv,tab_csv,opt_csv)



