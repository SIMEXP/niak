function [] = niak_append_ps(file_name,opt_print)
% Append the current figure to an eps file.
%
% SYNTAX:
% [FLAG_FAIL,MESSAGE] = NIAK_APPEND_PS(FILE_NAME,OPT_PRINT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME
%       (string) the name of the output eps file.
%       
% OPT_PRINT
%       (string, default '-dspc2') the option used to call print and 
%       generate the new figure. Note that multiple options can be
%       specified, e.g. '-r300 -dspc2'.
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
% PRINT
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
% In Matlab, this would simply be a print -append FILE_NAME. Note that the
% format of options is slightly different (PRINT requires one argument per
% option, e.g. "print(toto.ps,'-r300','-dspc2')" while this function
% supports "opt_print = '-r300 -dspc2'".
%
% In Octave '-append' is not available, so a workaround was
% implemented using the ghostscript package.
%
% NOTE 2:
% If the output file does not exist, the file is simply created with the
% current figure.
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

if nargin<2
    opt_print = '-dpsc2';
end

if ~exist(file_name,'file')
    
    opt_print = niak_string2words(opt_print);
    sub_print(file_name,opt_print);
    
else
    if ~exist('OCTAVE_VERSION','builtin')
      opt_print = [opt_print ' -append'];
    end
    opt_print = niak_string2words(opt_print);
    
    if exist('OCTAVE_VERSION','builtin')
        
        %% Generate a PS description of the current figure in a temporary file
        %% and read it
        file_eps_tmp1 = niak_file_tmp('_1.eps');
        file_eps_tmp2 = niak_file_tmp('_2.eps');
        sub_print(file_eps_tmp1,opt_print);
        instr_merge = ['gs  -q -dNOPAUSE -dBATCH -dNOPLATFONTS -sOutputFile=' file_eps_tmp2 '  -sDEVICE=pswrite ' file_name ' ' file_eps_tmp1 ' quit.ps'];
        [failed,msg] = system(instr_merge);
        if failed
            error(msg);
        end
        instr_mv = ['mv ' file_eps_tmp2 ' ' file_name];
        [failed,msg] = system(instr_mv);
        if failed
            error(msg)
        end
        
    else
        
        sub_print(file_name,opt_print);
        flag_fail = false;
        message = '';
        
    end
end

function [] = sub_print(file_name,opt_print)

instr_print = ['print(''' file_name ''''];
for num_e = 1:length(opt_print)
    instr_print = [instr_print ',''' opt_print{num_e},''''];
end
instr_print = [instr_print ');'];
eval(instr_print);
