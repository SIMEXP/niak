function [files_in,files_out,opt] = niak_brick_concat_transf(files_in,files_out,opt)
% Concatenate multiple transformations in xfm format.
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CONCAT_TRANSF(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN (cell of strings) FILES_IN{I} is the name of the Ith transformation 
%   file in xfm format.
% FILES_OUT (string) the concatenated transformation.
% OPT.FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%   do anything but update the default values in FILES_IN, FILES_OUT and OPT.
%
% Note 1: The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% Note 2: If f(I) is the Ith transformation, the concantenated transformation is
%   f(end)(...(f(1))...).

% SEE ALSO: NIAK_TRANSF2PARAM, NIAK_PARAM2TRANSF
%
% Copyright (c) Pierre Bellec, see license information in the code.

% Montreal Neurological Institute, 2008-2010
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2010-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, transformation

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')||~exist('files_out','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CONCAT_TRANSF(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_concat_transf'' for more info.')
end

if  ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings !');
end

if ~ischar(files_out)
    error('FILES_OUT should be a string !');
end

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_test'};
gb_list_defaults = {0};
niak_set_defaults
        
if flag_test == 1
    return
end

instr_concat = 'xfmconcat';

for num_f = 1:length(files_in)
    instr_concat = cat(2,instr_concat,' ',files_in{num_f});
end

instr_concat = cat(2,instr_concat,' ',files_out);

[flag,str] = system(instr_concat);

if flag~=0
    error(str);
end
   