 function files = niak_grab_folder(path_data,black_list,init)
% Grab all the files inside a folder (recursively)
%
% SYNTAX:
% FILES = NIAK_GRAB_FOLDER(PATH_DATA,BLACK_LIST)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') a folder
%
% BLACK_LIST
%   (string or cell of string) a list of folders, or files to 
%   be ignored by the grabber. Absolute names should be used
%   (i.e. '/home/user23/database/toto' rather than 'toto'). If not, the names
%   will be assumed to refer to the current directory.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%    (cell of strings) the list of files inside the folder (and subfolders)
%    The directories are excluded from the list.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Griatrie de Montral,
%               Dpartement d'informatique et de recherche oprationnelle,
%               Universit de Montral, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : grabber

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

%% Default path for the database
if (nargin<1)||isempty(path_data)
    path_data = [pwd filesep];
end

if nargin < 3
    init = true;
end

if init

    path_data = niak_full_path(path_data);

    %% The black list
    black_list_file = {};
    if nargin < 2
        black_list = {};
    end

    if ischar(black_list)
        black_list = {black_list};
    end

    for num_e = 1:length(black_list)
        [path_tmp,name_tmp,ext_tmp] = fileparts(black_list{num_e});
        if isempty(path_tmp)
            path_tmp = path_data;
        else
            path_tmp = [path_tmp filesep];
        end
        black_list{num_e} = [path_tmp name_tmp ext_tmp];
    end
end

%% List of folders
if ~exist(path_data,'dir')
    error('I could not find the directory %s',path_data);
end

%% Get the list of files in the current directory
files_loc = dir(path_data);
is_dir = [files_loc.isdir];
files_loc = {files_loc.name};
mask = ~ismember(files_loc,{'.','..'});
is_dir = is_dir(mask);
files_loc = files_loc(mask);
files_loc = strcat(repmat({path_data},size(files_loc)),files_loc);

files = files_loc(~is_dir);
files = files(:);

%% Recursively find files in subdirectories
ind_dir = find(is_dir);
for num_d = 1:length(ind_dir)
    if (nargin < 2) || ~ismember(files_loc{ind_dir(num_d)},black_list)
        files = [ files ; niak_grab_folder([files_loc{ind_dir(num_d)} filesep],black_list,false) ];    
    end
end

% Removing black listed files
files = files(~ismember(files,black_list));
