function [files_in,files_out,opt] = niak_brick_clean(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_CLEAN
%
% Clean up files (used to get rid of some intermediate outputs in a 
% pipeline)
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CLEAN(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (string, cell of string or structure) 
%       A list of files that need to exist before the clean up can start. 
%       The files can be organized as a cell of strings or nested 
%       structures. Typically, in a pipeline, you may want to clean the 
%       outputs of stage N when stage N+1 is complete. 
%       In this case, FILES_IN would be the list of outputs at stage N+1.
%
%  * FILES_OUT       
%       (empty cell) This field is ignored. The clean-up does not produce 
%       any output.
%
%  * OPT           
%       (structure) with the following fields :
%
%       CLEAN  
%           (string, cell of string or structure) A list of files that 
%           need to be cleaned up. The files can be organized as a 
%           cell of strings or nested structures. 
%           Typically, in a pipeline, you may want to clean the outputs of 
%           stage N when stage N+1 is complete. In this case, OPT.CLEAN
%           would be the list of outputs at stage N.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT, and OPT.
%               
% _________________________________________________________________________
% OUTPUTS
%
% If the files in FILES_IN do not exist, the function simply issues a
% warning and quit.
%
% If the files in FILES_IN exist, the files in OPT.CLEAN are deleted.
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified files in OPT.CLEAN are
% deleted.
%
% _________________________________________________________________________
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

files_in = niak_files2cell(files_in);

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'clean','flag_verbose','flag_test'};
gb_list_defaults = {NaN,1,0};
niak_set_defaults

opt.clean = niak_files2cell(opt.clean);

files_out = {};

if flag_test
    return
end

%% Test if all the input files exist
nb_files_in = length(files_in);
flag_clean = 1;

for num_fi = 1:length(files_in);
    if ~ exist (files_in{num_fi},'file')
        warning(cat(2,'I could not find the file ',files_in{num_fi},'. No cleaning for now !'));
    end
    flag_clean = flag_clean & exist(files_in{num_fi},'file');
end

%% If all the input files exist, remove the files in OPT.CLEAN
if flag_clean

    nb_files = length(opt.clean);

    for num_f = 1:nb_files
        file_name = opt.clean{num_f};

        if flag_verbose
            fprintf('Deleting file ''%s'' \n',file_name);
        end

        instr_delete = ['rm -rf ',file_name];
        [err,msg] = system(instr_delete);
        if err~=0
            warning('There was a problem deleting file %s. Error message : %s',file_name,msg);
        end
    end
end