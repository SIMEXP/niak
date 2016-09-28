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
if ~exist('gb_niak_gb_vars_local','var')&&exist('niak_gb_vars_local.m','file')
    gb_niak_gb_vars_local = true;
    niak_gb_vars_local
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables are needed for very fast initialization %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% What is the operating system ?
comp = computer;
tag_unix = {'SOL2','GLNX','unix','linux'};
tag_windaub = {'PCWIN','windows'};


% All niak var that has an equivalent in psom should be assigned in
% this if block
if ~exist('gb_psom_gb_vars','var')&&exist('psom_gb_vars.m','file')
    gb_psom_gb_vars = true;
    psom_gb_vars
end

if exist('gb_psom_gb_vars','var') 
    % loading common psom vars 
    gb_psom_gb_vars;
    gb_niak_tmp = gb_psom_tmp;
    gb_niak_language = gb_psom_language;
    gb_niak_language_version = gb_psom_language_version;
    gb_niak_OS = gb_psom_OS;
    gb_niak_user = gb_psom_user;
else 
    % tmpfile
    gb_niak_tmp = [tempdir filesep];

    % Is the environment Octave or Matlab ?
    if exist('OCTAVE_VERSION','builtin')    
        gb_niak_language = 'octave'; %% this is octave !
    else
        gb_niak_language = 'matlab'; %% this is not octave, so it must be matlab
    end

    % Get langage version
    if strcmp(gb_niak_language,'octave');
        gb_niak_language_version = OCTAVE_VERSION;
    else
        gb_niak_language_version = version;
    end 


    if max(niak_find_str_cell(comp,tag_unix))>0
        gb_niak_OS = 'unix';
    elseif max(niak_find_str_cell(comp,tag_windaub))>0
        gb_niak_OS = 'windows';
    elseif ~isempty(findstr('linux',comp))
        gb_niak_OS = 'unix';
    else
        gb_niak_OS = 'unkown';
    end

    %% getting user name.
    switch (gb_niak_OS)
    case 'unix'
        gb_niak_user = getenv('USER');
    case 'windows'
        gb_niak_user = getenv('USERNAME');	
    otherwise
        gb_niak_user = 'unknown';
    end
end

% The command to zip files
gb_niak_zip = 'gzip -f'; 

% The command to unzip files
gb_niak_unzip = 'gunzip -f'; 

% The extension of zipped files
gb_niak_zip_ext = '.gz'; 

if exist('flag_gb_niak_fast_gb','var')&&flag_gb_niak_fast_gb
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables describe the folders and external tools NIAK is using for various tasks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The folder of the CIVET pipeline
gb_niak_path_civet = '/data/aces/aces1/quarantines/Linux-i686/Feb-14-2008/CIVET-1.1.9' ;

% program to display ps files
gb_niak_viewerps = 'evince';

% program to display jpg files
gb_niak_viewerjpg = 'eog';

% program to display svg files
gb_niak_viewersvg ='eog';

% The command to convert ps or eps documents into the pdf file format
gb_niak_ps2pdf = 'ps2pdf';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NIAK version
gb_niak_version = 'v0.17.0';

%% Target for tests
gb_niak_target_test = 'ac';

%% In which path is NIAK ?
str_read_vol = which('niak_read_vol');
if isempty(str_read_vol)
    error('NIAK is not in the path ! (could not find NIAK_READ_VOL)')
end
tmp_folder = niak_string2words(str_read_vol,{filesep});
gb_niak_path_niak = filesep;
for num_f = 1:(length(tmp_folder)-3)
    gb_niak_path_niak = [gb_niak_path_niak tmp_folder{num_f} filesep];
end

%% In which path are the templates ?
gb_niak_path_template = cat(2,gb_niak_path_niak,'template',filesep);

%% In which path is the NIAK demo ?
if ~exist('gb_niak_path_demo','var')
    gb_niak_path_demo = cat(2,gb_niak_path_niak,'data_demo',filesep);
end

%% In which format is the niak demo ?
gb_niak_format_demo = 'minc2';
if exist(cat(2,gb_niak_path_demo,'anat_subject1.mnc'),'file')
    gb_niak_format_demo = 'minc2';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.mnc.gz'),'file')
    gb_niak_format_demo = 'minc1';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.nii'),'file')
    gb_niak_format_demo = 'nii';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.img'),'file')
    gb_niak_format_demo = 'analyze';
end
