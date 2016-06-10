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
%   SUBTYPE.<NETWORK>
%       (string, default 'gb_niak_omitted' ) path to previously
%       generated subtype maps that will be used for weight extraction on the
%       current dataset. The scale of these subtypes has to match the scale in
%       OPT.SCALE with continuously ascending order 1:OPT.SCALE. Naming of the
%       subfields has to correspond to the pattern 'network_i' for the ith
%       network in 1:OPT.SCALE.
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
%       SUB_MAP_TYPE
%           (string, default 'mean') the model for the subtype map. Options are:
%               'mean'
%               'median' 
%
%   ASSOCIATION
%       (struct, optional) with the following fields:
%
%       SCALE
%           (integer, default OPT.SCALE) ...
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
%           (structure, with fields <NAME>, which needs to correspond
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
%   CHI2
%       (struct, optional) with the following fields:
%
%       GROUP_COL_ID
%           (string, default 'Group') the name of the column in 
%           FILES_IN.MODEL that the contingency table will be based on.
%
%       FLAG_WEIGHTS
%           (boolean, default false) if the flag is true, the brick will
%           calculate statistics based on the weights from FILES_IN.WEIGHTS
%
%   FLAG_CHI2
%       (boolean, default true) turn on/off to calculate Chi2 and Cramer's
%       V statistics
%
%   FLAG_VISU
%       (boolean, default true) turn on/off to generate figures for the
%       association test
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
% Copyright (c) Pierre Bellec, Sebastian Urchs, Angela Tam
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
           { 'data' , 'mask' , 'model'           , 'subtype'         },...
           { NaN    , NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' });

% Options
opt = psom_struct_defaults(opt,...
           { 'folder_out' , 'scale' , 'psom'   , 'stack'   , 'subtype' , 'association' , 'chi2'   , 'flag_visu' , 'flag_chi2' , 'flag_verbose' , 'flag_test' },...
           { NaN          , NaN     , struct() , struct()  , struct()  , struct()      , struct() , true        , true       , true           , false       });

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
             { 'nb_subtype' , 'sub_map_type' },...
             { 2            , 'mean'         });         

% Association options
opt.association = psom_struct_defaults(opt.association,...
                  { 'scale'   , 'fdr' , 'type_fdr' , 'contrast' , 'interaction' , 'normalize_x' , 'normalize_y' , 'select' , 'flag_intercept' },...
                  { opt.scale , 0.05  , 'BH'       , NaN        , struct()      , true          , false         , struct() , true             });
              
% Chi-2 and Cramer's V options
opt.chi2 = psom_struct_defaults(opt.chi2,...
             { 'group_col_id' , 'flag_weights' , 'network'         },...
             { 'Group'        , false          , 'gb_niak_omitted'  }); 
              
% See if external subtypes have been specified
ext_sbt = false;
if ~strcmp(files_in.subtype, 'gb_niak_omitted')
    % External subtypes were specified
    ext_sbt = true;
    n_sbt_ext = length(fieldnames(files_in.subtype));
    % See if we have the same number of networks
    if ~n_sbt_ext == opt.scale
        % For some reason we don't have the correct number of external subtype
        % networks
        error('The external subtypes in FILES_IN.SUBTYPE have %d networks but OPT.SCALE = %d. These have to be the same. Exiting!', n_sbt_ext, opt.scale);
    end 
else
    files_in = rmfield(files_in, 'subtype'); % remove files_in.subtype in everything if not supplied by user
end

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
    if ext_sbt
        pre_in = rmfield(files_in, 'subtype'); % remove 'subtype' field from files_in for brick stack when subtypes are supplied by user
    else
        pre_in = files_in;
    end
    pre_out = [network_folder filesep sprintf('network_%d_stack.mat', net_id)];
    pipe = psom_add_job(pipe, pre_name, 'niak_brick_network_stack',...
                        pre_in, pre_out, pre_opt);
    % Assign output to weight extraction step
    weight_in.data.(net_name) = pipe.(pre_name).files_out;
    
    % Check if external subtypes have been supplied
    if ~ext_sbt
        % Compute subtypes on the current data
        % Subtyping
        sub_name = sprintf('subtype_%d', net_id);
        % Assign options
        sub_opt = opt.subtype;
        % Set the network folder
        sub_opt.folder_out = network_folder;
        % Assign inputs
        sfields = {'data', 'model'};
        sub_in = rmfield(files_in, sfields);
        sub_in.data = pipe.(pre_name).files_out;
        sub_out = struct;
        sub_out.subtype = [network_folder filesep sprintf('network_%d_subtype.mat', net_id)];
        pipe = psom_add_job(pipe, sub_name, 'niak_brick_subtyping',...
                            sub_in, sub_out, sub_opt);
        % Assign output to weight extraction step
        weight_in.subtype.(net_name) = pipe.(sub_name).files_out.subtype;
    else
        % Assign output to weight extraction step
        weight_in.subtype.(net_name) = files_in.subtype.(net_name);
    end
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
assoc_out.stats = [opt.folder_out filesep 'association_stats.mat'];
assoc_out.csv = [opt.folder_out filesep 'association_summary.csv'];
pipe = psom_add_job(pipe, 'association_test', 'niak_brick_association_test',...
                    assoc_in, assoc_out, assoc_opt);

if opt.flag_visu
    % Generate the figures for the association test brick
    visu_in = struct;
    visu_in.weight = pipe.weight_extraction.files_out.weights;
    visu_in.association = pipe.association_test.files_out.stats;
    visu_out = struct;
    fields = {'fdr', 'type_fdr', 'interaction', 'normalize_x', 'normalize_y',...
                        'select', 'flag_intercept'};
    visu_opt = rmfield(opt.association, fields);
    visu_opt.folder_out = opt.folder_out;
    pipe = psom_add_job(pipe, 'visu_association', 'niak_brick_visu_subtype_glm',...
                        visu_in, visu_out, visu_opt);
end 

% Set up the Chi2 and Cramer's V test options
if opt.flag_chi2
    % Iterate these jobs for each network
    for net_id = 1:opt.scale; 
        % Set network and subtype name
        net_name = sprintf('network_%d', net_id);
        sub_name = sprintf('subtype_%d', net_id);
        % Set the root folder to the network name
        network_folder = [opt.folder_out filesep net_name];
        chi2_in = struct;
        chi2_in.model = files_in.model;
        chi2_opt = opt.chi2;
        % Set the network folder
        chi2_opt.folder_out = network_folder;
        chi2_out = struct;
        chi2_out.stats = [network_folder filesep sprintf('network_%d_group_stats.mat', net_id)];
        chi2_out.contab = [network_folder filesep sprintf('network_%d_chi2_contingency_table.csv', net_id)];
        % Check if external subtypes have been supplied
        if ~ext_sbt
            chi2_in.subtype = pipe.(sub_name).files_out.subtype;
        else
            chi2_opt.network = net_id;
            chi2_opt.flag_weights = true;
            chi2_in.weights = weight_out.weights;
        end
        chi2_name = sprintf('chi2_network_%d', net_id);
        pipe = psom_add_job(pipe, chi2_name, 'niak_brick_chi_cramer',...
            chi2_in, chi2_out, chi2_opt);
    end
end

%% Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end
