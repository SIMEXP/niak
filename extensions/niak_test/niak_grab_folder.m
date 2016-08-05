 function files = niak_grab_folder(path_data,black_list)
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
%   (string or cell of string) a list of folder (or subfolders) to 
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

path_data = niak_full_path(path_data);

%% The black list
if (nargin > 1)
    if iscellstr(black_list)
        black_n = 0;
        for num_e = 1:length(black_list)
            black_list{num_e} = niak_full_path(black_list{num_e});
            % make sure there is no / and the end of a file name.
            if ~isdir(black_list{num_e})
               black_list_file{++black_n} = regexprep(black_list{num_e},'(.*)/','$1') ;
            end
        end
    elseif ischar(black_list)
        black_list = {niak_full_path(black_list)};
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
    if (nargin < 2) || ~ismember(niak_full_path(files_loc{ind_dir(num_d)}),black_list)
        files = [ files ; niak_grab_folder(files_loc{ind_dir(num_d)}) ];    
    end
end

% super slow way of removing files
if exist('black_list_file') && iscell(black_list_file)
   files = setdiff(files,black_list_file) ;
end