function file_pipeline = niak_init_pipeline(pipeline,opt)

% Create some perl and bash scripts ready to be fed in the poor man's pipeline
% (PMP) system.
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
%               BRICK (string) the name of the brick you want to apply at 
%                       this stage, e.g. NIAK_BRICK_SLICE_TIMING.
%
%               FILES_IN (string, cell of strings, structure) the argument
%                      FILES_IN of the BRICK. Note that for properly
%                      handling dependencies, this field needs to contain
%                      the exact name of the file (no wildcards, no '' for
%                      default values). One way is to run the brick with
%                       OPT.FLAG_TEST = 1 a first time in order to get all
%                       default values set for you.
%
%               FILES_OUT (string, cell of strings, structure) the argument
%                      FILES_OUT of the BRICK. Note that for properly
%                      handling dependencies, this field needs to contain
%                      the exact name of the file (no wildcards, no '' for
%                      default values). One way is to run the brick with
%                       OPT.FLAG_TEST = 1 a first time in order to get all
%                       default values set for you.
%
%               OPT (string, structure) the argument
%                      FILES_OUT of the BRICK. Note that for properly
%                      keeping track of the options you used, all fields of 
%                      this structure should be specified, meaning that you 
%                      won't let the brick apply default values. One way to
%                      do that is to run the brick with OPT.FLAG_TEST = 1 a
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
%               FOLDER_LOGS (string, default '') The path where the BASH scripts
%                      will be generated for this stage of the pipeline.
%                      If needed, the FOLDER will be created. All folders
%                      live in the OPT.PATH_LOGS folder (see below).
% 
%
% OPT           (structure) with the following fields :
%
%               PATH_LOGS (string, default PWD) The folder where the PERL 
%                      and BASH scripts will be stored. All 
%                      PIPELINE.<STAGE_NAME>.FOLDER_LOGS will be created in
%                      this path.
%
%               QUARANTINE (string) Path to the CIVET quarantine. This
%                      quarantine includes the minc tools, perl, civet and
%                       PMP. Those tools are prerequesites of all BRICK which
%                      deals with MINC files or with T1 images. It is also
%                      a prerequesite of the pipeline system itself !
%
%               INIT_SH (string, default PATH_QUARANTINE/INIT-SGE.SH) 
%                      a file name of a script to init the SH
%                      environment if you are using any BRICK using the 
%                      'bash' environement. The default value will work if
%                      you want to use tools from the quarantine.
%
%               MATLAB_COMMAND	(string, default 'matlab') how to invoke
%                      matlab. You may want to update that to add the full
%                      path of the command.
%
%               OCTAVE_COMMAND (string, default 'octave') how to invoke
%                      octave. You may want to update that to add the full
%                      path of the command.
%
%               FILE_PATH_MAT (string, default PATH_LOGS/PATH_DEF.MAT) 
%                      If a non-empty string is provided, PATH_DEF_MAT should be 
%                      a '.MAT' file (in actual matlab format, not octave) that will be
%                      loaded and set as search path in the matlab/octave sessions.
%                      If omitted or the file does not exist, the current 
%                      search path will be saved in PATH_LOGS under the 
%                       name PATH_DEF_MAT. If CLOBBER == 0 and the file
%                       already exists, nothing will be done.
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
% OUTPUTS:
%
% FILE_PIPELINE     (string) the name of a PERL script implementing the
%                   pipeline through PMP.
%              
% The directories PATH_LOGS/FOLDER_LOGS are created. In PATH_LOGS, a PERL
% script named 'pipeline.pmp' is created which implements the pipeline in PMP.
% This script is overwritten every time NIAK_INIT_PIPELINE is executed in
% the folder PATH_LOGS.
%
% There is also a file 'pipeline.mat' in PATh_LOGS. The first time 
% NIAK_INIT_PIPELINE is used, the structures pipeline and opt are saved
% here in matlab format, along with a string called history which describes
% the date, user name and system. Subsequent use of NIAK_INIT_PIPELINE will
% update these values and, if CLOBBER==0, previous values are saved in a
% structure called PREVIOUS_PIPELINE. Multiple use of NIAK_INIT_PIPELINE
% will result into nested structures PREVIOUS_PIPELINE.PREVIOUS_PIPELINE.(...)
%
% A bash script called PATH_LOGS/FOLDER_LOGS/<STAGE_NAME>.SH is created for
% each stage of the pipeline. This script is the one executed at the given stage.
% If the script lives in matlab and octave environment, a file
% PATH_LOGS/FOLDER_LOGS/<STAGE_NAME>.MAT is also created where the fields
% BRICK, FILES_IN, FILES_OUT and OPT of the current stage are saved.
% If CLOBBER == 0, the files won't be written : if a stage has been
% completed (file PATH_LOGS/FOLDER_LOGS/<STAGE_NAME>.LOCK exists), nothing
% is done ; otherwise, previous content is saved in a PREVIOUS_PIPELINE
% structure, and variables are updated.
%
% Note that other files will be created in PATH_LOGS/FOLDER_LOGS when
% running the pipeline. See NIAK_RUN_PIPELINE for more information.
%
% SEE ALSO:
% NIAK_RUN_PIPELINE, NIAK_DEMO_PIPELINE*
%
% COMMENTS
% A description of the Poor Man's Pipeline system written in PERL can be
% found on the BIC wiki :
% http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline
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
gb_list_fields = {'path_logs','quarantine','init_sh','matlab_command','octave_command','file_path_mat','clobber','flag_verbose'};
gb_list_defaults = {pwd,NaN,'','matlab','octave','',0,1};
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
file_pipeline_mat = cat(2,path_logs,'pipeline.mat');

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
    file_path_mat = cat(2,path_logs,filesep,'path_def.mat');

    if (clobber == 1)|~exist(file_path_mat,'file')
        path_work = path;
        save('-mat',file_path_mat,'path_work')
    end    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating the bash scripts for all stages of the pipeline, as well as the PMP script %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_pipeline = cat(2,path_logs,'pipeline.pm');
list_stage = fieldnames(pipeline);

for num_s = 1:length(list_stage)
    
    %% Getting information on the stage
    stage_name = list_stage{num_s};
    stage = getfield(pipeline,stage_name);
        
    gb_name_structure = 'stage';
    gb_list_fields = {'label','brick','files_in','files_out','opt','environment','folder_logs',};
    gb_list_defaults = {'',NaN,NaN,NaN,NaN,'octave',''};
    niak_set_defaults
    
    [succ,messg,messgid] = niak_mkdir(cat(2,path_logs,filesep,folder_logs));

    if succ == 0
        error('niak:pipeline',messg);
    end
    
    %% Generation of file names
    
    file_var = cat(2,path_logs,filesep,folder_logs,filesep,stage_name,'.mat');
    file_sh =  cat(2,path_logs,filesep,folder_logs,filesep,stage_name,'.sh');
    file_log = cat(2,path_logs,filesep,folder_logs,filesep,stage_name,'.log');
    file_lock = cat(2,path_logs,filesep,folder_logs,filesep,stage_name,'.lock');
    file_oct = cat(2,path_logs,filesep,folder_logs,filesep,stage_name,'.m');
    
    %% Creation of the .mat file with all variables necessary to perform
    %% the stage
    if (clobber == 1)|~exist(file_var,'file')
        save('-mat',file_var,'brick','files_in','files_out','opt')
    else
        if ~exist(file_lock,'file')
            previous_pipeline = load(file_var);
            if exist(file_sh,'file')
                fid = fopen(file_sh,'r');                
                previous_pipeline.file_sh = fread(fid, Inf, 'uint8=>char')';
                fclose(fid);
            end
            save('-mat',file_var,'brick','files_in','files_out','opt','previous_pipeline')
        end
    end
    
    %% Creation of the bash script for the stage, along with a .m file if
    %% the stage lives in octave
    if ~exist(file_lock,'file')|(clobber == 1)
    
        hs = fopen(file_sh,'w');
        
        switch environment
            case 'matlab'
                
                %fprintf(hs,'%s -nojvm -nosplash -logfile %s -r ''load(''-mat'',%s), path(path_work), load(''-mat'',%s), %s(files_in,files_out,opt), exit''\n',matlab_command,file_log,file_path_mat,file_var,brick);
                fprintf(hs,'%s -nojvm -nosplash -r ''load(''-mat'',%s), path(path_work), load(''-mat'',%s), %s(files_in,files_out,opt), exit''\n',matlab_command,file_path_mat,file_var,brick);
                
            case 'octave'
                
                %fprintf(hs,'%s %s -x > %s\n',octave_command,file_oct,file_log);
                fprintf(hs,'%s %s \n',octave_command,file_oct);
                
                ho = fopen(file_oct,'w');
                fprintf(ho,'load(''-mat'',%s), path(path_work), load(''-mat'',%s), %s(files_in,files_out,opt),',file_path_mat,file_var,brick);
                fclose(ho);
                
            case 'bash'
                
                fprintf(hs,'%s \n',brick);
                
            otherwise
                
                error('niak:pipeline','%s is an unknown environment for stage %s of the pipeline',environment,stage_name);
                
        end
        
        fclose(hs);
        
    end    
    
    %% In the first iteration, generating the header of the PMP script
    
    if num_s == 1
        
        hp = fopen(file_pipeline,'w');
       
        fprintf(hp,'#!/usr/bin/env perl\n\n'); % The script is written in PERL
        fprintf(hp,'use PMP::PMP; \nuse PMP::spawn; \nuse PMP::pbs; \nuse PMP::sge; \nuse PMP::Array;\n\n'); % Import the necessary PERL libraries, notably PMP        
        fprintf(hp,'my $pipes = PMP::Array->new();\n\n'); % Create a new array of pipelines
        fprintf(hp,'if ($ARGV[0] == 1) { \nmy $pipeline = PMP::sge->new(); \n} \nelsif ($ARGV[0] == 2) { \nmy $pipeline = PMP::pbs->new(); \n}\nelse {\nmy $pipeline = PMP::spawn->new();\n}\n\n'); % Choose the execution mode : SPAWN is local, PBS is parallel using PBS, SGE is parallel using the SGE QSUB system
        fprintf(hp,'$pipeline->name(''%s'');\n\n',[datestr(now) ' ' gb_niak_user ' on a ' gb_niak_OS ' system used NIAK v' gb_niak_version ' to create this pipeline']); % The name of the pipeline
        fprintf(hp,'$pipeline->statusDir(''%s'');\n\n',path_logs); % Where to access log
        
    end
    
    %% Adding the stage of the pipeline in the PMP script
    
    fprintf(hp,'$pipeline->addStage(\n');
    fprintf(hp,'{ name => ''%s''\n',stage_name); % The name of the stage is used for the graph representation of the pipeline and to sort out dependencies
    
    fprintf(hp,'  args => [''%s'', %s, %s] });\n\n',file_sh,niak_files2str(files_in,'in:'),niak_files2str(files_out,'out:'));
    
end

fprintf(hp,'# compute the dependencies based on the filenames:\n$pipeline->computeDependenciesFromInputs()\n\n');
fprintf(hp,'# update the status of all stages based on previous pipeline runs\n$pipeline->updateStatus();\n\n');
fprintf(hp,'# update the status of all stages based on previous pipeline runs\n$pipeline->updateStatus();\n\n');
fprintf(hp,'# restart all stages that failed in a previous run\n$pipeline->resetFailures();\n\n');
fprintf(hp,'$pipes->addPipe($pipeline);\n\n');
fprintf(hp,'# loop until all pipes are done\n$pipes->run();\n\n');
fclose(hp);
