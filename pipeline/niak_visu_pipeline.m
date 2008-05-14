function [succ] = niak_visu_pipeline(file_pipeline,action,opt)

% Run or reset a PMP pipeline.
%
% SYNTAX:
% [] = NIAK_VISU_PIPELINE(FILE_PIPELINE,ACTION)
%
% INPUTS:
% FILE_PIPELINE      (string) The file name of a PMP script generated using
%                           NIAK_INIT_PIPELINE.
%               
% ACTION             (string) either 'graph_stages', 'graph_filenames' or 'unfinished'.
%
% OUTPUTS:
% 
% What the function does depends on the argument ACTION :
%
% ACTION = 'graph_stages'
% Create a file PATH_LOGS/NAME_PIPELINE.graph_stages.dot
% This is a graph representation of the stages of the pipeline in dot format (see
% graphviz package on internet). It also attempts to convert this dot file
% into a svg file using dot, and displays it using the program specified in
% the variable GB_NIAK_VIEWER_SVG in the file NIAK_GB_VARS.
%
% ACTION = 'graph_filenames'
% Create a file PATH_LOGS/NAME_PIPELINE.graph_filenames.dot
% This is a graph representation of the stages of the pipeline in dot format (see
% graphviz package on internet), along with a list of all files that will be
% generated. It also attempts to convert this dot file
% into a svg file using dot, and displays it using the program specified in
% the variable GB_NIAK_VIEWER_SVG in the file NIAK_GB_VARS.
%
% ACTION = 'unfinished'
% Display a list of the unfinished stages of the pipeline.
%
% SEE ALSO:
% NIAK_INIT_PIPELINE, NIAK_MANAGE_PIPELINE, NIAK_DEMO_PIPELINE*
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

init_sh = cat(2,gb_niak_path_civet,'init.sh');

if ~exist('action','var'); error('niak:pipeline: please specify an action'); end

[path_logs,name_pipeline,ext_pl] = fileparts(file_pipeline);

file_graph_stages = cat(2,path_logs,filesep,name_pipeline,'.graph_stages.dot');
file_svg_stages = cat(2,path_logs,filesep,name_pipeline,'.graph_stages.svg');
file_graph_filenames = cat(2,path_logs,filesep,name_pipeline,'.graph_filenames.dot');
file_svg_filenames = cat(2,path_logs,filesep,name_pipeline,'.graph_filenames.svg');
switch action
    
    case 'graph_stages'
        
        file_tmp = niak_file_tmp('.sh');
        
        hs = fopen(file_tmp,'w');

        fprintf(hs,'#!/bin/bash \n');
        fprintf(hs,'source %s \n',init_sh);
        fprintf(hs,'%s createDotGraph;',file_pipeline);
        
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,'sh ',file_tmp));
        
        fprintf(messg);
        
        delete(file_tmp)                
        
        system(cat(2,'dot -Tsvg -o ',file_svg_stages,' ',file_graph_stages));
        
        system(cat(2,gb_niak_viewersvg,' ',file_svg_stages,'&'));
        
   case 'graph_filenames'
        
        file_tmp = niak_file_tmp('.sh');
        
        hs = fopen(file_tmp,'w');

        fprintf(hs,'#!/bin/bash \n');
        fprintf(hs,'source %s \n',init_sh);
        fprintf(hs,'%s createFilenameDotGraph',file_pipeline);
        
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,'sh ',file_tmp));
        
        fprintf(messg);
        
        delete(file_tmp)                
        
        system(cat(2,'dot -Tsvg -o ',file_svg_filenames,' ',file_graph_filenames));
        
        system(cat(2,gb_niak_viewersvg,' ',file_svg_filenames,'&'));
        
    case 'unfinished'
        
        file_tmp = niak_file_tmp('.sh');
        
        hs = fopen(file_tmp,'w');

        fprintf(hs,'#!/bin/bash \n');
        fprintf(hs,'source %s \n',init_sh);
        fprintf(hs,'%s printUnfinished',file_pipeline);
        
        fclose(hs);
        
        system(cat(2,'chmod u+x ',file_tmp));
        [succ,messg] = system(cat(2,'sh ',file_tmp));
        
        fprintf(messg);
        
        delete(file_tmp)                
        
    otherwise
        error('niak:pipeline: unknown action',action);
end