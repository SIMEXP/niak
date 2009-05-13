function val = niak_get_minc_att(hdr,var_name,att_name);
%
% _________________________________________________________________________
% SUMMARY NIAK_GET_MINC_ATT
%
% Get the value of a the attribute of a minc variable from a minc header.
%
% SYNTAX:
% VAL = NIAK_GET_MINC_ATT(HDR,VAR_NAME,ATT_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% HDR
%       (structure) a minc header (see NIAK_READ_HDR_MINC).
%
% VAR_NAME
%       (string) the name of a variable in the minc file.
%
% ATT_NAME
%       (string) the name of an attribute of the variable.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VAL
%       The value of the selected attribute of the selected variable.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_GET_MINC_ATT
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
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

if ~exist('hdr','var')|~exist('var_name','var')|~exist('att_name','var')
    error('niak:commands','syntax: VAL = NIAK_GET_MINC_ATT(HDR,VAR_NAME,ATT_NAME).\n Type ''help niak_get_minc_att'' for more info.')
end

if ~isstruct(hdr)
    error('HDR should be a structure');
end

try
    var_data = hdr.details.(var_name);
catch
    error('I could not find the variable %s in HDR',var_name);
end

ind = find(ismember(var_data.varatts,att_name),1);

if isempty(ind)
    error('I could not find the attribute %s in the variable %s',att_name,var_name);
end

val = var_data.attvalue{ind};