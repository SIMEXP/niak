function [files_in,files_out,opt] = niak_brick_build_stack(files_in,files_out,opt)
% Create network, mean and std stack 4D maps from individual functional maps
%
% SYNTAX:
% [FILE_IN,FILE_OUT,OPT] = NIAK_BRICK_BUILD_STACK(FILE_IN,FILE_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN (structure) with the following fields :
%
%   MAP.<SUBJECT>
%       (string) Containing the individual map (e.g. rmap_part,stability_maps, etc)
%       NB: assumes there is only 1 .nii.gz or mnc.gz map per individual.
%
%   PHENO
%       (strings,Default '') a .csv files coding for the pheno

%
% FILES_OUT (string) the full path for a load_stack.mat file with the folowing variables :
%   
%   STACK_NET_<N> 4D volumes stacking networks for network N across individual maps  
%   MEAN          4D volumes stacking networks for the mean networks across individual maps.
%   STD           4D volumes stacking networks for the std networks across individual maps.
%
% OPT  (structure, optional) with the following fields:
%
%   SCALE (cell of integer,default all networks) A list of networks number 
%   in individual maps
%
%   REGRESS_CONF (Cell of string, Default {}) A liste of variables name to be regressed out.
%   WARNING: subject's ID should be the same as in the csv pheno file.
%   
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
if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_BUILD_STACK(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_build_stack'' for more info.')
end

% Input
if ~isstruct(files_in)
    error('FILES_IN should be a structure. Type "help niak_brick_build_stack" for more info.');
end

% Output
if ~exist('files_out','var')||isempty(files_out)
    files_out = pwd;
end
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

% Options
if nargin < 3
    opt = struct;
end

list_fields   = { 'scale' , 'regress_conf' , 'flag_verbose' , 'flag_test' };
list_defaults = {  {}     ,  {}            ,  true          ,  false      };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

% setup list of networks
if isempty(opt.scale)
   [hdr,vol]=niak_read_vol(files_in.map.(fieldnames(files_in.map){1}))
   list_network =  hdr.info.dimensions(end);
   list_network = [1 : list_network];
else
   list_network = cell2mat(opt.scale);
end
   

% Network 4D volumes with M subjects
for ss = list_network
    for ii = 1:length(files_in.map)
        sub = files_in.map{ii};
        path_vol = [path_in sub];
        [hdr,vol] = niak_read_vol(path_vol);
        stack(:,:,:,ii) = vol(:,:,:,ss);
    end
    hdr.file_name = [path_out 'stack_net_' num2str(ss) '.nii.gz'];
    niak_write_vol(hdr,stack);

    % Mean & std 4D volumes with N networks
    mean_stack(:,:,:,ss) = mean(stack,4);
    std_stack(:,:,:,ss) = std(stack,0,4);
end
hdr.file_name = [path_out 'stack_mean.nii.gz'];
niak_write_vol(hdr,mean_stack);
hdr.file_name = [path_out,'stack_std.nii.gz'];
niak_write_vol(hdr,std_stack);
