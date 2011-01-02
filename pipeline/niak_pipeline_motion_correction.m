function [pipeline,opt,files_out] = niak_pipeline_motion_correction(files_in,opt)
% Within-subject motion correction of fMRI data.
% Correction is implemented via estimation of a rigid-body transform and 
% spatial resampling.
%
% [PIPELINE,OPT,FILES_OUT] = NIAK_PIPELINE_MOTION_CORRECTION(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields (the field names <SESSION> can be 
%   any arbitrary string) : 
%
%   <SESSION>   
%       (cell of string) each entry is a file name of one fMRI dataset.
%
% OPT   
%   (structure) with the following fields:
%
%   LABEL
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
%   SUPPRESS_VOL 
%       (integer, default 0) the number of volumes that are suppressed at 
%       the begining of the time series. This is a good stage to get rid of 
%       "dummy scans" necessary to reach signal stabilization (that takes 
%       about 10 seconds, usually 3 to 5 volumes depending on the TR). Note 
%       that most brain imaging centers now automatically discard dummy 
%       scans.
%
%   INTERPOLATION 
%       (string, default 'tricubic') the spatial interpolation method used 
%       for resampling. Available options : 
%       'trilinear', 'tricubic', 'nearest_neighbour', 'sinc'.
%
%   FLAG_SKIP
%       (boolean, default 0) if FLAG_SKIP == 1, the brick does not do 
%       anything, just copying the inputs to the outputs (note that it is 
%       still possible to suppress volumes). The motion parameters are 
%       still estimated and the quality control is still performed.
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
%       MOTION_CORRECTED
%           (structure) a list of the final (motion corrected) output 
%           files organized as FILES_IN.
%
%       MOTION_PARAMETERS
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
% NOTE 3: if FLAG_SKIP==1, the motion parameters are still estimated yet
% no correction is applied to the fMRI datasets.
%
% NOTE 4: A session corresponds to a single scanning session with one
% participant (typically 1 hour) while a run is a single set of brain
% volumes (typically around 5 minutes). The real distinction between
% sessions and runs should be based upon size of displacements rather than
% time : if a subject had to get out of the scanner and repositioned, the
% runs before and after repositioning should be regarded as being collected
% on different sessions.
%
% NOTE 5: The TRANSF variables are standard 4*4 matrix array representation 
% of an affine transformation [M T ; 0 0 0 1] for (y=M*x+T) 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% geriatrie de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@criugm.qc.ca
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
    error('SYNTAX: [PIPELINE,OPT] = NIAK_PIPELINE_MOTION_CORRECTION(FILES_IN,OPT).\n Type ''help niak_pipeline_motion_correction'' for more info.')
end

%% FILES_IN
if ~isstruct(files_in)
    error('FILES_IN should be a structure')
end
list_session = fieldnames(files_in);
nb_session = length(list_session);
nb_run = zeros([nb_session 1]);
list_run = cell([nb_session 1]);
for num_s = 1:nb_session        
    nb_run(num_s) = length(files_in.(list_session{num_s}));
end

%% OPTIONS
opt_tmp.flag_test = true;
opt_psom.path_logs = '';
gb_name_structure = 'opt';
gb_list_fields   = {'ignore_slice' ,'fwhm' ,'step' ,'tol_within_run' ,'tol_between_run' ,'psom'   , 'label'  , 'vol_ref', 'run_ref', 'session_ref'   , 'parameters', 'suppress_vol', 'interpolation', 'flag_skip', 'folder_out', 'flag_test', 'flag_verbose'};
gb_list_defaults = {1              ,5      ,10     ,0.0005           ,0.00001           ,opt_psom , ''       , 'median' , 1        , list_session{1} , opt_tmp     , 0             , 'tricubic'     , false      , NaN         , false      , true          };
niak_set_defaults

if ~strcmp(opt.folder_out(end),filesep)
    opt.folder_out = [opt.folder_out filesep];
end
opt.psom.path_logs = [folder_out,'logs',filesep];
if isempty(label)
   label = 'subject';
end
opt.parameters.ignore_slice = opt.ignore_slice;
opt.parameters.fwhm         = opt.fwhm;
opt.parameters.step         = opt.step;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate the targets (run) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pipeline = [];
for num_s = 1:nb_session
    session = list_session{num_s};
    for num_r = 1:nb_run(num_s)               
        if (num_s==1)&&(num_r==1)
             [path_f,name_f,ext_f] = niak_fileparts(files_in.(session){num_r});
        end
        clear files_in_tmp files_out_tmp opt_tmp
        name_job        = sprintf('motion_target_%s_%s_run%i',label,session,num_r);
        files_in_tmp{1} = files_in.(session){num_r};
        files_out_tmp   = [opt.folder_out name_job ext_f];
        if ischar(vol_ref)
            opt_tmp.operation = 'vol = median(vol_in{1},4);';
        else
            opt_tmp.operation = sprintf('vol = vol_in{1}(:,:,:,%i);',vol_ref);
        end   
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_math_vol',files_in_tmp,files_out_tmp,opt_tmp);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimate the within-run motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};
    for num_r = 1:nb_run(num_s)               
        clear files_in_tmp files_out_tmp opt_tmp
        name_job_target                              = sprintf('motion_target_%s_%s_run%i',label,session,num_r);
        name_job                                     = sprintf('motion_Wrun_%s_%s_run%i',label,session,num_r);
        files_in_tmp.fmri                            = files_in.(session){num_r};
        files_in_tmp.target                          = pipeline.(name_job_target).files_out;
        files_out_tmp                                = [opt.folder_out name_job '.mat'];
        files_out.motion_parameters.(session){num_r} = files_out_tmp;
        opt_tmp                                      = opt.parameters;
        opt_tmp.tol                                  = opt.tol_within_run;                
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_motion_parameters',files_in_tmp,files_out_tmp,opt_tmp);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimate the within-session motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};    
    for num_r = 1:nb_run(num_s)
        if num_r~=run_ref            
            clear files_in_tmp files_out_tmp opt_tmp
            name_job_source     = sprintf('motion_target_%s_%s_run%i',label,session,num_r);
            name_job_target     = sprintf('motion_target_%s_%s_run%i',label,session,run_ref);                        
            name_job            = sprintf('motion_Wsession_%s_%s_run%i',label,session,num_r);
            files_in_tmp.fmri   = pipeline.(name_job_source).files_out;
            files_in_tmp.target = pipeline.(name_job_target).files_out;
            files_out_tmp       = [opt.folder_out name_job '.mat'];            
            opt_tmp             = opt.parameters;
            opt_tmp.tol         = opt.tol_between_run;                
            pipeline = psom_add_job(pipeline,name_job,'niak_brick_motion_parameters',files_in_tmp,files_out_tmp,opt_tmp);
        end
    end            
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Estimate the between-session motion parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};    
    if ~strcmp(session,session_ref)        
        clear files_in_tmp files_out_tmp opt_tmp
        name_job_target     = sprintf('motion_target_%s_%s_run%i',label,session_ref,run_ref);    
        name_job_source     = sprintf('motion_target_%s_%s_run%i',label,session,run_ref);            
        name_job            = sprintf('motion_Bsession_%s_%s',label,session);
        files_in_tmp.fmri   = pipeline.(name_job_source).files_out;
        files_in_tmp.target = pipeline.(name_job_target).files_out;
        files_out_tmp       = [opt.folder_out name_job '.mat'];
        opt_tmp             = opt.parameters;
        opt_tmp.tol         = opt.tol_between_run;                
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_motion_parameters',files_in_tmp,files_out_tmp,opt_tmp);        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Combine within-run, within-session and between-session motion %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};
    for num_r = 1:nb_run(num_s)        
        clear files_in_tmp files_out_tmp opt_tmp
        name_job            = sprintf('motion_parameters_%s_%s_run%i',label,session,num_r);
        files_in_tmp{1}     = pipeline.(sprintf('motion_Wrun_%s_%s_run%i',label,session,num_r)).files_out;
        if num_r~=run_ref
            files_in_tmp{2} = pipeline.(sprintf('motion_Wsession_%s_%s_run%i',label,session,num_r)).files_out;
            nb_transf = 3;
        else
            nb_transf = 2;
        end
        if ~strcmp(session,session_ref)            
            files_in_tmp{nb_transf} = pipeline.(sprintf('motion_Bsession_%s_%s',label,session)).files_out;
        end                
        files_out_tmp                     = [opt.folder_out name_job '.mat'];        
        opt_tmp.var_name                  = 'transf';
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_combine_transf',files_in_tmp,files_out_tmp,opt_tmp);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resample fMRI datasets %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_s = 1:nb_session
    session = list_session{num_s};
    for num_r = 1:nb_run(num_s)
        clear files_in_tmp files_out_tmp opt_tmp
        [path_f,name_f,ext_f]                       = niak_fileparts(files_in.(session){num_r});
        files_out_tmp                               = [opt.folder_out name_f '_mc' ext_f];
        files_out.motion_corrected.(session){num_r} = files_out_tmp;
        if flag_skip
            name_job = sprintf('motion_copy_%s_%s_run%i',label,session,num_r);            
            files_in_tmp{1}            = files_in.(session){num_r};                        
            opt_tmp.operation          = sprintf('vol = vol_in{1}(:,:,:,%i:end);',1+suppress_vol);
            pipeline = psom_add_job(pipeline,name_job,'niak_brick_math_vol',files_in_tmp,files_out_tmp,opt_tmp);
        else
            name_job = sprintf('motion_resample_%s_%s_run%i',label,session,num_r);            
            files_in_tmp.transformation = pipeline.(sprintf('motion_parameters_%s_%s_run%i',label,session,num_r)).files_out;
            files_in_tmp.source         = files_in.(session){num_r};
            files_in_tmp.target         = pipeline.(sprintf('motion_target_%s_%s_run%i',label,session_ref,run_ref)).files_out;            
            opt_tmp.interpolation       = opt.interpolation;
            opt_tmp.suppress_vol        = opt.suppress_vol;
            pipeline = psom_add_job(pipeline,name_job,'niak_brick_resample_vol',files_in_tmp,files_out_tmp,opt_tmp);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
if ~flag_test
    psom_run_pipeline(pipeline,opt.psom);
end