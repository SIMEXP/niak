function [files_in,files_out,opt] = niak_brick_association_test(files_in, files_out, opt)
% Create network, mean and std stack 4D maps from individual functional
% maps
%
% SYNTAX: [FILE_IN,FILE_OUT,OPT] =
% NIAK_BRICK_network_stack(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   WEIGHT
%       (string) path to a weight matrix. First column expected to be
%       subjects ordered the same way as in the MODEL
%
%   MODEL
%       (string) a .csv files coding for the
%       pheno data. Is expected to have a header and a first column
%       specifying the case IDs/names corresponding to the data in
%       FILES_IN.DATA
%
%
%   
%
% FILES_OUT
%   (string, default 'network_stack.mat') absolute path to the output .mat
%   file containing the subject by voxel by network stack array.
%
% OPT
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   NETWORK
%       (int array, default all networks) A list of networks number in
%       individual maps
%
%   TEST_NAME
%       (string) the name of the current analysis
%
%   INTERACTION.<LABEL>
%       (cell array, optional) subfields denote interactions to be generated
%       the brick. The new interaction will have the same name as the
%       subfield (<LABEL>).
%
%       (cell of string) covariates that are being multiplied together
%       to build the interaction covariate.
%   
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT (structure)with the following fields:
%
%   STACK
%       (double array) SxVxN array where S is the number of subjects, V is
%       the number of voxels and N the number of networks (if N=1, Matlab
%       displays the array as 2 dimensional, i.e. the last dimension gets
%       squeezed)
%
%   PROVENANCE
%       (structure) with the following fields:
%
%       SUBJECTS
%           (cell array) Sx2 cell array containing the names/IDs of
%           subjects in the same order as they are supplied in
%           FILES_IN.DATA and FILES_OUT.STACK. The first column contains
%           the names as they are suppiled in FILES_IN.DATA whereas the
%           second column contains the (optional) names that are taken from
%           the model file in FILES_IN.MODEL
%
%       MODEL
%           (structure, optional) Only available if OPT.FLAG_CONF is set to
%           true and a correct model was supplied. Contains the following
%           fields:
%
%           MATRIX
%               (double array, optional) Contains the model matrix that was
%               used to perform the confound regression.
%
%           CONFOUNDS
%               (cell array, optional) Contains the names of the covariates
%               in the model that are regressed from the input data
%
%       VOLUME
%           (structure) with the following fields:
%
%           NETWORK
%               (double array) Contains the network ID or IDs in the same
%               order that they appear in FILES_OUT.STACK
%
%           SCALE
%               (double) The scale of the network solution of the input
%               data (i.e. how many networks were available in the input
%               data).
%
%           MASK
%               (boolean array) The binary brain mask that can be used to
%               map the vectorized data in FILES_OUT.STACK back into volume
%               space.
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.


%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ASSOCIATION_TEST(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_association_test'' for more info.')
end

% FILES_IN
files_in = psom_struct_defaults(files_in,...
           { 'weight' , 'model' },...
           { NaN      , NaN     });

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'network' , 'interaction'  , 'flag_verbose' , 'flag_conf' , 'flag_test' },...
      { ''           , []        , struct         , true           , true        , false       });

% Check the output specification
if isempty(files_out) && ~strcmp(files_out, 'gb_niak_omitted')
    if isempty(opt.folder_out)
        error('Neither FILES_OUT nor OPT.FOLDER_OUT are specified. Won''t generate any outputs');
    else
        files_out = [niak_full_path(opt.folder_out) 'network_stack.mat'];
    end
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read and prepare the group model
if opt.flag_verbose
    fprintf('Reading the group model ...\n');
end

% Read the model file and store it in the internal structure
[model_data, ~, cov_labels] = niak_read_csv(files_in.model);
model.x = model_data(:, 2:end);
model.labels_x = model_data(:, 1);
model.labels_y = cov_labels(2:end);

if ~isempty(fieldnames(opt.interaction))
    % Add the interactions
    model = make_interaction(model, opt.interaction);
end

% Choose the subjects that go in the model
opt_model.labels_y = {'Age', 'FD'};
[labels, ind, model_select] = niak_model_select(model, opt_model);

% Normalize the model (X/Y)
index = find(cellfun('length',regexp(C,'B')) == 1);

% Fit the model


% Compute the post hoc contrasts


% Run FDR on the p-values


% Create figures and volumes



% choosing the subjects of the model


% Need to setup interactions
int

% need to normalize the model
norm

% fit the model
fit

%post hoc tests
post hoc

% fdr correction
fdr










%% Check which subjects will be included in the analysis based on test specifications
opt_sel.select = opt.test.(test).select;
opt_sel.flag_filter_nan = true;
opt_sel.labels_x = fieldnames(files_in.connectome);
opt_sel.labels_y = fieldnames(opt.test.(test).contrast);
[list_subject, ind_s] = niak_model_select(model_csv,opt_sel);

% Subfunctions
function model = make_interaction(model, interaction)
    % Updates the model file with a new interaction. 
    %
    % MODEL is a structure expected to contain the subfields:
    %   X (array) the model data
    %   LABELS_Y (cell array) the labels corresponding to the covariates in
    %   the model
    %
    % INTERACTION is a structure expected to contain the subfields:
    %   <LABEL>(cell array) subfield name corresponds to the name of the
    %   interaction variable. The cell array contains the covariates that
    %   are supposed to enter the corresponding interaction.
    interaction_list = fieldnames(interaction);
    n_interact = length(interaction_list);

    % Iterate over the requested interactions
    for int_id = 1:n_interact
       % Get the name of the interaction
       int_name = interaction_list{int_id};
       % Get the names of the variables to combine
       int_factors = interaction.(int_name);
       n_factors = length(int_factors);
       % Find the indices of these factors
       cov_index = zeros(n_factors, 1);
       for fac_id = 1:n_factors
          cov_index(fac_id) = find(strcmp([model.labels_y], int_factors{fac_id}));
       end
       % Get the slice of the model that corresponds to these factors and
       % multiply the elements columnwise
       int_prod = prod(model.x(:, cov_index),2);
       % Add the interaction to the model
       model.x(:, end+1) = int_prod;
       model.labels_y{end+1} = int_name;
    end
return