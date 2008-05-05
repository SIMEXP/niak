function cell_files = niak_files2cell(files)

% Convert a string, cell of strings or a structure where each field is a
% string into one single cell of strings.
%
% SYNTAX :
% CELL_FILES = NIAK_FILES2CELL(FILES)
%
% INPUTS :
% FILES         (string, cell of strings or a structure where each field is a
%               string or a cell of strings) All those strings are file
%               names.
%
% OUTPUTS :
%
% CELL_FILES    (cell of strings) all file names in FILES stored in a cell
%               of strings (wheter it was initially string, cell of strings
%               or structure does not matter).
%
% COMMENTS : 
% Copyright (c) Pierre Bellec 01/2008

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

num_cell = 1;
cell_files = cell(0);

if isstruct(files)
    list_field = fieldnames(files);

    if ~isempty(list_field);

        for num_f = 1:length(list_field)
            list_files_in = getfield(files,list_field{num_f});

            if isstruct(list_files_in)
                
                cell_tmp = niak_files2cell(list_files_in);
                cell_files(end+1:end+length(cell_tmp)) = cell_tmp;
                num_cell = num_cell + length(cell_tmp);
                
            elseif iscell(list_files_in)
                
                for num_i = 1:length(list_files_in)

                    if ~strcmp(list_files_in{num_i},'gb_niak_omitted')
                        cell_files{num_cell} = list_files_in{num_i};
                        num_cell = num_cell + 1;
                    end
                end
                
            else
                
                if ~strcmp(list_files_in,'gb_niak_omitted')
                    cell_files{num_cell} = list_files_in;
                    num_cell = num_cell + 1;
                end
                
            end
        end % loop over all fields
    end % if ~isempty(list_field)

elseif iscellstr(files)
    cell_files = files;
elseif ischar(files)

    for num_f = 1:size(files)
        if ~strcmp(deblank(files(num_f,:)),'gb_niak_omitted')
            cell_files{num_cell} = deblank(files(num_f,:));
        end
    end

end
