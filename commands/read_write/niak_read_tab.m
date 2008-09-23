function [tab,labels_line,labels_col] = niak_read_tab(file_name)
%
% _________________________________________________________________________
% SUMMARY NIAK_READ_TAB
%
% Read a table from a text file. 
% The first line and first columns are assumed to be string labels, while
% the rest of the table is assumed to be a numerical array. 
% The "line" labels are optional.
%
% SYNTAX:
% [TAB,LABELS_LINE,LABELS_COL] = NIAK_READ_TAB(FILE_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME     
%       (string) the name of the text file (usually ends in .dat)
% 
% _________________________________________________________________________
% OUTPUTS:
%
% TAB   (matrix M*N) the numerical data array. 
%
% LABELS_LINE        
%       (cell of strings 1*?) LABELS_LINE{NUM_L} is the label of line NUM_L in
%       TAB.
%
% LABELS_COL
%       (cell of strings 1*N) LABELS_COL{NUM_C} is the label of column 
%       NUM_C in TAB.
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

if ~exist(file_name,'file')
    error(cat(2,'Could not find any file matching the description ',file_name));
end

%% Reading the table
hf = fopen(file_name);
str_tab = fread(hf,Inf,'uint8=>char')';
cell_tab = niak_string2lines(str_tab);
fclose(hf);

%% Extracting the labels
labels_col = niak_string2words(cell_tab{1});

%% Extracting the numerical data
nb_col = length(labels_col);
tab = zeros([length(cell_tab)-1 nb_col]);

for num_v = 2:length(cell_tab)
    line_tmp = niak_string2words(cell_tab{num_v});
    if length(line_tmp) ~= nb_col
        if length(line_tmp) == nb_col + 1
         
            labels_line{num_v-1} = line_tmp{1};
            tab(num_v-1,:) = str2num(char(line_tmp(2:end)));
        else
            line = str2num(char(line_tmp));
            if num_v == 2
                warning(cat(2,'all the lines of ',file_name,' should have the same number of columns! (separator is space)'));
                tab = zeros([length(cell_tab)-1 length(line)]);                                
            end
            tab(num_v-1,:) = str2num(char(line_tmp));
        end 

    else
        labels_line{num_v-1} = '';
        tab(num_v-1,:) = str2num(char(line_tmp));
    end
end