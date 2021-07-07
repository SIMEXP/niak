function [hdr,vol] = niak_read_minc(file_name,precision_data)
% Read 3D or 3D+t data in MINC format.
% http://www.bic.mni.mcgill.ca/software/minc/
%
% SYNTAX: [HDR,VOL] = NIAK_READ_MINC(FILE_NAME)
%
% FILE_NAME (string) a 3D+t or 3D minc file. 
% VOL (3D+t or 3D array of double) the fMRI or MRI data.
% HDR (structure) description of the data. See NIAK_READ_VOL 
%   and NIAK_READ_HDR_MINC for details.
%
% SEE ALSO: NIAK_READ_HDR_MINC, NIAK_WRITE_MINC, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% COMMENTS: Use shell commands MINCINFO (for minc1), MINCHEADER and MINCTORAW which 
%  requires a proper install of minc tools. This function is
%  creating temporary files. If it does not work, try to change the location 
%  of temporary files using the GB_NIAK_TMP variable defined in 
%  the NIAK_GB_VARS function.
%
% EXAMPLES: 
%   To read the header of a file, with the volumetric data
%     [hdr,vol] = niak_read_minc('my_file.mnc');
%
% See license in the code. 
 
% Copyright (c) Pierre Bellec, 2008-2016.
% Montreal Neurological Institute, 2008-2010
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2010-2016
% Maintainer: pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: medical imaging, I/O, reader, minc
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

if nargin < 2
    precision_data = 'float';
end

%% Unzip
[path_f,name_f,ext_f] = fileparts(file_name);
path_f = niak_full_path(path_f);
file_name = [path_f,name_f,ext_f];
[file_tmp,flag_zip] = niak_unzip(file_name);

%% Parsing the header
hdr = niak_read_hdr_minc(file_tmp);
hdr.info.file_parent = file_name;
if nargout > 1
    vol = niak_read_data_minc(hdr);
end
if flag_zip
  delete(file_tmp);
end