function [files_in,files_out,opt] = niak_brick_mask_brain(files_in,files_out,opt)
% Derive a brain mask from one fMRI dataset
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (cell of string) multiple file names 3D+t dataset in the same
%       space.
%
%  * FILES_OUT   
%       (structure) with the following fields : 
%   
%       MASK_AVERAGE
%           (string, default <path of FILES_IN{1}>_mask_average.<EXT>) 
%           the average of binary mask of the brain for all files in 
%           FILES_IN.
%
%       MASK_GROUP
%           (string, default <path of FILES_IN{1}>_mask.<EXT>) 
%           A binary version of MASK_AVERAGE after a threshold has been
%           applied.
%
%       MEAN_AVERAGE
%           (string, default <path of FILES_IN{1}>_mean.<EXT>) 
%           the average of the mean volumes for all files in 
%           FILES_IN.
%
%       STD_AVERAGE
%           (string, default <path of FILES_IN{1}>_mean.<EXT>) 
%           the average of the std volumes for all files in 
%           FILES_IN.
%
%       MASK_GROUP
%           (string, default <path of FILES_IN{1}>_mask.<EXT>) 
%           A binary version of MASK_AVERAGE after a threshold has been
%           applied.
%
%       TAB_FIT
%           (string, default <path of FILES_IN{1}>_mask_fit.dat)
%           A text table. First line is a lable ('fit_to_group_mask'), and
%           subsequent lines are for each entry of FILES_IN. The score is
%           the relative overlap between the individual mask and the group
%           mask. This is useful to identify subjects/runs that have been
%           poorly coregistered.
%   
%  * OPT           
%       (structure) with the following fields.  
%
%       THRESH
%           (real number, default 0.5) the threshold used to define a group 
%           mask based on the average of all individual masks.
%
%       FLAG_IS_MASK
%           (boolean, default 0) if FLAG_IS_MASK is true, the data in
%           FILES_IN is assumed to be a binary mask.
%
%       FWHM 
%           (real value, default 3) the FWHM of the blurring kernel in 
%           the same unit as the voxel size. A value of 0 for FWHM will 
%           skip the smoothing step.
%       
%       FLAG_REMOVE_EYES 
%           (boolean, default 0) if FLAG_REMOVE_EYES == 1, an
%           attempt is done to remove the eyes from the mask.
%           
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) 
%           If present, the output will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_MASK_BRAIN, NIAK_PIPELINE_MASK_BRAIN
%
% _________________________________________________________________________
% COMMENTS
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_brain'' for more info.')
end

%% FILES_IN
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of string');
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'mean_average','std_average','mask_average','mask','tab_fit'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','','gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'thresh','flag_is_mask','fwhm','flag_remove_eyes','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {0.5,false,6,0,true,false,''};
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in{1});
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.mask)
    files_out.mask = [opt.folder_out name_f,'_mask',ext_f];
end

if isempty(files_out.mask_average)
    files_out.mask_average = [opt.folder_out name_f,'_mask_averaged',ext_f];
end

if isempty(files_out.mean_average)
    files_out.mean_average = [opt.folder_out name_f,'_mean',ext_f];
end

if isempty(files_out.std_average)
    files_out.std_average = [opt.folder_out name_f,'_std',ext_f];
end

if isempty(files_out.tab_fit)
    files_out.tab_fit = [opt.folder_out name_f,'_mask_fit.dat'];
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Masking individual data
opt_mask.flag_remove_eyes = opt.flag_remove_eyes;
opt_mask.fwhm = opt.fwhm;
if flag_verbose
    fprintf('Masking brain ...\n');
end

for num_f = 1:length(files_in)
    if flag_verbose
        fprintf('   File %s ...\n',files_in{num_f});
    end
    [hdr,vol] = niak_read_vol(files_in{num_f});
    opt_mask.voxel_size = hdr.info.voxel_size;
    if flag_is_mask
        mask = vol;
    else
        mask = niak_mask_brain(vol,opt_mask);
    end
    if num_f == 1
        mask_avg = double(mask);
        
        if ~strcmp(files_out.tab_fit,'gb_niak_omitted')
            mask_list = false([size(mask) length(files_in)]);
            mean_list = zeros([size(mask) length(files_in)]);
        end

        mean_avg = zeros(size(mask));
        std_avg = zeros(size(mask));
    else
        mask_avg = mask_avg + double(mask);
    end
    
    mean_vol = mean(vol,4);
    mean_avg = mean_avg + mean_vol;
    
    if ~strcmp(files_out.tab_fit,'gb_niak_omitted')
        mask_list(:,:,:,num_f) = mask;
        mean_list(:,:,:,num_f) = mean_vol;
    end

    std_avg = std_avg + std(vol,[],4);

end

mask_avg = mask_avg/length(files_in);
mean_avg = mean_avg/length(files_in);
std_avg = std_avg/length(files_in);
mask_all = mask_avg>=opt.thresh;


%% Compute score of fit
if ~strcmp(files_out.tab_fit,'gb_niak_omitted')
    tab_fit = zeros([length(files_in) 3]);
    mask_v = mask_all(:);
    mean_v = mean_avg(mask_all);
    size_g = sum(mask_v);
    for num_f = 1:length(files_in)
        mask_f = mask_list(:,:,:,num_f);
        mean_f = mean_list(:,:,:,num_f);
        mean_f = mean_f(mask_all);
        tab_fit(num_f,1) = sum(mask_v&mask_f(:))/sum(mask_f(:));
        tab_fit(num_f,2) = sum(mask_v&mask_f(:))/size_g;
        rmean = corrcoef(mean_v,mean_f);
        tab_fit(num_f,3) = rmean(1,2);
    end
end

%% Saving outputs
if ~strcmp(files_out.mask,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the mask in the file %s ...\n',files_out.mask);
    end
    hdr.file_name = files_out.mask;
    niak_write_vol(hdr,mask_all);
end

if ~strcmp(files_out.mask_average,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average mask in the file %s ...\n',files_out.mask_average);
    end
    hdr.file_name = files_out.mask_average;
    niak_write_vol(hdr,mask_avg);
end

if ~strcmp(files_out.mean_average,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average mean volume in the file %s ...\n',files_out.mean_average);
    end
    hdr.file_name = files_out.mean_average;
    niak_write_vol(hdr,mean_avg);
end

if ~strcmp(files_out.std_average,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average std volume in the file %s ...\n',files_out.std_average);
    end
    hdr.file_name = files_out.std_average;
    niak_write_vol(hdr,std_avg);
end

if ~strcmp(files_out.tab_fit,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the scores of fit in the file %s ...\n',files_out.tab_fit);
    end    
    niak_write_tab(files_out.tab_fit,tab_fit,files_in,{'fit_mask_ind_to_group','fit_mask_group_to_ind','fit_mean_in_mask'});
end