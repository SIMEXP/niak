function mask_f = niak_cmp_str_cell(cell_str1,cell_str2)

% Test if one of many strings exist in another list of strings
%
% SYNTAX:
% MASK_F = niak_cmp_str_cell(CELL_STR1,CELL_STR2)
% 
% INPUTS:
% CELL_STR1     (string or cell of strings)
% CELL_STR2     (string or cell of strings)
% 
% OUTPUTS:
% MASK_F        (vector) MASK_F(i) equals 1 if CELL_STR{i} is identical to 
%               CELL_STR2{j} for any j, 0 otherwise. If one argument is a
%               simple string, it is converted into a cell of string with
%               one element.
%
% SEE ALSO:
% NIAK_FIND_STR_CELL
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : string


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

if ischar(cell_str1)
    str1{1} = cell_str1;
    cell_str = str1;
    clear str1
end

if ischar(cell_str2)
    str2{1} = cell_str2;
    cell_str2 = str2;
    clear str2
end

mask_f = ismember(cell_str1,cell_str2)';