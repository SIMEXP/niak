% Template for the NIAK TRT (test-retest) pipeline
%
% To run this pipeline, the fMRI datasets first need to be preprocessed 
% using the NIAK fMRI preprocessing pipeline.
%
% WARNING: This script will clear the workspace
%
% Copyright (c) Pierre Bellec, Christian Dansereau
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Québec, Canada, 2010-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, preprocessing, pipeline

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
% THE SOFTWARE

clear all

%%%%%%%%%%%%
%% Input / Output folders 
%%%%%%%%%%%%
path_preproc     = '/home/toto/database/fmri_preprocess/'; % the output folder of NIAK fMRI preprocessing pipeline
opt.folder_out   = '/home/toto/database/trt_results/'; % output folder to store the results
opt.list_session = {'session1','session2'}; % the two session name to compare

%%%%%%%%%%%%
%% Reference path, will be set one time only 
%%%%%%%%%%%%
basc_partition   = '/home/toto/database/niak/trunk/template/basc_cambridge_sc100.mnc.gz'; % Brain partition to use inthe TRT
seed_path        = '/home/toto/database/niak/trunk/template/list_seeds_cambridge_100.csv'; % seed region associated with BASC_PARTITION variable




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ----------------------- DO NOT MODIFY AFTER THIS LINE ----------------------- %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Grab the results from the NIAK fMRI preprocessing pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_sess = 1:length(opt.list_session)
    
    %% Grabbing the results per session
	opt_g.min_nb_vol = 100;     % The minimum number of volumes for an fMRI dataset to be included. This option is useful when scrubbing is used, and the resulting time series may be too short.
	opt_g.min_xcorr_func = 0; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of functional images in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
	opt_g.min_xcorr_anat = 0; % The minimum xcorr score for an fMRI dataset to be included. This metric is a tool for quality control which assess the quality of non-linear coregistration of the anatomical image in stereotaxic space. Manual inspection of the values during QC is necessary to properly set this threshold.
	opt_g.type_files = 'glm_connectome'; % Specify to the grabber to prepare the files for the glm_connectome pipeline
    opt_g.filter.session = opt.list_session(num_sess); % Just grab session 1
    
    tmp_dataset = niak_grab_fmri_preprocess(path_preproc,opt_g); % grab results
    tmp_dataset.network = basc_partition; % add the reference network partition
    dataset{num_sess} = tmp_dataset; % store the result per session
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Grab the mask from the preprocessing %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt_g.type_files = 'roi'; % Specify to the grabber to prepare the files for the glm_connectome pipeline
tmp_dataset = niak_grab_fmri_preprocess(path_preproc,opt_g);

files_in.dataset = dataset;
files_in.mask = tmp_dataset.mask;
files_in.seeds   = seed_path;

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

[pipeline,opt]   = niak_pipeline_trt_rmap(files_in,opt)
