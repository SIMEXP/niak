function pipeline = niak_pipeline_corsica(files_in,opt)
% Pipeline to run CORSICA (correction of the physiological noise) on fMRI
%
% PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   <SUBJECT>.FMRI 
%       (cell of strings) a list of fMRI datasets. The field name 
%       <SUBJECT> can be any arbitrary string. All data in 
%       FILES_IN.<SUBJECT> should come from the same subject.
%
%   <SUBJECT>.TRANSFORMATION 
%       (string, default identity) a transformation from the functional 
%       space to the "MNI152 non-linear" space.
%
%   <SUBJECT>.COMPONENT_TO_KEEP
%       (string, default none) a text file, whose first line is a set of 
%       string labels, and each column is otherwise a temporal component of 
%       interest. The ICA component with highest correlation with each 
%       signal of interest will be automatically attributed a selection 
%       score of 0 (i.e. it will not be selected as physiological noise).
%
% OPT   
%   (structure) with the following fields : 
%
%   SIZE_OUTPUT
%       (string, default 'quality_control') possible values : 
%       ‘minimum’, 'quality_control’, ‘all’.
%       The quantity of intermediate results that are generated. 
%           * With the option ‘minimum’, only the physiological-noise
%           corrected data is written. 
%           * With the option ‘quality_control’, in addition to the outputs 
%           of the 'minimum' option, a pdf document recapitulating 
%           the ICA components and the score of components in the stepwise 
%           regression are generated.
%           * With the option ‘all’, in addition to the outputs of the 
%           'minimum' option, the space and time distributions of the ICA 
%           are generated.
%
%   FOLDER_OUT 
%       (string) where to write the results of the pipeline.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline
%       will just produce a pipeline structure, and will not actually
%       process the data. Otherwise, PSOM_RUN_PIPELINE will be used to
%       process the data.
%
%   SICA 
%       (structure) options of NIAK_BRICK_SICA
%
%       NB_COMP 
%           (integer) the number of components (default 60).
%
%   COMPONENT_SEL 
%       (structure) options of NIAK_BRICK_COMPONENT_SEL.
%
%   COMPONENT_SUPP 
%       (structure) options of NIAK_BRICK_COMPONENT_SUPP.
%
%   THRESHOLD 
%       (scalar, default 0.15) a threshold to apply on the score for 
%       suppression (scores above the thresholds are selected). 
%
% _________________________________________________________________________
% OUTPUTS:
%
% PIPELINE 
%   (structure) describe all the jobs that need to be performed in the
%   pipeline. 
%
% _________________________________________________________________________
% COMMENTS:
%
% The steps of the pipeline are the following :
%  
%   1.  Individual spatial independent component of each functional run.
%
%   2. Selection of independent component related to physiological noise, 
%   using spatial priors (masks of the ventricle and a part of the brain 
%   stem).
%
%   3. Generation of a "physiological noise corrected" fMRI dataset for
%   each run, where the effect of the selected independent components has 
%   been removed. 
%
% The PSOM pipeline manager is used to process the pipeline if
% OPT.FLAG_TEST is false. PSOM has a number of interesting features to deal
% with job failures or pipeline updates. You can read the following
% tutorial for a review of its capabilities : 
% http://code.google.com/p/psom/wiki/HowToUsePsom
% http://code.google.com/p/psom/wiki/ConfigurationPsom
%
% _________________________________________________________________________
% REFERENCES:
%
% Perlbarg, V., Bellec, P., Anton, J.-L., Pelegrini-Issac, P., Doyon, J. and 
% Benali, H.; CORSICA: correction of structured noise in fMRI by automatic
% identification of ICA components. Magnetic Resonance Imaging, Vol. 25,
% No. 1. (January 2007), pp. 35-46.
%
% MJ Mckeown, S Makeig, GG Brown, TP Jung, SS Kindermann, AJ Bell, TJ
% Sejnowski; Analysis of fMRI data by blind separation into independent
% spatial components. Hum Brain Mapp, Vol. 6, No. 3. (1998), pp. 160-188.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : CORSICA, fMRI, physiological noise, ICA

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

%% import NIAK global variables

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if ~exist('files_in','var')|~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_CORSICA(FILES_IN,OPT).\n Type ''help niak_pipeline_corsica'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)
    error('FILE_IN should be a struture!')
end

list_subject = fieldnames(files_in);
nb_subject = length(list_subject);

for num_s = 1:nb_subject    
    subject = list_subject{num_s};    
    
    if ~isstruct(files_in.(subject))
        error('FILE_IN.%s should be a structure!',upper(subject));
    end
    
    if ~isfield(files_in.(subject),'fmri')
        error(sprintf('I could not find the field FILE_IN.%s.FMRI!',upper(subject)));
    end
        
    if ~iscellstr(files_in.(subject).fmri)
        error(sprintf('FILE_IN.%s.fmri is not a cell of strings!',upper(subject)));
    end
    
    if ~isfield(files_in.(subject),'transformation')
        files_in.(subject).transformation = 'gb_niak_omitted';
    end
    
    if ~ischar(files_in.(subject).transformation)
        error(sprintf('FILE_IN.%s.TRANSFORMATION is not a string!',upper(subject)));
    end
    
    if ~isfield(files_in.(subject),'component_to_keep')
        files_in.(subject).component_to_keep = 'gb_niak_omitted';
    end                
end

%% Options
default_psom.path_logs = '';
opt_tmp.flag_test = 1;
gb_name_structure = 'opt';
gb_list_fields    = {'size_output'     , 'psom'       , 'flag_test' , 'folder_out' , 'sica'  , 'component_sel' , 'component_supp' };
gb_list_defaults  = {'quality_control' , default_psom , false       , NaN          , opt_tmp , opt_tmp         , opt_tmp          };
niak_set_defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct([]);

%%%%%%%%%%
%% SICA %%
%%%%%%%%%%
for num_s = 1:nb_subject
    subject = list_subject{num_s};                      
    for num_r = 1:length(files_in.(subject).fmri)        
        clear files_in_tmp files_out_tmp opt_tmp
        run = cat(2,'run',num2str(num_r));
        name_job             = cat(2,'sica_',subject,'_',run);
        files_in_tmp         = files_in.(subject).fmri{num_r};
        files_out_tmp.space  = '';
        files_out_tmp.time   = '';
        files_out_tmp.figure = '';
        opt_tmp              = opt.sica;
        opt_tmp.folder_out   = cat(2,opt.folder_out,filesep,subject,filesep);
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_sica',files_in_tmp,files_out_tmp,opt_tmp);        
    end % run
end % subject


%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPONENT SELECTION %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%% with the ventricles
for num_s = 1:nb_subject
    subject = list_subject{num_s};   
    for num_r = 1:length(files_in.(subject).fmri)                
        run = cat(2,'run',num2str(num_r));
        name_job = cat(2,'component_sel_ventricle_',subject,'_',run);               
        name_job_in = cat(2,'sica_',subject,'_',run);        
        clear files_in_tmp files_out_tmp opt_tmp
        files_in_tmp.fmri              = files_in.(subject).fmri{num_r};        
        files_in_tmp.component         = pipeline.(name_job_in).files_out.time;
        files_in_tmp.mask              = cat(2,gb_niak_path_niak,'template',filesep,'roi_ventricle.mnc.gz');
        files_in_tmp.transformation    = files_in.(subject).transformation;
        files_in_tmp.component_to_keep = files_in.(subject).component_to_keep;        
        files_out_tmp                  = '';
        opt_tmp                        = opt.component_sel;
        opt_tmp.folder_out             = cat(2,opt.folder_out,filesep,subject,filesep);        
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_component_sel',files_in_tmp,files_out_tmp,opt_tmp);        
    end % run
end % subject

%% with the brain stem
for num_s = 1:nb_subject
    subject = list_subject{num_s};   
    for num_r = 1:length(files_in.(subject).fmri)                
        run         = cat(2,'run',num2str(num_r));
        name_job    = cat(2,'component_sel_stem_',subject,'_',run);               
        name_job_in = cat(2,'sica_',subject,'_',run);        
        clear files_in_tmp files_out_tmp opt_tmp
        files_in_tmp.fmri              = files_in.(subject).fmri{num_r};        
        files_in_tmp.component         = pipeline.(name_job_in).files_out.time;
        files_in_tmp.mask              = cat(2,gb_niak_path_niak,'template',filesep,'roi_stem.mnc.gz');
        files_in_tmp.transformation    = files_in.(subject).transformation;
        files_in_tmp.component_to_keep = files_in.(subject).component_to_keep;        
        files_out_tmp                  = '';
        opt_tmp                        = opt.component_sel;
        opt_tmp.folder_out             = cat(2,opt.folder_out,filesep,subject,filesep);        
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_component_sel',files_in_tmp,files_out_tmp,opt_tmp);        
    end % run
end % subject

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPONENT SUPPRESSION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_subject
    subject = list_subject{num_s};   
    for num_r = 1:length(files_in.(subject).fmri)  
        run = cat(2,'run',num2str(num_r));        
        name_job           = cat(2,'component_supp_',subject,'_',run);                       
        name_job_sica      = cat(2,'sica_',subject,'_',run);
        name_job_comp_vent = cat(2,'component_sel_ventricle_',subject,'_',run);
        name_job_comp_stem = cat(2,'component_sel_stem_',subject,'_',run);              
        clear files_in_tmp files_out_tmp opt_tmp        
        files_in_tmp.fmri        = files_in.(subject).fmri{num_r};        
        files_in_tmp.space       = pipeline.(name_job_sica).files_out.space;
        files_in_tmp.time        = pipeline.(name_job_sica).files_out.time;
        files_in_tmp.compsel{1}  = pipeline.(name_job_comp_vent).files_out;
        files_in_tmp.compsel{2}  = pipeline.(name_job_comp_stem).files_out;
        files_out_tmp            = '';        
        opt_tmp                  = opt.component_supp;
        opt_tmp.folder_out       = cat(2,opt.folder_out,filesep,subject,filesep);
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_component_supp',files_in_tmp,files_out_tmp,opt_tmp);        
    end % run
end % subject

%%%%%%%%%%%%%%
%% CLEANING %%
%%%%%%%%%%%%%%
if strcmp(opt.size_output,'minimum')|strcmp(opt.size_output,'quality_control')
    for num_s = 1:nb_subject
        subject = list_subject{num_s};                
        for num_r = 1:length(files_in.(subject).fmri)  
            run          = cat(2,'run',num2str(num_r));            
            name_job     = cat(2,'clean_corsica_intermediate_',subject,'_',run);            
            name_job_in0 = cat(2,'sica_',subject,'_',run);
            name_job_in1 = cat(2,'component_sel_ventricle_',subject,'_',run);
            name_job_in2 = cat(2,'component_sel_stem_',subject,'_',run);
            name_job_in3 = cat(2,'component_supp_',subject,'_',run);
            clear files_in_tmp files_out_tmp opt_tmp            
            files_in_tmp         = pipeline.(name_job_in3).files_out;            
            files_out_tmp        = '';
            opt_tmp.flag_verbose = 1;
            switch opt.size_output
                case 'minimum'
                    opt_tmp.clean.space      = pipeline.(name_job_in0).files_out.space;
                    opt_tmp.clean.time       = pipeline.(name_job_in0).files_out.time;
                    opt_tmp.clean.figure     = pipeline.(name_job_in0).files_out.figure;
                    opt_tmp.clean.compsel{1} = pipeline.(name_job_in1).files_out;
                    opt_tmp.clean.compsel{2} = pipeline.(name_job_in2).files_out;
                case 'quality_control'
                    opt_tmp.clean.space      = pipeline.(name_job_in0).files_out.space;
                    opt_tmp.clean.time       = pipeline.(name_job_in0).files_out.time;                    
            end
            pipeline = psom_add_job(pipeline,name_job,'niak_brick_clean',files_in_tmp,files_out_tmp,opt_tmp);                    
        end % run
    end % subject
end % size_output

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end