function [files_in,files_out,opt] = niak_brick_smooth_vol(files_in,files_out,opt)
% Spatial smoothing of 3D or 3D+t data, using a Gaussian separable kernel
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SMOOTH_VOL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  FILES_IN        
%       (string or cell of string) a file name of a 3D+t dataset. If
%       FILES_IN is a cell of string, the first entry is the file name of a
%       3D+t dataset, while the second entry is used as a binary mask to 
%       correct the edges effects of the smoothing (note that 
%       values outside the mask will be set to zero). This correction will
%       only be applied if OPT.FLAG_EDGE = 1 (see below).
%
%  FILES_OUT       
%       (string, default <BASE FILES_IN>.<EXT>) File name for outputs. 
%       NOTE that if FILES_OUT is an empty string or cell, the name of the 
%       outputs will be the same as the inputs, with a '_s' suffix added 
%       at the end.
%
%  OPT           
%       (structure) with the following fields :
%
%       FWHM  
%           (vector of size [1 3], default 6) the full width at half 
%           maximum of the Gaussian kernel, in each dimension. If fwhm has 
%           length 1, an isotropic kernel is implemented.
%
%       FLAG_SKIP
%           (boolean, default false) if FLAG_SKIP==1, the brick does not do
%           anything, just copy the input on the output. 
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_EDGE
%           (boolean, default 1) if the flag is 1, then a correction is
%           applied for edges effects in the smoothing (such that a volume
%           full of ones is left untouched by the smoothing).
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function prints 
%           some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are generated.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_SMOOTH_VOL, NIAK_DEMO_SMOOTH_VOL
%
% _________________________________________________________________________
% COMMENTS:
% This is essentially a wraper of MINCBLUR. Major differences is that it
% deals with 4D images, and corrects for edges effects in the smoothing.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, smoothing, fMRI

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
niak_gb_vars; % load important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SMOOTH_VOL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_smooth_vol'' for more info.')
end

%% Input file
if iscellstr(files_in)
    file_mask = files_in{2};
    files_in  = files_in{1};
else
    file_mask = 'gb_niak_omitted';
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = { 'flag_edge' , 'fwhm' , 'flag_verbose' , 'flag_test' , 'folder_out' , 'flag_skip' };
gb_list_defaults  = { true        , 6      , 1              , 0           , ''           , 0           };
niak_set_defaults

if length(opt.fwhm) == 1
    opt.fwhm = opt.fwhm * ones([1 3]);
end

if size(opt.fwhm,1)>size(opt.fwhm,2)
    opt.fwhm = opt.fwhm';
end

fwhm = opt.fwhm;

%% Output files
[path_f,name_f,ext_f] = niak_fileparts(files_in);

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

%% Building default output names
if isempty(files_out)

    if size(files_in,1) == 1

        files_out = cat(2,opt.folder_out,filesep,name_f,'_s',ext_f);

    else

        name_filtered_data = cell([size(files_in,1) 1]);

        for num_f = 1:size(files_in,1)
            [path_f,name_f,ext_f] = fileparts(files_in(1,:));

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f] = fileparts(name_f);
            end

            name_filtered_data{num_f} = cat(2,opt.folder_out,filesep,name_f,'_s',ext_f);
        end
        files_out = char(name_filtered_data);

    end
end

if flag_test == 1
    return
end

if (min(opt.fwhm) ~=0) && (flag_skip~=1)

    %% Blurring
    if flag_verbose
        fprintf('Reading data ...\n');
    end

    [hdr,vol] = niak_read_vol(files_in);    
        
    opt_smooth.voxel_size = hdr.info.voxel_size;
    opt_smooth.fwhm = opt.fwhm;
    opt_smooth.flag_verbose = opt.flag_verbose;
    opt_smooth.flag_edge = opt.flag_edge;
    if ~strcmp(file_mask,'gb_niak_omitted')
        [hdr_mask,mask] = niak_read_vol(file_mask);
        opt_smooth.mask = mask>0;
        clear mask
    end
    vol_s = niak_smooth_vol(vol,opt_smooth);                    

    %% Updating the history and saving output
    hdr = hdr(1);
    hdr.file_name = files_out;
    niak_write_vol(hdr,vol_s);

else

    instr_copy = cat(2,'cp ',files_in,' ',files_out);
    
    [status,msg] = system(instr_copy);
    if status~=0
        error(msg)
    end

end