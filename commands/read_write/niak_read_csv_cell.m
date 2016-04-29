function csv_cell = niak_read_csv_cell(file_name,opt)
% Read a table from a text file with comma-separated values (csv). 
% All the values are stored in a cell of strings
%
% SYNTAX:
% CSV_CELL = NIAK_READ_CSV_CELL(FILE_NAME,OPT)
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
% CSV_CELL
%   (cell of strings) CSV_CELL{i,j} is a string corresponding to the ith row
%   and jth column of the csv file.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_WRITE_CSV_CELL
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
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

list_fields   = {'separator' , 'flag_trim' , 'flag_string' };
list_defaults = {','         , true        , true          };
if nargin == 1
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Reading the table
hf = fopen(file_name);
str_tab = fread(hf,Inf,'uint8=>char')';
cell_tab = niak_string2lines(str_tab);
fclose(hf);

%% Extracting the labels
for num_r = 1:length(cell_tab)
    cell_line = sub_csv(cell_tab{num_r},opt.separator);
    if num_r == 1
        csv_cell = cell(length(cell_tab),length(cell_line));
    end
    for num_c = 1:length(cell_line)
        if opt.flag_string
            csv_cell{num_r,num_c} = regexprep(cell_line{num_c},'[''"]','');
        else
            csv_cell{num_r,num_c} = cell_line{num_c};
        end
    end 
end
if opt.flag_trim
    csv_cell = strtrim(csv_cell);
end

function cell_values = sub_csv(str_values,separator)

if ~isempty(str_values)
    ind = findstr([separator str_values separator],separator);
    
    cell_values = cell([length(ind)-1 1]);
    for num_i = 1:length(ind)-1
        cell_values{num_i} = str_values(ind(num_i):ind(num_i+1)-2);
    end
else
    cell_values = '';
end