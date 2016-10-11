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
opt.sub_map_type = 'mean';        % the model for the subtype map

%% Association & visualization
opt.flag_assoc = true;                                % turn on/off GLM association testing (true: apply / false: don't apply)
opt.association.fdr = 0.05;                           % scalar number for the level of acceptable false-discovery rate (FDR) for the t-maps
opt.association.type_fdr = 'BH';                      % method for how the FDR is controlled

% To test a main effect of a variable
opt.association.contrast.variable_of_interest = 1;    % scalar number for the weight of the variable in the contrast
opt.association.contrast.confound1 = 0;               % scalar number for the weight of the variable in the contrast
opt.association.contrast.confound2 = 0;               % scalar number for the weight of the variable in the contrast

% To test an interaction
opt.association.interaction(1).label = 'interaction1';
opt.association.interaction(1).factor = {'variable1','variable2'};
opt.association.contrast.interaction1 = 1;
opt.association.contrast.variable1 = 0;
opt.association.contrast.variable2 = 0;



opt.flag_visu = true; % turn on/off making plots for GLM testing (true: apply / false: don't apply)




%% Chi2 statistics




