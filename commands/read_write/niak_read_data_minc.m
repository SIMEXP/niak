function vol = niak_read_data_minc(hdr,precision_data)
% Read data from a MINC file (.MNC or .MNC.GZ).
%
% SYNTAX: VOL = NIAK_READ_DATA_MINC(HDR)
%
% HDR (structure) a description of the data, generated from NIAK_READ_VOL.
%   The name of the file that will be used to extract data is stored in 
%   HDR.INFO.FILE_PARENT.
% VOL (array) volume data from the minc file used to read HDR. 
%
% SEE ALSO: NIAK_READ_HDR_MINC, NIAK_WRITE_MINC, NIAK_READ_VOL, 
%     NIAK_WRITE_VOL, NIAK_READ_MINC
%
% COMMENTS: the data is forced to float precision.
%
% EXAMPLE:
%   % start by reading the header of an existing file
%   hdr = niak_read_vol('my_file.mnc');
%   % latter read the actual volume data 
%   vol = niak_read_data_minc(hdr);
%   % read a different file, with identical header structure
%   hdr.info.file_parent = 'my_file2.mnc';
%   vol2 = niak_read_data_minc(hdr);
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

if nargin < 2
    precision_data = 'float';
end

%% Unzip file if necessary
file_name = hdr.info.file_parent;
[file_tmp_mnc,flag_zip] = niak_unzip(file_name);
[path_tmp,name_tmp,ext_tmp] = fileparts(file_tmp_mnc);

%% Generating a name for a temporary file
file_tmp = niak_file_tmp([name_tmp '.dat']);

%% extracting the data in float precision in the temporary file
[flag,str_info] = system(cat(2,'minctoraw -',precision_data,' -normalize ',file_name,' > ',file_tmp));

if flag>0
    error(sprintf('niak:read : %s',str_info))
end

%% reading information
hf = fopen(file_tmp,'r');
try
    vol = fread(hf,prod(hdr.info.dimensions),['*' precision_data]);
catch
    vol = fread(hf,prod(hdr.info.dimensions),precision_data);
end

%% Removing temporary stuff
fclose(hf);
if flag_zip
  delete(file_tmp_mnc);
end
delete(file_tmp);

%% Shapping vol as 3D+t array
vol = reshape(vol,hdr.info.dimensions);