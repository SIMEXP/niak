% This is a script to define important NIAK variables. Whenever needed, 
% NIAK commands will call this script to initialize the variables. If NIAK 
% does not behave the way you want, this might be the place to fix that.
%
% IF a variable called FLAG_GB_NIAK_FAST_GB is found in memory and is true,
% only a very limited number of global variables will be initialized.
% _________________________________________________________________________
% COMMENT:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Dpartement d'informatique et de recherche oprationnelle
% Centre de recherche de l'institut de Griatrie de Montral
% Universit de Montral, 2010-2015
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : NIAK

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


%% Use the local configuration file if any
if ~exist('gb_niak_gb_vars','var')
    gb_niak_gb_vars = true;
    if exist('niak_gb_vars_local.m','file')
        niak_gb_vars_local
    end
else
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables are needed for very fast initialization %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GB_NIAK = struct()

if isfield(GB_NIAK, 'loaded')
    return    
else
    GB_NIAK.loaded = true ;
end

%% What is the operating system ?
comp = computer;
tag_unix = {'SOL2','GLNX','unix','linux'};
tag_windaub = {'PCWIN','windows'};


% All niak var that has an equivalent in psom should be assigned in
% this if block
if exist('psom_gb_vars.m','file')
    psom_gb_vars;
    GB_NIAK.tmp = gb_psom_tmp;
    GB_NIAK.language = gb_psom_language;
    GB_NIAK.language_version = gb_psom_language_version;
    GB_NIAK.OS = gb_psom_OS;
    GB_NIAK.user = gb_psom_user;
else 
    % tmpfile
    GB_NIAK.tmp = [tempdir filesep];

    % Is the environment Octave or Matlab ?
    if exist('OCTAVE_VERSION','builtin')    
        GB_NIAK.language = 'octave'; %% this is octave !
    else
        GB_NIAK.language = 'matlab'; %% this is not octave, so it must be matlab
    end

    % Get langage version
    if strcmp(GB_NIAK.language,'octave');
        GB_NIAK.language_version = OCTAVE_VERSION;
    else
        GB_NIAK.language_version = version;
    end 


    if max(niak_find_str_cell(comp,tag_unix))>0
        GB_NIAK.OS = 'unix';
    elseif max(niak_find_str_cell(comp,tag_windaub))>0
        GB_NIAK.OS = 'windows';
    elseif ~isempty(findstr('linux',comp))
        GB_NIAK.OS = 'unix';
    else
        GB_NIAK.OS = 'unkown';
    end

    %% getting user name.
    switch (GB_NIAK.OS)
    case 'unix'
        GB_NIAK.user = getenv('USER');
    case 'windows'
        GB_NIAK.user = getenv('USERNAME');
    otherwise
        GB_NIAK.user = 'unknown';
    end
end

% The command to zip files
GB_NIAK.zip = 'gzip -f';

% The command to unzip files
GB_NIAK.unzip = 'gunzip -f';

% The extension of zipped files
GB_NIAK.zip_ext = '.gz';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables describe the folders and external tools NIAK is using for various tasks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The folder of the CIVET pipeline
GB_NIAK.path_civet = '/data/aces/aces1/quarantines/Linux-i686/Feb-14-2008/CIVET-1.1.9' ;

% program to display ps files
GB_NIAK.viewerps = 'evince';

% program to display jpg files
GB_NIAK.viewerjpg = 'eog';

% program to display svg files
GB_NIAK.viewersvg ='eog';

% The command to convert ps or eps documents into the pdf file format
GB_NIAK.ps2pdf = 'ps2pdf';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NIAK version
GB_NIAK.version = 'v0.19.1';

%% Target for tests
GB_NIAK.target_test = 'ah';

%% In which path is NIAK ?
str_read_vol = which('niak_read_vol');
if isempty(str_read_vol)
    error('NIAK is not in the path ! (could not find NIAK_READ_VOL)')
end
tmp_folder = niak_string2words(str_read_vol,{filesep});
GB_NIAK.path_niak = filesep;
for num_f = 1:(length(tmp_folder)-3)
    GB_NIAK.path_niak = [GB_NIAK.path_niak tmp_folder{num_f} filesep];
end

%% In which path are the templates ?
GB_NIAK.path_template = cat(2,GB_NIAK.path_niak,'template',filesep);

%% In which path is the NIAK demo ?
if ~exist('GB_NIAK.path_demo','var')
    GB_NIAK.path_demo = cat(2,GB_NIAK.path_niak,'data_demo',filesep);
end

%% In which format is the niak demo ?
GB_NIAK.format_demo = 'minc2';
if exist(cat(2,GB_NIAK.path_demo,'anat_subject1.mnc'),'file')
    GB_NIAK.format_demo = 'minc2';
elseif exist(cat(2,GB_NIAK.path_demo,'anat_subject1.mnc.gz'),'file')
    GB_NIAK.format_demo = 'minc1';
elseif exist(cat(2,GB_NIAK.path_demo,'anat_subject1.nii'),'file')
    GB_NIAK.format_demo = 'nii';
elseif exist(cat(2,GB_NIAK.path_demo,'anat_subject1.img'),'file')
    GB_NIAK.format_demo = 'analyze';
end

%% Use the local configuration file if any
if exist('niak_gb_vars_local.m','file')
    niak_gb_vars_local
end
