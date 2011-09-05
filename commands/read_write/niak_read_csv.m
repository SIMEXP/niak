function [tab,labels_x,labels_y] = niak_read_csv(file_name,opt)
% Read a table from a text file with comma-separated values (csv). 
% The first line and first columns are assumed to be string labels, while
% the rest of the table is assumed to be a numerical array. 
%
% SYNTAX:
% [TAB,LABELS_X,LABELS_Y] = NIAK_READ_CSV(FILE_NAME,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%	(string) the name of the csv file (usually ends in .csv)
% 
% OPT
%   (structure, optional) with the following fields:
%
%   SEPARATOR
%       (string, default ',') The character used to separate values. 
%
%   FLAG_STRING
%       (boolean, default true) remove the ' and " characters in strings.
%
%   FLAG_TRIM
%       (boolean, default true) trim leading and trailing spaces in labels.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TAB   
%   (matrix M*N) the numerical data array. 
%
% LABELS_X
%   (cell of strings 1*M) LABELS_X{X} is the label of line X in TAB.
%
% LABELS_Y
%	(cell of strings 1*N) LABELS_Y{Y} is the label of column Y in TAB.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_WRITE_CSV
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : table, CSV

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

if ~exist(file_name,'file')
    error(cat(2,'Could not find any file matching the description ',file_name));
end

%% Options
gb_name_structure = 'opt';
gb_list_fields   = {'separator' , 'flag_trim' , 'flag_string' };
gb_list_defaults = {','         , true        , true          };
niak_set_defaults

%% Reading the table
hf = fopen(file_name);
str_tab = fread(hf,Inf,'uint8=>char')';
cell_tab = niak_string2lines(str_tab);
fclose(hf);

%% Extracting the labels
labels_y = sub_csv(cell_tab{1},separator);
if flag_string    
    for num_e = 1:length(labels_y)
        labels_y{num_e} = regexprep(labels_y{num_e},'[''"]','');
    end
end
if flag_trim
    labels_y = strtrim(labels_y);
end

%% Extracting the numerical data
nb_col = length(labels_y);
labels_x = cell([length(cell_tab)-1 1]);

for num_x = 2:length(cell_tab)
    if flag_string
        cell_tab{num_x} = regexprep(cell_tab{num_x},'[''"]','');
    end
    
    line_tmp = sub_csv(cell_tab{num_x},separator);  
    if num_x == 2
        lines = cell([length(cell_tab)-1 length(line_tmp)]);
        lines(1,:) = line_tmp;
    else
        if length(line_tmp)~=size(lines,2)
            error('All lines do not have the same number of elements!')
        end
        lines(num_x-1,:) = line_tmp;
    end
end

if isempty(labels_y{1})
    labels_x = lines(:,1);
    tab = str2double(lines(:,2:end));
else
    tab = str2double(lines);
end

if flag_trim
    for num_e = 1:length(labels_x)
        if ~isempty(labels_x{num_e})
            labels_x{num_e} = strtrim(labels_x{num_e});
        end
    end
end

if isempty(labels_y{1})
    labels_y = labels_y(2:end);
end

function cell_values = sub_csv(str_values,separator)

if ~isempty(str_values)
    ind = findstr([separator str_values separator],separator);
    
    cell_values = cell([length(ind)-1 1]);
    for num_i = 1:length(ind)-1
        cell_values{num_i} = str_values(ind(num_i):ind(num_i+1)-2);
    end
else
    cell_values = cell(0);
end
