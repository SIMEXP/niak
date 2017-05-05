function files = niak_grab_connectome(path_data)
% Grab the outputs of NIAK_PIPELINE_CONNECTOME
%
% SYNTAX:
% FILES_OUT = NIAK_GRAB_CONNECTOME( PATH_DATA )
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
%               Centre de recherche de l'institut de Griatrie de Montral,
%               Dpartement d'informatique et de recherche oprationnelle,
%               Universit de Montral, 2013.
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

%% Initialize the files
files = struct;
file_roi = dir([path_data 'network_rois.*']);
files.network_rois = [path_data file_roi(1).name];

%% Grab connectomes
path_conn = [path_data 'connectomes' filesep];
if psom_exist(path_conn)
    list_conn = dir([path_conn 'connectome_rois_*.mat']);
    list_conn = {list_conn.name};
    ind_start = length('connectome_rois_')+1;
    list_subject = cell(length(list_conn),1);
    for num_c = 1:length(list_conn)
        conn = list_conn{num_c};
        ind_end = regexp(conn,'.mat$')-1;
        subject = conn(ind_start:ind_end);
        list_subject{num_c} = subject;
        files.connectome.(subject) = [path_conn conn];
    end
else
    error('I could not find the connectomes subfolder')
end

%% Grab r-map
path_rmap = [path_data 'rmap_seeds'];
if psom_exist(path_rmap)
    % Parse parcel IDs
    list_net = dir([path_rmap filesep 'rmap_' list_subject{1} '_*']);
    list_net = {list_net.name};
    for ff = 1:length(list_net)
        file_net =  list_net{ff};
        [~,name_net,ext_net] = niak_fileparts(file_net);
        ind = length(['rmap_' list_subject{1}]);
        ind = ind+2;
        name_net = name_net(ind:end);
        for ss = 1:length(list_subject)
            files.rmap.(name_net).(list_subject{ss}) = [path_rmap filesep 'rmap_' list_subject{ss} '_' name_net ext_net];
        end
        files.mask.(name_net) = [path_rmap filesep 'mask_' name_net ext_net];
    end
else
    warning ('I could not find the rmaps subfolder')
end
