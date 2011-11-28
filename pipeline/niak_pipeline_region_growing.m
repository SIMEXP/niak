function pipeline = niak_pipeline_region_growing(files_in,opt)
% Pipeline to perform a fixed-effect region growing on multiple datasets.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_REGION_GROWING(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%
%   FMRI
%       (cell of strings) a list of fMRI datasets, all in the same space.
%
%   AREAS
%       (string, default AAL template from NIAK) the name of the brain 
%       parcelation template that will be used to constrain the region 
%       growing.
%
%   MASK
%       (string, default FILES_IN.AREAS) a file name of a binary mask 
%       common to all datasets.
%
% OPT   
%   (structure) with the following fields : 
%   
%   LABELS
%       (cell of strings, default {'file1','files2',...}) LABELS{I} will be 
%       used as part of the name of the job for masking the brain of 
%       dataset FILES_IN{I}.
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
%   THRE_SIZE 
%       (integer,default 1000 mm3) threshold on the region size (maximum). 
%
%   THRE_SIM
%       (real value, default NaN) threshold on the similarity between
%       regions (minimum). If the value is NaN, no test is applied.
%
%   THRE_NB_ROIS 
%       (integer, default 0) the minimum number of homogeneous
%       regions (if no threshold are fixed on size and similarity,
%       THRE_NB_ROIS will be the actual number of homogeneous regions).
%
%   SIM_MEASURE 
%       (string, default 'afc') the similarity measure between regions.
%
%   CORRECTION_IND
%       (structure, default CORRECTION.TYPE = 'mean') the temporal 
%       normalization to apply on the individual time series before 
%       concatenation. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   CORRECTION_GROUP
%       (structure, default CORRECTION.TYPE = 'mean_var') the temporal 
%       normalization to apply on the individual time series before 
%       region growing. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   CORRECTION_AVERAGE
%       (structure, default CORRECTION.TYPE = 'mean') the temporal 
%       normalization to apply on the individual time series before 
%       averaging in each ROI. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   IND_ROIS
%       (vector of integer, default all) list of ROIs index that will 
%       be included in the analysis. By default, the brick is processing 
%       all the ROIs found in FILES_IN.MASK
%
%   FLAG_SIZE 
%       (boolean, default 1) if FLAG_SIZE == 1, all regions that
%       are smaller than THRE_SIZE at the end of the growing process
%       are merged into the most functionally close neighbour iteratively
%       unless all the regions are larger than THRE_SIZE
%
%   FLAG_TSERIES
%       (boolean, default 1) if FLAG_TSERIES == 1, the average time series 
%       within each ROI will be generated.
%
% _________________________________________________________________________
% OUTPUTS : 
%
% PIPELINE 
%   (structure) describe all jobs that need to be performed in the 
%   pipeline. This structure is meant to be used with the pipeline manage 
%   PSOM_RUN_PIPELINE.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_TSERIES, NIAK_BRICK_NEIGHBOUR, NIAK_BRICK_REGION_GROWING,
% NIAK_BRICK_MERGE_PART
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
% The steps of the pipeline are the following :
%   1. Combining the analysis mask and the areas.
%   2. Extracting the time series in each area.
%   3. Performing region growing in each area independently.
%   4. Merging all regions of all areas into one mask of regions, along
%   with the corresponding time series for each functional run (if
%   FLAG_TSERIES is true).
%
% NOTE 2:
% This pipeline assumed fully preprocessed fMRI data in stereotaxic space
% as inputs. See NIAK_PIPELINE_FMRI_PREPROCESS.
%
% NOTE 3:
% Please refer to the following paper for further details on the method :
% P. Bellec; V. Perlbarg; S. Jbabdi; M. Pélégrini-Issac; J.L. Anton; H.
% Benali, Identification of large-scale networks in the brain using fMRI. 
% Neuroimage, 2006, 29: 1231-1243.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

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
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_REGION_GROWING(FILES_IN,OPT).\n Type ''help niak_pipeline_region_growing'' for more info.')
end

%% Checking that FILES_IN is in the correct format
flag_areas = false;
if ~isstruct(files_in)
    error('FILES_IN should be a struture!')
else
   
    if ~isfield(files_in,'fmri')
        error('I could not find the field FILES_IN.FMRI!');
    end

    if ~iscellstr(files_in.fmri)
        error('FILES_IN.FMRI should be a cell of strings!');
    end

    if isfield(files_in,'areas_in')&&~isempty(files_in.areas_in)
        flag_areas = true;
    end
    
    if ~isfield(files_in,'mask')||isempty(files_in.mask)||strcmp(files_in.mask,'gb_niak_omitted')
        files_in.mask = files_in.areas;
    end

    if ~ischar(files_in.mask)
        error('FILES_IN.MASK should be a string !');
    end

end
   
%% Options
default_psom.path_logs = '';
opt_norm_ind.type      = 'mean';
opt_norm_group.type    = 'mean_var';
opt_norm_average.type  = 'mean';

gb_name_structure = 'opt';
gb_list_fields    = { 'flag_tseries' , 'labels' , 'ind_rois' , 'thre_size' , 'thre_sim' , 'thre_nb_rois' , 'sim_measure' , 'correction_ind' , 'correction_group' , 'correction_average' , 'flag_size' , 'folder_out' , 'psom'       , 'flag_test', 'flag_skip' };
gb_list_defaults  = { true           , {}       , []         , 1000        , []         , 0              , 'afc'         , opt_norm_ind     , opt_norm_group     , opt_norm_average     , true        , NaN          , default_psom , false      , true };
niak_set_defaults

if isempty(opt.thre_sim)
    opt.thre_sim = NaN;
    thre_sim = NaN;
end
opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if flag_skip
    return; 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization of the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nb_files = length(files_in.fmri);
if isempty(opt.labels)
    opt.labels = cell([nb_files 1]);
    for num_f = 1:nb_files
        opt.labels{num_f} = sprintf('file%i',num_f);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resampling of the AAL template  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% name_job = 'resamp_aal';
% clear files_in_tmp files_out_tmp opt_tmp



% files_in_tmp.source      = files_in.areas;
% files_in_tmp.target      = files_in.fmri{1};
% [path_f,name_f,ext_f,flag_zip,ext_short] = niak_fileparts(files_in_tmp.target);
% files_out_tmp            = [opt.folder_out filesep 'template_aal' ext_f];
% pipeline = psom_add_job(struct(),name_job,'niak_brick_resample_aal',files_in_tmp,files_out_tmp,[],false);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mask the areas with the brain mask  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
name_job = 'mask_areas';
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp{1}       = files_in.areas;
files_in_tmp{2}       = files_in.mask;
[path_f,name_f,ext_f] = niak_fileparts(files_in.fmri{1});
files_out_tmp         = [opt.folder_out filesep 'areas' filesep 'brain_areas' ext_f];
opt_tmp.operation     = 'vol = vol_in{1}; vol(vol_in{2}<=0) = 0;';
pipeline = psom_add_job(struct(),name_job,'niak_brick_math_vol',files_in_tmp,files_out_tmp,opt_tmp,false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract time series in the areas  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for num_f = 1:nb_files
    clear files_in_tmp files_out_tmp opt_tmp
    files_in_tmp.fmri{1}     = files_in.fmri{num_f};
    files_in_tmp.mask        = pipeline.mask_areas.files_out;
    files_out_tmp.tseries{1} = [opt.folder_out 'areas' filesep 'tseries_areas_' opt.labels{num_f} '.mat'];
    opt_tmp.flag_all         = true;
    opt_tmp.correction.type  = 'none';
    opt_tmp.ind_rois         = opt.ind_rois;
    pipeline = psom_add_job(pipeline,['tseries_' opt.labels{num_f}],'niak_brick_tseries',files_in_tmp,files_out_tmp,opt_tmp);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Build the spatial neighbourhood structure  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp = pipeline.mask_areas.files_out;
files_out_tmp = '';
opt_tmp.flag_all = true;
opt_tmp.ind_rois = opt.ind_rois;
pipeline = psom_add_job(pipeline,'neighbourhood_areas','niak_brick_neighbour',files_in_tmp,files_out_tmp,opt_tmp);

%%%%%%%%%%%%%%%%%%%%%
%% Region growing  %%
%%%%%%%%%%%%%%%%%%%%%
if flag_areas || ~isempty(opt.ind_rois)
    [hdr,mask] = niak_read_vol(files_in.areas_in); 
    mask = round(mask);
    if ~isempty(opt.ind_rois)
        mask = mask(ismember(mask,opt.ind_rois));
    end
    list_roi = unique(mask(:))';
    list_roi = list_roi(list_roi~=0);
else
    list_roi = [2001   2002   2101   2102   2111   2112   2201   2202   2211   2212   2301   2302   2311   2312   2321   2322   2331   2332   2401   2402   2501   2502   2601   2602   2611   2612   2701   2702   3001   3002   4001   4002   4011   4012   4021   4022 4101   4102   4111   4112   4201   4202   5001   5002   5011   5012   5021   5022   5101   5102   5201   5202   5301   5302 5401   5402   6001   6002   6101   6102   6201   6202   6211   6212   6221   6222   6301   6302   6401   6402   7001   7002 7011   7012   7021   7022   7101   7102   8101   8102   8111   8112   8121   8122   8201   8202   8211   8212   8301   8302 9001   9002   9011   9012   9021   9022   9031   9032   9041   9042   9051   9052   9061   9062   9071   9072   9081   9082 9100   9110   9120   9130   9140   9150   9160   9170];
end

for num_r = list_roi
    clear files_in_tmp files_out_tmp opt_tmp    
    files_in_tmp.tseries = cell([nb_files 1]);
    for num_f = 1:nb_files        
        files_in_tmp.tseries{num_f} = pipeline.(['tseries_' opt.labels{num_f}]).files_out.tseries{1};
    end
    files_in_tmp.neig        = pipeline.neighbourhood_areas.files_out;    
    files_out_tmp            = [opt.folder_out 'areas' filesep 'part_areas_' num2str(num_r) '.mat'];
    opt_tmp.correction_ind   = opt.correction_ind;
    opt_tmp.correction_group = opt.correction_group;
    opt_tmp.thre_size        = opt.thre_size;
    opt_tmp.thre_sim         = opt.thre_sim;
    opt_tmp.thre_nb_rois     = opt.thre_nb_rois;
    opt_tmp.sim_measure      = opt.sim_measure;
    opt_tmp.var_tseries      = ['tseries_',num2str(num_r)];
    opt_tmp.var_neig         = ['neig_',num2str(num_r)];
    opt_tmp.flag_size        = opt.flag_size;
    pipeline = psom_add_job(pipeline,['region_growing_area_' num2str(num_r)],'niak_brick_region_growing',files_in_tmp,files_out_tmp,opt_tmp);    
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% Merging the areas  %%
%%%%%%%%%%%%%%%%%%%%%%%%
clear files_in_tmp files_out_tmp opt_tmp    
files_in_tmp.tseries = cell([nb_files 1]);    
for num_f = 1:nb_files    
    files_in_tmp.tseries{num_f} = pipeline.(['tseries_' opt.labels{num_f}]).files_out.tseries{1};
end
for num_r = 1:length(list_roi)    
    files_in_tmp.part{num_r} = pipeline.(['region_growing_area_' num2str(list_roi(num_r))]).files_out;
end
files_in_tmp.areas = pipeline.mask_areas.files_out;    
if flag_tseries
    files_out_tmp.tseries = cell([nb_files 1]);
    for num_f = 1:nb_files
        files_out_tmp.tseries{num_f} = [opt.folder_out 'rois' filesep 'tseries_rois_' opt.labels{num_f} '.mat'];
    end
else
    files_out_tmp.tseries = 'gb_niak_omitted';
end
files_out_tmp.space =  [opt.folder_out 'rois' filesep 'brain_rois' ext_f];
opt_tmp.correction  = opt.correction_average;
opt_tmp.ind_rois    = list_roi;
pipeline = psom_add_job(pipeline,'merge_part','niak_brick_merge_part',files_in_tmp,files_out_tmp,opt_tmp);    

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
