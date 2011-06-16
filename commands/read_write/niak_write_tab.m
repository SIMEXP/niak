function  [err,msg] = niak_write_tab(file_name,tab,labels_line,labels_col)
% Write a table into a text file. 
% The first line and first columns are string labels, while
% the rest of the table is a numerical array. 
% Columns and line labels are optional 
%
% SYNTAX:
% [ERR,MSG] = NIAK_WRITE_TAB(FILE_NAME,TAB,LABELS_LINE,LABELS_COL)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%       (string) the name of the text file (usually ends in .dat)
%
% TAB   
%       (matrix M*N) the numerical data array. 
%
% LABELS_LINE        
%       (cell of strings 1*M) LABELS_LINE{NUM_L} is the label of line NUM_L in
%       TAB.
%
% LABELS_COL
%       (cell of strings 1*N) LABELS_COL{NUM_C} is the label of column 
%       NUM_C in TAB.
%
% _________________________________________________________________________
% OUTPUTS:
%
% ERR
%       (boolean) if ERR == 1 an error occured, ERR = 0 otherwise.
%
% MSG 
%       (string) the error message (empty if ERR==0).
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : xfm, minc


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

[nx,ny] = size(tab);

if ~exist('labels_line','var')
    labels_line = [];   
end

if isempty(labels_line)
    for ix = 1:nx
        labels_line{ix} = '';
    end
end

if ~exist('labels_col','var')
    labels_col = [];    
end

if isempty(labels_col)    
    for iy = 1:ny
        labels_col{iy} = sprintf('col%i',iy);
    end
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
for numx = 1:(nx+1)
    for numy = 1:(ny+1)
        if numy == 1
            if numx == 1
                tab_str{numx,numy} = '';
            else
                tab_str{numx,numy} = labels_line{numx-1};
            end
        else
            if numx == 1
                tab_str{numx,numy} = labels_col{numy-1};
            else
                tab_str{numx,numy} = sprintf('%1.15f',tab(numx-1,numy-1));                
            end
        end
    end
end

%% Get the size of each column 
max_length_col = zeros([size(tab_str,2),1]);

for numy = 1:size(tab_str,2)
    for numx = 1:size(tab_str,1)        
        max_length_col(numy) = max(max_length_col(numy),length(tab_str{numx,numy}));
    end
end

%% Write the table

for numx = 1:size(tab_str,1)
    for numy = 1:size(tab_str,2)        
        
        if ~((numy == 1)&(max_length_col(numy)==0))            
            comp = repmat(' ',[1 max_length_col(numy)+3-length(tab_str{numx,numy})]);
            str_tab = [tab_str{numx,numy} comp];
            if numy < size(tab_str,2)
                fprintf(hf,'%s   ',str_tab);
            else
                fprintf(hf,'%s',str_tab);
            end
        end     
    end
    fprintf(hf,'\n');
end

fclose(hf);
