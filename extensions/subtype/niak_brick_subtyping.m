function [files_in,files_out,opt] = niak_brick_subtyping(files_in,files_out,opt)
% Build subtypes
% 
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT)
% _________________________________________________________________________
% 
% INPUTS:
% 
% FILES_IN 
%       (structure) with the following fields:
%
%   DATA (string) path to a .mat file containing an array (#subjects x
%   #voxels OR vertices OR regions) generated from subtype_preprocessing
%
%   HIER
%       (string) path to a .mat file containing a variable HIER which is a
%       2D array defining a hierarchy on a similarity matrix
%
%   MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       are included in the time*space array
% 
% FILES_OUT 
%       (string, optional) path for results (default pwd)
% 
% OPT 
%       (structure) with the following fields:
%
%   NB_SUBTYPE
%       (integer, default 2) the number of desired subtypes
%
% % %   MASK (vector  1 x nb of voxels) a binary mask of voxels of interest. 
% % %       Only these voxels will be used for subtyping, although maps will be 
% % %       generated full brain. By default all voxels will be used.
% 
%   FLAG_VERBOSE
%       (boolean, optional, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, optional, default false) if the flag is true, the brick does not do 
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% % % % % % % % .mat file
% % % % % % % % % % PART
% % % % % % % %       (array 1 x #subjects) the partition of subjects into subgroups
% % % % % % % % % % hier
% % % % % % % % % % stats (ex. cramer v, chi2)
%%%%%%%%%%%%%%%% DIFF MAP  (vol)
%%%%%%%%%%%%%%%% AVERAGE SUBTYPE MAP (vol)
%%%%%%%%%%%%%%%% CHI2 .png
%%%%%%%%%%%%%%%% 

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtyping'' for more info.')
end

% Input
list_fields   = { 'data' , 'hier' , 'mask' };
list_defaults = { NaN    , NaN    , NaN    };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

% Output
if ~exist('files_out','var')||isempty(files_out)
    files_out = pwd;
end
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end
if exist('files_out','var')
    psom_mkdir(files_out);
end

% Options
if nargin == 1
    opt = struct;
end

list_fields   = { 'nb_subtype', 'flag_verbose' , 'flag_test' };
list_defaults = { 2           , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Load the data
data = load(files_in.data);

% Load the hierarchy
hier = load(files_in.hier);

% Read the mask
[hdr,mask] = niak_read_vol(files_in.mask);

%% Build the clusters by thresholding the hiearchy by the number of subtypes
part = niak_threshold_hierarchy(hier.hier,struct('thresh',opt.nb_subtype));

%% Build subtype maps

% Generating and writing the mean subtype maps in a single volume
sub.mean = zeros(max(part),size(data.data,2));
for ss = 1:max(part)
    sub.mean(ss,:) = mean(data.data(part==ss,:),1);
end
vol_mean_sub = niak_tseries2vol(sub.mean,mask);
file_name = 'mean_subtype.nii.gz';
hdr.file_name = fullfile(files_out, file_name);
niak_write_vol(hdr,vol_mean_sub);
    


%     sub.median(ss,:) = median(data.data(part==ss,:),1);
%     vol_median_sub = niak_tseries2vol(sub.median,mask);
%     hdr.file_name = [files_out filesep 'median_subtype_' num2str(ss) '.nii.gz'];
%     niak_write_vol(hdr,vol_median_sub);
%     
% %     m_sub = mean(sub.map(ss,mask),2);
% %     s_sub = std(sub.map(ss,mask),[],2);
% %     sub.map(ss,:) = (sub.map(ss,:)-m_sub)/s_sub;
%     sub.ttest(ss,:) = niak_ttest(data.data(part==ss,:),data.data(part~=ss,:),true);
%     vol_ttest_sub = niak_tseries2vol(sub.ttest,mask);
%     hdr.file_name = [files_out filesep 'ttest_subtype_' num2str(ss) '.nii.gz'];
%     niak_write_vol(hdr,vol_ttest_sub);
end








