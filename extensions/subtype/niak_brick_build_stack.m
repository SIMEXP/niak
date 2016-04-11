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
%   <SUBJECT>.map
%       (string) Containing the individual map (e.g. rmap_part,stability_maps, etc)
%       NB: assumes there is only 1 .nii.gz or mnc.gz map per individual.
%
% FILES_OUT
%       (string) the full name of .nii.gz/mnc.gz file with the folowing variables
%       
%   MEAN
%   STD
%
% OPT
%       (structure, optional) with the following fields:


%
% SCALE (integer) the number of networks in individual maps
%
% STACK 4D volumes stacking individual maps x N networks + 4D volumes stacking
%   networks for the mean and std across individual maps.
%


%% get file names
path_in = niak_full_path(path_in);
files_in = dir([path_in '*molr*']);
files_in = {files_in.name};
% Create output directory
psom_mkdir(path_out);

% Network 4D volumes with M subjects
for ss = 1:scale
    for ii = 1:length(files_in)
        sub = files_in{ii};
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
