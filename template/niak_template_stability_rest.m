% template for the basc pipeline (bootstrap analysis of stable clusters)
%
% to run this pipeline, the fmri datasets first need to be preprocessed
% using the niak fmri preprocessing pipeline.
%
% warning: this script will clear the workspace
%
% copyright (c) pierre bellec,
%   montreal neurological institute, 2008-2010.
%   research centre of the montreal geriatric institute
%   & department of computer science and operations research
%   university of montreal, québec, canada, 2010-2012
% maintainer : pierre.bellec@criugm.qc.ca
% see licensing information in the code.
% keywords : fmri, resting-state, clustering, basc

% permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "software"), to deal
% in the software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the software, and to permit persons to whom the software is
% furnished to do so, subject to the following conditions:
%
% the above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the software.
%
% the software is provided "as is", without warranty of any kind, express or
% implied, including but not limited to the warranties of merchantability,
% fitness for a particular purpose and noninfringement. in no event shall the
% authors or copyright holders be liable for any claim, damages or other
% liability, whether in an action of contract, tort or otherwise, arising from,
% out of or in connection with the software or the use or other dealings in
% the software.

clear

%%%%%%%%%%%%%%%%%%%%%
%% grabbing the results from the niak fmri preprocessing pipeline
%%%%%%%%%%%%%%%%%%%%%
opt_g.min_nb_vol = 100;     % the minimum number of volumes for an fmri dataset to be included. this option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % the minimum xcorr score for an fmri dataset to be included. this metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. manual inspection of the values during qc is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % the minimum xcorr score for an fmri dataset to be included. this metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. manual inspection of the values during qc is necessary to properly set this threshold.
opt_g.exclude_subject = {'subject1','subject2'}; % if for whatever reason some subjects have to be excluded that were not caught by the quality control metrics, it is possible to manually specify their ids here.
opt_g.type_files = 'rest'; % specify to the grabber to prepare the files for the stability_rest pipeline
files_in = niak_grab_fmri_preprocess('/home/toto/database/fmri_preprocess',opt_g); % replace the folder by the path where the results of the fmri preprocessing pipeline were stored.

%%%%%%%%%%%%%%%%%%%%%
%% !! alternative method
%% grab the results of the region growing pipeline.
%% if the region growing pipeline has already been executed on this database, it is possible to start right out from its outputs.
%% to use this alternative method, uncomment the following line and suppress the block of code above ("grabbing the results from the niak fmri preprocessing pipeline")
%%%%%%%%%%%%%%%%%%%%%

% files_in = niak_grab_region_growing('/home/toto/database/region_growing');

%%%%%%%%%%%%%%%%%%%%%
%% extra infos
%% these have to be organized in a comma-separated file (csv). example:
%%          , sex
%% subject1 , 0
%% subject2 , 1
%%
%% note that the first entry has to be left empty. the subject ids need to be identical to those used in the fmri preprocessing pipeline.
%% also, only numerical variables are supported (i.e. no 'm', 'w' to code for man and woman).
%% these variables will be used to split the subjects into strata, e.g. men vs women. in the group analysis, equal weight is given to all strata
%% (regardless of the number of subjects). resampling of subjects is also made within strata, but not between them. adding more covariates
%% will further stratify the group sample (e.g. two variables old/young men/women will translate into 4 strata).
%%
%% if you want to stratify the sample, uncomment the following line and indicate the csv file you want to use. otherwise, just leave it as is.
%% to check that the file is properly formatted prior to running the pipeline, run the following command in matlab/octave:
%% [tab,labx,laby] = niak_read_csv('/data/infos.csv');
%% the subject ids should load in labx, the covariate ids load in laby, and the value of the variables into a numerical array tab.
%%%%%%%%%%%%%%%%%%%%%

% files_in.infos = '/data/infos.csv'; % a file of comma-separeted values describing additional information on the subjects, this can be omitted

%%%%%%%%%%%%%
%% options %%
%%%%%%%%%%%%%

opt.folder_out = '/home/toto/database/basc/'; % where to store the results
opt.region_growing.thre_size = 1000; %  the size of the regions, when they stop growing. a threshold of 1000 mm3 will give about 1000 regions on the grey matter.
opt.grid_scales = [10:10:100 120:20:200 240:40:500]; % search for stable clusters in the range 10 to 500
opt.scales_maps = repmat(opt.grid_scales,[1 3]); % the scales that will be used to generate the maps of brain clusters and stability.
                                                 % in this example the same number of clusters are used at the individual (first column),
                                                 % group (second column) and consensus (third and last colum) levels.
opt.stability_tseries.nb_samps = 100; % number of bootstrap samples at the individual level. 100: the ci on indidividual stability is +/-0.1
opt.stability_group.nb_samps = 500; % number of bootstrap samples at the group level. 500: the ci on group stability is +/-0.05

opt.flag_ind = false;   % generate maps/time series at the individual level
opt.flag_mixed = false; % generate maps/time series at the mixed level (group-level networks mixed with individual stability matrices).
opt.flag_group = true;  % generate maps/time series at the group level

%%%%%%%%%%%%%%%%%%%%%%
%% run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false; % put this flag to true to just generate the pipeline without running it. otherwise the region growing will start.
%opt.psom.max_queued = 10; % uncomment and change this parameter to set the number of parallel threads used to run the pipeline
pipeline = niak_pipeline_stability_rest(files_in,opt); 