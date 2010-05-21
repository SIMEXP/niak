function file_name = niak_file_tmp(ext)
%
% _________________________________________________________________________
% SUMMARY NIAK_FILE_TMP
%
% Suggest a name of temporary file 
%
% SYNTAX:
% FILE_NAME = NIAK_FILE_TMP(EXT)
%
% _________________________________________________________________________
% INPUTS:
%
% EXT             (string) An extension for the file name
%
% OUTPUTS:
% 
% A (full path) name for a temporary file.
%
% _________________________________________________________________________
% COMMENTS:
%
% The temporary files live in the temporary directory. This directory is by 
% default '/tmp/', but this can be changed using the variable GB_NIAK_TMP
% in the file NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
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

global gb_psom_name_job
flag_gb_niak_fast_gb = 1; %% the initialization of global variables will be as fast as possible
niak_gb_vars
flag_tmp = 1;

while flag_tmp == 1;
    if ~isempty(gb_psom_name_job)
        file_name = sprintf('%sniak_tmp_%s_%i%s',gb_niak_tmp,gb_psom_name_job,floor(1000000000*rand(1)),ext);
    else
        file_name = sprintf('%sniak_tmp_%i%s',gb_niak_tmp,floor(1000000000*rand(1)),ext);
    end
    flag_tmp = exist(file_name,'file')>0;
end
save(file_name,'flag_tmp')