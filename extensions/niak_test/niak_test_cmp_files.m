function [in,out,opt] = niak_test_cmp_files(in,out,opt)
% Test that two sets of files are identical.
%
% SYNTAX:
% [IN,OUT,OPT] = NIAK_TEST_CMP_FILES(IN,OUT,OPT)
%
% IN.SOURCE (cell of strings) a list of files.
% IN.TARGET (cell of strings) another list of files.
%
% OUT (string) the name of a .csv (report) file
% 
% OPT.BASE_SOURCE (string) the base folder for SOURCE files.
% OPT.BASE_TARGET (string) the base folder for TARGET files.
% OPT.BLACK_LIST_SOURCE (string) the black list to grab files from SOURCE,
%   if IN.SOURCE is omitted.
% OPT.BLACK_LIST_TARGET (string) the black list to grab files from TARGET,
%   if IN.TARGET is omitted.
% OPT.EPS (scalar, default 10^(-5)) the amount of "numeric noise" tolerated to 
%   declare two volumes to be equal
% OPT.FLAG_SOURCE_ONLY (boolean, default false) when comparing two matlab structures,
%   the tests will only consider fields found in the source, i.e. if there are 
%   more fields in the target, those will be ignored.
% OPT.FLAG_TEST (boolean, default 0) if the flag is 1, then the function does not
%   do anything but update IN, OUT, OPT
% OPT.FLAG_VERBOSE (boolean, default 1) if the flag is 1, then the function 
%   prints some infos during the processing.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_CMP_FILES
%
% The documentation of the report .csv file as well as the definition of 
% identical files is in the COMMENTS section of NIAK_BRICK_CMP_FILES
%
% If IN.SOURCE or IN.TARGET is omitted, the brick will call NIAK_GRAB_FOLDER
% to grab all files in SOURCE and TARGET.
%
% The main result of the test is:
%   Pass:    the two versions of the preprocessing are identical 
%   Fail:    the two versions of preprocessing differ 
%   Warning: the files that are found in both SOURCE and TARGET are identical,
%            but some files could only be found in either SOURCE or TARGET
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, files

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

%% Compare the source and target
[in,out,opt] = niak_brick_cmp_files(in,out,opt);

if opt.flag_test
    return
end

%% Check the results of the comparison
[tab,lx,ly] = niak_read_csv(out);
flag_diff = any(tab(:,3)==0);
flag_miss = any(tab(:,1)==0)||any(tab(:,2)==0);

%% Issue status/message
if flag_diff    
    error('Some files are different in SOURCE and TARGET. See %s for more details.',out);        
elseif flag_miss    
    warning('All files in common were identical, but some files were unique to either SOURCE or TARGET. See %s for more details.',out);
else     
    fprintf('All files are identical.');
end
