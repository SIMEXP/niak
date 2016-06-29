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
%	(string) the name of the text file. This usually ends in .csv for comma-separated 
%   values, .tsv for tabulation-separated values and and can have a .gz extension for
%   compressed files.
% 
% OPT
%   (structure, optional) with the following fields:
%
%   SEPARATOR
%      (string, default ',' for csv files, char(9) - tabulation - for .tsv files, ',' otherwise) 
%      The character used to separate values. 
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
% The extension of zipped files is assumed to be .gz. The tools used to zip 
% files is 'gzip'. This setting can be changed by changing the variables 
% GB_NIAK_ZIP_EXT and GB_NIAK_UNZIP in the file NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de griatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2013-2015
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

% Check that the file exists
if ~exist(file_name,'file')
    error(cat(2,'Could not find any file matching the description ',file_name));
end

% Load global variables
flag_gb_niak_fast_gb = 1;
niak_gb_vars

%% Check extension
[path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(file_name);

%% Options
list_fields   = {'separator' , 'flag_trim' , 'flag_string' };
list_defaults = {''          , true        , true          };
if nargin == 1
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Default separator
if isempty(opt.separator)
   switch ext_short
       case '.csv'
           opt.separator = ',';
       case '.tsv'
           opt.separator = char(9);
       otherwise
           opt.separator = ',';
   end
end

%% Unzip if necessary
if flag_zip
    file_tmp_gz = niak_file_tmp([name_f ext_f]);
    [succ,msg] = system(cat(2,'cp "',file_name,'" ',file_tmp_gz));
    if succ~=0
        error(msg)
    end            
    instr_unzip = cat(2,gb_niak_unzip,' "',file_tmp_gz,'"');
    [succ,msg] = system(instr_unzip);
    if succ ~= 0
        error(cat(2,'niak:read: ',msg,'. There was a problem unzipping the file. Please check that the command ''',gb_niak_unzip,''' works, or change this command using the variable GB_NIAK_UNZIP in the file NIAK_GB_VARS'));
    end
    file_name = file_tmp_gz(1:end-length(gb_niak_zip_ext));
end

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

if flag_zip
    psom_clean(file_name,struct('flag_verbose',false));
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