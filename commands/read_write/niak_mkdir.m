function [success,message,messageid] = niak_mkdir(path_name)
%
% _________________________________________________________________________
% SUMMARY NIAK_MKDIR
%
% Create a new directory. The difference between the regular matlab MKDIR
% command and NIAK_MKDIR is that NIAK_MKDIR will create all folders and
% subfolders, while MKDIR will only let you create a subdirectory in an
% existing directory. 
%
% SYNTAX:
% [SUCCESS,MESSAGE,MESSAGEID] = MKDIR(PATH_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_NAME      
%       (string) the name of the path to create
%       
% _________________________________________________________________________
% OUTPUTS:
%
% SUCCESS     
%       (boolean) define the outcome of NIAK_MKDIR. 
%           1 : NIAK_MKDIR executed successfully.
%           0 : an error occurred.
%
% MESSAGE     
%       (string)  define the error or warning message. 
%           empty string : MKDIR executed successfully.
%           message : an error or warning message, as applicable.
%
% MESSAGEID   
%       (string) defining the error or warning identifier.
%           empty string : MKDIR executed successfully.
%           message id: the MATLAB error or warning message
%           identifier
%           
% _________________________________________________________________________
% SEE ALSO:
%
% ERROR, LASTERR, WARNING, LASTWARN
%
% _________________________________________________________________________
% COMMENTS:
%
% Under Linux, this command is equivalent to a system call to the real
% shell command MKDIR. Unfortunately for windows system it is necessary to use this
% workaround :-((. Moreover, the call to MKDIR is slightly different in
% Matlab and Octave. This function fixes that too.
%
% Contrary to the regular MKDIR command, SUCCESS = 1 if the directory
% already exists.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, pipeline, fMRI, PMP

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

list_path = psom_string2words(path_name,{filesep});

if ispc
    % This is windows, include the volume name in the root directory
    path_curr = list_path{1};
    path_curr = [path_curr filesep];
    list_path = list_path(2:end);
else
    % this is a reasonable OS, the root is /
    path_curr = filesep;
end

success = 1;
message = '';
messageid = '';

if exist(path_name)
    return
end

for num_p = 1:length(list_path)
    
    if ~exist(cat(2,path_curr,list_path{num_p}),'dir')
        
        if isempty(path_curr)
            [success,message] = mkdir(list_path{num_p});
        else
             if exist('OCTAVE_VERSION','builtin')
                [success,message] = mkdir(cat(2,path_curr,filesep,list_path{num_p}));
            else
                [success,message] = mkdir(path_curr,list_path{num_p});
            end
        end
        
    end
    
    path_curr = cat(2,path_curr,list_path{num_p},filesep);
    
end
        
        