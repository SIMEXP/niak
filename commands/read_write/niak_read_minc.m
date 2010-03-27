function [hdr,vol] = niak_read_minc(file_name,precision_data)
%
% _________________________________________________________________________
% SUMMARY NIAK_READ_MINC
%
% Read 3D or 3D+t data in MINC format.
% http://www.bic.mni.mcgill.ca/software/minc/
%
% SYNTAX:
% [HDR,VOL] = NIAK_READ_MINC(FILE_NAME)
% 
% _________________________________________________________________________
% INPUT:
%
% FILE_NAME         
%       (string) a 3D+t or 3D minc file.
%
% _________________________________________________________________________
% OUTPUT:
%
% VOL           
%       (3D+t or 3D array of double) the fMRI or MRI data.
%
% HDR
%       a structure containing a description of the data. See NIAK_READ_VOL 
%       and NIAK_READ_HDR_MINC for details.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_READ_HDR_MINC, NIAK_WRITE_MINC, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% _________________________________________________________________________
% COMMENTS: 
%
% Use shell commands MINCINFO (for minc1), MINCHEADER and MINCTORAW which 
% requires a proper install of minc tools. This function is
% creating temporary files. If it does not work, try to change the location 
% of temporary files using the GB_NIAK_TMP variable defined in 
% the NIAK_GB_VARS function.
% 
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc

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

%% Parsing the header
hdr = niak_read_hdr_minc(file_name);
hdr.info.precision = precision_data;

[path_tmp,name_tmp,ext_tmp] = fileparts(file_name);

if nargout == 2
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
    delete(file_tmp);

    %% Shapping vol as 3D+t array
    vol = reshape(vol,hdr.info.dimensions);
end