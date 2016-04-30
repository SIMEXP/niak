function [hdr,vol] = niak_read_nifti(file_name)
% Read a NIFTI file (.NII or .IMG).
% The old Analyze 7.5 is also supported, and if a .MAT file is present, the
% affine transformation information will be included.
% http://nifti.nimh.nih.gov/nifti-1
%
% SYNTAX: [HDR,VOL] = NIAK_READ_NIFTI(FILE_NAME)
%
% FILE_NAME (string) a 3D+t or 3D minc nifti file.
% VOL (3D+t or 3D array of double) the fMRI or MRI data.
% HDR (structure) a description of the data. See NIAK_READ_VOL 
%    and NIAK_READ_HDR_NIFTI for details.
%
% SEE ALSO: NIAK_READ_HDR_NIFTI, NIAK_WRITE_NIFTI, NIAK_READ_VOL, 
%     NIAK_WRITE_VOL, NIAK_READ_DATA_NIFI
%
% COMMENTS:
%   In case of multiple files data (e.g. .IMG + .HDR, or .IMG + .HDR + .MAT),
%   specify the name using the .IMG extension only.
%
%   The affine transformation in hdr.info corresponds to the sform, if specified, or 
%   the qform (if sform unspecified and qform is), or simply the pixel dimension 
%   and offset, if neither qform or sform are specified. 
% 
%   The data is forced to single precision.
%
% See license in the code. 
 
% Copyright (c) Pierre Bellec, Jimmy Shen, 2008-2016.
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

[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    path_f = '.';
end
switch ext_f
    case {'.nii','.nii.gz'}
        file_header = file_name;
    case '.img'
        file_header = cat(2,path_f,filesep,name_f,'.hdr');
    otherwise
        error('niak:read: Unkown extension type : %s. I am expecting ''.nii'' or ''.img''',ext_f)
end

%% Parsing the header
hdr = niak_read_hdr_nifti(file_header);
hdr.info.file_parent = file_name;
if nargout > 1
    vol = niak_read_data_nifti(hdr);
end
