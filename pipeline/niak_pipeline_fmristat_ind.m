function pipeline = niak_pipeline_fmristat_ind(files_in,opt)
% Individual-level linear model analysis of fMRI data.
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
%       (string, default 'gb_niak_omitted') the name of a file containing
%       relative slice acquisition times i.e. absolute acquisition time of 
%       a slice is FRAME_TIMES+SLICE_TIMES. If omitted, the differences in 
%       slice timing will be ignored.
%       See the description of FILES_IN.SLICING in NIAK_BRICK_FMRI_DESIGN
%
% OPT   
%   (structure) with the following fields : 
%
%   LABEL
%       (string) a string that will be used to name the outputs.
%
%   CONTRAST
%       (structure)
%
%   FOLDER_OUT 
%       (string) where to write the results of the pipeline. 
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

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:brick','syntax: PIPELINE = NIAK_PIPELINE_FMRISTAT_IND(FILES_IN,OPT).\n Type ''help niak_pipeline_fmristat_ind'' for more info.')
end

%% Input files
gb_name_structure      = 'files_in';
gb_list_fields         = {'fmri' , 'events' , 'slicing'         , 'mask'            };
gb_list_defaults       = {NaN    , NaN      , 'gb_niak_omitted' , 'gb_niak_omitted' };
niak_set_defaults

%% Options
gb_name_structure      = 'opt';
gb_list_fields         = {'spatial_av' , 'fmri_design' , 'fmri_lm' , 'spatial_normalization' , 'contrasts' , 'which_stats' , 'exclude' , 'mask_thresh' , 'folder_out' , 'flag_test' , 'psom'   };
gb_list_defaults       = {struct()     , struct()      , struct()  , 'none'                  , NaN         , []            , []        , []            , NaN          , false       , struct() };
niak_set_defaults
opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if ~ismember(opt.spatial_normalization,{'additive_glb_av','scaling_glb_av','all_glb_av','none'})
    error(cat(2,opt.spatial_normalization,': is an unknown option for OPT.SPATIAL_NORMALIZATION. Available options are ''additive_glb_av'', ''scaling_glb_av'', ''all_glb_av'',''none'''))
end
flag_spatial_av = ~strcmp(opt.spatial_normalization,'none');

if ~isstruct(opt.contrasts)
     error('OPT.CONTRASTS should be a struture!')
end

%%%%%%%%%%%%%%%%%%%%%
%% Spatial average %%
%%%%%%%%%%%%%%%%%%%%%
pipeline = struct();
if flag_spatial_av % If the user requested a correction for spatial_av
    name_job_av         = cat(2,'spatial_av_',label);                            
    files_in_tmp.fmri   = files_session{num_r};
    files_in_tmp.mask   = files_in.mask;
    files_out_tmp       = [opt.folder_out name_job_av '.mat'];
    opt_tmp             = opt.spatial_av;
    opt_tmp.exclude     = opt.exclude;
    opt_tmp.mask_thresh = opt.mask_thresh;
    pipeline            = psom_add_job(pipeline,name_job_av,'niak_brick_spatial_av',files_in_tmp,files_out_tmp,opt_tmp);                
end % if flag_spatial_av

%%%%%%%%%%%%%%%%%
%% fmri design %%
%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_job_design   = ['fmri_design_' label];
files_in_tmp.fmri = rmfield(files_in,'mask');
if flag_spatial_av
    files_in_tmp.spatial_av = pipeline.(name_job_av).files_out;
end
files_out_tmp     = [opt.folder_out name_job_design '.mat'];
opt_tmp           = opt.bricks.fmri_design;
opt_tmp.exclude   = opt.exclude;
if (~isfield(opt_tmp,'nb_trends_spatial'))&&ismember(opt.spatial_normalization,{'additive_glb_av','all_glb_av'})
    opt_tmp.nb_trends_spatial = 1;
end
pipeline = psom_add_job(pipeline,name_job_design,'niak_brick_fmri_design',files_in_tmp,files_out_tmp,opt_tmp);
            
%%%%%%%%%%%%
%% fmrilm %%
%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
name_job_lm = ['fmri_lm_' label];
files_in_tmp.fmri = files_in.fmri;
files_in_tmp.design = pipeline.(name_job_design).files_out;
files_in_tmp.mask = files_in.mask;
if flag_spatial_av
    files_in_tmp.spatial_av = pipeline.(name_job_av).files_out;
end
if ~isempty(opt.which_stats)
    nf_which = length(opt.which_stats);
    for num_i=1:nf_which
        files_out_tmp.(opt.which_stats{num_i}) = '';
    end
end
opt_tmp = opt.bricks.fmri_lm;
opt_tmp.folder_out = opt.folder_out;
if isfield(opt.contrasts,'name')
    opt_tmp.contrast_names = opt.contrasts.name;
end
opt_tmp.contrast = opt.contrasts.weight;
opt_tmp.exclude = opt.exclude;
opt_tmp.mask_thresh = opt.mask_thresh;
if (~isfield(opt_tmp,'nb_trends_spatial'))&&ismember(opt.spatial_normalization,{'additive_glb_av','all_glb_av'})
    opt_tmp.nb_trends_spatial = 1;
end
if (~isfield(opt_tmp,'pcnt'))&&ismember(opt.spatial_normalization,{'scaling_glb_av','all_glb_av'})
    opt_tmp.pcnt = 1;
end
pipeline = psom_add_job(pipeline,name_job_design,'niak_brick_fmri_lm',files_in_tmp,files_out_tmp,opt_tmp);                                  

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end