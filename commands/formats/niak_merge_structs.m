function struct12 = niak_merge_structs(struct1,struct2)
%
% _________________________________________________________________________
% SUMMARY NIAK_MERGE_STRUCTS
%
% Merge two structures.
%
% SYNTAX:
%   STRUCT12 = NIAK_MERGE_STRUCTS(STRUCT1,STRUCT2)
%
% _________________________________________________________________________
% INPUTS:
%
% STRUCT1   
%       (structure)
%
% STRUCT2   
%       (structure)
%
% _________________________________________________________________________
% OUTPUTS:
%
% STRUCT12  
%       (structure) combines the fields of STRUCT1 and STRUCT2. 
%
% _________________________________________________________________________
% COMMENTS:
%
% If structures have fields in common, the fields of STRUCT2 override the
% ones of STRUCT1.
%
% For speed optimization, the smallest structure should be passed as
% STRUCT2.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : structure

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

list_fields = fieldnames(struct2);
struct12 = struct1;

for num_f = 1:length(list_fields)
    
    struct12 = setfield(struct12,list_fields{num_f},getfield(struct2,list_fields{num_f}));
    
end