function [in,out,opt] = niak_test_files_preprocess(in,out,opt)
% Test the presence of all expected outputs of the fMRI preprocessing pipeline.
%
% SYNTAX:
% [IN,OUT,OPT] = NIAK_TEST_FILES_PREPROCESS(IN,OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% IN (cell of strings, default see COMMENTS) the list of files to check.
%
% OUT (string) a .mat file that will be generated with two variables:
%   FILES_MISSING (cell of strings) missing files in SOURCE to match TARGET
%   FILES_EXTRA (cell of strings) extra files in SOURCE no found in TARGET
%
% OPT.PATH_RESULTS (string, default see COMMENT) the folder of the results.
% OPT.FILES_IN (structure, default struct()) the FILES_IN structure fed 
%   to the fMRI preprocessing pipeline. If omitted, some minimal information 
%   are gathered from OPT.PATH_RESULTS to build the list of expected outputs.
% OPT.FLAG_TEST (boolean, default 0) if the flag is 1, then the function does not
%   do anything but update IN, OUT, OPT
% OPT.FLAG_VERBOSE (boolean, default 1) if the flag is 1, then the function 
%   prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% IN, OUT, OPT are similar to the inputs, but updated with default values.
% _________________________________________________________________________
% SEE ALSO:
% NIAK_GRAB_ALL_PREPROCESS, NIAK_GRAB_FOLDER
%
% _________________________________________________________________________
% COMMENTS:
%
% Possible results of the test:
%   Pass:    the folder passes the integrity check. 
%   Fail:    the folder is missing some expected files.
%   Warning: the folder contains some additional files. These may be due 
%      to a faulty cleanup in the pipeline, or the OPT.SIZE_OUTPUT
%      parameter was set to something else than 'quality_control'
%
% It is possible to specify the folder of the results of the fMRI 
% preprocessing pipeline in IN rather than the list of files. In this 
% case, the function NIAK_GRAB_FOLDER will be used to get the list of 
% outputs. 
% Also in this case, and in this case only, OPT.PATH_RESULTS does not need to be specified
% (it's using IN instead). Otherwise it is mandatory.
%
% It is also possible not to specify IN and specify OPT.PATH_RESULTS instead, 
% which will be considered as if IN = OPT.PATH_RESULTS. 
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, fMRI preprocessing

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

%% Syntax
if ~exist('in','var')||~exist('out','var')
    error('niak:brick','Bad syntax, type ''help %s'' for more info.',mfilename)
end
   
%% Options
list_fields   = { 'files_in' , 'path_results' , 'flag_verbose' , 'flag_test' };
list_defaults = { struct()   , ''             , true           , false       };
if nargin>2
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end

if isempty(in)
    in = opt.path_results;
end

if ischar(in)
    opt.path_results = in;
end

if isempty(opt.path_results)
    error('Please specify OPT.PATH_RESULTS')
end

if ischar(in) % it's a folder !
    % Build the list of expected outputs
    in = niak_grab_folder(in,[niak_full_path(in) filesep 'logs']); % grab all the files in the folder
end

if opt.flag_test
    return
end

%% Build the list of expected outputs
if length(fieldnames(opt.files_in))>0
    files_exp = niak_grab_all_preprocess(opt.path_results,opt.files_in);
else
    files_exp = niak_grab_all_preprocess(opt.path_results);
end

%% Check for missing files (send back an error if there are any)
files_c = psom_files2cell(files_exp);
mask_missing = ~ismember(files_c,in);
files_missing = files_c(mask_missing);

%% Check for unexpected files (send back a warning if there are any)
mask_else = ~ismember(in,files_c);
files_else = in(mask_else);

%% Save report
save(out,'files_else','files_missing');

%% Throw warning/error if necessary
if any(mask_else)
    warning('Some files found in the results of the fMRI preprocessing pipeline were not expected. See the report for details.');
else
    fprintf('All expected files were found.\n')
end


if any(mask_missing)
    error('Some expected files were not found in the results of the fMRI preprocessing pipeline. See the report for details.');
end
