function [succ] = niak_manage_pipeline(file_pipeline,action,execution_mode,max_queued)
%
% _________________________________________________________________________
% SUMMARY OF NIAK_MANAGE_PIPELINE
%
% Run or reset a PMP pipeline.
%
% SYNTAX:
% [] = NIAK_MANAGE_PIPELINE(FILE_PIPELINE,ACTION,EXECUTION_MODE,MAX_QUEUED)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_PIPELINE      
%       (string) The file name of a PMP script generated using 
%       NIAK_INIT_PIPELINE.
%               
% ACTION             
%       (string) either 'run', 'restart' or 'reset'.
%
% EXECUTION_MODE                
%       (string, default 'spawn') how to execute the pipeline :
%           'spawn' : local execution
%           'sge' : sge qsub system
%           'pbs' : portable batch system
%
% MAX_QUEUED
%       (integer, default 9999) the maximal number of jobs that can be
%       submitted simultaneously.
%
% _________________________________________________________________________
% OUTPUTS:
% 
% What the function does depends on the arguments ACTION and OPT:
%
% ACTION = 'run'
%   Start the pipeline.
%
% ACTION = 'restart'
%   Delete all '.running', '.failed' and '.lock' files and re-runs the
%   pipeline. 
%
% ACTION = 'reset' 
%   Clean all '.running', '.failed', '.lock' and '.finished' files, then 
%   restarts the pipeline from scratch.
%
% OPT specifies the mode to run the pipeline :
%   'spawn' (default) : sequential execution on the local machine.
%               'sge' : parallel execution, using the sge qsub system.
%               'pbs' : parallel execution, using pbs.
%
% When running, the pipeline is going to produce the following files:
%
%   PIPELINE_NAME.lock : means that the pipeline is currently running.
%
%   PIPELINE_NAME.STAGE_NAME.running : means that this stage is currently
%       running.
%
%   PIPELINE_NAME.STAGE_NAME.log : all messages sent to the terminal during
%       the execution of the stage.
%
%   PIPELINE_NAME.STAGE_NAME.failed : means that an attempt to run this stage
%       was made, and that it failed (meaning that some outputs are reported
%       missing). 
%
%   PIPELINE_NAME.STAGE_NAME.finished : means this stage has been completed,
%       meaning that all output files have been created (no guarantee is that
%       these outputs are correct in any sense though).
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_INIT_PIPELINE, NIAK_VISU_PIPELINE, NIAK_DEMO_PIPELINE*
%
% _________________________________________________________________________
% COMMENTS:
%
% Note 1:
%   A description of the Poor Man's Pipeline system written in PERL can be
%   found on the BIC wiki :
%   http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline
%
% Note 2:
%   This function needs a CIVET quarantine to run, see :
%   http://wiki.bic.mni.mcgill.ca/index.php/CIVET
%   The path to the quarantine can be manually specified in the variable
%   GB_NIAK_PATH_CIVET of the file NIAK_GB_VARS.
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

init_sh = cat(2,gb_niak_path_civet,gb_niak_init_civet_local);

if ~exist('action','var'); error('niak:pipeline','please specify an action'); end

if ~exist('execution_mode','var'); execution_mode = 'spawn'; end

if ~exist('max_queued','var'); max_queued = 9999; end

[path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);

file_lock = cat(2,path_logs,filesep,name_pipeline,'.lock');
file_log = cat(2,path_logs,filesep,name_pipeline,'.log');
file_start = cat(2,path_logs,filesep,name_pipeline,'.start');

switch action
    
    case 'run'
        if exist(file_lock,'file')
            error('niak:pipeline:A lock file has been found ! This means the pipeline is either running or crashed.\n If it is crashed, try a ''restart'' or ''reset'' action instead of ''run''')
        end
        
        fprintf('Starting the pipeline ... \n');
        
        file_tmp = niak_file_tmp('.sh');
        
        hs = fopen(file_tmp,'w');

        if exist(file_log,'file')
            system(cat(2,'rm -f ',file_log));
        end
        
        fprintf(hs,'#!/bin/bash \n');
        fprintf(hs,'source %s \n',init_sh);        
        fprintf(hs,'%s run %s %i> %s &',file_pipeline,execution_mode,max_queued,file_log);        
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,'batch sh ',file_tmp,' > ',file_start));
        
        if succ == 0
            fprintf('The pipeline was started in the background\n');
        else
            error(messg)
        end        
        
        delete(file_tmp);
        
    case 'restart'
        
        fprintf('Cleaning all lock, running and failed jobs ... \n');
        
        list_ext = {'running','failed','lock'};
        
        for num_e = 1:length(list_ext)
            
            list_files = dir(cat(2,path_logs,filesep,'*',list_ext{num_e}));
            list_files = {list_files.name};
            
            for num_f = 1:length(list_files)
                base_file = list_files{num_f};
                base_file = base_file(1:end-length(list_ext{num_e}));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,'log'));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,list_ext{num_e}));
            end
            
        end                    
                
        s = niak_manage_pipeline(file_pipeline,'run',execution_mode)
        
    case 'reset'
        
        fprintf('Cleaning all lock, running, failed and finished jobs ... \n');        
        
        list_ext = {'running','failed','lock','finished'};
        
        for num_e = 1:length(list_ext)
            
            list_files = dir(cat(2,path_logs,filesep,'*',list_ext{num_e}));
            list_files = {list_files.name};
            
            for num_f = 1:length(list_files)
                base_file = list_files{num_f};
                base_file = base_file(1:end-length(list_ext{num_e}));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,'log'));
                system(cat(2,'rm -f ',path_logs,filesep,base_file,list_ext{num_e}));
            end
            
        end                    
               
        s = niak_manage_pipeline(file_pipeline,'run',execution_mode);        
        
    otherwise
        error('niak:pipeline:%s : unknown action',action);
end