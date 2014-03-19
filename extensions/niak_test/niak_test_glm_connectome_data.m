function [in,out,opt] = niak_test_glm_connectome_data(in,out,opt)
% Generate the data for the tests of NIAK_TEST_GLM_CONNECTOME
%
% SYNTAX: 
%   [] = NIAK_TEST_GLM_CONNECTOME(IN,OUT,OPT)
%
% INPUTS:
%   IN (structure) not used
%   OUT (structure), with the following fields (all have defaults if empty or unspecified):
%      FMRI_RUN     (cell of strings) simulated fMRI runs 
%      GROUP        (string) a .csv file with group-level covariates
%      NETWORKS     (cell of strings) simulated networks
%      PARAM        (string) a .mat file with all the parameters of the simulation.
%      GROUND_TRUTH (structure) a .mat file with the expected results 
%   OPT (structure) with the following fields:
%      FOLDER_OUT   (string) where to generate the defaults
%      RAND_SEED    (integer, default 0) the seed of the random number 
%                   generator. If left empty, nothing is done.
%      FLAG_TEST    (boolean, default false) if true, the brick only updates
%                   the structures IN, OUT, OPT.
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
list_fields   = { 'ground_truth' , 'fmri_run' , 'group' , 'networks' , 'param' };
list_default  = { ''             , ''         , ''      , ''         , ''      };
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
    out.fmri_run{1} = [folder_out 'fmri_subject1.mnc.gz'];
    out.fmri_run{2} = [folder_out 'fmri_subject2.mnc.gz'];
    out.fmri_run{3} = [folder_out 'fmri_subject3.mnc.gz'];
    out.fmri_run{4} = [folder_out 'fmri_subject4.mnc.gz'];
end    

if isempty(out.networks)
    out.networks{1} = [folder_out 'network_4.mnc.gz'];
    out.networks{2} = [folder_out 'network_16.mnc.gz'];
end

if isempty(out.group)
    out.group = [folder_out 'group.csv'];
end

if isempty(out.param)
    out.param = [folder_out 'param_simu.mat'];
end

if isempty(out.ground_truth)
    list_test = {'avg_corr_all','avg_corr_young','corr_vs_age'};
    list_network = {'network4','network16'};
    for tt = 1:length(list_test)
        test = list_test{tt};
        for nn = 1:length(list_network)
            network = list_network{nn};
            out.ground_truth.(test).(network) = [folder_out 'ground_truth' filesep network filesep test filesep 'glm_' test '_' network '.mat'];
        end
    end
end

if opt.flag_test
    return
end

%% The brick starts here
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Generate two partitions (one with 16 networks, the other with 4 networks)
fprintf('Generate partitions ...\n')
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
%% Generate two runs with the same parameters
fprintf('Generate 3D+t fMRI runs ...\n')
[nx,ny,nz] = size(part16);
nt = 100;
tseries1 = niak_normalize_tseries(randn([nt 16]));
tseries2 = niak_normalize_tseries(randn([nt 4]));

ind = find(true(nx,ny,nz));
mask_v = zeros(size(part16));
mask_v(ind) = 1:length(ind);
tseries.run1 = zeros(nt,nx*ny*nz);
tseries.run1(:,ind) = sqrt(0.4)*tseries1(:,part16(ind)) + sqrt(0.4)*tseries2(:,part4(ind)) + sqrt(0.2)*niak_normalize_tseries(randn(size(tseries.run1)));
vol = niak_part2vol(tseries.run1,mask_v);

hdr.info.tr = 2.5;
hdr.file_name = out.fmri_run{1};
niak_write_vol(hdr,vol);

tseries.run2 = zeros(nt,nx*ny*nz);
tseries.run2(:,ind) = sqrt(0.4)*tseries1(:,part16(ind)) + sqrt(0.4)*tseries2(:,part4(ind)) + sqrt(0.2)*niak_normalize_tseries(randn(size(tseries.run2)));
vol = niak_part2vol(tseries.run2,mask_v);

hdr.file_name = out.fmri_run{2};
niak_write_vol(hdr,vol);

% Check it worked ...
%  r = niak_mat2vec(corr(tseries.run2));
%  adj16 = niak_mat2vec(niak_part2mat(part16,1))>0;
%  adj4 = niak_mat2vec(niak_part2mat(part4,1))>0;
%  mean(r(adj16))
%  mean(r(adj4&~adj16))
%  mean(r(~adj4))

%% Generate dynamics in the two-level partition, with a correlation of 0.3 locally within small network, and 0.5 locally in the large network
%% Generate two runs with the same parameters
[nx,ny,nz] = size(part16);
nt = 100;
tseries1 = niak_normalize_tseries(randn([nt 16]));
tseries2 = niak_normalize_tseries(randn([nt 4]));

ind = find(true(nx,ny,nz));
mask_v = zeros(size(part16));
mask_v(ind) = 1:length(ind);
tseries.run3 = zeros(nt,nx*ny*nz);
tseries.run3(:,ind) = sqrt(0.3)*tseries1(:,part16(ind)) + sqrt(0.2)*tseries2(:,part4(ind)) + sqrt(0.5)*niak_normalize_tseries(randn(size(tseries.run3)));
vol = niak_part2vol(tseries.run3,mask_v);

hdr.info.tr = 2.5;
hdr.file_name = out.fmri_run{3};
niak_write_vol(hdr,vol);

tseries.run4 = zeros(nt,nx*ny*nz);
tseries.run4(:,ind) = sqrt(0.3)*tseries1(:,part16(ind)) + sqrt(0.2)*tseries2(:,part4(ind)) + sqrt(0.5)*niak_normalize_tseries(randn(size(tseries.run4)));
vol = niak_part2vol(tseries.run4,mask_v);
hdr.file_name = out.fmri_run{4};
niak_write_vol(hdr,vol);

% Check it worked ...
%  r = niak_mat2vec(corr(tseries_run2));
%  adj16 = niak_mat2vec(niak_part2mat(part16,1))>0;
%  adj4 = niak_mat2vec(niak_part2mat(part4,1))>0;
%  mean(r(adj16))
%  mean(r(adj4&~adj16))
%  mean(r(~adj4))

%% write a .csv file for the group-level model
fprintf('Generate a group-level model ...\n')
opt_c.labels_x = {'subject1','subject2','subject3','subject4'};
opt_c.labels_y = {'age','group'};
tab = [ 23 1 ; ...
        29 1 ; ...
        64 2 ; ...
        73 2 ];
niak_write_csv(out.group,tab,opt_c);

%% Average correlation for all
fprintf('Generate results for the "avg_corr_all" contrast ...\n')
y = sub_all_corr(tseries,part4,1:4);
res.eff = mean(y,1);
save(out.ground_truth.avg_corr_all.network4,'-struct','res')
y = sub_all_corr(tseries,part16,1:4);
res.eff = mean(y,1);
save(out.ground_truth.avg_corr_all.network16,'-struct','res')

%% Average correlation for youngs
fprintf('Generate results for the "avg_corr_young" contrast ...\n')
y = sub_all_corr(tseries,part4,1:2);
res.eff = mean(y,1);
save(out.ground_truth.avg_corr_young.network4,'-struct','res')
y = sub_all_corr(tseries,part16,1:2);
res.eff = mean(y,1);
save(out.ground_truth.avg_corr_young.network16,'-struct','res')

%% Covariance with age for all 
fprintf('Generate results for the "corr_vs_age" contrast ...\n')
y = sub_all_corr(tseries,part4,1:4);
res.eff = niak_lse(y,[ones(size(tab,1),1) (tab(:,1)-mean(tab(:,1)))]);
res.eff = res.eff(2,:);
save(out.ground_truth.corr_vs_age.network4,'-struct','res')
y = sub_all_corr(tseries,part16,1:4);
res.eff = niak_lse(y,[ones(size(tab,1),1) (tab(:,1)-mean(tab(:,1)))]);
res.eff = res.eff(2,:);
save(out.ground_truth.corr_vs_age.network16,'-struct','res')

%% Save the true correlation matrices in a .mat file 

%% Save simulation parameters
save(out.param)

function y = sub_all_corr(tseries,part,list_run)
ee = 1;
for rr = list_run
    run = sprintf('run%i',rr);
    if rr == list_run(1)
        y = zeros(length(list_run),length(sub_correlation(tseries.(run),part)));
    end
    y(ee,:) = sub_correlation(tseries.(run),part);
    ee = ee+1;
end

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