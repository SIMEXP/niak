function [status,msg,path_demoniak] = niak_grab_test_demoniak(path_demoniak)
% Grabs the test demoniak dataset
% SYNTAX: [STATUS,MSG] = NIAK_GRAB_TEST_DEMONIAK(PATH_DEMONIAK)
%
% PATH_DEMONIAK (string, default [pwd filesep 'data_test_niak_mnc1' filesep]) the path
%   to the demoniak dataset
% STATUS (integer) the status of the grabbing process. 0: OK, positive values: problem
% MSG (string) feedback from the grabbing process
%
% NOTE: If the folder PATH_DEMONIAK exists, the grabber assumes the data is present and 
% does not do anything. See licensing information in the code.

% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Griatrie de Montral, Dpartement d'informatique et de recherche 
% oprationnelle, Universit de Montral, 2012-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : test, NIAK, fMRI preprocessing, pipeline, DEMONIAK

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

niak_gb_vars

% Default folder
if (nargin<1)||isempty(path_test.demoniak)
    path_test.demoniak = [pwd filesep 'data_test_niak_mnc1' filesep];
end

if ~psom_exist(path_test.demoniak)
    % The folder is not present, download data
    
    % Clean older archives, if present
    psom_clean('data_test_niak_mnc1.zip')
    
    if exist('gb_niak_url_test_niak','var')&&~isempty(gb_niak_url_test_niak)
        [status,msg] = system(['wget ' gb_niak_url_test_niak]);
        if status
            error('There was a problem downloading the test data: %s',msg)
        end
    else
        error('Automatic download of the test data is not supported for this version of NIAK')
    end
    [status,msg] = system('unzip data_test_niak_mnc1.zip');
    psom_clean('data_test_niak_mnc1.zip')    
else
    status = 0;
    msg = 'Folder already present. Nothing to do';
end