
%% Here are important NIAK variables. Whenever needed, NIAK commands will call
%% this script to initialize the variables. If NIAK does not behave the way
%% you want, this might be the place to fix that.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables are needed for very fast initialization %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_tmp = cat(2,filesep,'tmp',filesep); % where to store temporary files

gb_niak_zip = 'gzip -f'; % The command to zip files

gb_niak_unzip = 'gunzip -f'; % The command to unzip files

gb_niak_zip_ext = '.gz'; % The extension of zipped files

if exist('flag_gb_niak_fast_gb','var')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables need to be changed to configure the pipeline %%
%% system                                                               %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_shell = '/bin/sh'; %% Shell type when running a pipeline

gb_niak_path_quarantine = '/data/aces/aces1/quarantines/Linux-i686/Feb-14-2008/'; % Where to find the CIVET quarantine

gb_niak_path_civet = '/data/aces/aces1/quarantines/Linux-i686/Feb-14-2008/CIVET-1.1.9'; % The folder of the CIVET pipeline

if length(findstr(gb_niak_shell,'csh'))>0
    gb_niak_init_civet_local = 'init-sge.csh'; % Use the CSH shell initialization script
else
    gb_niak_init_civet_local = 'init-sge.sh'; % Use the SH shell initialization script
end

if length(findstr(gb_niak_shell,'csh'))>0
    gb_niak_init_civet = 'init.csh'; % Use the CSH shell initialization script
else
    gb_niak_init_civet = 'init.sh'; % Use the CSH shell initialization script
end

gb_niak_command_matlab = 'matlab -nojvm -nosplash'; % how to invoke matlab   

gb_niak_command_octave = 'octave-2.9.9'; % how to invoke octave

gb_niak_sge_options = ''; % Options for the sge qsub system, example : '-q all.q@yeatman,all.q@zeus' will force qsub to only use the yeatman workstation;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables describe the folders and external tools NIAK is using for various tasks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_viewerps = 'evince'; % program to display ps files

gb_niak_viewerjpg = 'eog'; % program to display jpg files

gb_niak_viewersvg = 'eog'; % program to display svg files

gb_niak_ps2pdf = 'ps2pdf'; % The command to convert ps or eps documents into the pdf file format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NIAK version
gb_niak_version = '0.4'; % 

%% Is the environment Octave or Matlab ?
if exist('OCTAVE_VERSION')    
    gb_niak_language = 'octave'; %% this is octave !
else
    gb_niak_language = 'matlab'; %% this is not octave, so it must be matlab
end

%% Get langage version
if strcmp(gb_niak_language,'octave');
    gb_niak_language_version = OCTAVE_VERSION;
else
    gb_niak_language_version = version;
end 

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
gb_niak_path_demo = cat(2,gb_niak_path_niak,'data_demo',filesep);

%% In which format is the niak demo ?
gb_niak_format_demo = 'minc2';
if exist(cat(2,gb_niak_path_demo,'anat_subject1.mnc'))
    gb_niak_format_demo = 'minc2';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.mnc.gz'))
    gb_niak_format_demo = 'minc1';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.nii'))
    gb_niak_format_demo = 'nii';
elseif exist(cat(2,gb_niak_path_demo,'anat_subject1.img'))
    gb_niak_format_demo = 'analyze';
end

%% What is the operating system ?
comp = computer;
tag_unix = {'SOL2','GLNX','unix','linux'};
tag_windaub = {'PCWIN','windows'};

if max(niak_find_str_cell(comp,tag_unix))>0
    gb_niak_OS = 'unix';
elseif max(niak_find_str_cell(comp,tag_windaub))>0
    gb_niak_OS = 'windows';
else
    warning('System %s unknown!\n',comp);
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