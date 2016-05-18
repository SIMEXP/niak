function [pipe,opt] = niak_pipeline_subtype(files_in,opt)
% Estimation of surface space cluster stability
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_SUBTYPE(IN,OPT)
% ______________________________________________________________________________
%
% INPUTS:
%
% FILES_IN (structure) with the following fields :
%
%   DATA.<SUBJECT>
%       (string) Containing the individual map (e.g. rmap_part,stability_maps, 
%       etc) NB: assumes there is only 1 .nii.gz or mnc.gz map per individual.
%
%   MASK
%       (string) path to mask of the voxels that will be included in the 
%       time*space array.
%
%   MODEL
%       (strings, Default '') a .csv files coding for the pheno data. Is
%       expected to have a header and a first column specifying the case
%       IDs/names corresponding to the data in FILES_IN.DATA
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string) this specifies the root path where outputs are generated
%
%   SCALE
%       (integer) this specifies the scale of the networks specified in
%       FILES_IN.DATA. E.g. a brain partition of 5 networks is considered
%       to be at scale 5.
%
%   STACK
%       (struct, optional) with the following fields:
%
%       REGRESS_CONF 
%           (Cell of string, Default {}) A list of variable names to be 
%           regressed out.
%
%   SUBTYPE
%       (struct, optional) with the following fields:
%
%       NB_SUBTYPE
%           (integer, default 2) the number of subtypes to extract
%
%       SBT_MAP_TYPE
%           (string, default 'mean') the model for the subtype map. Options are:
%               'mean'
%               'median'
%
%       GROUP_COL
%           (integer, default 0) the index of the group column in FILES_IN.MODEL
%           that the confusion table is based on. If OPT.SUBTYPE.FLAG_STATS is
%           set to true, then this value has to be a non-zero integer.
%
%       FLAG_STATS
%           (boolean, default true) if set to true, stats will be computed for
%           the extracted subtypes.
%
%   ASSOCIATION
%       (struct, optional) with the following fields:
%
%       FDR
%           (scalar, default 0.05) the level of acceptable false-discovery rate
%       for the t-maps.
%
%       TYPE_FDR
%           (string, default 'BH') how the FDR is controled. See the METHOD
%           argument of NIAK_FDR.
%
%       CONTRAST
%           (structure, with arbitray fields <NAME>, which needs to correspond
%           to the label of one column in the file FILES_IN.MODEL) The fields
%           found in CONTRAST will determine which covariates enter the model:
%
%           <NAME>
%               (scalar) the weight of the covariate NAME in the contrast.
%
%       INTERACTION
%           (structure array, optional) with multiple entries and the following
%           fields:
%          
%           LABEL
%               (string) a label for the interaction covariate.
%
%           FACTOR
%               (cell of string) covariates that are being multiplied together 
%               to build the interaction covariate.  There should be only one
%               covariate associated with each label.
%
%           FLAG_NORMALIZE_INTER
%               (boolean,default true) if FLAG_NORMALIZE_INTER is true, the
%               factor of interaction will be normalized to a zero mean and unit
%               variance before the interaction is derived (independently of
%               OPT.<LABEL>.GROUP.NORMALIZE below).
%
%       NORMALIZE_X
%           (structure or boolean, default true) If a boolean and true, all
%           covariates of the model are normalized (see NORMALIZE_TYPE below).
%           If a structure, the fields <NAME> need to correspond to the label of
%           a column in the file FILES_IN.MODEL):
%
%           <NAME>
%               (arbitrary value) if <NAME> is present, then the covariate is
%               normalized (see NORMALIZE_TYPE below).
%
%       NORMALIZE_Y
%           (boolean, default false) If true, the data is normalized (see
%           NORMALIZE_TYPE below).
%
%       NORMALIZE_TYPE
%           (string, default 'mean') Available options:
%               'mean': correction to a zero mean (for each column) 'mean_var':
%               correction to a zero mean and unit variance (for each column)
%
%       SELECT
%           (structure, optional) with multiple entries and the following
%           fields:
%
%           LABEL
%               (string) the covariate used to select entries *before
%               normalization*
%
%           VALUES
%               (vector, default []) a list of values to select (if empty, all
%               entries are retained).
%
%           MIN
%               (scalar, default []) only values higher (strictly) than MIN are
%               retained.
%
%           MAX
%               (scalar, default []) only values lower (strictly) than MAX are
%               retained.
%
%           OPERATION
%               (string, default 'or') the operation that is applied to select
%               the frames. Available options: 'or' : merge the current 
%               selection SELECT(E) with the result of the previous one. 'and' :
%               intersect the current selection SELECT(E) with the result of the
%               previous one.
%
%       FLAG_INTERCEPT
%           (boolean, default true) if FLAG_INTERCEPT is true, a constant
%           covariate will be added to the model.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of IN, OUT and OPT. 
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2016
%   Montreal Neurological Institute, 2016
% Maintainer : sebastian.urchs@mail.mcgill.ca
%
% See licensing information in the code.
% Keywords : subtyping

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
% ______________________________________________________________________________

%% Seting up default arguments
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_SUBTYPE(IN,OPT).\n Type ''help niak_pipeline_subtype'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'data' , 'mask' , 'model'           },...
           { NaN    , NaN    , 'gb_niak_omitted' });

% Options
opt = psom_struct_defaults(opt,...
           { 'folder_out' , 'scale' , 'psom'   , 'stack'   , 'subtype' , 'association' , 'flag_verbose' , 'flag_test' },...
           { NaN          , NaN     , struct() , struct()  , struct()  , struct()      , true           , false       });

% Psom options
opt.psom = psom_struct_defaults(opt.psom,...
           { 'path_logs'                     },...
           { [opt.folder_out filesep 'logs'] });

% Preprocessing options
opt.stack = psom_struct_defaults(opt.stack,...
            { 'regress_conf' },...
            { {}             });
          
% Subtype options
opt.subtype = psom_struct_defaults(opt.subtype,...
             { 'nb_subtype' , 'sub_map_type' , 'group_col_id' , 'flag_stats' },...
             { 2            , 'mean'         , 0              , true         });

% Association options
opt.association = psom_struct_defaults(opt.association,...
                  { 'fdr' , 'type_fdr' , 'contrast' , 'interaction' , 'normalize_x' , 'normalize_y' , 'select' , 'flag_intercept' },...
                  { 0.05  , 'BH'       , struct()   , struct()      , true          , false         , struct() , true             });
         
%% Construct the pipeline
pipe = struct;
% Prepare the input structure for the subtype weight extraction step
weight_in = struct('data', struct, 'subtype', struct);

% Iterate these jobs for each network
for net_id = 1:opt.scale;
    % Set network name
    net_name = sprintf('network_%d', net_id);
    % Set the root folder to the network name
    network_folder = [opt.folder_out filesep net_name];
    % Network extraction and preprocessing
    pre_name = sprintf('stack_%d', net_id);
    pre_opt = opt.stack;
    % Set the network
	pre_opt.network = net_id;
    pre_in = files_in;
    pre_out = [network_folder filesep sprintf('network_%d_stack.mat', net_id)];
    pipe = psom_add_job(pipe, pre_name, 'niak_brick_network_stack',...
                        pre_in, pre_out, pre_opt);
    % Assign output to weight extraction step
    weight_in.data.(net_name) = pipe.(pre_name).files_out;
                    
    % Similarity matrix computation
    sim_name = sprintf('similarity_%d', net_id);
    sim_opt = struct;
    sim_opt.folder_out = network_folder;
    sim_in = pipe.(pre_name).files_out;
    sim_out = struct;
    sim_out.matrix = [network_folder filesep sprintf('network_%d_similarity_matrix.mat', net_id)];
    pipe = psom_add_job(pipe, sim_name, 'niak_brick_similarity_matrix',...
                        sim_in, sim_out, sim_opt);
    
    % Subtyping
    sub_name = sprintf('subtype_%d', net_id);
    % Assign options
    sub_opt = opt.subtype;
    % Set the network folder
    sub_opt.folder_out = network_folder;
    % Assign inputs
    sub_in = rmfield(files_in, 'data');
    sub_in.data = pipe.(pre_name).files_out;
    sub_in.matrix = pipe.(sim_name).files_out.matrix;
    sub_out = struct;
    sub_out.subtype = [network_folder filesep sprintf('network_%d_subtype.mat', net_id)];
    pipe = psom_add_job(pipe, sub_name, 'niak_brick_subtyping',...
                        sub_in, sub_out, sub_opt);
    % Assign output to weight extraction step
    weight_in.subtype.(net_name) = pipe.(sub_name).files_out.subtype;
end

% Set up the weight extraction options
weight_opt = struct;
weight_opt.scales = 1:opt.scale;
weight_opt.folder_out = opt.folder_out;
weight_out.weights = [opt.folder_out filesep 'subtype_weights.mat'];
pipe = psom_add_job(pipe, 'weight_extraction', 'niak_brick_subtype_weight',...
                    weight_in, weight_out, weight_opt);
                
% Set up the association test options
assoc_opt = opt.association;
assoc_opt.folder_out = opt.folder_out;
assoc_in = struct;
assoc_in.weight = pipe.weight_extraction.files_out.weights;
assoc_in.model = files_in.model;
assoc_out = struct;
pipe = psom_add_job(pipe, 'association_test', 'niak_brick_association_test',...
                    assoc_in, assoc_out, assoc_opt);

%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end