% Template for the BASC pipeline (bootstrap analysis of stable clusters)
%
% To run this pipeline, the fMRI datasets first need to be preprocessed 
% using the NIAK fMRI preprocessing pipeline.
%
% WARNING: This script will clear the workspace
%
% Copyright (c) Pierre Bellec, 
%   Montreal Neurological Institute, 2008-2010.
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Québec, Canada, 2010-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI, resting-state, clustering, BASC

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

%%%%%%%%%%%%%%%%%%%%%
%% Grabbing the results from the NIAK fMRI preprocessing pipeline
%%%%%%%%%%%%%%%%%%%%%
opt_g.min_nb_vol = 100;     % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
opt_g.min_xcorr_func = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.min_xcorr_anat = 0.5; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
opt_g.exclude_subject = {'subject1','subject2'}; % If for whatever reason some subjects have to be excluded that were not caught by the quality control metrics, it is possible to manually specify their IDs here.
opt_g.type_files = 'rest'; % Specify to the grabber to prepare the files for the STABILITY_REST pipeline
files_in = niak_grab_fmri_preprocess('/home/toto/database/fmri_preprocess',opt_g); % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

%%%%%%%%%%%%%%%%%%%%%
%% !! ALTERNATIVE METHOD
%% Grab the results of the region growing pipeline. 
%% If the region growing pipeline has already been executed on this database, it is possible to start right out from its outputs. 
%% To use this alternative method, uncomment the following line and suppress the block of code above ("Grabbing the results from the NIAK fMRI preprocessing pipeline")
%%%%%%%%%%%%%%%%%%%%%

% files_in = niak_grab_region_growing('/home/toto/database/region_growing');

%%%%%%%%%%%%%%%%%%%%%
%% Extra infos
%% These have to be organized in a comma-separated file (CSV). Example:
%%          , sex
%% subject1 , 0 
%% subject2 , 1
%%
%% Note that the first entry has to be left empty. The subject IDs need to be identical to those used in the fMRI preprocessing pipeline. 
%% Also, only numerical variables are supported (i.e. no 'M', 'W' to code for man and woman). 
%% These variables will be used to split the subjects into strata, e.g. men vs women. In the group analysis, equal weight is given to all strata 
%% (regardless of the number of subjects). Resampling of subjects is also made within strata, but not between them. Adding more covariates
%% will further stratify the group sample (e.g. two variables old/young men/women will translate into 4 strata). 
%%
%% If you want to stratify the sample, uncomment the following line and indicate the csv file you want to use. Otherwise, just leave it as is. 
%% To check that the file is properly formatted prior to running the pipeline, run the following command in Matlab/Octave:
%% [tab,labx,laby] = niak_read_csv('/data/infos.csv');
%% The subject IDs should load in LABX, the covariate IDs load in LABY, and the value of the variables into a numerical array TAB. 
%%%%%%%%%%%%%%%%%%%%%

% files_in.infos = '/data/infos.csv'; % A file of comma-separeted values describing additional information on the subjects, this can be omitted

%%%%%%%%%%%%%
%% Options %%
%%%%%%%%%%%%%

opt.folder_out = '/home/toto/database/basc/'; % Where to store the results
opt.region_growing.thre_size = 1000; %  the size of the regions, when they stop growing. A threshold of 1000 mm3 will give about 1000 regions on the grey matter. 
opt.grid_scales = [10:10:100 120:20:200 240:40:500]'; % Search for stable clusters in the range 10 to 500 
opt.scales_maps = repmat(opt.grid_scales,[1 3]); % The scales that will be used to generate the maps of brain clusters and stability. 
                                                 % In this example the same number of clusters are used at the individual (first column), 
                                                 % group (second column) and consensus (third and last colum) levels.
opt.stability_tseries.nb_samps = 100; % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
opt.stability_group.nb_samps = 500; % Number of bootstrap samples at the group level. 500: the CI on group stability is +/-0.05

opt.flag_ind = false;   % Generate maps/time series at the individual level
opt.flag_mixed = false; % Generate maps/time series at the mixed level (group-level networks mixed with individual stability matrices).
opt.flag_group = true;  % Generate maps/time series at the group level

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
opt.flag_test = false; % Put this flag to true to just generate the pipeline without running it. Otherwise the region growing will start. 
%opt.psom.max_queued = 10; % Uncomment and change this parameter to set the number of parallel threads used to run the pipeline
pipeline = niak_pipeline_stability_rest(files_in,opt); 