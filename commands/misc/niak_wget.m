function [status,msg,data] = niak_wget(data)
% Fetch a dataset using wget
%
% SYNTAX: [STATUS,MSG,DATA] = NIAK_WGET(DATA)
%
% DATA.TYPE (string, default '') If provided, this sets the default for datasets
%    'data_test_niak_mnc1': The small version of the demoniak dataset.
%    'target_test_niak_mnc1': The results of all NIAK pipelines on the demoniak minc1 data.
%    'single_subject_cambridge_preprocessed_nii': preprocessed data for a single subject.
% DATA.URL (string, see DATA.TYPE for default) the url to get the dataset.
% DATA.NAME (string, see DATA.TYPE for default) the name of the file to retrieve.
% DATA.PATH (string, [pwd filesep DATA.NAME], without the extension of the name) 
%     where to download the dataset.
%
% STATUS (integer) the status of the grabbing process. 0: OK, positive values: problem
% MSG (string) feedback from the grabbing process
%
% NOTE 1: If the folder DATA.PATH exists, the grabber assumes the data is present and 
%   does not do anything. 
% NOTE 2: Files are expeted to come as .zip.
% NOTE 3: if DATA is a string, it is treated as if a single field DATA.TYPE was 
%   provided, and everything else gets assigned default values.
% NOTE 4: See licensing information in the code.

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

% If the user provides a string, treats it as data.type
if ischar(data)
    data = struct('type',data);
end

% Set loose defaults
data = psom_struct_defaults( data , ...
    { 'path' , 'name' , 'url' , 'type' } , ...
    { ''     , ''     , ''    , ''     });
    
% Set actual defaults, based on data.type
switch data.type;
    case 'data_test_niak_mnc1'
        data.name = 'data_test_niak_mnc1.zip';
        data.url  = ['http://www.nitrc.org/frs/download.php/7241/' data.name];
    case 'target_test_niak_mnc1'  
        data.name = ['target_test_niak_mnc1-' gb_niak_target_test '.zip']
        data.url  = ['https://github.com/simexp/niak_target/archive/' data.name];
    case 'single_subject_cambridge_preprocessed_nii'
        data.name = 'single_subject_cambridge_preprocessed_nii.zip';
        data.url = 'http://www.nitrc.org/frs/download.php/6784/single_subject_cambridge_preprocessed_nii.zip';
    case 'cambridge_template_mnc'
        data.name = 'template_cambridge_basc_multiscale_mnc_sym.zip';
        data.url = 'http://files.figshare.com/1861821/template_cambridge_basc_multiscale_mnc_sym.zip';
    case 'cambridge_template_nii'
        data.name = 'template_cambridge_basc_multiscale_nii_sym.zip';
        data.url = 'http://files.figshare.com/1861819/template_cambridge_basc_multiscale_nii_sym.zip';
    case ''
        if isempty(data.name)||isempty(data.url)
            error('Please specify DATA.TYPE or DATA.NAME/DATA.URL')
        end
    otherwise
        error('Type %s is not supported',data.type)
end
[path_name,base_name,ext_name] = fileparts(data.name);
if isempty(data.path)
    data.path = [pwd filesep base_name];
end

if ~psom_exist(data.path)
    % The folder is not present, download data
    psom_mkdir(data.path);
    [status,msg] = system(['env -i bash -ilc "wget ' data.url ' -P ' data.path ' "']);
    if status
        warning('There was a problem downloading the test data: %s',msg)
    end    
    if strcmp(data.type, 'target_test_niak_mnc1')
        [status,msg] = system(['unzip ' data.path filesep data.name ' -d '  data.path]);
        system(['mv ' data.path filesep '*/* '  data.path ])
        system(['rm ' data.path filesep '*target*' ])
    else
        [status,msg] = system(['unzip ' data.path filesep data.name  ' -d '  data.path '/..']);
    end
    if status
        warning('There was a problem unzipping the dataset: %s',msg)
    end    
    psom_clean([data.path filesep data.name]) 
else
    % The folder already exists, don't do anything
    status = 0;
    msg = 'Folder already present. Nothing to do';
end
