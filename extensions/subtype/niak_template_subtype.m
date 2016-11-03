% Template to write a script for the NIAK subtyping pipeline
%
% To run a demo of the subtyping, please see
% NIAK_DEMO_SUBTYPE.
%
% Copyright (c) Pierre Bellec, Sebastian Urchs, Angela Tam
%   Montreal Neurological Institute, McGill University, 2008-2016.
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Qubec, Canada, 2010-2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, clustering, pipeline

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting input/output files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clear the workspace 
clear all

%% Set up the files_in structure

% Subject 1
files_in.data.subject1 = '/home/atam/demo_niak/func_rest_subject1.mnc.gz';    % 3D or 4D volume
% Subject 2
files_in.data.subject2 = '/home/atam/demo_niak/func_rest_subject2.mnc.gz';    % 3D or 4D volume

% Mask
files_in.mask = '/home/atam/mask.mnc.gz';     % a 3D binary mask

% Model
files_in.model = '/home/atam/niak/demos/data/demoniak_model_group.csv';

%%%%%%%%%%%%%%%%%%%%%%%
%% Pipeline options  %%
%%%%%%%%%%%%%%%%%%%%%%%

%% General
opt.folder_out = '/home/atam/subtype_results/';     % where to store the results
opt.scale = 7;                                      % integer for the number of networks specified in files_in.data

%% Stack
opt.stack.flag_conf = true;                    % turn on/off regression of confounds during stacking (true: apply / false: don't apply)
opt.stack.regress_conf = {'confound1','confound2'};     % a list of varaible names to be regressed out

%% Subtyping
opt.subtype.nb_subtype = 2;       % the number of subtypes to extract
opt.sub_map_type = 'mean';        % the model for the subtype maps (options are 'mean' or 'median')

%% Association testing via GLM

% GLM options
opt.flag_assoc = true;                                % turn on/off GLM association testing (true: apply / false: don't apply)
opt.association.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
opt.association.type_fdr = 'BH';                      % method for how the FDR is controlled
opt.association.normalize_x = true;                   % turn on/off normalization of covariates in model (true: apply / false: don't apply)
opt.association.normalize_y = false;                  % turn on/off normalization of all data (true: apply / false: don't apply)
opt.association.normalize_type = 'mean';              % type of correction for normalization (options: 'mean', 'mean_var')
opt.association.flag_intercept = true;                % turn on/off adding a constant covariate to the model

% Note the pipeline can only test one main effect or interaction at a time

% To test a main effect of a variable
opt.association.contrast.variable_of_interest = 1;    % scalar number for the weight of the variable in the contrast
opt.association.contrast.confound1 = 0;               % scalar number for the weight of the variable in the contrast
opt.association.contrast.confound2 = 0;               % scalar number for the weight of the variable in the contrast

% To test an interaction
opt.association.interaction(1).label = 'interaction1';              % string label for the interaction
opt.association.interaction(1).factor = {'variable1','variable2'};  % covariates (cell of strings) that are being multiplied together to build the interaction
opt.association.contrast.interaction1 = 1;                          % scalar number for the weight of the interaction
opt.association.contrast.variable1 = 0;                             % scalar number for the weight of the variable in the contrast
opt.association.contrast.variable2 = 0;                             % scalar number for the weight of the variable in the contrast
opt.association.flag_normalize_inter = true;  % turn on/off normalization of factors to zero mean and unit variance prior to the interaction


% Visualization
opt.flag_visu = true;               % turn on/off making plots for GLM testing (true: apply / false: don't apply)
opt.visu.data_type = 'continuous';  % type of data for contrast or interaction in opt.association (options are 'continuous' or 'categorical')

%% Chi2 statistics

opt.flag_chi2 = true;               % turn on/off running Chi-square test (true: apply / false: don't apply)
opt.chi2.group_col_id = 'Group';    % string name of the column in files_in.model on which the contigency table will be based


%%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline  %%
%%%%%%%%%%%%%%%%%%%%%%%

opt.flag_test = false;  % Put this flag to true to just generate the pipeline without running it.
pipeline = niak_pipeline_fmri_preprocess(files_in,opt);


