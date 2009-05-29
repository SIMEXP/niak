function [files_in,files_out,opt] = niak_brick_4d_to_3d(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_4D_TO_3D
%
% Extract volumes from a 4D file and generates multiple 3D volume files
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_4D_TO_3D(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN  
%       (string) a 4D dataset
%
%  * FILES_OUT 
%       (cell of strings, default <BASE NAME INPUT>_<NUM COMP>.<EXT>)
%       Each entry is the file name for a 3D dataset.
%
%  * OPT   
%       (structure) with the following fields :
%
%       LIST 
%           (vector, default all) the list of volume to extract from the 4D 
%           data. Volumes are numbered from 1 to the number of volumes.
%
%       FLAG_CORRECT 
%           (boolean, default 0) If this flag is true (1), a mask
%           will be extracted from the 4D dataset using NIAK_BRAIN_MASK, and
%           the distribution for each volume within the mask will be asjusted
%           to zero mean and unit variance using robust estimates (see
%           NIAK_CORRECT_VOL).
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
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
% COMMENTS
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

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

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_4D_TO_3D(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_3d_to_4d'' for more info.')
end

if ~exist('files_out','var')
    files_out = '';
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'list','flag_correct','flag_test','folder_out'};
gb_list_defaults = {[],0,0,''};
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in(1,:));
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

%% Reading the header of the input file for updating the output
hdr = niak_read_vol(files_in);
if isempty(opt.list)
    if length(hdr.info.dimensions)>3
        opt.list = 1:hdr.info.dimensions(4);
    else
        opt.list = 1;
    end
end

%% Files out
if ~iscell(files_out)
    if ~isempty(files_out)
        error('Files out should be a cell of strings. See the help for more info')
    else
        files_out = cell(0);
        for num_c = opt.list
            lab_vol = [repmat('0',[1 4-length(num2str(num_c))]) num2str(num_c)];
            files_out{num_c} = cat(2,opt.folder_out,filesep,name_f,'_',lab_vol,ext_f);
        end
    end
end
        
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% Extracting volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%

[hdr,vol] = niak_read_vol(files_in);

if flag_correct
    mask = niak_mask_brain(mean(abs(vol),4));
end

for num_c = opt.list
    hdr.file_name = files_out{num_c};

    if flag_correct
        vol_write = niak_correct_vol(vol(:,:,:,num_c),mask);
    else
        vol_write = vol(:,:,:,num_c);
    end
    
    niak_write_vol(hdr,vol_write);
    
end
