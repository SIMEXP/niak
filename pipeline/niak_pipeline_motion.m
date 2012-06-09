function [pipeline,opt,files_out] = niak_pipeline_motion(files_in,opt)
% Estimation of within-subject motion in fMRI data.
%
% [PIPELINE,OPT,FILES_OUT] = NIAK_PIPELINE_MOTION(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN.<SESSION>.<RUN>  
%   (string) the file name of one fMRI dataset. All datasets in <SESSIONS>
%       are acquired in the same session (small displacements).
%
% OPT   
%   (structure) with the following fields:
%
%   SUBJECT
%       (string, default 'subject') an extra string which will be added in the
%       output names.
%
%   PSOM
%       (structure, default from the PSOM configuration file) the options 
%       of the pipeline system, see PSOM_RUN_PIPELINE. The folder for logs 
%       is not optional though, it is 'logs' located in OPT.FOLDER_OUT
%
%   FOLDER_OUT 
%       (string) The name of the folder to save all the outputs.
%
%   VOL_REF 
%       (vector, default 'median') VOL_REF is the number of the volume that 
%       will be used as target in each run. If VOL_REF is a string, the 
%       median volume of the run of reference in each session will be used 
%       rather than an arbitrary volume. This option superseeds the 
%       contents of OPT.PARAMETERS
%
%   RUN_REF 
%       (vector, default 1) RUN_REF(NUM) is the number of the run that will 
%       be used as target for session NUM. If RUN_REF is a single integer, 
%       the same number will be used for all sessions.
%
%   SESSION_REF 
%       (string, default first session) name of the session of reference. 
%       By default, it is the first field found in FILES_IN.
%
%   IGNORE_SLICE
%       (integer, default 1) ignore the first and last IGNORE_SLICE slices 
%       of the volume in the coregistration process.
%
%   FWHM
%       (real number, default 5 mm) the fwhm of the blurring kernel applied 
%       to all volumes before coregistration.
%
%   STEP
%       (real number, default 10) The step argument for MINCTRACC.
%
%   TOL_WITH_RUN
%       (real number, default 0.0005) The tolerance level for convergence 
%       in MINCTRACC for within-run motion correction.
%
%   TOL_BETWEEN_RUN
%       (real number, default 0.00001) The tolerance level for convergence 
%       in MINCTRACC in between-run motion correction (either intra- or 
%       inter-session).
%
%   FLAG_TEST 
%       (boolean, default: 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
%   FLAG_VERBOSE 
%       (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%       indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   PIPELINE
%       (structure) each field describes one job of the pipeline.
%
%   OPT
%       (structure) same as inputs, updated for default values.
%
%   FILES_OUT
%       (structure) with the following fields :
%
%       FINAL
%           (structure) a list of the final motion parameters (the target is 
%           the run of reference in the session of reference).
%
%       WITHIN_RUN
%           (structure) a list of the within-run motion parameters
%           organized as FILES_IN.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MOTION_PARAMETERS, NIAK_DEMO_PIPELINE_MOTION_CORRECTION
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1: The motion correction follows a hierachical strategy :
% Rigid-body transforms are first estimated within each run 
% independently by registering all volumes to one single reference volume
% in a run of reference.
% Then, the volumes of reference within each session are coregistered with 
% one volume of reference (of the run of reference)
% Finally, these volumes of references (session level) are coregistered to
% the volume of reference of the session of references.
% The within-run, within-session and between-sessions transformation are 
% combined.
%
% NOTE 2: if FLAG_SESSION == 1, the within-run transformations are not 
% applied. 
%
% NOTE 3: A session corresponds to a single scanning session with one
% participant (typically 1 hour) while a run is a single set of brain
% volumes (typically around 5 minutes). The real distinction between
% sessions and runs should be based upon size of displacements rather than
% time : if a subject had to get out of the scanner and repositioned, the
% runs before and after repositioning should be regarded as being collected
% on different sessions.
%
% NOTE 4: The TRANSF variables are standard 4*4 matrix array representation 
% of an affine transformation [M T ; 0 0 0 1] for (y=M*x+T) 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% geriatrie de Montreal, Montreal, Canada, 2010-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, motion correction, fMRI

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

flag_gb_niak_fast_gb = true;
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')
    error('SYNTAX: [PIPELINE,OPT] = NIAK_PIPELINE_MOTION(FILES_IN,OPT).\n Type ''help niak_pipeline_motion'' for more info.')
end

%% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a structure')
end
list_session = fieldnames(files_in);

%% OPTIONS
job_opt.flag_test = true;
opt_psom.path_logs = '';
gb_name_structure = 'opt';
gb_list_fields   = {'ignore_slice' ,'fwhm' ,'step' ,'tol_within_run' ,'tol_between_run' , 'psom'   , 'subject' , 'vol_ref', 'run_ref', 'session_ref'   , 'parameters', 'folder_out', 'flag_test', 'flag_verbose'};
gb_list_defaults = {1              ,5      ,10     ,0.0005           ,0.00001           , opt_psom , 'subject' , 'median' , 1        , list_session{1} , job_opt     , NaN         , false      , true          };
psom_set_defaults

opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out,'logs',filesep];
opt.parameters.ignore_slice = opt.ignore_slice;
opt.parameters.fwhm         = opt.fwhm;
opt.parameters.step         = opt.step;

%% Initialize the pipeline
pipeline = [];
tmp.(subject) = files_in;
[fmri,label] = niak_fmri2cell(tmp);
fmri_s = niak_fmri2struct(tmp);
[path_f,name_f,ext_f] = niak_fileparts(fmri{1});

%% Generate the targets (run) 
for num_e = 1:length(fmri)
    clear job_in job_out job_opt
    job_in = fmri(num_e);
    job_out   = [opt.folder_out 'motion_target_' label(num_e).name ext_f];
    if ischar(vol_ref)
        job_opt.operation = 'vol = median(vol_in{1},4);';
    else
        job_opt.operation = sprintf('vol = vol_in{1}(:,:,:,%i);',vol_ref);
    end   
    job_opt.flag_extra = false;
    pipeline = psom_add_job(pipeline,['motion_target_' label(num_e).name],'niak_brick_math_vol',job_in,job_out,job_opt);
end

%% Estimate the within-run motion parameters
for num_e = 1:length(fmri)
    clear job_in job_out job_opt
    job_in.fmri     = fmri{num_e};
    job_in.target   = pipeline.(['motion_target_' label(num_e).name]).files_out;
    job_out         = [opt.folder_out 'motion_Wrun_' label(num_e).name '.mat'];
    files_out.within_run.(label(num_e).subject).(label(num_e).session).(label(num_e).run) = job_out;
    job_opt         = opt.parameters;
    job_opt.tol     = opt.tol_within_run;        
    pipeline = psom_add_job(pipeline,['motion_Wrun_' label(num_e).name],'niak_brick_motion_parameters',job_in,job_out,job_opt);
end

%% Estimate the within-session motion parameters 
for num_s = 1:length(list_session)
    session = list_session{num_s};
    list_run = fieldnames(fmri_s.(subject).(session));
    for num_r = 1:length(list_run)
        if num_r~=run_ref
            clear job_in job_out job_opt
            name_job_source = ['motion_target_'   subject '_' session '_' list_run{num_r}   ];
            name_job_target = ['motion_target_'   subject '_' session '_' list_run{run_ref} ];
            name_job        = ['motion_Wsession_' subject '_' session '_' list_run{num_r}   ];
            job_in.fmri   = pipeline.(name_job_source).files_out;
            job_in.target = pipeline.(name_job_target).files_out;
            job_out       = [opt.folder_out name_job '.mat'];            
            job_opt       = opt.parameters;
            job_opt.tol   = opt.tol_between_run;                
            pipeline = psom_add_job(pipeline,name_job,'niak_brick_motion_parameters',job_in,job_out,job_opt);
        end
    end            
end

%% Estimate the between-session motion parameters 
list_run_ref = fieldnames(fmri_s.(subject).(session_ref));
for num_s = 1:length(list_session)
    session = list_session{num_s};   
    if ~strcmp(session,session_ref)        
        clear job_in job_out job_opt
        name_job_source     = ['motion_target_'   subject '_' session     '_' list_run{run_ref} ];           
        name_job_target     = ['motion_target_'   subject '_' session_ref '_' list_run_ref{run_ref} ];   
        name_job            = ['motion_Bsession_' subject '_' session ];
        job_in.fmri   = pipeline.(name_job_source).files_out;
        job_in.target = pipeline.(name_job_target).files_out;
        job_out       = [opt.folder_out name_job '.mat'];
        job_opt       = opt.parameters;
        job_opt.tol   = opt.tol_between_run;                
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_motion_parameters',job_in,job_out,job_opt);        
    end
end

%% Combine within-run, within-session and between-session motion
for num_s = 1:length(list_session)
    session = list_session{num_s};
    list_run = fieldnames(fmri_s.(subject).(session));
    for num_r = 1:length(list_run)      
        clear job_in job_out job_opt
        name_job  = ['motion_parameters_' subject '_' session '_' list_run{num_r}];
        job_in{1} = pipeline.(['motion_Wrun_' subject '_' session '_' list_run{num_r}]).files_out;
        if num_r~=run_ref
            job_in{2} = pipeline.(['motion_Wsession_' subject '_' session '_' list_run{num_r}]).files_out;
        end
        if ~strcmp(session,session_ref)            
            job_in{end+1} = pipeline.(['motion_Bsession_' subject '_' session]).files_out;
        end                
        job_out          = [opt.folder_out name_job '.mat'];  
        files_out.final.(subject).(session).(list_run{num_r}) = job_out;
        job_opt.var_name = 'transf';
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_combine_transf',job_in,job_out,job_opt);
    end
end

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
if ~flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
