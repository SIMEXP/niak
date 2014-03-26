function [pipeline,opt_pipe,files_in] = niak_demo_stability_rest(path_demo,opt)
% This function runs NIAK_PIPELINE_STABILITY_REST on the preprocessed DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_STABILITY_REST(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_STABILITY_REST
%   will do here. The demo only changes one default:
%
%   FILES_IN.FMRI
%      (structure, default grab the preprocessed demoniak) the input files 
%      from the preprocessing to be fed in the stability_rest pipeline.
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/stability_rest) where to store the 
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
%   (structure) the option to call NIAK_PIPELINE_STABILITY_REST
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_STABILITY_REST
%
% _________________________________________________________________________
% COMMENTS
%
% Note 1:
% The demo will apply the stability_rest pipeline on the preprocessed version 
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
% Keywords : stability analysis, clustering, resting-state fMRI

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
opt = psom_struct_defaults(opt, ...
      {'files_in' , 'folder_out'                                , 'flag_test' }, ...
      {''         , [path_demo,filesep,'stability_rest',filesep] , false       }, ...
      false);

%% Grab the results from the NIAK fMRI preprocessing pipeline
if ~isempty(opt.files_in)&&~strcmp(opt.files_in,'gb_niak_omitted')    
    files_in = rmfield(opt.files_in,'fmri');
    [fmri_c,labels_f] = niak_fmri2cell(opt.files_in.fmri);
    for ee = 1:length(fmri_c)
        if strcmp(labels_f(ee).run,'rest')
            files_in.fmri.(labels_f(ee).subject).(labels_f(ee).session).(labels_f(ee).run) = fmri_c{ee};
        end
    end
else
    %% Grab the results from the NIAK fMRI preprocessing pipeline
    opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
    opt_g.type_files = 'fir'; % Specify to the grabber to prepare the files for the stability FIR pipeline
    opt_g.filter.run = {'rest'}; % Just grab the "motor" runs
    files_in = niak_grab_fmri_preprocess(path_demo,opt_g); 
end

%% Options: grid scales
if ~isfield(opt,'grid_scales')||isempty(opt.grid_scales)
    opt.grid_scales = [2 5 10:10:40]'; 
end

%% Options: scales to generate stability maps & time series
if ~isfield(opt,'scales_maps')||isempty(opt.scales_maps)
    opt.scales_maps = [ 2 2 2 ; 5 5 5 ; 10 10 10; 30 30 30]; % The scales that will be used to generate the maps of brain clusters and stability
end

%% Options: number of bootstrap samples (individual stability)
if ~isfield(opt,'stability_tseries')||~isfield(opt.stability_tseries,'nb_samps')||isempty(opt.stability_tseries.nb_samps)
    opt.stability_tseries.nb_samps = 50;
end

%% Options: number of bootstrap samples (group stability)
if ~isfield(opt,'stability_group')||~isfield(opt.stability_group,'nb_samps')||isempty(opt.stability_group.nb_samps)
    opt.stability_group.nb_samps = 50; 
end

%% Options: generate results at the indiviudal level
if ~isfield(opt,'flag_ind')
    opt.flag_ind = true;   
end

%% Options: generate results at the mixed level
if ~isfield(opt,'flag_ind')
    opt.flag_mixed = true;   
end

%% Options: generate results at the group level
if ~isfield(opt,'flag_group')
    opt.flag_group = true;   
end

%% Options: generate network-level time series
if ~isfield(opt,'flag_tseries_network')
    opt.flag_tseries_network = true;   
end

%% Options: minimum number of datasets
if ~isfield(opt,'stability_group')||~isfield(opt.stability_group,'min_subject')
    opt.stability_group.min_subject = 2;
end

%% Generate the pipeline
[pipeline,opt_pipe] = niak_pipeline_stability_rest(files_in,opt);