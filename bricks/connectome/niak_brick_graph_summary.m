function [files_in,files_out,opt] = niak_brick_graph_summary(files_in,files_out,opt)
% Generate graph properties from a connectome
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GRAPH_SUMMARY(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with arbitrary names SUBJECT. FILES_IN.(SUBJECT) is a .mat file 
%   with measures stored in indiviual variables MEASURE as follows
%
%    (MEASURE).TYPE (string) the type of measure
%    (MEASURE).PARAM (structure) the options of the measure
%    (MEASURE).VAL (type may vary) the measure
%
% FILES_OUT
%   (string) the name of a .csv file with all the measures organized in one spread sheet
%   Each row is a SUBJECT, each column is a MEASURE
%
% OPT
%   (structure) with arbitrary fields (MEASURE). Each entry has the following fields:
%
%   FLAG_TEST
%       (boolean, default: 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
%   FLAG_VERBOSE
%       (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%       indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_CONNECTOME, NIAK_BRICK_GRAPH_PROP, NIAK_PIPELINE_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% Each measure should be found with identical names across all .mat files, 
% otherwise the brick will send back an error. The list of measures is 
% defined by the first .mat file.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, connectome, atoms, fMRI
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

%% Defaults

% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a structure')
end
list_subject = fieldnames(files_in);

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

% OPTIONS
list_fields      = { 'flag_test'    , 'flag_verbose' };
list_defaults    = { false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if opt.flag_test == 1
    return
end

%% Thre brick starts here

%% Read the connectome
if opt.flag_verbose
    fprintf('Building a summary spreadsheet of all measures ...\n')
end
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    if opt.flag_verbose
        fprintf('Reading graph measures in file %s ...\n',files_in.(subject));
    end
    prop = load(files_in.(subject));
    if num_s == 1
        list_mes = fieldnames(prop);
        tab = zeros(length(list_subject),length(list_mes));        
    end
    for num_m = 1:length(list_mes)
        tab(num_s,num_m) = prop.(list_mes{num_m}).val;
    end
end

%% Save the results
if opt.flag_verbose
    fprintf('Saving outputs in %s ...\n',files_out);
end
opt_c.labels_x = list_subject;
opt_c.labels_y = list_mes;
niak_write_csv(files_out,tab,opt_c);