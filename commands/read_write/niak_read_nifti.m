function [hdr,vol] = niak_read_nifti(file_name)
% Read a NIFTI file (.NII or .IMG).
% The old Analyze 7.5 is also supported, and if a .MAT file is present, the
% affine transformation information will be included.
% http://nifti.nimh.nih.gov/nifti-1
%
% SYNTAX:
% [HDR,VOL] = NIAK_READ_NIFTI(FILE_NAME)
%
% _________________________________________________________________________
% INPUT:
%
% FILE_NAME         
%    (string) a 3D+t or 3D minc file.
%
% _________________________________________________________________________
% OUTPUT:
%
% VOL           
%    (3D+t or 3D array of double) the fMRI or MRI data.
%
% HDR           
%    a structure containing a description of the data. See NIAK_READ_VOL 
%    and NIAK_READ_HDR_NIFTI for details.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_READ_HDR_NIFTI, NIAK_WRITE_NIFTI, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% _________________________________________________________________________
% COMMENTS:
%
% In case of multiple files data (e.g. .IMG + .HDR, or .IMG + .HDR + .MAT),
% specify the name using the .IMG extension only.
%
% One may assume that the affine transformation brings the data into
% (Left-Right, Posterior-Anterior, Inferior-Superior) order (this is a 
% NIFTI requirement).
%
% Part of this file is copied and modified under GNU license from
% MRI_TOOLBOX developed by CNSP in Flinders University, Australia
%
% Important parts of this code are copied and modified from a matlab
% toolbox by Jimmy Shen (pls@rotman-baycrest.on.ca). Unfortunately, this
% toolbox did not include a copyright notice.
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=8797&objectType=file
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, nifti

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

if nargin < 2
    precision_data = 'float';
end

[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    path_f = '.';
end
switch ext_f
    case '.nii'
        file_header = file_name;
    case '.img'
        file_header = cat(2,path_f,filesep,name_f,'.hdr');
    otherwise
        error('niak:read: Unkown extension type : %s. I am expecting ''.nii'' or ''.img''',ext_f)
end

%% Parsing the header
hdr = niak_read_hdr_nifti(file_header);

if nargout > 1
    %% Opening the data file

    fid = fopen(file_name,'r',hdr.info.machine);

    if fid < 0,
        msg = sprintf('Cannot open file %s.',file_name);
        error(msg);
    end

    if hdr.details.dim(5) < 1
        hdr.details.dim(5) = 1;
    end

    %  move pointer to the start of image block
    %
    switch hdr.type
        case {'vol', 'analyze'}
            fseek(fid, 0, 'bof');
        case 'nii'
            fseek(fid, hdr.details.vox_offset, 'bof');
    end


    %  For each frame, precision of value will be read
    %  in vol_siz times, where vol_siz is only the
    %  dimension size of an image, not the byte storage
    %  size of an image.
    vol_siz = prod(hdr.details.dim(2:5));

    %%  For complex float32 or complex float64, voxel values
    %%  include [real, imag]
    if hdr.details.datatype == 32 | hdr.details.datatype == 1792
        vol_siz = vol_siz * 2;
    end

    %% MPH: For RGB24, voxel values include 3 separate color planes
    if hdr.details.datatype == 128 | hdr.details.datatype == 511
        vol_siz = vol_siz * 3;
    end

    vol = fread(fid, vol_siz, sprintf('*%s',hdr.info.precision));

    %%  For complex float32 or complex float64, voxel values
    %%  include [real, imag]
    if hdr.details.datatype == 32 | hdr.details.datatype == 1792
        vol = reshape(vol, [2, length(vol)/2]);
        vol = complex(vol(1,:)', vol(2,:)');
    end

    fclose(fid);

    %%  Update the global min and max values
    hdr.details.glmax = max(double(vol(:)));
    hdr.details.glmin = min(double(vol(:)));

    %% Reshape the volume to correct dimensions
    vol_idx = 1:hdr.details.dim(5);

    if hdr.details.datatype == 128 & hdr.details.bitpix == 24
        vol = squeeze(reshape(vol, [3 hdr.details.dim(2:4) length(vol_idx)]));
        vol = permute(vol, [2 3 4 1 5]);
    elseif hdr.details.datatype == 511 & hdr.details.bitpix == 96
        vol = single(vol);
        vol = (vol - min(vol))/(max(vol) - min(vol));
        vol = squeeze(reshape(vol, [3 hdr.details.dim(2:4) length(vol_idx)]));
        vol = permute(vol, [2 3 4 1 5]);
    else
        vol = squeeze(reshape(vol, [hdr.details.dim(2:4) length(vol_idx)]));
    end
    
    if ((hdr.details.scl_slope~=0)&(hdr.details.scl_slope~=1))|(hdr.details.scl_inter~=0)
        vol = hdr.details.scl_slope * single(vol) + hdr.details.scl_inter;
        hdr.details.scl_slope = 1;
        hdr.details.scl_inter = 0;
    end  
    vol = single(vol);
end