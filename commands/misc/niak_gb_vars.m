
%% Here are important NIAK variables. Whenever needed, NIAK commands will call
%% this script to initialize the variables. If NIAK does not behave the way
%% you want, this might be the place to fix that.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% User may want to change some of the following variables %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_tmp = cat(2,filesep,'tmp',filesep); % where to store temporary files

gb_niak_viewerps = 'evince'; % program to display ps files

gb_niak_viewerjpg = 'eog'; % program to display jpg files

gb_niak_viewersvg = 'eog'; % program to display svg files

gb_niak_zip = 'gzip'; % The command to zip files

gb_niak_format_demo = 'minc2'; % The file format of the default data. That could be 'minc1','minc2','analyze' or 'nifti'.

gb_niak_path_demo = cat(2,'/data/aces/aces1/pbellec/public/data_niak/',gb_niak_format_demo,filesep); % Where to find demo data

gb_niak_path_civet = '/data/aces/aces1/quarantines/Linux-i686/Feb-14-2008/'; % Where to find the CIVET quarantine

gb_niak_init_civet = 'init-sge.sh'; % Which script to use for initializing the CIVET quarantine

gb_niak_command_matlab = 'matlab'; % how to invoke matlab   

gb_niak_command_octave = 'octave-2.9.9'; % how to invoke octave

gb_niak_sge_options = '-q all.q@audrey,all.q@banquo,all.q@caius,all.q@denney,all.q@dow,all.q@gertrude,all.q@gobbo,all.q@gonzalo,all.q@grumpy,all.q@gypsy,all.q@oberon,all.q@penfolds,all.q@phebe,all.q@philemon,all.q@pluto,all.q@portia,all.q@rosaline,all.q@silius,all.q@snout,all.q@snug,all.q@taylor,all.q@theseus,all.q@valhalla,all.q@yeatman,all.q@zeus'; % send jobs only to the "fetch" systems

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_version = '0.1.2'; % 

if exist('OCTAVE_VERSION')    
    gb_niak_language = 'octave'; %% this is octave !
else
    gb_niak_language = 'matlab'; %% this is not octave, so it must be matlab
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

%% getting user name
switch (gb_niak_OS)
case 'unix'
	gb_niak_user = getenv('USER');
case 'windows'
	gb_niak_user = getenv('USERNAME');	
otherwise
	gb_niak_user = 'unknown';
end