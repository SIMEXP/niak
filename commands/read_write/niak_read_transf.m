function transf = niak_read_transf(file_name)
% Read a lsq12 transformation matrix from an xfm file
%
% SYNTAX:
% TRANSF = NIAK_READ_TRANSF(FILE_NAME)
% 
% FILE_NAME (string) the name of the xfm file (usually ends in .xfm)
% TRANSF (matrix 4*4) a classical matrix representation of an lsq12
%   transformation.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% CRIUGM, DIRO, University of Montreal, 2010-2017
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : xfm, minc


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

hf = fopen(file_name);
xfm_info = fread(hf,Inf,'uint8=>char')';
cell_info = niak_string2lines(xfm_info);
transf = eye(4);
transf(1,:) = str2num(cell_info{end-2});
transf(2,:) = str2num(cell_info{end-1});
transf(3,:) = str2num(cell_info{end}(1:end-1));
fclose(hf);