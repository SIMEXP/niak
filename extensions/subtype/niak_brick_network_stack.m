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
%       (strings,Default '') a .csv files coding for the pheno
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
%   SCALE 
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

list_fields   = { 'scale' , 'regress_conf' , 'flag_verbose' , 'flag_test' };
list_defaults = { []      , {}             , true           , false       };
opt = psom_struct_defaults(opt, list_fields, list_defaults);


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

% Check how many files we have to read
in_names = fieldnames(files_in.data);
n_input = length(in_names);

% Pre-allocate the output matrix. If we have more than one network, we'll
% repmat it
stack = zeros(n_input, n_vox);

% Iterate over the input files
for in_id = 1:n_input
    % Get the name for the input field we need
    in_name = in_names{in_id};
    % Load the corresponding path
    [~, vol] = niak_read_vol(files_in.data.(in_name));
    
    % If this is the first iteration and scale is empty, set it to the
    % number of networks in this file (we'll check that they are all the
    % same across subjects)
    if in_id == 1 && isempty(opt.scale)
        n_nets = size(vol, 4);
        opt.scale = 1:n_nets;
        % Pre-allocate the stack variable as needed
        stack = repmat(stack, [1, 1, n_nets]);
    end
    
    % Loop through the networks and mask the thing
    for net_id = 1:length(opt.scale)
        % Get the correct network number
        net = opt.scale(net_id);
        % Mask the volume
        masked_vol = niak_vol2tseries(vol(:, :, :, net), mask);
        % Save the masked array into the stack variable
        stack(in_id, :, net_id) = masked_vol;
    end
end


%% Regress confounds


% Save the stack matrix
stack_file = fullfile(files_out, 'stack_file.mat');
save(stack_file, 'stack');