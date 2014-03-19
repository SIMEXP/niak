function [in,out,opt] = niak_test_connectome_multiscale_data(in,out,opt)
% Generate the data for the tests of NIAK_TEST_CONNECTOME_MULTISCALE
%
% SYNTAX: 
%   [] = NIAK_TEST_CONNECTOME_MULTISCALE(IN,OUT,OPT)
%
% INPUTS:
%   IN  (structure) not used
%   OUT (structure), with the following fields (all have defaults if empty or unspecified):
%      FMRI_RUN      (cell of strings) simulated fMRI runs 
%      INTER_RUN     (string) a .csv file with inter-run covariates
%      INTRA_RUN_COV (cell of strings) .csv files with intra-run covariates
%      INTRA_RUN_EV  (cell of strings) .csv files with intra-run events
%      NETWORKS      (cell of strings) simulated networks
%      PARAM         (string) a .mat file with all the parameters of the simulation.
%      GROUND_TRUTH  (cell of strings) a .mat file with the expected results 
%   OPT (structure) with the following fields:
%      FOLDER_OUT    (string) where to generate the defaults
%      RAND_SEED     (integer, default 0) the seed of the random number 
%                    generator. If left empty, nothing is done.
%      FLAG_TEST     (boolean, default false) if true, the brick only updates
%                    the structures IN, OUT, OPT.
%
% OUTPUTS:
%   IN, OUT, OPT are updated. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, connectome

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

%% Set defaults

% output files
if nargin < 2
    out = struct();
end
list_fields   = { 'ground_truth' , 'fmri_run' , 'inter_run' , 'intra_run_cov' , 'intra_run_ev' , 'networks' , 'param' };
list_default  = { ''             , ''         , ''          , ''              , ''             , ''         , ''      };
out = psom_struct_defaults(out,list_fields,list_default);

% Options
if nargin < 2
    opt = struct();
end
list_fields   = { 'folder_out' , 'flag_test' , 'rand_seed' };
list_default  = { NaN          , false       , 0           };
opt = psom_struct_defaults(opt,list_fields,list_default);

folder_out = niak_full_path(opt.folder_out);

% generate default output files
if isempty(out.fmri_run)
    out.fmri_run{1} = [folder_out 'fmri_run1.mnc.gz'];
    out.fmri_run{2} = [folder_out 'fmri_run2.mnc.gz'];
end    

if isempty(out.networks)
    out.networks{1} = [folder_out 'network_4.mnc.gz'];
    out.networks{2} = [folder_out 'network_16.mnc.gz'];
end

if isempty(out.inter_run)
    out.inter_run = [folder_out 'inter_run.csv'];
end

if isempty(out.intra_run_cov)
    out.intra_run_cov{1} = [folder_out 'intra_run1_covariate.csv'];
    out.intra_run_cov{2} = [folder_out 'intra_run2_covariate.csv'];
end

if isempty(out.intra_run_ev)
    out.intra_run_ev{1} = [folder_out 'intra_run1_event.csv'];
    out.intra_run_ev{2} = [folder_out 'intra_run2_event.csv'];
end

if isempty(out.param)
    out.param = [folder_out 'param_simu.mat'];
end

if isempty(out.ground_truth)
    out.ground_truth{1} = [folder_out 'test_correlation_network4.mat'];
    out.ground_truth{2} = [folder_out 'test_correlation_network16.mat'];
end

if opt.flag_test
    return
end

%% The brick starts here
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Generate two partitions (one with 16 networks, the other with 4 networks)
part16 = zeros([16 16 2]);
ll = 1;
for xx = 1:4
    for yy = 1:4
        part16((1+(xx-1)*4):(xx*4),(1+(yy-1)*4):(yy*4),1,1) = ll;
        ll = ll+1;
    end
end
part16(:,:,2) = part16(:,:,1);

part4 = zeros([16 16 2]);
ll = 1;
for xx = 1:2
    for yy = 1:2
        part4((1+(xx-1)*8):(xx*8),(1+(yy-1)*8):(yy*8),1) = ll;
        ll = ll+1;
    end
end
part4(:,:,2) = part4(:,:,1);

hdr.type = 'minc1';
hdr.info.voxel_size = [3 3 3];
hdr.info.mat = niak_hdr_minc2mat(eye(3),[3 3 3]',[0 0 0]');
hdr.file_name = out.networks{2};
niak_write_vol(hdr,part16);

hdr.file_name = out.networks{1};
niak_write_vol(hdr,part4);

%% Generate dynamics in the two-level partition, with a correlation of 0.8 locally within small network, and 0.4 locally in the large network
[nx,ny,nz] = size(part16);
nt = 100;
tseries1 = niak_normalize_tseries(randn([nt 16]));
tseries2 = niak_normalize_tseries(randn([nt 4]));

ind = find(true(nx,ny,nz));
mask_v = zeros(size(part16));
mask_v(ind) = 1:length(ind);
tseries_run1 = zeros(nt,nx*ny*nz);
tseries_run1(:,ind) = sqrt(0.4)*tseries1(:,part16(ind)) + sqrt(0.4)*tseries2(:,part4(ind)) + sqrt(0.2)*niak_normalize_tseries(randn(size(tseries_run1)));
vol = niak_part2vol(tseries_run1,mask_v);

hdr.info.tr = 2.5;
hdr.file_name = out.fmri_run{1};
niak_write_vol(hdr,vol);

% Check it worked ...
%  r = niak_mat2vec(corr(tseries_run1));
%  adj16 = niak_mat2vec(niak_part2mat(part16,1))>0;
%  adj4 = niak_mat2vec(niak_part2mat(part4,1))>0;
%  mean(r(adj16))
%  mean(r(adj4&~adj16))
%  mean(r(~adj4))

%% Generate dynamics in the two-level partition, with a correlation of 0.3 locally within small network, and 0.5 locally in the large network
[nx,ny,nz] = size(part16);
nt = 100;
tseries1 = niak_normalize_tseries(randn([nt 16]));
tseries2 = niak_normalize_tseries(randn([nt 4]));

ind = find(true(nx,ny,nz));
mask_v = zeros(size(part16));
mask_v(ind) = 1:length(ind);
tseries_run2 = zeros(nt,nx*ny*nz);
tseries_run2(:,ind) = sqrt(0.3)*tseries1(:,part16(ind)) + sqrt(0.2)*tseries2(:,part4(ind)) + sqrt(0.5)*niak_normalize_tseries(randn(size(tseries_run2)));
vol = niak_part2vol(tseries_run2,mask_v);

hdr.info.tr = 2.5;
hdr.file_name = out.fmri_run{2};
niak_write_vol(hdr,vol);

% Check it worked ...
%  r = niak_mat2vec(corr(tseries_run2));
%  adj16 = niak_mat2vec(niak_part2mat(part16,1))>0;
%  adj4 = niak_mat2vec(niak_part2mat(part4,1))>0;
%  mean(r(adj16))
%  mean(r(adj4&~adj16))
%  mean(r(~adj4))

%% write a .csv file for the inter-run model
opt_c.labels_x = {'session1_run1','session1_run2'};
opt_c.labels_y = {'run1' 'run'};
tab = [ 1 1 ; ...
        0 2 ];
niak_write_csv(out.inter_run,tab,opt_c);

%% Write a .csv file for the intra-run model: run 1
opt_c.labels_y = {'motion_tx','motion_ty','motion_tz','motion_rx','motion_ry','motion_rz'};
opt_c.labels_x = {};
cov_run1 = randn([100 6]);
niak_write_csv(out.intra_run_cov{1},cov_run1,opt_c);

%% Write an event file for the intra-run model: run 1
ev_run1.labels_y = {'times','duration','amplitude'};
ev_run1.labels_x = {'motor','motor','motor','visual','visual','visual'};
ev_run1.x = [0 30 1 ; 60 30 1; 120 30 1; 180 10 1; 200 10 1; 220 10 1];
niak_write_csv(out.intra_run_ev{1},ev_run1.x,rmfield(ev_run1,'x'));

%% Write a .csv file for the intra-run model: run 2
opt_c.labels_y = {'motion_tx','motion_ty','motion_tz','motion_rx','motion_ry','motion_rz'};
opt_c.labels_x = {};
cov_run2 = randn([100 6]);
niak_write_csv(out.intra_run_cov{2},cov_run2,opt_c);

%% Write an event file for the intra-run model: run 2
ev_run2.labels_y = {'times','duration','amplitude'};
ev_run2.labels_x = {'motor','visual','motor','motor'};
ev_run2.x = [0 30 1 ; 60 10 1; 80 30 1; 160 30 1];
niak_write_csv(out.intra_run_ev{2},ev_run2.x,rmfield(ev_run2,'x'));

%% Generate convolved versions of the events
ev_run1_c = sub_convolve(ev_run1,(0:99)'*hdr.info.tr);
ev_run2_c = sub_convolve(ev_run2,(0:99)'*hdr.info.tr);

%% simple correlation, for run1
res_network4.run1.connectome  = sub_correlation(tseries_run1,part4);
res_network16.run1.connectome = sub_correlation(tseries_run1,part16);

%% simple correlation, for run2
res_network4.run2.connectome  = sub_correlation(tseries_run2,part4);
res_network16.run2.connectome = sub_correlation(tseries_run2,part16);

%% simple correlation, run1 minus run2
res_network4.run1_minus_run2.connectome  = res_network4.run1.connectome - res_network4.run2.connectome;
res_network16.run1_minus_run2.connectome = res_network16.run1.connectome - res_network16.run2.connectome;

%% simple correlation, for run1, regressing out the covariates
opt_n.type = 'mean';
x = [ones(size(tseries_run1,1),1) niak_normalize_tseries(cov_run1,opt_n)];
[beta,E] = niak_lse(tseries_run1,x);
res_network4.run1_motion.connectome  = sub_correlation(E,part4);
res_network16.run1_motion.connectome = sub_correlation(E,part16);

%% simple correlation, for run1, regressing out the events
opt_n.type = 'mean';
x = [ones(size(tseries_run1,1),1) niak_normalize_tseries(ev_run1_c.x,opt_n)];
[beta,E] = niak_lse(tseries_run1,x);
res_network4.run1_motor_visual.connectome  = sub_correlation(E,part4);
res_network16.run1_motor_visual.connectome = sub_correlation(E,part16);

%% correlation, for run1, regressing out covariates,
%% and selecting only the motor events
opt_n.type = 'mean';
mask_time = ev_run1_c.x(:,strcmp(ev_run1_c.labels_y,'motor'))>=0.95;
x = [ones(size(tseries_run1(mask_time,:),1),1) niak_normalize_tseries(cov_run1(mask_time,:),opt_n)];
[beta,E] = niak_lse(tseries_run1(mask_time,:),x);
res_network4.run1_motion_sel_motor.connectome  = sub_correlation(E,part4);
res_network16.run1_motion_sel_motor.connectome = sub_correlation(E,part16);

% difference of correlation between run1 and run2, selecting the motor volumes. 
opt_n.type = 'mean';
mask1 = ev_run1_c.x(:,strcmp(ev_run1_c.labels_y,'motor'))>=0.95;
mask2 = ev_run2_c.x(:,strcmp(ev_run2_c.labels_y,'motor'))>=0.95;
res_network4.run1_minus_run2_sel_motor.connectome  = sub_correlation(tseries_run1(mask1,:),part4) - sub_correlation(tseries_run2(mask2,:),part4);
res_network16.run1_minus_run2_sel_motor.connectome = sub_correlation(tseries_run1(mask1,:),part16) - sub_correlation(tseries_run2(mask2,:),part16);

% difference of correlation between run1 and run2, selecting the visual volumes. 
% there are not enough volumes in run2, so a NaN is produced
res_network4.run1_minus_run2_sel_visual.connectome  = NaN;
res_network16.run1_minus_run2_sel_visual.connectome = NaN;

%% Save the true correlation matrices in a .mat file 
save(out.ground_truth{1},'-struct','res_network4')
save(out.ground_truth{2},'-struct','res_network16')
save(out.param)

function rmat = sub_correlation(tseries,part)
nb_roi = max(part(:));
rmat = zeros(nb_roi,nb_roi);
for xx = 1:nb_roi
    for yy = 1:xx
        if xx == yy
            rtmp = corr(tseries(:,part==xx));
            rmat(xx,xx) = mean(niak_mat2vec(rtmp));
        else
            tseries_x = mean(niak_normalize_tseries(tseries(:,part==xx)),2);
            tseries_y = mean(niak_normalize_tseries(tseries(:,part==yy)),2);
            rmat(xx,yy) = corr(tseries_x,tseries_y);
            rmat(yy,xx) = rmat(xx,yy);
        end        
    end
end
rmat = niak_mat2lvec(niak_fisher(rmat))';

function event_c = sub_convolve(event,time_frames)
[list_event,tmp,all_event]  = unique(event.labels_x); 
opt_m.events = [all_event(:) event.x];
opt_m.frame_times = time_frames;
x_cache =  niak_fmridesign(opt_m); 
event_c.x = x_cache.x(:,:,1,1);
event_c.labels_y = list_event(:);