function [tab,labels_x,labels_y,labels_id] = niak_read_csv(file_name,opt)
% Read a table from a text file with comma-separated values (csv). 
% The first line and first columns are assumed to be string labels, while
% the rest of the table is assumed to be a numerical array. 
%
% SYNTAX:
% [TAB,LABELS_X,LABELS_Y,LABELS_ID] = NIAK_READ_CSV(FILE_NAME,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%   (string) the name of the csv file (usually ends in .csv)
% 
% OPT
%   (structure, optional) with the following fields:
%
%   SEPARATOR
%      (string or cell of strings, default {',',';',horizontal tabulation}) 
%      The character used to separate values. If a cell of strings, the 
%      separators are tested one after the other, until a separator is 
%      detected.
%
%   FLAG_STRING
%      (boolean, default true) remove the ' and " characters in strings.
%
%   FLAG_TRIM
%      (boolean, default true) trim leading and trailing spaces in labels.
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
%   (cell of strings 1*N) LABELS_Y{Y} is the label of column Y in TAB.
%
% LABELS_ID
%   (string) the labels of the first column (associated with LABELS_X).
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_WRITE_CSV
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1: The labels of rows can be omitted. 
% NOTE 2: If the first cell is not empty, the function checks for the presence
%   of " in the following rows to detect if these are the labels of rows, 
%   or if these labels have been ommitted. 
% NOTE 3: To have a proper behaviour without tweaking the OPT, the csv should
%   be using "," or a ";" or an horizontal tabulation as a separator, and all 
%   strings should be between ".
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de 
%               Gériatrie de Montréal, Département d'informatique et de recherche 
%               opérationnelle, Université de Montréal, 2008-2013.
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
list_fields   = {'separator'             , 'flag_trim' , 'flag_string' };
list_defaults = {{',',';',sprintf('\t')} , true        , true          };
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Reading the table
hf = fopen(file_name);
str_tab = fread(hf,Inf,'uint8=>char')';
cell_tab = niak_string2lines(str_tab);
fclose(hf);

%% Detect the separator
if iscellstr(opt.separator)
    list_separator = opt.separator;
    opt.separator = list_separator{1};
    ss = 1;
    while isempty(strfind(cell_tab{1},opt.separator))&&(ss<length(list_separator))
        ss = ss+1;
        opt.separator = list_separator{ss};
    end 
end     
    
%% Extracting the labels
labels_y = sub_csv(cell_tab{1},opt.separator);
if opt.flag_string    
    for num_e = 1:length(labels_y)
        labels_y{num_e} = regexprep(labels_y{num_e},'[''"]','');
    end
end
if opt.flag_trim
    labels_y = strtrim(labels_y);
end

%% Extracting the numerical data
nb_col = length(labels_y);
labels_x = cell([length(cell_tab)-1 1]);
flag_id = ismember(cell_tab{2}(1),{'''','"'});
for num_x = 2:length(cell_tab)
    if opt.flag_string
        cell_tab{num_x} = regexprep(cell_tab{num_x},'[''"]','');
    end
    
    line_tmp = sub_csv(cell_tab{num_x},opt.separator); 
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

if isempty(labels_y{1})||flag_id
    labels_x = lines(:,1);
    tab = str2double(strtrim(lines(:,2:end)));
else
    tab = str2double(strtrim(lines));
end

if opt.flag_trim
    for num_e = 1:length(labels_x)
        if ~isempty(labels_x{num_e})
            labels_x{num_e} = strtrim(labels_x{num_e});
        end
    end
end

if isempty(labels_y{1})||flag_id
    labels_id = labels_y{1};
    labels_y = labels_y(2:end);
else 
    labels_id = '';
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
