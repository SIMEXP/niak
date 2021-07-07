function vol = niak_read_data_nifti(hdr)
% Read data from a NIFTI file (.NII or .IMG).
%
% SYNTAX: VOL = NIAK_READ_DATA_NIFTI(HDR)
%
% HDR (structure) a description of the data, generated from NIAK_READ_VOL.
%   The name of the file that will be used to extract data is stored in 
%   HDR.INFO.FILE_PARENT.
% VOL (array) volume data from the nifti file used to read HDR. 
%
% SEE ALSO: NIAK_READ_HDR_NIFTI, NIAK_WRITE_NIFTI, NIAK_READ_VOL, 
%     NIAK_WRITE_VOL, NIAK_READ_NIFI
%
% COMMENTS: the data is forced to single precision.
%
% EXAMPLE:
%   % start by reading the header of an existing file
%   hdr = niak_read_vol('my_file.nii.gz');
%   % latter read the actual volume data 
%   vol = niak_read_data_nifti(hdr);
%   % read a different file, with identical header structure
%   hdr.info.file_parent = 'my_file2.nii.gz';
%   vol2 = niak_read_data_nifti(hdr);
%
% See license in the code. 
 
% Copyright (c) Pierre Bellec, 2008-2016.
% Montreal Neurological Institute, 2008-2010
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2010-2016
% Maintainer: pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: medical imaging, I/O, reader, nifti
%
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

%% Unzip file if necessary
file_name = hdr.info.file_parent;
[file_tmp,flag_zip] = niak_unzip(file_name);
    
%% Opening the data file
fid = fopen(file_tmp,'r',hdr.info.machine);

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
if (hdr.details.datatype == 32) || (hdr.details.datatype == 1792)
    vol_siz = vol_siz * 2;
end

%% MPH: For RGB24, voxel values include 3 separate color planes
if (hdr.details.datatype == 128) || (hdr.details.datatype == 511)
    vol_siz = vol_siz * 3;
end

vol = fread(fid, vol_siz, sprintf('*%s',hdr.info.precision));

%%  For complex float32 or complex float64, voxel values
%%  include [real, imag]
if (hdr.details.datatype == 32) || (hdr.details.datatype == 1792)
    vol = reshape(vol, [2, length(vol)/2]);
    vol = complex(vol(1,:)', vol(2,:)');
end
fclose(fid);

%% Reshape the volume to correct dimensions
vol_idx = 1:hdr.details.dim(5);

if (hdr.details.datatype == 128) && (hdr.details.bitpix == 24)
    vol = squeeze(reshape(vol, [3 hdr.details.dim(2:4) length(vol_idx)]));
    vol = permute(vol, [2 3 4 1 5]);
elseif (hdr.details.datatype == 511) && (hdr.details.bitpix == 96)
    vol = single(vol);
    vol = (vol - min(vol))/(max(vol) - min(vol));
    vol = squeeze(reshape(vol, [3 hdr.details.dim(2:4) length(vol_idx)]));
    vol = permute(vol, [2 3 4 1 5]);
else
    vol = squeeze(reshape(vol, [hdr.details.dim(2:4) length(vol_idx)]));
end

if ((hdr.details.scl_slope~=0)&&(hdr.details.scl_slope~=1))||(hdr.details.scl_inter~=0)
    vol = hdr.details.scl_slope * single(vol) + hdr.details.scl_inter;
end  

%% Hack: force to single precision
vol = single(vol);

%% remove temporary file
if flag_zip
    delete(file_tmp);
end    