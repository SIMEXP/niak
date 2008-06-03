function [files_in,files_out,opt] = niak_brick_smooth_vol(files_in,files_out,opt)

% Spatial smoothing of 3D or 3D+t data, using a Gaussian separable kernel
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN        (string OR cell of string) a file name of a 3D+t dataset OR
%                       a cell of strings where each entry is a file name
%                       of 3D data, all in the same space.
%
% FILES_OUT       (string or cell of strings) File names for outputs. NOTE that
%                       if FILES_OUT is an empty string or cell, the name 
%                       of the outputs will be the same as the inputs, 
%                       with a '_s' suffix added at the end.
%
% OPT           (structure) with the following fields :
%
%               FWHM  (vector of size [3 1], default [4 4 4]) the full width at half maximum of
%                      the Gaussian kernel, in each dimension. If fwhm has length 1,
%                      an isotropic kernel is implemented.
%
%               STEP  (vector of size [3 1] or [4 1], default resolution of 
%                      input files). This parameter usually does not need to be
%                      manually specified, but is rather read from the input 
%                      file. Specification through this file will override 
%                      these values. STEP is the resolution
%                      in the respective dimensions, i.e. the space in mmm
%                      between two voxels in x, y, and z. Note that the unit is
%                      irrelevant and just need to be consistent with
%                      the filter width (fwhm)). The fourth element is
%                      ignored.
%
%               FLAG_ZIP   (boolean, deafult 0) if FLAG_ZIP equals 1, an
%                      attempt will be made to zip the outputs.
%
%               FOLDER_OUT (string, default: path of FILES_IN) If present,
%                      all default outputs will be created in the folder FOLDER_OUT.
%                      The folder needs to be created beforehand.
%
%               FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%                      the function prints some infos during the
%                      processing.
%
%               FLAG_TEST (boolean, default 0) if FLAG_TEST equals 1, the
%                      brick does not do anything but update the default 
%                      values in FILES_IN and FILES_OUT.
%               
% OUTPUTS:
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% SEE ALSO:
% NIAK_SLICE_TIMING, NIAK_DEMO_SLICE_TIMING
%
% COMMENTS
%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SMOOTH_VOL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_smooth_vol'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'fwhm','voxel_size','flag_verbose','flag_test','folder_out','flag_zip'};
gb_list_defaults = {[4 4 4],[],1,0,'',0};
niak_set_defaults

%% Output files

[path_f,name_f,ext_f] = fileparts(files_in(1,:));
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

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

%% Blurring

if flag_verbose
    fprintf('Reading data ...\n');
end

[hdr,vol] = niak_read_vol(files_in);

file_vol_tmp = niak_file_tmp('_vol.mnc');
file_vol_tmp_s = niak_file_tmp('_blur.mnc');
instr_smooth = cat(2,'mincblur -fwhm ',num2str(opt.fwhm),' -no_apodize -clobber ',file_vol_tmp,' ',file_vol_tmp_s(1:end-9));

if flag_verbose
    fprintf('Smoothing volume :');
end

for num_v = 1:size(vol,4)
    if flag_verbose
        fprintf('%i ',num_v);
    end
    hdr.file_name = file_vol_tmp;
    niak_write_vol(hdr,vol(:,:,:,num_v));
    [succ,msg] = system(instr_smooth);
    if succ~=0
        error(msg)
    end
    [hdr_tmp,tmp] = niak_read_vol(file_vol_tmp_s);
    vol(:,:,:,num_v) = tmp;
end

if flag_verbose
    fprintf('\n');
end

delete(file_vol_tmp);
delete(file_vol_tmp_s);
    
%% Updating the history and saving output
hdr = hdr(1);
hdr.flag_zip = flag_zip;
hdr.file_name = files_out;
opt_hist.command = 'niak_smooth_vol';
opt_hist.files_in = files_in;
opt_hist.files_out = files_out;
hdr = niak_set_history(hdr,opt_hist);
niak_write_vol(hdr,vol);
