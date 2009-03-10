function str2 = niak_replace_str(str1,str_find,str_replace)
%
% _________________________________________________________________________
% SUMMARY NIAK_REPLACE_STR
%
% Replace all occurences of one string by another in a string.
%
% SYNTAX:
% STR = NIAK_REPLACE_STR(STR1,STR2)
% 
% _________________________________________________________________________
% INPUTS:
%
% STR1      
%       (string) an arbitrary string.
%
% STR_FIND      
%       (string) the string that needs to be replaced
%
% STR_REPLACE   
%       (string) the "replace by" string
%
% _________________________________________________________________________
% OUTPUTS:
%
% STR2       
%       (string) same as STR1, except all occurences of STR_FIND have
%       been replaced by STR_REPLACE.
%
% _________________________________________________________________________
% COMMENTS
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : niak, string

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

pos = findstr(str1,str_find);
if isempty(pos)
    
    str2 = str1;
    
else
    str2 = [];

    num_p = 1;
    while num_p <= length(str1)

        if ismember(num_p,pos)
            str2 = [str2 str_replace];
            num_p = num_p + length(str_find);
        else
            str2 = [str2 str1(num_p)];
            num_p = num_p+1;
        end
    end
end