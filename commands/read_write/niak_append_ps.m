function [flag_fail,message] = niak_append_ps(file_name)
%
% _________________________________________________________________________
% SUMMARY NIAK_APPEND_EPS
%
% Append the current figure to an eps file.
%
% SYNTAX:
% [FLAG_FAIL,MESSAGE] = NIAK_APPEND_EPS(PATH_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME
%       (string) the name of the output eps file.
%       
% _________________________________________________________________________
% OUTPUTS:
%
% FLAG_FAIL
%       (boolean) define the outcome of NIAK_APPEND_EPS 
%           0 : NIAK_APPEND_EPS executed successfully.
%           1 : an error occurred.
%
% MESSAGE     
%       (string)  define the error or warning message. 
%           empty string : NIAK_APPEND_EPS executed successfully.
%           message : an error or warning message, as applicable.
%
% _________________________________________________________________________
% SEE ALSO:
%
% PRINT
%
% _________________________________________________________________________
% COMMENTS:
%
% In Matlab, this would simply be a print -append FILE_NAME.
%
% In Octave this functionality is not available, so a workaround was
% implemented using the PSMERGE functions (comes with the package PSUTILS).
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : EPS

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

if exist('OCTAVE_VERSION','builtin')
    
    %% Generate a PS description of the current figure in a temporary file
    %% and read it
    file_eps_tmp1 = niak_file_tmp('_1.eps');            
    print(file_eps_tmp1,'-dpsc2');    
    hf2 = fopen(file_eps_tmp1,'r');
    data = fread(hf2,Inf,'uint8');
    fclose(hf2);
    delete(file_eps_tmp1);    
    
    %% Append the description to the PS file
    hf = fopen(file_name,'a+');    
    fwrite(hf,data);
    fclose(hf);
    

else
    
    print(file_name,'-append','-dpsc2');
    flag_fail = false;
    message = '';
    
end

