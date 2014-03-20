function [stab,tseries,opt] = niak_demo_glm_connectome_run(opt)
% This is a script to demonstrate how to estimate a statistical parametric
% connectome based on a fMRI run. 
%
% The code is organized by blocks which can be copy/pasted and executed in 
% a Matlab or Octave session.
%
% _________________________________________________________________________
% COMMENTS:
%
% Warning: this script will clear the workspace.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : linear model

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

clear

%% A toy model of time series
model_tseries.tseries = randn([100 1000]); % Some time series, with a 100 time frames and 1000 regions
model_tseries.time_frames = 2*([0:9 20:109]); % The time associated with each frame in TSERIES. Here a missing windows of 10 frames was introduced, with a TR of 2 seconds
model_tseries.mask_suppressed = [false(1,10) true(1,10) false(1,90)]; % MASK_SUPPRESSED indicates which time frames were suppressed from the original time series
model_tseries.confounds = randn([100 10]); % a bunch of confounds, usually come from the preprocessing (slow time drifts, motion parameters, etc)
model_tseries.labels_confounds = repmat({'confounds'},[1 10]);
model_tseries.covariate.x = randn([110 2]); % Some manually specified covariates for the linear model. Note that this covariate has to include the same number of time frames as the original fMRI time series (here 110). 
model_tseries.covariate.labels_y = { 'cov1' , 'cov2' }; 
model_tseries.event.x = [10 3 1 ; 40 3 2 ; 70 5 1 ; 100 3 2]; % Some time for events
model_tseries.event.labels_x = { 'fixation' , 'visual' , 'fixation' , 'visual'}; % The labels associated to each event. Events of the same type are merged to generate one covariate

%% A simple correlation coefficient
clear opt
opt.type = 'correlation';
opt.flag_fisher = false;
spc = niak_glm_connectome_run(model_tseries,opt);

%% Correlation coefficient after regressing out the effect of the visual activation
clear opt
opt.type = 'correlation';
opt.projection = {'visual'};
opt.flag_fisher = false;
spc = niak_glm_connectome_run(model_tseries,opt);

%% correlation coefficient outside of the visual activation
clear opt
opt.type = 'correlation';
opt.flag_fisher = false;
opt.select.label = 'visual';
opt.select.max = 0.01;
opt.select.min = -0.01;
spc = niak_glm_connectome_run(model_tseries,opt);

%% Difference in correlation coefficients outside minus inside of the visual activation
clear opt
opt.type = 'correlation';
opt.flag_fisher = false;
opt.select(1).label = 'visual';
opt.select(1).max = 0.01;
opt.select(1).min = -0.01;
opt.select(2).label = 'visual';
opt.select(2).min = 0.01;
spc = niak_glm_connectome_run(model_tseries,opt);

%% An interaction term to test changes in activity with visual activity
clear opt
opt.type = 'glm';
opt.interaction.label = 'visual_x_seed';
opt.interaction.factor{1} = 'visual';
opt.interaction.factor{2} = 'seed';
opt.normalize_y = true;
opt.normalize_x = true;
opt.contrast.visual = 0;
opt.contrast.seed = 0;
opt.contrast.visual_x_seed = 1;
spc = niak_glm_connectome_run(model_tseries,opt);