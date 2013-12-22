function [pipeline,opt_pipe,files_in] = niak_demo_stability_fir(path_demo,opt)
% This function runs NIAK_PIPELINE_STABILITY_FIR on the preprocessed DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_STABILITY_FIR(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_STABILITY_FIR
%   will do here. The demo only changes one default:
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/connectome) where to store the 
%      results of the pipeline.
%
% _________________________________________________________________________
% OUTPUT
%
% PIPELINE
%   (structure) a formal description of the pipeline. See
%   PSOM_RUN_PIPELINE.
%
% OPT_PIPE
%   (structure) the option to call NIAK_PIPELINE_STABILITY_FIR
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS
%
% Note 1:
% The demo will apply the connectome pipeline on the preprocessed version 
% of the DEMONIAK dataset. It is possible to configure the pipeline manager 
% to use parallel computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% NOTE 2:
% The demo database exists in multiple file formats. NIAK looks into the demo 
% path and is supposed to figure out which format you are intending to use 
% by itself. 
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : stability analysis, clustering, finite-impulse response

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

niak_gb_vars
if nargin < 1
    error('Please specify the path to the preprocessed DEMONIAK database in PATH_DEMO')
end
if nargin < 2
    opt = struct();
end

path_demo = niak_full_path(path_demo);
opt = psom_struct_defaults(opt,{'folder_out'},{[path_demo,filesep,'stability_fir',filesep]},false);

%% Grab the results from the NIAK fMRI preprocessing pipeline
opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the stability FIR pipeline
opt_g.filter.run = {'motor'}; % Just grab the "motor" runs
files_in = niak_grab_fmri_preprocess(path_demo,opt_g); 

%% Set the timing of events;
files_in.timing = [gb_niak_path_niak 'demos' filesep 'data' filesep 'demoniak_events.csv'];
opt.name_condition = 'motor';
opt.name_baseline  = 'rest';
%% Set the scales of analysis
opt.grid_scales = [5 10]'; % Search for stable clusters in the range 10 to 500 
opt.scales_maps = [  5  5  5  ; ...   % The scales that will be used to generate the maps of brain clusters and stability. 
                    10 10 10  ];                   
opt.stability_fir.nb_samps = 20;     % Number of bootstrap samples at the individual level. 100: the CI on indidividual stability is +/-0.1
opt.stability_fir.std_noise = 0;     % The standard deviation of the judo noise. The value 0 will not use judo noise. 
opt.stability_group.nb_samps = 20;   % Number of bootstrap samples at the group level. 500: the CI on group stability is +/-0.05
opt.stability_group.min_subject = 2; % Lower the min number of subject ... there are only two subjects in the demo_niak. 

%% FIR estimation
opt.fir.nb_min_baseline = 1; % There is not much data in the demo_niak, so don't set a minimum on the number of points used to estimate the baseline
opt.fir.type_norm     = 'fir_shape'; % The type of normalization of the FIR. Only "fir_shape" is available (starts at zero, unit sum-of-squares)
opt.fir.time_window   = 20;          % The size (in sec) of the time window to evaluate the response
opt.fir.time_sampling = 1;           % The time between two samples for the estimated response. Do not go below 1/2 TR unless there is a very large number of trials.
opt.fir.max_interpolation = 15;      % Allow interpolations of up to 15 seconds to cover for scrubbing. That's because the small demo dataset has hardly any usable time window ...

%% FDR estimation
opt.nb_samps_fdr = 100; % The number of samples to estimate the false-discovery rate

%% Multi-level options
opt.flag_ind = false;   % Generate maps/FIR at the individual level
opt.flag_mixed = false; % Generate maps/FIR at the mixed level (group-level networks mixed with individual stability matrices).
opt.flag_group = true;  % Generate maps/FIR at the group level

%% Generate the pipeline
[pipeline,opt_pipe] = niak_pipeline_stability_fir(files_in,opt);
