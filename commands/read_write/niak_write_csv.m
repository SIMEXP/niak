function  [err,msg] = niak_write_csv(file_name,tab,opt)
% Write a table into a CSV (comma-separated values) text file. 
% The first row and first column can be used as string labels, while
% the rest of the table is a numerical array. 
%
% SYNTAX:
% [ERR,MSG] = NIAK_WRITE_CSV(FILE_NAME,TAB,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%   (string) the name of the text file (usually ends in .csv)
%
% TAB   
%   (matrix M*N) the numerical data array. 
%
%
% OPT           
%   (structure) with the following fields.  
%
%   LABELS_X
%   	(cell of strings 1*M, default {}) LABELS_X{NUM_R} is the label 
%       of row NUM_R in TAB.
%
%   LABELS_Y
%   	(cell of strings 1*N, default {}) LABELS_X{NUM_C} is the label 
%       of column NUM_C in TAB.
%
%   SEPARATOR
%   	(string, default ',') The character used to separate values. 
%
%   PRECISION
%   	(integer, default 15) The number of decimals used to write the
%       table.
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
% NIAK_READ_CSV
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

%% Default inputs
if ~exist('tab','var')|~exist('file_name','var')
    error('Please specify FILE_NAME and TAB as inputs');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields   = {'labels_x' , 'labels_y' , 'separator' ,'precision' };
gb_list_defaults = {{}         , {}         , ','         ,15          };
niak_set_defaults

[nx,ny] = size(tab);

if isempty(labels_x)
    labels_x = repmat({''},[nx 1]);
end

%% Writting the table

%% column labels
[hf,msg] = fopen(file_name,'w');
if hf == -1
    err = 1;
else 
    err = 0;
end

%% Convert the table into string
tab_str = cell([nx+1 ny+1]);
str_num = ['%1.' num2str(precision) 'f'];

for numx = 1:(nx+1)
    for numy = 1:(ny+1)
        if numy == 1
            if numx == 1
                tab_str{numx,numy} = '';
            else
                if ~isempty(labels_x{numx-1})
                    tab_str{numx,numy} = ['"' labels_x{numx-1} '"'];
                else
                    tab_str{numx,numy} = '';
                end
            end
        else
            if numx == 1
                if ~isempty(labels_y)&&~isempty(labels_y{numy-1})                
                    tab_str{numx,numy} = ['"' labels_y{numy-1} '"'];
                else
                    tab_str{numx,numy} = '';
                end
                    
            else
                tab_str{numx,numy} = sprintf(str_num,tab(numx-1,numy-1));
            end
        end
    end
end

%% Write the table
if isempty(labels_y)
    startx = 2;
else
    startx = 1;
end
for numx = startx:size(tab_str,1)
    for numy = 1:size(tab_str,2)        
        
        if ~(numy == ny+1)
            fprintf(hf,'%s ,',tab_str{numx,numy});
        else
            fprintf(hf,'%s\n',tab_str{numx,numy});
        end     
    end    
end

fclose(hf);