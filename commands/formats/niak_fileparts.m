function [path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(file_name);
% Extract the path, name and extension from a full path name
%
% SYNTAX:
% [PATH_F,NAME_F,EXT_F,FLAG_ZIP,EXT_SHORT] = NIAK_FILEPARTS(FILE_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME
%       (string) a (full path) file name
%
% _________________________________________________________________________
% OUTPUTS:
%
% PATH_F
%       (string) The path of FILE_NAME. If unspecified, it is '.'
%
% NAME_F
%       (string) the name of FILE_NAME (without path or extension).
%
% EXT_F
%       (string) the extension of FILE_NAME. If multiple extensions exist,
%       only the first one will be recognized except if the second is
%       '.gz' (or actually the extension defined in GB_NIAK_ZIP_EXT defined
%       in NIAK_GB_VARS.M), in which case two extensions will be extracted.
%
% FLAG_ZIP
%       (boolean) FLAG_ZIP is true if the first extension of the file is 
%       '.gz' (or actually the extension defined in GB_NIAK_ZIP_EXT defined
%       in NIAK_GB_VARS.M)
%
% EXT_SHORT
%       (string) same as EXT_F, but without the '.gz' at the end if any.
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
% 
% This is essentially a wraper around the function FILEPARTS, but it
% behaves differently for .gz files (see OUTPUTS).
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, 2010
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : 

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

if iscellstr(file_name)
    nb_file = length(file_name);
    path_f  = cell([nb_file 1]);
    name_f  = cell([nb_file 1]);
    ext_f   = cell([nb_file 1]);
    for num_f = 1:nb_file
        [path_f{num_f},name_f{num_f},ext_f{num_f}] = niak_fileparts(file_name{num_f});
    end
    return
end

flag_gb_niak_fast_gb = true;
niak_gb_vars

[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    path_f = ['.' filesep];
end
                
if strcmp(ext_f,gb_niak_zip_ext)
	[tmp,name_f,ext_short] = fileparts(name_f);
    ext_f = [ext_short gb_niak_zip_ext];
    flag_zip = true;
else
    ext_short = ext_f;
    flag_zip  = false;
end