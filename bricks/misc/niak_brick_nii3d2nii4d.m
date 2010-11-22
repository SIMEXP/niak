function [files_in,files_out,opt] = niak_brick_nii3d2nii4d(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_NII3D2NII4D
%
% Convert a bunch of nifti 3d volumes into one 4d nifti file.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NII3D2NII4D(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN
%       (string or cell of strings) FILES_IN{N} is the Nth 3D volume to be
%       included in the 4D file. Note that a string with wildcards can also
%       be used, e.g. 'my_file_*.img'. See the COMMENTS section below.
%
%  * FILES_OUT
%       (string) the name of the output 4D nifti file
%
%  * OPT
%       (structure) with the following fields :
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1
%
% Wild cards '*' for the input files are supported. The following example :
% >> niak_brick_nii3d2nii4d('my_fmri_*.img','my_fmri_4d.nii')
%
% Will convert all files 'my_fmri_0001.img', 'my_fmri_0002.img', ... into
% one single 4D nifti volume called 'my_fmri_4d.nii'. 
%
% NOTE 2
%
% All the 3D volumes need to be in the same space (both at the voxel and 
% world levels). The header of the first volume will actually be used to
% generate the 4D volume.
%
%
% NOTE 3
%
% To zip the output, the output file should end with 'nii.gz' instead of
% '.nii'.  The tool used to zip files is 'gzip'. This behavior can be 
% changed by editing the variables GB_NIAK_ZIP_EXT and GB_NIAK_UNZIP in the 
% file NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : niak, nifti, conversion, 4D

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

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NII3D2NII4D(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_nii3D2nii4d'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_verbose','flag_test'};
gb_list_defaults = {true,false};
niak_set_defaults

if ischar(files_in)
    list_files_tmp = dir(files_in);
    mask_dir = [list_files_tmp(:).isdir];
    files_in = {list_files_tmp(~mask_dir).name};
end

if flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading volume header %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Reading volume header from %s\n',files_in{1});
end
hdr = niak_read_vol(files_in{1});
hdr_out = hdr;
hdr_out.type = 'nii';

%%%%%%%%%%%%%%%%%%%%%%%%
%% Processing volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%

vol_out = zeros([hdr.info.dimensions(1:3) length(files_in)],'single');
if flag_verbose
    fprintf('Processing volume :\n')
end

for num_v = 1:length(files_in)
    if flag_verbose
        fprintf('   %i : %s\n',num_v,files_in{num_v});
    end
    [hdr,vol] = niak_read_vol(files_in{num_v});
    vol_out(:,:,:,num_v) = single(vol);
end

%%%%%%%%%%%%%%%%%%%%%
%% Writting output %%
%%%%%%%%%%%%%%%%%%%%%
hdr_out.file_name = files_out;
niak_write_vol(hdr_out,vol_out);