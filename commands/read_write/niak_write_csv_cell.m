function  [err,msg] = niak_write_csv_cell(file_name,csv_cell,separator)
% Write a cell of strings into a CSV (comma-separated values) text file. 
%
% SYNTAX:
% [ERR,MSG] = NIAK_WRITE_CSV_CELL(FILE_NAME,CSV_CELL,SEPARATOR)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%   (string) the name of the text file. This usually ends in .csv for comma-separated 
%   values, .tsv for tabulation-separated values and and can have a .gz extension for
%   compressed files.
%
% CSV_CELL
%   (cell of strings/float) the data
%
% SEPARATOR
%   (string, default ',' for csv files, char(9) - tabulation - for .tsv files, ',' otherwise) 
%   The character used to separate values. 
%
% _________________________________________________________________________
% OUTPUTS:
%
% ERR
%   (boolean) if ERR == 1 an error occured, ERR = 0 otherwise.
%
% MSG 
%   (string) the error message (empty if ERR==0).
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_READ_CSV_CELL
%
% _________________________________________________________________________
% COMMENTS:
%
% The extension of zipped files is assumed to be .gz. The tools used to zip 
% files is 'gzip'. This setting can be changed by changing the variables 
% GB_NIAK_ZIP_EXT and GB_NIAK_UNZIP in the file NIAK_GB_VARS.

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

% Load global variables
flag_gb_niak_fast_gb = 1;
niak_gb_vars

%% Default inputs
if ~exist('csv_cell','var')||~exist('file_name','var')
    error('Please specify FILE_NAME and CSV_CELL as inputs');
end

%% Check extension
[path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(file_name);
file_name = [path_f,filesep,name_f,ext_short];

%% Options
if nargin < 3
   switch ext_short
       case '.csv'
           separator = ',';
       case '.tsv'
           separator = char(9);
       otherwise
           separator = ',';
   end
end

[nx,ny] = size(csv_cell);

%% Writting the CSV
[hf,msg] = fopen(file_name,'w');
if hf == -1
    err = 1;
else 
    err = 0;
end

for numx = 1:nx
    for numy = 1:ny        
        if ischar(csv_cell{numx,numy})
            sw = '%s';
        elseif isnumeric(csv_cell{numx,numy})
            if csv_cell{numx,numy}==round(csv_cell{numx,numy})
                sw = '%i';
            else
                sw = '%1.15f';
            end
        else
            error('all cells should be either string or numeric variables')
        end 
        if numy ~= ny
            fprintf(hf,[sw separator],csv_cell{numx,numy});            
        else
            fprintf(hf,[sw '\n'],csv_cell{numx,numy});
        end     
    end    
end

fclose(hf);

%% Compress file
if flag_zip
    instr_zip = cat(2,gb_niak_zip,' ',file_name);
    [status,msg] = system(instr_zip);
    if status~=0
        error(cat(2,'niak:write: ',msg,'. There was a problem when attempting to zip the file. Please check that the command ''',gb_niak_zip,''' works, or change program using the variable GB_NIAK_ZIP in the file NIAK_GB_VARS'));
    end
end