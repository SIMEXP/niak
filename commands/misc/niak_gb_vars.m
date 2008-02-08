
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gb_niak_version = '0.0'; % 

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