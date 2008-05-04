function [files_in,files_out,opt] = niak_brick_clean(files_in,files_out,opt)

% Clean up some intermediate outputs in a pipeline
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CLEAN(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN        (cell of string) A list of files that need to exist
%                   before the clean up can start. Typically, in a
%                   pipeline, you may want to clean the outputs of stage N
%                   when stage N+1 is complete. In this case, FILES_IN
%                   would be the list of outputs at stage N+1.
%
% FILES_OUT       (empty string) This field is ignored. The clean-up does
%                   not produce any output.
%
% OPT           (structure) with the following fields :
%
%               CLEAN  (cell of string) A list of files that need to be cleaned up. Typically, in a
%                   pipeline, you may want to clean the outputs of stage N
%                   when stage N+1 is complete. In this case, OPT.CLEAN
%                   would be the list of outputs at stage N.
%
%               FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%                      the function prints some infos during the
%                      processing.
%
%               FLAG_TEST (boolean, default 0) if FLAG_TEST equals 1, the
%                      brick does not do anything but update the default 
%                      values in FILES_IN and FILES_OUT.
%               
% OUTPUTS:
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified files in OPT.CLEAN are
% deleted.
%
% COMMENTS
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : 

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CLEAN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_clean'' for more info.')
end

%% Test on formats
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings !');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'clean','flag_verbose','flag_test'};
gb_list_defaults = {{},1,0};
niak_set_defaults

if ~isempty(opt.clean)
    if ~iscellstr(opt.clean)
        error('OPT.CLEAN should be a cell of strings !');
    end
end

if flag_test
    return
end

nb_files = length(opt.clean);

for num_f = 1:nb_files
    file_name = opt.clean{num_f};
    
    if flag_verbose
        fprintf('Deleting file ''%s'' \n',file_name);
    end
    
    delete(file_name)
end