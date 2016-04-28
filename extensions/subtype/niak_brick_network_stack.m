function [files_in,files_out,opt] = niak_brick_network_stack(files_in, files_out, opt)
% Create network, mean and std stack 4D maps from individual functional maps
%
% SYNTAX:
% [FILE_IN,FILE_OUT,OPT] = NIAK_BRICK_network_stack(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN (structure) with the following fields :
%
%   DATA.<SUBJECT>
%       (string) Containing the individual map (e.g. rmap_part,stability_maps, etc)
%       NB: assumes there is only 1 .nii.gz or mnc.gz map per individual.
%
%   MASK
%       (3D volume) a binary mask of the voxels that will be included in the 
%       time*space array.
%
%   MODEL
%       (strings,Default '') a .csv files coding for the pheno data. Is
%       expected to have a header and a first column specifying the case
%       IDs/names corresponding to the data in FILES_IN.DATA
%
%
% FILES_OUT (string) the full path for a load_stack.mat file with the folowing variables :
%   
%   STACK_NET_<N> 4D volumes stacking networks for network N across individual maps  
%   MEAN_NET_<N>  4D volumes stacking networks for the mean networks across individual maps.
%   STD_NET_<N>   4D volumes stacking networks for the std networks across individual maps.
%
% OPT  (structure, optional) with the following fields:
%
%   NETWORK 
%       (int array, default all networks) A list of networks number in 
%       individual maps
%
%   REGRESS_CONF 
%       (Cell of string, Default {}) A list of variables name to be regressed out.
%
%   FLAG_CONF
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
%           (structure, optional) Only available if OPT.FLAG_CONF is set 
%           to true and a correct model was supplied. Contains the
%           following fields:
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NETWORK_STACK(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_network_stack'' for more info.')
end

% FILES_IN
list_fields   = { 'data' , 'mask' , 'model'           };
list_defaults = { NaN    , NaN    , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string');
elseif isempty(files_out)
    files_out = pwd;
end

% Options
if nargin < 3
    opt = struct;
end

list_fields   = { 'network' , 'regress_conf' , 'flag_verbose' , 'flag_conf' , 'flag_test' };
list_defaults = { []      , {}             , true           , true        , false       };
opt = psom_struct_defaults(opt, list_fields, list_defaults);

% Get the model and check if there are any NaNs in the factors to be
% regressed
[conf_model, ~, cat_names, ~] = niak_read_csv(files_in.model);
n_conf = length(opt.regress_conf);
conf_ids = zeros(n_conf, 1);
% Go through the confound cell array and find the indices
for cid = 1:n_conf
    conf_name = opt.regress_conf{cid};
    cidx = find(strcmp(cat_names, conf_name));
    % Make sure we found the covariate
    if ~isempty(cidx)
        conf_ids(cid) = cidx;
    else
        error('Could not find column for %s in %s', conf_name, files_in.model);
    end
    % Make sure there are no NaNs in the model
    if any(isnan(conf_model(:, cidx)))
        % Get the indices of the subjects
        missing = find(isnan(conf_model(:, cidx)));
        % Matlab error messages only allow for the double to iterate. Not
        % sure how we could tell them both the subject ID and the confound
        % name
        error('Subject #%d has missing data for one or more confounds. Please fix.\n', missing);
    end
end
 
% Check the first subject file and see how many networks we have
subject_list = fieldnames(files_in.data);
n_input = length(subject_list);
[~, vol] = niak_read_vol(files_in.data.(subject_list{1}));
scale = size(vol, 4);
% If no scale has been supplied, use all networks
if isempty(opt.network)
    opt.network = 1:scale;
% Make sure all networks are there
elseif max(opt.network) > scale
    error(['You requested networks up to #%d to be investigated '...
           'but the specified input only has %d networks'], max(opt.network), scale);
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Brick starts here
% Read the mask
[~, mask] = niak_read_vol(files_in.mask);
% Turn the mask into a boolean array
mask = logical(mask);
% Get the number of non-zero voxels in the mask
n_vox = sum(mask(:));
% Get the number of scales
n_scales = length(opt.network);

% Pre-allocate the output matrix. If we have more than one network, we'll
% repmat it
raw_stack = zeros(n_input, n_vox, n_scales);

% Iterate over the input files
for in_id = 1:n_input
    % Get the name for the input field we need
    in_name = subject_list{in_id};
    % Load the corresponding path
    [~, vol] = niak_read_vol(files_in.data.(in_name));
    
    % Loop through the networks and mask the thing
    for net_id = 1:length(opt.network)
        % Get the correct network number
        net = opt.network(net_id);
        % Mask the volume
        masked_vol = niak_vol2tseries(vol(:, :, :, net), mask);
        % Save the masked array into the stack variablne
        raw_stack(in_id, :, net_id) = masked_vol;
    end
end

%% Regress confounds
% Set up the model structure for the regression
opt_mod = struct;
opt_mod.flag_residuals = true;
m = struct;
m.x = conf_model(:, conf_ids);

conf_stack = zeros(n_input, n_vox, n_scales);

% Loop through the networks again for the regression
for net_id = 1:length(opt.network)
    % Get the correct network
    m.y = raw_stack(:, :, net_id);
    [res] = niak_glm(m, opt_mod);
    % Store the residuals in the confound stack
    conf_stack(:, :, net_id) = res.e;
end

%% Build the outputs
% Decide which of the two stacks to save
if opt.flag_conf
    stack = conf_stack;
else
    stack = raw_stack;
end

% Build the provenance data
provenance = struct;
% Get the subjects
provenance.subjects = cell(n_input, 2);
% First column are the input field names
provenance.subjects(:, 1) = subject_list;
% Second column is so far undefined

% Add the model information
provenance.model = struct;
provenance.model.matrix = m.x;
provenance.model.confounds = opt.regress_conf;

% Add the volume information
provenance.volume.network = opt.network;
% Store the scale of the prior networks
provenance.volume.scale = scale;
% Save the brain mask to map the data back into volume space
provenance.volume.mask = mask;
% Region mask is missing so far

% Define the output name
stack_file = fullfile(files_out, 'network_stack.mat');

% Save the stack matrix
save(stack_file, 'stack', 'provenance');