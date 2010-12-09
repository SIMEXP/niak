function pipeline = niak_pipeline_fmristat_ind(files_in,opt)
% Individual level linear model analysis of fMRI data.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_FMRISTAT_IND(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   FMRI
%       (string) an fMRI dataset.
%
%   MASK 
%       (string, default 'gb_niak_omitted') a binary mask of the brain. If
%       omitted, a mask will be computed from the volume.
%
%   EVENTS
%       (string) a file describing the events. See the description of
%       FILES_IN.EVENTS in NIAK_BRICK_FMRI_DESIGN
%
%   SLICING
%       (string, default 'gb_niak_omitted') a file describing the events. 
%       See the description of FILES_IN.SLICING in NIAK_BRICK_FMRI_DESIGN
%
% OPT   
%   (structure) with the following fields : 
%
%
%   FOLDER_OUT 
%   (string) where to write the results of the pipeline. 
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will 
%       just produce a pipeline structure, and will not actually process 
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the 
%       data.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
% _________________________________________________________________________
% OUTPUTS : 
%
% PIPELINE 
%   (structure) describe all jobs that need to be performed in the
%   pipeline.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% The steps of the pipeline are the following :
%
% 1. (optional) Generation of one spatial average for each volume.
% 2. Generation of the design matrix based on the events and slicing infos.
% 3. Estimation of the parameters of the model, and statistical tests.
%
% _________________________________________________________________________
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, McGill 
% University, 2010.
% Pierre Bellec, Centre de recherche de l'institut de gériatrie de Montréal
% Université de Montréal, 2010.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, linear model, individual analysis, fmristat

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
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRISTAT_IND(FILES_IN,OPT).\n Type ''help niak_pipeline_fmristat_ind'' for more info.')
end

%% Checking that FILES_IN is in the correct format
if ~isstruct(files_in)

    error('FILES_IN should be a struture!')
    
else
   
    list_subject = fieldnames(files_in);
    nb_subject   = length(list_subject);
    flag_mask    = false([nb_subject 1]);
    flag_events  = false([nb_subject 1]);
    flag_slicing = false([nb_subject 1]);
    list_session = cell([nb_subject 1]);
    
    for num_s = 1:nb_subject
        
        subject = list_subject{num_s};
        data_subject = files_in.(subject);
        
        if ~isstruct(data_subject)
            error('FILES_IN.%s should be a structure!',upper(subject));
        end
        
        if ~isfield(data_subject,'fmri')
            error('I could not find the field FILES_IN.%s.FMRI!',upper(subject));
        end
        
        flag_mask(num_s)    = isfield(data_subject,'mask');
        flag_events(num_s)  = isfield(data_subject,'events');
        flag_slicing(num_s) = isfield(data_subject,'slicing');
                      
        data_fmri = data_subject.fmri;        
            
        list_session{num_s} = fieldnames(data_fmri);
        
        for num_c = 1:length(list_session{num_s})
            session = list_session{num_s}{num_c};
            data_session = data_fmri.(session);
            if ~iscellstr(data_session)
                error('FILES_IN.%s.fmri.%s is not a cell of strings!',upper(subject),upper(session));
            end                                
        end                
    end    
end

%% Options
gb_name_structure      = 'opt';
default_psom.path_logs = '';
gb_list_fields         = {'spatial_av' , 'fmri_design' , 'fmri_lm' , 'spatial_normalization' , 'contrasts' , 'which_stats' , 'exclude' , 'mask_thresh' , 'folder_out' , 'flag_test' , 'psom'       };
gb_list_defaults       = {struct()     , struct()      , struct()  , 'none'                  , NaN         , []            , []        , []            , NaN          , false       , default_psom };
niak_set_defaults

opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if ~ismember(opt.spatial_normalization,{'additive_glb_av','scaling_glb_av','all_glb_av','none'})
    error(cat(2,opt.spatial_normalization,': is an unknown option for OPT.SPATIAL_NORMALIZATION. Available options are ''additive_glb_av'', ''scaling_glb_av'', ''all_glb_av'',''none'''))
end
flag_spatial_av = ~strcmp(opt.spatial_normalization,'none');

if ~isstruct(opt.contrasts)
     error('OPT.CONTRASTS should be a struture!')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = struct();

%%%%%%%%%%%%%%%%%%%%%
%% Spatial average %%
%%%%%%%%%%%%%%%%%%%%%

name_process = 'spatial_av';

if flag_spatial_av % If the user requested a correction for spatial_av
    
    for num_s = 1:nb_subject               
        subject      = list_subject{num_s};
        list_session = fieldnames(files_in.(subject).fmri);                
        
        for num_sess = 1:length(list_session)      
            session       = list_session{num_sess};
            files_session = files_in.(subject).fmri.(list_session{num_sess});
            
            for num_r = 1:length(files_session)                
                run      = cat(2,'run',num2str(num_r));
                name_job = cat(2,'spatial_av_',subject,'_',session,'_',run);
                
                %% Bulding inputs for NIAK_BRICK_SPATIAL_AV
                files_in_tmp.fmri = files_session{num_r};
                if flag_mask(num_s)
                    files_in_tmp.mask = files_in.(subject).mask;
                else
                    files_in_tmp.mask = [];
                end
                files_out_tmp      = [folder_out name_job '.mat'];
                opt_tmp            = opt.spatial_av;
                opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);

                %% Setting up defaults of the spatial_av
                opt_tmp.exclude = opt.exclude;
                opt_tmp.mask_thresh = opt.mask_thresh;
                
                pipeline = psom_add_job(pipeline,name_job,
                opt_tmp.flag_test = 1;
                [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_spatial_av(files_in_tmp,files_out_tmp,opt_tmp);
                opt_tmp.flag_test = 0;
                
                %% Keeping track of the file names
                files_sav.(subject).(session){num_r} = files_out_tmp;

                %% Adding the stage to the pipeline
                pipeline(1).(name_stage).command = 'niak_brick_spatial_av(files_in,files_out,opt)';
                pipeline(1).(name_stage).files_in = files_in_tmp;
                pipeline(1).(name_stage).files_out = files_out_tmp;
                pipeline(1).(name_stage).opt = opt_tmp;

            end % run
        end % session
    end % subject
    
end % if flag_spatial_av


%%%%%%%%%%%%%%%%%
%% fmri design %%
%%%%%%%%%%%%%%%%%

name_process = 'fmri_design';

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    list_session = fieldnames(files_in.(subject).fmri);
    nb_session = length(list_session);
    
    for num_sess = 1:nb_session
        
        session = list_session{num_sess};
        files_session = files_in.(subject).fmri.(session);
        files_session_slicing = files_in.(subject).slicing.(session);
        files_session_events = files_in.(subject).events.(session);
        nb_run = length(files_session);
        
        for num_r = 1:nb_run
            
            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,'fmri_design_',subject,'_',session,'_',run);
            
            %% Bulding inputs for NIAK_BRICK_FMRI_DESIGN
            files_in_tmp.fmri = files_session{num_r};
            if flag_slicing(num_s)
                files_in_tmp.slicing = files_session_slicing{num_r};
            end
            if flag_events(num_s)
                files_in_tmp.events = files_session_events{num_r};
            end
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.fmri_design;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
            
            %% Setting up defaults of the fmri_design
            opt_tmp.exclude = opt.exclude;
            if flag_spatial_av
                spatial_av_tmp = importdata(files_sav.(subject).(session){num_r});
                opt_tmp.spatial_av = spatial_av_tmp;
                if (~isfield(opt_tmp,'nb_trends_spatial'))&&any(strcmp(opt.spatial_normalization,{'additive_glb_av','all_glb_av'}))
                    opt_tmp.nb_trends_spatial = 1;
                end
            end
                       
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_fmri_design(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
            
            %% Keeping track of the file names
            files_des.(subject).(session){num_r} = files_out_tmp;
            
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).command = 'niak_brick_fmri_design(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
        end % run
    end % session
end % subject
   
%%%%%%%%%%%%
%% fmrilm %%
%%%%%%%%%%%%
name_process = 'fmri_lm';    

for num_s = 1:nb_subject
    
    subject = list_subject{num_s};
    clear opt_tmp files_in_tmp files_out_tmp
    list_session = fieldnames(files_in.(subject).fmri);
    nb_session = length(list_session);
    
    for num_sess = 1:nb_session
        
        session = list_session{num_sess};
        files_session = files_in.(subject).fmri.(session);
        nb_run = length(files_session);
        
        for num_r = 1:nb_run
            
            run = cat(2,'run',num2str(num_r));
            name_stage = cat(2,'fmri_lm_',subject,'_',session,'_',run);
            
            %% Bulding inputs for NIAK_BRICK_FMRI_LM
            files_in_tmp.fmri = files_session{num_r};
            files_in_tmp.design = files_des.(subject).(session){num_r};
            if flag_mask(num_s)
                files_in_tmp.mask = files_in.(subject).mask;
            else
                files_in_tmp.mask = [];
            end
            files_out_tmp = '';
            
            %% Setting up options
            opt_tmp = opt.bricks.fmri_lm;
            opt_tmp.folder_out = cat(2,opt.folder_out,filesep,name_process,filesep,subject,filesep);
            if ~isempty(opt.which_stats)
                nf_which = length(opt.which_stats);
                for i=1:nf_which
                    files_out_tmp.(opt.which_stats{i}) = '';
                end
            end
            
            %% Setting up defaults of the fmrilm
            if isfield(opt.contrasts,'name')
                opt_tmp.contrast_names = opt.contrasts.name;
            end
            opt_tmp.contrast = opt.contrasts.weight;
            opt_tmp.exclude = opt.exclude;
            opt_tmp.mask_thresh = opt.mask_thresh;
            if flag_spatial_av
                spatial_av_tmp = importdata(files_sav.(subject).(session){num_r});
                opt_tmp.spatial_av = spatial_av_tmp;
                if (~isfield(opt_tmp,'nb_trends_spatial'))&&any(strcmp(opt.spatial_normalization,{'additive_glb_av','all_glb_av'}))
                    opt_tmp.nb_trends_spatial = 1;
                end
                if (~isfield(opt_tmp,'pcnt'))&&any(strcmp(opt.spatial_normalization,{'scaling_glb_av','all_glb_av'}))
                    opt_tmp.pcnt = 1;
                end
            end
                      
            opt_tmp.flag_test = 1;
            [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_fmri_lm(files_in_tmp,files_out_tmp,opt_tmp);
            opt_tmp.flag_test = 0;
            
            %% Keeping track of the file names
            %files_a.(subject).(session){num_r} = files_out_tmp;
            
            %% Adding the stage to the pipeline
            pipeline(1).(name_stage).command = 'niak_brick_fmri_lm(files_in,files_out,opt)';
            pipeline(1).(name_stage).files_in = files_in_tmp;
            pipeline(1).(name_stage).files_out = files_out_tmp;
            pipeline(1).(name_stage).opt = opt_tmp;
        
        end % run
    end % session
end % subject


%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end