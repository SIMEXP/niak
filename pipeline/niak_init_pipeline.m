function file_pipeline = niak_init_pipeline(pipeline,opt)

% Convert a matlab-based pipeline structure into a set of PERL and BASH 
% scripts ready to run using the poor man's pipeline (PMP) PERL library.
%
% SYNTAX:
% FILE_PIPELINE = NIAK_INIT_PIPELINE(PIPELINE,OPT)
%
% INPUTS:
% PIPELINE      (structure) a matlab structure which defines a pipeline.
%                       Each field <STAGE_NAME> is a structure. Note that 
%                       <STAGE_NAME> will be used to name jobs in PMP and 
%                       set dependencies. Note also that, by
%                       definition of a matlab structure, all <STAGE_NAME>
%                       are distinct from each other). <STAGE_NAME> has the
%                       following fields : 
%               
%               LABEL (string, default '') any string you want. This will only be used
%                       in the verbose mode, and in the dot graph
%                       recapitulating all the jobs and dependencies.
%
%               COMMAND (string) the name of the command you want to apply at 
%                       this stage. This command can use the variables 
%                       FILES_IN, FILES_OUT and OPT. Example :
%                       'niak_brick_something(files_in,files_out,opt);'
%
%               FILES_IN (string, cell of strings, structure) the argument
%                      FILES_IN of the BRICK. Note that for properly
%                      handling dependencies, this field needs to contain
%                      the exact name of the file (no wildcards, no '' for
%                      default values). One way is to run the command with
%                       OPT.FLAG_TEST = 1 a first time in order to get all
%                       default values set for you.
%
%               FILES_OUT (string, cell of strings, structure) the argument
%                      FILES_OUT of the BRICK. Note that for properly
%                      handling dependencies, this field needs to contain
%                      the exact name of the file (no wildcards, no '' for
%                      default values). One way is to run the command with
%                       OPT.FLAG_TEST = 1 a first time in order to get all
%                       default values set for you.
%
%               OPT (string, structure) the argument
%                      FILES_OUT of the BRICK. Note that for properly
%                      keeping track of the options you used, all fields of 
%                      this structure should be specified, meaning that you 
%                      won't let the command apply default values. One way to
%                      do that is to run the command with OPT.FLAG_TEST = 1 a
%                       first time in order to get all default values set for 
%                       you.
%
%               ENVIRONMENT (string, default 'octave') the environment 
%                      where the BRICK should run. Available options : 
%                       'matlab', 'octave' or 'bash'. 
%                      In 'bash' mode, the 'int-sge.sh' script of
%                      the CIVET quarantine will be sourced by default. The
%                      fields FILES_IN, FILES_OUT and OPT will be ignored. The
%                      field BRICK should be a (string) shell command, 
%                      where input files are preceded by a 'in:' and output
%                      files preceded by a 'out:'.
%
%
% OPT           (structure) with the following fields :
%
%               NAME_PIPELINE (string, default 'NIAK_pipeline') the name of
%                      the pipeline. No space, no weird characters please.
%
%               PATH_LOGS (string, default PWD) The folder where the PERL 
%                      and BASH scripts will be stored.
%
%               CLOBBER (boolean, default 0) if clobber == 1, the PATH_LOGS
%                      will be cleared and all files written again from
%                      scratch. If CLOBBER ~=1, any file already present in
%                      PATH_LOGS will be left as it was, including
%                      PATH_DEF_MAT and all the SH scripts. The PERL script
%                      will be updated no matter what.
%
%               FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%                      the function prints some infos during the
%                      processing.
%
%               INIT_SH (string, default GB_NIAK_PATH_CIVET/INIT-SGE.SH) 
%                      a file name of a script to init the SH
%                      environment if you are using any BRICK using the 
%                      'bash' environement. The default value will work if
%                      you want to use tools from the quarantine. The
%                      variable GB_NIAK_PATH_CIVET can be manually
%                      specified in the file NIAK_GB_VARS.
%
%               COMMAND_MATLAB (string, default GB_NIAK_COMMAND_MATLAB) 
%                      how to invoke matlab. You may want to update that 
%                      to add the full path of the command. The defaut for
%                      this field can be set using the variable
%                      GB_NIAK_COMMAND_MATLAB in the file NIAK_GB_VARS.
%
%               COMMAND_OCTAVE (string, default GB_NIAK_COMMAND_MATLAB) 
%                      how to invoke matlab. You may want to update that 
%                      to add the full path of the command. The defaut for
%                      this field can be set using the variable
%                      GB_NIAK_COMMAND_MATLAB in the file NIAK_GB_VARS.
%
%               FILE_PATH_MAT (string, default PATH_LOGS/NAME_PIPELINE.path_def.mat) 
%                      If a non-empty string is provided, PATH_DEF_MAT should be 
%                      a '.MAT' file (in actual matlab format, not octave) that will be
%                      loaded and set as search path in the matlab/octave sessions.
%                      If omitted or if the file does not exist, the current 
%                      search path will be saved in PATH_LOGS under the 
%                       name NAME_PIPELINE.path_def.mat .
%                      If CLOBBER == 0 and the file already exists, nothing 
%                       will be done.
%
%               SGE_HOSTS (string, default '') A string which is directly 
%                       passed to qsub when using the SGE execution mode 
%                       (and is ignored otherwise). The following string 
%                       "-l vf=2G" would, for example, reserve 2 gigabytes 
%                       of memory, and "-l aces.q@node0,aces.q@node1" would 
%                       specify to run the jobs through the aces queue, 
%                       and specifically on node0 or node1.
%
%               
% OUTPUTS:
%
% FILE_PIPELINE     (string) the name of a PERL script implementing the
%                   pipeline through PMP.
%
% All output directories for output files are created here.
%
% The directory PATH_LOGS is created. It contains the following files :
%
% PATH_LOGS/NAME_PIPELINE.pl : A PERL script which implements the pipeline in PMP.
%       This script is overwritten every time NIAK_INIT_PIPELINE is executed in
%       the folder PATH_LOGS.
%
% PATH_LOGS/NAME_PIPELINE.mat : The first time NIAK_INIT_PIPELINE is used, the 
%       structures PIPELINE and OPT are saved here in matlab format, along 
%       with a string called HISTORY which describes the date, user name 
%       and system. Subsequent use of NIAK_INIT_PIPELINE will update these 
%       values and, if CLOBBER==0, previous values are saved in a structure
%       called PREVIOUS_PIPELINE. Multiple use of NIAK_INIT_PIPELINE
%       will result into nested structures
%       PREVIOUS_PIPELINE.PREVIOUS_PIPELINE.
%
% PATH_LOGS/NAME_PIPELINE.path_def.mat : The c
%
% PATH_LOGS/NAME_PIPELINE.<STAGE_NAME>.SH : This script is the one executed at the given stage.
% 
% PATH_LOGS/NAME_PIPELINE.<STAGE_NAME>.MAT : If the stage lives in matlab and octave 
%       environment, this file contains the variables BRICK, FILES_IN, 
%       FILES_OUT and OPT of the current stage.
%
% PATH_LOGS/NAME_PIPELINE.<STAGE_NAME>.M : If the stage lives in octave, this is an
%       octave script which is run at the current stage.
%
% If CLOBBER == 0, the files won't be written : if a stage has been
%       completed (file PATH_LOGS/FOLDER_LOGS/<STAGE_NAME>.LOCK exists), nothing
%       is done ; otherwise, previous content is saved in a PREVIOUS_PIPELINE
%       structure, and variables are updated.
%
% SEE ALSO:
% NIAK_MANAGE_PIPELINE, NIAK_VISU_PIPELINE, NIAK_DEMO_PIPELINE*
%
% COMMENTS
% A description of the Poor Man's Pipeline system written in PERL can be
% found on the BIC wiki :
% http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline
%
% Note that other files will be created in PATH_LOGS when
% running the pipeline. See NIAK_RUN_PIPELINE for more information.
%
% This function needs a CIVET quarantine to run, see :
% http://wiki.bic.mni.mcgill.ca/index.php/CIVET
% The path to the quarantine can be manually specified in the variable
% GB_NIAK_PATH_CIVET of the file NIAK_GB_VARS.
% The initialization script of the quarantine can be specified through the
% variable GB_NIAK_INIT_CIVET.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, pipeline, fMRI, PMP

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

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'path_logs','init_sh','command_matlab','command_octave','file_path_mat','clobber','flag_verbose','name_pipeline','sge_hosts'};
gb_list_defaults = {pwd,cat(2,gb_niak_path_civet,gb_niak_init_civet),gb_niak_command_matlab,gb_niak_command_octave,'',0,1,'NIAK_pipeline',''};
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%
%% Creating log path %%
%%%%%%%%%%%%%%%%%%%%%%%
[succ,messg,messgid] = niak_mkdir(path_logs);

if succ == 0 
    error('niak:pipeline',messg);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Saving the matlab version of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_pipeline_mat = cat(2,path_logs,filesep,name_pipeline,'.mat');

if (clobber == 1)|~exist(file_pipeline_mat,'file')
    history = [datestr(now) ' ' gb_niak_user ' on a ' gb_niak_OS ' system used NIAK v' gb_niak_version '>>>> Created a pipeline !\n'];
    save('-mat',file_pipeline_mat,'pipeline','opt','history')
else
    previous_pipeline = load(file_pipeline_mat);
    history = [datestr(now) ' ' gb_niak_user ' on a ' gb_niak_OS ' system used NIAK v' gb_niak_version '>>>> Modified the pipeline '];
    save('-mat',file_pipeline_mat,'previous_pipeline','pipeline','opt','history')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up path for the Matlab/Octave environment %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(file_path_mat)
    file_path_mat = cat(2,path_logs,filesep,name_pipeline,'.path_def.mat');

    if (clobber == 1)|~exist(file_path_mat,'file')
        path_work = path;
        save('-mat',file_path_mat,'path_work')
    end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

file_pipeline = cat(2,path_logs,name_pipeline,'.pl');
hp = fopen(file_pipeline,'w');

fprintf(hp,'#!/usr/bin/env perl\n\n'); % The script is written in PERL

%% A small help for the script
fprintf(hp,'if ($ARGV[0] eq help) {\n');
fprintf(hp,'print '' \nThis PERL script has been generated on %s by %s on a %s system, using NIAK version %s. It is running a processing pipeline on neuroimaging data. While it can be used as a stand-alone command, it is meant to be used via the NIAK_RUN_PIPELINE and NIAK_VISU_PIPELINE commands in Matlab/Octave.\n',datestr(now),gb_niak_user,gb_niak_OS,gb_niak_version);
fprintf(hp,'\n SYNTAX: \n %s%s%s ARG0 ARG1\n\n','./',name_pipeline,'.pl');
fprintf(hp,'ARG0 is optional. A first set of commands gives control on the pipeline execution :\n');
fprintf(hp,'    help : Show this message and die \n');
fprintf(hp,'    run : Run all the incomplete stages of the pipeline. \n');
fprintf(hp,'    resetFailures : Reset all stages that have failed so that they can be run again.\n');
fprintf(hp,'    resetAll : Reset all stages of the pipeline.\n');
fprintf(hp,'    resetFromStage : Take a stage name as an argument and resets all stages from that stage onwards (including that stage itself).\n');
fprintf(hp,'    resetRunning : Reset all stages thought to be running.\n');
fprintf(hp,'\nA second set of commands in ARG0 allows to monitor the pipeline design and execution :\n');
fprintf(hp,'    GetPipelineStatus : Get the pipeline’s status (not started, running, failed or finished).\n');
fprintf(hp,'    printStages : Print all stages in the pipeline.\n');
fprintf(hp,'    createDotGraph : Generate a graph representation of the stages of the pipeline in dot format (see graphviz package on internet).\n');
fprintf(hp,'    createFilenameDotGraph : Generate a graph representation of the files of the pipeline in dot format (see graphviz package on internet).\n');
fprintf(hp,'    printUnfinished : Print the unfinished stages of the pipeline.\n');
fprintf(hp,'\nARG1 is optional. It specifies how the pipeline will run :\n');
fprintf(hp,'    spawn (default) : sequential execution on the local machine \n');
fprintf(hp,'    sge : parallel execution, using the sge qsub system \n');
fprintf(hp,'    pbs : parallel execution, using pbs \n\n'';\nexit 0\n');
fprintf(hp,'}\n\n');

fprintf(hp,'use PMP::PMP; \nuse PMP::spawn; \nuse PMP::pbs; \nuse PMP::sge; \nuse PMP::Array;\nuse Env qw( PATH ) ; \nuse FindBin; \nuse lib "FindBin::Bin"; \n\n'); % Import the necessary PERL libraries, notably PMP
fprintf(hp,'$PATH = "$FindBin::Bin:${PATH}" ;\n'); % Add the log path to the path search of PMP
fprintf(hp,'my $pipeline = undef;\n\n'); % Initialization of a new pipeline
fprintf(hp,'if ($ARGV[1] eq sge) { \n$pipeline = PMP::sge->new(); \n} \nelsif ($ARGV[1] eq pbs) { \n$pipeline = PMP::pbs->new(); \n}\nelse {\n$pipeline = PMP::spawn->new();\n}\n\n'); % Choose the execution mode : SPAWN is local, PBS is parallel using PBS, SGE is parallel using the SGE QSUB system

fprintf(hp,'$pipeline->name(''NIAK_pipeline'');\n\n'); % The name of the pipeline
fprintf(hp,'$pipeline->statusDir(''%s'');\n\n',path_logs); % Where to access logs
fprintf(hp,'my $pipes = PMP::Array->new();\n'); % Create a new array of pipelines


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating the bash scripts for all stages of the pipeline, as well as the core of the PMP script %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

list_stage = fieldnames(pipeline);

for num_s = 1:length(list_stage)
    
    %% Getting information on the stage
    stage_name = list_stage{num_s};
    stage = getfield(pipeline,stage_name);
        
    gb_name_structure = 'stage';
    gb_list_fields = {'label','command','files_in','files_out','opt','environment',};
    gb_list_defaults = {'',NaN,NaN,NaN,NaN,'octave'};
    niak_set_defaults        
    
    %% Creation of output directories
    cell_files = niak_files2cell(files_out);
    for num_cell = 1:length(cell_files)
        path_cell = fileparts(cell_files{num_cell});
        niak_mkdir(path_cell);
    end
        
    %% Generation of file names
    
    file_var = cat(2,path_logs,filesep,filesep,name_pipeline,'.',stage_name,'.mat');
    file_sh =  cat(2,path_logs,filesep,filesep,name_pipeline,'.',stage_name,'.sh');
    file_log = cat(2,path_logs,filesep,filesep,name_pipeline,'.',stage_name,'.log');
    file_lock = cat(2,path_logs,filesep,filesep,name_pipeline,'.',stage_name,'.lock');
    file_oct = cat(2,path_logs,filesep,filesep,name_pipeline,'.',stage_name,'.m');
    
    %% Creation of the .mat file with all variables necessary to perform
    %% the stage
    if (clobber == 1)|~exist(file_var,'file')
        save('-mat',file_var,'command','files_in','files_out','opt')
    else
        if ~exist(file_lock,'file')
            previous_pipeline = load(file_var);
            if exist(file_sh,'file')
                fid = fopen(file_sh,'r');                
                previous_pipeline.file_sh = fread(fid, Inf, 'uint8=>char')';
                fclose(fid);
            end
            save('-mat',file_var,'command','files_in','files_out','opt','previous_pipeline')
        end
    end
    
    %% Creation of the bash script for the stage, along with a .m file if
    %% the stage lives in octave
    if ~exist(file_lock,'file')|(clobber == 1)
    
        hs = fopen(file_sh,'w');
        
        switch environment
            case 'matlab'
                                
                fprintf(hs,'#!/bin/bash \n');
                fprintf(hs,'source %s \n',init_sh);
                fprintf(hs,'%s -nojvm -nosplash -r ''load -mat %s, path(path_work), load -mat %s, files_in, files_out, opt, %s; exit''\n',command_matlab,file_path_mat,file_var,command);
                
            case 'octave'
                
                fprintf(hs,'#!/bin/bash \n');
                fprintf(hs,'source %s \n',init_sh);                
                fprintf(hs,'%s %s -x \n',command_octave,file_oct);
                
                ho = fopen(file_oct,'w');
                fprintf(ho,'load(''-mat'',''%s''),\n path(path_work),\n load(''-mat'',''%s''), files_in, files_out, opt,\n %s;\n',file_path_mat,file_var,command);
                fclose(ho);
                
            case 'bash'
                
                fprintf(hs,'%s \n',command);
                
            otherwise
                
                error('niak:pipeline','%s is an unknown environment for stage %s of the pipeline',environment,stage_name);
                
        end
        
        for num_cell = 1:length(cell_files)
            fprintf(hs,'\nif [ ! -e %s ]; then \n exit 1 \nfi',cell_files{num_cell});
        end
        fclose(hs);
        
    end    
        
    %% Adding the stage of the pipeline in the PMP script
    
    fprintf(hp,'$pipeline->addStage(\n');
    fprintf(hp,'{ name => ''%s'',\n',stage_name); % The name of the stage is used for the graph representation of the pipeline and to sort out dependencies
    [path_sh,name_sh,ext_sh] = fileparts(file_sh);
    fprintf(hp,'  args => [''%s%s'', %s, %s],\n',name_sh,ext_sh,niak_files2str(files_in,'in:'),niak_files2str(files_out,'out:'));
    fprintf(hp,'  sge_opts => ''%s''});\n\n',sge_hosts);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating the end of the PMP script, with the actual commands where PMP do something %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(hp,'# compute the dependencies based on the filenames:\n$pipeline->computeDependenciesFromInputs(); \n\n');
fprintf(hp,'# update the status of all stages based on previous pipeline runs\n$pipeline->updateStatus();\n\n');
fprintf(hp,'# Add the pipeline to the pipeline array\n$pipes->addPipe($pipeline);\n\n'); % Add the pipeline to the pipeline array

fprintf(hp,'if ($ARGV[0] eq run) { \n# loop until all pipes are done\n$pipes->run(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq resetFailures) { \n$pipes->resetFailures(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq resetAll) {\n$pipes->resetAll(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq resetRunning) { \n$pipes->resetRunning(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq resetFromStage) { \n$pipes->resetFromStage($ARGV[3]); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq getPipelineStatus) { \n$pipes->getPipelineStatus(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq printStages) { \n$pipes->printStages(); \n}');
fprintf(hp,'\nelsif ($ARGV[0] eq createDotGraph) { \n$pipes->createDotGraph(''%s%s.graph_stages.dot''); \n}',cat(2,path_logs,filesep),name_pipeline);
fprintf(hp,'\nelsif ($ARGV[0] eq createFilenameDotGraph) { \n$pipes->createFilenameDotGraph(''%s%s.graph_filenames.dot''); \n}',cat(2,path_logs,filesep),name_pipeline);
fprintf(hp,'\nelsif ($ARGV[0] eq printUnfinished) { \n$pipes->printUnfinished(); \n}');

fprintf(hp,'\nelse { \nprint ''\nSYNTAX :\n ./%s.pl arg0 arg1 \n Type ./%s.pl help for details.\n\n''\n}',name_pipeline,name_pipeline);
fclose(hp);
