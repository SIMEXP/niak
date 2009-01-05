function [files_in,files_out,opt] = niak_brick_mask_brain(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MASK_BRAIN
%
% Derive brain masks in multiple fMRI datasets, and combine them into a
% group mask.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (cell of strings) each entry is a file name of a 3D+t dataset. All
%       datasets need to be in the same space (either one individual, or
%       stereotaxic space).
%
%  * FILES_OUT       
%       (structure) with the following entries (if a field is absent, the 
%       corresponding output will not be generated, empty field will be 
%       replaced by a default name when possible) :
%       
%       GROUP_MASK
%           (string) The group binary mask.
%
%       MEAN_MASK
%           (string) the average of all masks
%
%       INDIVIDUAL_MASK
%           (cell of strings, default <path of FILES_IN{I}>_mask.<EXT>) 
%           IND_MASK{I} is the binary mask of FILES_IN{I}.
%   
%  * OPT           
%       (structure) with the following fields.  
%
%       FWHM 
%           (real value, default 3) the FWHM of the blurring kernel in 
%           the same unit as the voxel size. A value of 0 for FWHM will 
%           skip the smoothing step.
%       
%       VOXEL_SIZE 
%           (vector of size [3 1] or [4 1], default : read the header) the 
%           resolution in the respective dimensions, i.e. the space in mmm
%           between two voxels in x, y, and z (yet the unit is
%           irrelevant and just need to be consistent with
%           the filter width (fwhm)). The fourth element is ignored.
%
%       FLAG_REMOVE_EYES 
%           (boolean, default 0) if FLAG_REMOVE_EYES == 1, an
%           attempt is done to remove the eyes from the mask.
%           
%       THRESH_MEAN
%           (scalar, default 1) the threshold that is applied on the
%           average mask to define the group mask.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN{I} for INDIVIDUAL_MASK{I}) 
%           If present, all default outputs will be created in the folder 
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
% NIAK_MASK_BRAIN
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

niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_BRAIN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_brain'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'fwhm','voxel_size','flag_remove_eyes','thresh_mean','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {6,[],0,1,true,false,''};
niak_set_defaults

%% Files out
gb_name_structure = 'files_out';
gb_list_fields = {'mask_group','mask_mean','mask_individual'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Output files
nb_files = length(files_in);

if strcmp(opt.folder_out,'')
    flag_folder = true;
else
    flag_folder = false;
end

if isempty(files_out.mask_individual)
    
    files_out.mask_individual = cell([nb_files 1]);
    
    for num_f = 1:nb_files
        [path_f,name_f,ext_f] = fileparts(files_in{num_f});
        if isempty(path_f)
            path_f = '.';
        end

        if strcmp(ext_f,gb_niak_zip_ext)
            [tmp,name_f,ext_f] = fileparts(name_f);
            ext_f = cat(2,ext_f,gb_niak_zip_ext);
        end
        
        if flag_folder
           opt.folder_out = path_f;
        end
        
        files_out.mask_individual{num_f} = [opt.folder_out name_f,'_mask',ext_f];
    end
    
end


%% Building default output names
if isempty(files_out)

    if size(files_in,1) == 1

        files_out = cat(2,opt.folder_out,filesep,name_f,'_a',ext_f);

    else

        name_filtered_data = cell([size(files_in,1) 1]);

        for num_f = 1:size(files_in,1)
            [path_f,name_f,ext_f] = fileparts(files_in(num_f,:));

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f] = fileparts(name_f);
            end
            
            name_filtered_data{num_f} = cat(2,opt.folder_out,filesep,name_f,'_a',ext_f);
        end
        files_out = char(name_filtered_data);

    end
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

opt_mask.flag_remove_eyes = opt.flag_remove_eyes;
opt_mask.fwhm = opt.fwhm;

for num_f = 1:nb_files
    
    if flag_verbose
        fprintf('Masking brain in data %s ...\n',files_in{num_f});
    end
    [hdr,vol] = niak_read_vol(files_in{num_f});
    if num_f == 1
        hdr_func = hdr;
        if isempty(opt.voxel_size)
            opt_mask.voxel_size = hdr_func.info.voxel_size;
        end
        mask_all = zeros([hdr_func.info.dimensions(1:3) nb_files]);
    end

    mask_all(:,:,:,num_f) = niak_mask_brain(max(abs(vol),[],4),opt_mask);

end

%% Group mask
if flag_verbose
    fprintf('Deriving group mask ...\n');
end

mask_mean = mean(mask_all,4);
mask_group = mask_mean>=opt.thresh_mean;

%% Saving outputs

if ~strcmp(files_out.mask_group,'gb_niak_omitted')
    hdr_func.file_name = files_out.mask_group;
    niak_write_vol(hdr_func,mask_group);
end

if ~strcmp(files_out.mask_mean,'gb_niak_omitted')
    hdr_func.file_name = files_out.mask_mean;
    niak_write_vol(hdr_func,mask_mean);
end

if ~ischar(files_out.mask_individual)
    for num_f = 1:nb_files
        hdr_func.file_name = files_out.mask_individual{num_f};
        niak_write_vol(hdr_func,squeeze(mask_all(:,:,:,num_f)));
    end
end
