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
%   DATA.(NETWORK).(SUBJECT)
%       (string) Containing the individual 3D map (e.g. rmap_part,stability_maps,
%       etc) for each SUBJECT and each NETWORK. 
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
%       FLAG_CONF
%           (boolean, default true) turn on or off the regression of
%           confounds from the maps. Even if no regression confounds are
%           specified, the intercept is always regressed unless this flag
%           is set to false.
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
%   ASSOCIATION.(NAME_CONTRAST)
%       (struct, optional) with the following fields:
%
%       SCALE
%           (integer, default OPT.SCALE) ...
%
%       FDR
%           (scalar, default 0.05) the level of acceptable false-discovery rate
%           for the t-maps.
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
%       TYPE_VISU
%           (string, either 'categorical' or 'continuous') the kind of data
%           in OPT.ASSOCIATION.CONTRAST.<NAME>
%
%       FLAG_VISU
%           (boolean, default true) turn on/off to generate figures for the
%           association test
%
%   CHI2
%       (string, default '') the name of the column in 
%       FILES_IN.MODEL that the contingency table will be based on.
%       If left empty, no CHI2 will be applied. 
%
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED for each job. If left empty,
%       the generator is not initialized by the bricks. As PSOM features an 
%       initialization based on the clock, the results will be slightly 
%       different due to random variations in bootstrap sampling if the 
%       pipeline is executed twice.
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
%   Centre de recherche de l'institut de Griatrie de Montral
%   Dpartement d'informatique et de recherche oprationnelle
%   Universit de Montral, 2010-2016
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
           { 'folder_out' , 'scale' , 'psom'   , 'stack'   , 'subtype' , 'association' , 'chi2'   , 'rand_seed', 'flag_verbose' , 'flag_test' },...
           { NaN          , NaN     , struct() , struct()  , struct()  , struct()      , ''       , []         , true           , false       });
opt.folder_out = niak_full_path(opt.folder_out);

% Psom options
opt.psom = psom_struct_defaults(opt.psom,...
           { 'path_logs'                     },...
           { [opt.folder_out 'logs'] });

% Preprocessing options
opt.stack = psom_struct_defaults(opt.stack,...
            { 'regress_conf' , 'flag_conf' },...
            { {}             , true        });

% Subtype options
opt.subtype = psom_struct_defaults(opt.subtype,...
             { 'nb_subtype' , 'sub_map_type' },...
             { 2            , 'mean'         });

% Association options

list_contrast = fieldnames(opt.association);
for cc = 1:length(list_contrast)
    opt.association.(list_contrast{cc}) = psom_struct_defaults(opt.association.(list_contrast{cc}),...
        { 'type_visu'  , 'flag_visu' , 'scale'   , 'fdr' , 'type_fdr' , 'contrast' , 'interaction' , 'normalize_x' , 'normalize_y' , 'select' , 'flag_intercept' },...
        { 'continuous' , true        , opt.scale , 0.05  , 'BH'       , NaN        , struct()      , true          , false         , struct() , true             });
end
opt.flag_assoc = length(list_contrast)>0;
         
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
list_net = fieldnames(files_in.data);

% Iterate these jobs for each network
for net_id = 1:length(list_net);
    % Set network name
    net_name = list_net{net_id};
    % Set the root folder to the network name
    network_folder = [opt.folder_out filesep 'networks' filesep net_name];
    % Network extraction and preprocessing
    pre_name = sprintf('stack_%s', net_name);
    pre_opt = opt.stack;
    % Set the network
	  pre_opt.network = 1;
    pre_in.mask  = files_in.mask;
    pre_in.model = files_in.model;
    pre_in.data  = files_in.data.(net_name);
    if ext_sbt
        pre_in.subtype = files_in.subtype;
    end
    pre_out = [network_folder filesep sprintf('stack_%s.mat', net_name)];
    pipe = psom_add_job(pipe, pre_name, 'niak_brick_network_stack',...
                        pre_in, pre_out, pre_opt);
    % Assign output to weight extraction step
    weight_in.data.(net_name) = pipe.(pre_name).files_out;
    weight_out.weights_csv{net_id} = [network_folder filesep sprintf('sbt_weights_net_%s.csv', net_name)];
    weight_out.weights_pdf{net_id} = [network_folder filesep sprintf('sbt_weights_net_%s.pdf', net_name)];
    
    % Check if external subtypes have been supplied
    if ~ext_sbt
        % Compute subtypes on the current data
        % Subtyping
        sub_name = sprintf('subtype_%s', net_name);
        % Assign options
        sub_opt = opt.subtype;
        sub_opt.rand_seed = opt.rand_seed;
        % Set the network folder
        sub_opt.folder_out = network_folder;
        % Set the provenance folder
        sub_opt.flag_prov = true;
        % Assign inputs
        sfields = {'data', 'model'};
        sub_in = rmfield(files_in, sfields);
        sub_in.data = pipe.(pre_name).files_out;
        sub_out = struct;
        sub_out.subtype = [network_folder filesep sprintf('subtype_%s.mat', net_name)];
        sub_out.provenance = [network_folder filesep sprintf('provenance_%s.mat', net_name)];
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
weight_opt.scales = 1:length(list_net);
weight_opt.folder_out = opt.folder_out;
if ext_sbt
    weight_opt.flag_external = true;
end
weight_out.weights = [opt.folder_out filesep 'subtype_weights.mat'];
pipe = psom_add_job(pipe, 'weight_extraction', 'niak_brick_subtype_weight',...
                    weight_in, weight_out, weight_opt);

% Set up the association test options
if opt.flag_assoc
    for cc = 1:length(list_contrast)
        cont = list_contrast{cc};
        assoc_opt = opt.association.(cont);
        assoc_opt.folder_out = opt.folder_out;
        assoc_in = struct;
        assoc_in.weight = pipe.weight_extraction.files_out.weights;
        assoc_in.model = files_in.model;
        assoc_out = struct;
        assoc_out.stats = [opt.folder_out filesep 'associations' filesep cont filesep 'association_stats_' cont '.mat'];
        assoc_out.csv = [opt.folder_out filesep 'associations' filesep cont filesep 'association_summary_' cont '.csv'];
        pipe = psom_add_job(pipe, ['association_test_' cont], 'niak_brick_association_test',...
                    assoc_in, assoc_out, assoc_opt);
        if opt.association.(cont).flag_visu
            % Generate the figures for the association test brick
            visu_in = struct;
            visu_in.weight = pipe.weight_extraction.files_out.weights;
            visu_in.association = pipe.(['association_test_' cont]).files_out.stats;
            visu_out = struct;
            fields = {'fdr', 'type_fdr', 'interaction', 'normalize_x', 'normalize_y',...
                        'select', 'flag_intercept'};
            visu_opt = rmfield(opt.association.(cont), fields);
            visu_opt.folder_out = [opt.folder_out 'associations' filesep cont filesep];
            visu_opt.data_type = opt.association.(cont).type_visu;
            pipe = psom_add_job(pipe, ['visu_' cont], 'niak_brick_visu_subtype_glm',...
                        visu_in, visu_out, visu_opt);
        end 
    end
end

% Set up the Chi2 and Cramer's V test options
if ~isempty(opt.chi2)
    % Iterate these jobs for each network
    for net_id = 1:length(list_net)
        % Set network and subtype name
        net_name = list_net{net_id};
        sub_name = sprintf('subtype_%s', net_name);
        % Set the root folder to the network name
        network_folder = [opt.folder_out filesep 'networks' filesep net_name];
        chi2_in = struct;
        chi2_in.model = files_in.model;
        chi2_opt.group_col_id = opt.chi2;
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
