function str_files = niak_files2str(files,pref)

% Convert a string, cell of strings or a structure where each field is a
% string or a cell of strings into one single string, formatted for PMP
%
% SYNTAX
% STR_FILES = NIAK_FILES2STR(FILES)
% 
% INPUTS
% FILES         (string, cell of strings or a structure where each field is a
%               string or a cell of strings) All those strings are file
%               names.
%
% PREF          (string)
% 
% OUTPUTS
% STR_FILES     (string) all file names in FILES are concatenated in a
%               string of the form '[PREFfilename1]', '[PREFfilename2]' ...
% 
% COMMENTS
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

if nargin < 2
    pref = '';
end


str_files = '';


if isstruct(files)
    list_field = fieldnames(files);
    
    if ~isempty(list_field);

        for num_f = 1:length(list_field)
            list_files_in = getfield(files,list_field{num_f});

            if iscell(list_files_in)
                for num_i = 1:length(list_files_in)

                    if ~strcmp(list_files_in{num_i},'gb_niak_omitted')
                        if isempty(str_files)
                            str_files = [str_files '"' pref list_files_in{num_i} '"'];
                        else
                            str_files = [str_files ', ' '"' pref list_files_in{num_i} '"'];
                        end
                    end
                end
            else
                if ~strcmp(list_files_in,'gb_niak_omitted')
                    if isempty(str_files)
                        str_files = [str_files '"' pref list_files_in '"'];
                    else
                        str_files = [str_files ', ' '"' pref list_files_in '"'];
                    end
                end
            end

        end
    end
    
elseif iscellstr(files)

    if ~isempty(files);
    
        for num_f = 1:length(list_field)
            if ~strcmp(files{num_f},'gb_niak_omitted')
                if isempty(str_files)
                    str_files = [str_files '"' pref files{num_f} '"'];
                else
                    str_files = [str_files ', ' '"' pref files{num_f} '"'];
                end
            end
        end

    end
    
elseif ischar(files)
    
    if ~strcmp(files,'gb_niak_omitted')
        str_files = [str_files '"' pref files '"'];
    end
    
end
