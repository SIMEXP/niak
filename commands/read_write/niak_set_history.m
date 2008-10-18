function hdr2 = niak_set_history(hdr,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SET_HISTORY
%
% Write a new line of history in a header
%
% SYNTAX
% HDR2 = NIAK_SET_HISTORY(HDR,OPT)
% 
% _________________________________________________________________________
% INPUTS:
%
% HDR           
%       (structure) header of a 3D or 3D+t data file (see NIAK_READ_VOL).
%
% OPT           
%       (struture) with the following fields :
%
%       COMMAND 
%           (string, default '') the name of the command applied.
%
%       FILES_IN   
%           (structure, cell of strings or strings, default struct()) List 
%           of input files.
%
%       FILES_OUT  
%           (structure, cell of strings or strings, default struct() ) List 
%           of output files.
%
%       COMMENT 
%           (string, default struct()) user-specified comment.
% 
% _________________________________________________________________________
% OUTPUTS:
%
% HDR2          
%       (structure) same as HDR, yet the HDR.INFO.HISTORY has a new line.
% 
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : minc

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up default values for the header %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gb_name_structure = 'opt';
gb_list_fields = {'command','files_in','files_out','comment'};
gb_list_defaults = {'',struct([]),struct([]),''};
niak_set_defaults

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Building one line of history %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generic info (date, username, version of the NIAK, etc...)
str_hist = datestr(now);
str_hist = [str_hist ' ' gb_niak_user ' on a ' gb_niak_OS ' system used NIAK v' gb_niak_version '>>>> '];

%% Name of the command
if ~isempty(opt.command)
    str_hist = [str_hist opt.command ' : '];
end

str_hist = [str_hist niak_files2str(opt.files_in,'in:')]; % List of inputs
str_hist = [str_hist niak_files2str(opt.files_out,'out:')]; % List of outputs

%% Comment
if ~isempty(opt.comment)
    str_hist = [str_hist ' ,COMMENT: ' opt.comment];
end   

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Updating the header  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr2 = hdr;
flag_done = 0;
while (length(hdr2.info.history)>1)&(flag_done == 0)
    if (double(hdr2.info.history(end))==10)
        hdr2.info.history = hdr2.info.history(1:end-1);
    else
        flag_done = 1;
    end
end

if (isempty(hdr2.info.history))|strcmp(hdr2.info.history,char(10))
    hdr2.info.history = [str_hist char(10)];
else
    hdr2.info.history = [hdr2.info.history char(10) str_hist char(10)];    
end
