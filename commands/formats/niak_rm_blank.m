function vec_string_b = niak_rm_blank(vec_string)

% Remove leading and trailing blanks from vec_string, and suppress blanks
% following a blank.
%
% SYNTAX
% vec_string_b = niak_rm_blank(vec_string)
% 
% INPUT
% vec_string    (vector of strings)
%
% OUTPUT
% vec_string_b  (vector of strings) a "deblanked" version of vec_string
%
% COMMENTS
% 
% Copyright (c) Pierre Bellec 01/2008
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

vec_string_b = repmat(' ',1,length(vec_string));
nb_car = 0;

flag_car = 0;
for num_c = 1:length(vec_string);
    
    flag_OK = (~strcmp(vec_string(num_c),' '))|flag_car;
    flag_car = ~strcmp(vec_string(num_c),' ');
    if flag_OK
        nb_car = nb_car+1;
        vec_string_b(nb_car) = vec_string(num_c);        
    end
    
end
vec_string_b = deblank(vec_string_b);

    