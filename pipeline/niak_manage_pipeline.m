function [succ] = niak_manage_pipeline(file_pipeline,action,opt)

% Run or reset a PMP pipeline.
%
% SYNTAX:
% [] = NIAK_MANAGE_PIPELINE(FILE_PIPELINE,ACTION,OPT)
%
% INPUTS:
% FILE_PIPELINE      (string) The file name of a PMP script generated using
%                           NIAK_INIT_PIPELINE.
%               
% ACTION             (string) either 'run', 'restart' or 'reset'.
%
% OPT                (string) options dependent on ACTION. See OUTPUTS.
%
% OUTPUTS:
% 
% What the function does depends on the argument ACTION :
%
% ACTION = 'run'
% Start the pipeline.
%
% ACTION = 'restart'
% Delete all '.running', '.failed' and '.lock' files and re-runs the
% pipeline. OPT specifies the mode to run the pipeline :
%       'spawn' (default) : sequential execution on the local machine.
%       'sge' : parallel execution, using the sge qsub system.
%       'pbs' : parallel execution, using pbs.
%
% ACTION = 'reset' 
% Clean all '.running', '.failed', '.lock' and '.finished' files, then 
% restarts the pipeline from scratch.
%
% When running, the pipeline is going to produce the following files:
%
% PIPELINE_NAME.lock : means that the pipeline is currently running.
%
% PIPELINE_NAME.STAGE_NAME.running : means that this stage is currently
%       running.
%
% PIPELINE_NAME.STAGE_NAME.log : all messages sent to the terminal during
%       the execution of the stage.
%
% PIPELINE_NAME.STAGE_NAME.failed : means that an attempt to run this stage
%       was made, and that it failed (meaning that some outputs are reported
%       missing). 
%
% PIPELINE_NAME.STAGE_NAME.finished : means this stage has been completed,
%       meaning that all output files have been created (no guarantee is that
%       these outputs are correct in any sense though).
%
% SEE ALSO:
% NIAK_INIT_PIPELINE, NIAK_VISU_PIPELINE, NIAK_DEMO_PIPELINE*
%
% COMMENTS
% A description of the Poor Man's Pipeline system written in PERL can be
% found on the BIC wiki :
% http://wiki.bic.mni.mcgill.ca/index.php/PoorMansPipeline
%
% This function needs a CIVET quarantine to run, see :
% http://wiki.bic.mni.mcgill.ca/index.php/CIVET
% The path to the quarantine can be manually specified in the variable
% GB_NIAK_PATH_CIVET of the file NIAK_GB_VARS.
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

init_sh = cat(2,gb_niak_path_civet,gb_niak_init_civet);

if ~exist('action','var'); error('niak:pipeline','please specify an action'); end

if ~exist('opt','var'); opt = 'spawn'; end

[path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);

file_lock = cat(2,path_logs,filesep,name_pipeline,'.lock');
file_log = cat(2,path_logs,filesep,name_pipeline,'.log');

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
        
        %% Little test to check if we can run the script
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,file_tmp));        
        if succ~=0
            error(messg);
        end
        
        %% Run the pipeline in the background
        fprintf(hs,'%s run %s > %s &',file_pipeline,opt,file_log);
        
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,file_tmp,'&'));
        
        if succ == 0
            fprintf('The pipeline was started in the background');
        end        
        
        delete(file_tmp)
        
    case 'restart'
        
        fprintf('Cleaning all .lock .running and .failed files ... \n');
        
        system(cat(2,'rm -f ',path_logs,filesep,'*.running'));
        system(cat(2,'rm -f ',path_logs,filesep,'*.failed'));
        system(cat(2,'rm -f ',path_logs,filesep,'*.lock'));
                
        s = niak_manage_pipeline(file_pipeline,'run',opt)
        
    case 'reset'
        
        fprintf('Cleaning all .lock .running, .failed and .finished files ... \n');        
        system(cat(2,'rm -f ',path_logs,filesep,'*.running'));
        system(cat(2,'rm -f ',path_logs,filesep,'*.failed'));
        system(cat(2,'rm -f ',path_logs,filesep,'*.lock'));
        system(cat(2,'rm -f ',path_logs,filesep,'*.finished'));
        
        fprintf('Restarting the pipeline ... \n')
        s = niak_manage_pipeline(file_pipeline,'run',opt);        
        
    otherwise
        error('niak:pipeline:%s : unknown action',action);
end