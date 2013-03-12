function files = niak_grab_connectome(path_data)
% Grab all the connectomes created by NIAK_PIPELINE_CONNECTOME
%
% SYNTAX:
% FILES_OUT = NIAK_GRAB_CONNECTOMES( PATH_DATA )
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_CONNECTOME
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT
%   (structure) the list of outputs of the CONNECTOME pipeline
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2013.
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

if nargin<2
    files_in = struct();
end

path_data = niak_full_path(path_data);

%% List of parcellations
dir_parc = dir(path_data);
list_parc = {dir_parc.name};
mask_parc = true(length(dir_parc),1);
for num_e = 1:length(dir_parc)
    mask_parc(num_e) = dir_parc(num_e).isdir && ~ismember(list_parc{num_e},{'.','..'});
end
list_parc = list_parc(mask_parc);

if isempty(list_parc)
    error('I could not find any subfolder in %s',path_data);
end

%% Loop of parcellations
for num_p = 1:length(list_parc)
    parc = list_parc{num_p};
    path_parc = [path_data parc filesep];
    list_conn = dir([path_parc 'connectome_' parc '_*.mat']);
    list_conn = {list_conn.name};
    if isempty(list_conn)
        warning('I could not find any connectome_%s_*.mat files in %s',parc,parc)
    end
    ind_start = length(['connectome_' parc '_'])+1;
    for num_c = 1:length(list_conn)
        conn = list_conn{num_c};
        ind_end = regexp(conn,'.mat$')-1;
        subject = conn(ind_start:ind_end);
        files.(parc).(subject) = [path_parc conn];
    end
end