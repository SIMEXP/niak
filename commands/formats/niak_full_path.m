function path_name_f = niak_full_path(path_name)
% convert a path name (either relative or absolute) into a full path name
%
% SYNTAX:
% PATH_NAME_F = NIAK_FULL_PATH(PATH_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_NAME
%    (string, default pwd) a relative or absolute path name.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PATH_NAME_F 
%       (string) same as PATH_NAME, but in a absolute form and with a
%       filesep appended at the end.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
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

if nargin == 0
    path_name = pwd;
end

%% convert relative into full path
path_name = strrep(path_name,[filesep filesep],filesep);
if isempty(strfind(path_name,[':' filesep]))&&~strcmp(path_name(1),filesep)&&~strcmp(path_name(1:min(2,length(path_name))),['.' filesep])&&~strcmp(path_name(1:min(3,length(path_name))),['..' filesep])
    path_name_f = [ pwd filesep path_name ] ;
elseif strcmp(path_name(1:min(2,length(path_name))),['.' filesep])
    path_name_f = [pwd filesep path_name(3:end)];
elseif strcmp(path_name(1:min(3,length(path_name))),['..' filesep])
    path_name_f = pwd;
    ind = strfind(path_name_f,filesep);
    if ~isempty(ind)&&(ind(end)>1)
        path_name_f = path_name_f(1:(ind(end)-1));
    end
    path_name_f = [path_name_f filesep path_name(4:end)];
else
    path_name_f = path_name;
end

%% Append filesep at the end
if ~strcmp(path_name_f(end),filesep)
    path_name_f = [path_name_f filesep];
end

