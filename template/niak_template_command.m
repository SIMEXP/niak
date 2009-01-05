function opt_out = niak_template_command(in_arg,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_TEMPLATE_COMMAND
%
% This is a dummy .m files to show how to format a command function in
% NIAK.
%
% SYNTAX :
% OPT_OUT = NIAK_TEMPLATE_COMMAND(IN_ARG,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% IN_ARG
%       (string) That argument needs to be specified. If note, it will
%       crash the function.
%
% OPT
%       (structure) with the following fields :
%
%       ARG1
%           (numeric) That argument is necessary to the command. If absent,
%           it will produce an error message.
%
%       ARG2 
%           (string, default 'toto') That argument is optional. If the
%           field is absent, or left empty, the default value 'toto' will
%           be used.
%
%       ARG3
%           (string, default 'tata') That third argument is optional too.
%           If the field is absent, the default value 'tata' will be
%           applied. An empty value will be left "as it is" though.
%
% _________________________________________________________________________
% OUTPUTS :
%
% OPT_OUT
%       (structure) same as OPT, except that the default values have been
%       updated.
%
% _________________________________________________________________________
% SEE ALSO :
%
% http://code.google.com/p/niak/wiki/Commands
%
% _________________________________________________________________________
% COMMENTS
%
% That code is just to demonstrate the guidelines for NIAK commmands. It is
% also a good idea to start a new command project by editing this file and
% saving it under the new command name.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : NIAK, documentation, template, command

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flag_gb_niak_fast_gb = true; % Only load the most important global variables for fast initialization
niak_gb_vars % Load the niak global variables, just in case
  
%% Syntax 
if ~exist('in_arg','var')||~exist('opt','var')
    error('Syntax : OPT_OUT = NIAK_TEMPLATE_COMMAND(IN_ARG,OPT) ; for more infos, type ''help niak_template_command''.')
end

%% Setting up default values for the OPT structure
gb_name_structure = 'opt';
gb_list_fields = {'arg1','arg2','arg3'};
gb_list_defaults = {NaN,'','tata'};
niak_set_defaults

if isempty(arg2)
    opt.arg2 = 'toto';
    arg2 = 'toto';
end

%% Checking argument types
if ~ischar(in_arg)
    error('IN_ARG should be a string');
end

if ~isnumeric(arg1)
    error('OPT.ARG1 should be numeric');
end

if ~ischar(arg2)
    error('OPT.ARG2 should be a string');
end

if ~ischar(arg3)
    error('OPT.ARG3 should be a string');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the function starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Sending back the updated OPT structure
opt_out = opt;
