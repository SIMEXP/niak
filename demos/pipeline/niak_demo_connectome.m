function [pipeline,opt_pipe,files_in] = niak_demo_connectome(path_demo,opt)
% This function runs NIAK_PIPELINE_CONNECTOME on the preprocessed DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_CONNECTOME(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_CONNECTOME
%   will do here. The demo only changes one default and enforces a few 
%   parameters (see COMMENTS below):
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
%   (structure) the option to call NIAK_PIPELINE_CONNECTOME
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_CONNECTOME
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
% Keywords : region growing, fMRI

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
opt = psom_struct_defaults(opt,{'folder_out'},{[path_demo,filesep,'connectome',filesep]},false);

%% Set the template
files_in.network = [gb_niak_path_niak 'template' filesep 'basc_cambridge_sc100.mnc.gz'];

%% Grab the results from the NIAK fMRI preprocessing pipeline
opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
opt_g.type_files = 'roi'; % Specify to the grabber to prepare the files for the region growing pipeline
files_in.fmri = niak_grab_fmri_preprocess(path_demo,opt_g).fmri; % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 

%% Set the seeds
files_in.seeds = [gb_niak_path_niak 'template' filesep 'list_seeds_cambridge_100.csv'];

%% Generate the pipeline
[pipeline,opt_pipe] = niak_pipeline_connectome(files_in,opt);