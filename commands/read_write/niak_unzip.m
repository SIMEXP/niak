function [file_tmp,flag_zip] = niak_unzip(file_name)
% Unzip a zipped file 
%
% SYNTAX: [FILE_TMP,FLAG_ZIP] = NIAK_UNZIP(PATH_NAME)
%
% FILE_NAME (string) the name to a zipped file.
% FILE_TMP (string) the name of the unzipped file. 
% FLAG_ZIP (boolean) true if the file was indeed zipped. 
%
% If the file is zipped, a temporary unzipped file is created. 
% If the file is not zipped, FILE_TMP is identical to FILE_NAME. 
%           
% See license in the code. 
 
% Copyright (c) Pierre Bellec, 2016.
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2016
% Maintainer: pierre.bellec@criugm.qc.ca
% See licensing information in the code.
%
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

[path_f,name_f,type] = fileparts(file_name);

flag_zip = strcmp(type,'.gz');
if flag_zip
    %% The file is zipped... Unzip it first and start reading                  
    [path_f_tmp,name_f,type] = fileparts(name_f);
    file_tmp = niak_file_tmp([name_f type '.gz']);
    
    [succ,msg] = system(cat(2,'cp "',file_name,'" ',file_tmp));
    if succ~=0
        error(msg)
    end
    
    instr_unzip = cat(2,'gunzip -f "',file_tmp,'"');
    
    [succ,msg] = system(instr_unzip);
    if succ ~= 0
        error(cat(2,'niak:read: ',msg,'. There was a problem unzipping the file. Please check that the command ''',gb_niak_unzip,''' works, or change this command using the variable GB_NIAK_UNZIP in the file NIAK_GB_VARS'));
    end
    file_tmp = file_tmp(1:end-length('.gz'))
else
    file_tmp = file_name;
end  