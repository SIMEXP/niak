function [pipeline,opt] = niak_pipeline_stability_rest(files_in,opt)
% Multi-level, multi-scale analysis of stable clusters in resting-state fMRI
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_STABILITY_REST(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   DATA
%      (structure) with the following fields :
%
%      <SUBJECT>.<SESSION>.<RUN>
%         (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> 
%         and <RUN> can be any arbitrary string. Note that time series can 
%         be specified directly as variables in a .mat file. The file 
%         FILES_IN.ATOMS needs to be specified in that instance. 
%         The <SESSION> level can be skipped.
%
%   INFOS
%      (string, default 'gb_niak_omitted') the name of a CSV file. 
%      Example :
%                , SEX , HANDEDNESS
%      <SUBJECT> , 0   , 0 
%      This type of file can be generated with Excel (save under CSV).
%      The infos will be used to "stratify" the data, i.e. resampling of
%      the data will be restricted within groups of subjects that share 
%      identical infos. All strata will be given equal weights to build
%      the consensus across subjects. If omitted, all subjects will belong
%      to the same strata.
%
%   AREAS
%      (string, default AAL template from NIAK) the name of the brain 
%      parcelation template that will be used to constrain the region 
%      growing.
%
%   MASK
%      (string, default AREAS>0) a file name of a binary mask common to 
%      all subjects and runs.
%
%   ATOMS
%      (string, optional) a file name of a mask of brain regions (region I
%      is filled with Is, 0 is for the background). The analysis will be
%      done at the level of these atomic regions. This means that the fMRI
%      time series will be averaged in each region, and the stability
%      analysis will be carried on these regional time series. If
%      unspecified, the regions will be built using a region growing
%      approach. It is also possible to enter directly regional time series
%      in the analysis (see FILES_IN.DATA), and ATOMS needs to be specified
%      in that instance.
%
% OPT
%   (structure) with the following fields :
%
%   FOLDER_OUT
%      (string) where to write the results of the pipeline. 
%
%   GRID_SCALES
%      (vector) GRID_SCALES describes the grid of scale parameters that
%      will be investigated. GRID_SCALES(K) is more specifically the number
%      of individual clusters for test number K. Some combinations of scales
%      will be investigated at the individual and group levels. Basically
%      the group scales located in a neighbourhood of each individual scale
%      (see OPT.NEIGH below) will be tested, as well as all possible final
%      number of clusters, whether it be at the individual or the group levels.
%      This parameter is mandatory unless OPT.FLAG_ROI is true (see
%      below).
%
%   SCALES_MAPS
%      (array, default []) SCALES_MAPS(K,:) is the list of scales that will
%      be used to generate stability maps (individual, group and mixed
%      levels, depending on the flags described below):
%          SCALES_MAPS(K,1) is the number of individual clusters
%          SCALES_MAPS(K,2) is the number of group clusters
%          SCALES_MAPS(K,3) is the number of final clusters
%      Usually the pipeline runs a first time to get the results of the MSTEPS
%      selection, and then the scale parameters selected by MSTEPS are used to
%      set SCALES_MAPS.
%
%   NEIGH
%      (vector, default [0.7 0.1 1.3]) defines the local neighbourhood of
%      a number of group clusters to derive local maxima in contrast
%      functions and explore the individual/group scales. More
%      specifically, for each group scale L, all scales in ceil(neigh*L)
%      will be tested. A number of clusters L will be defined as local
%      maximum if the associated summary measure of stability is higher
%      or equal than for any other scale in [NEIGH(1)*L NEIGH(end)*L].
%
%   PARAM
%      (scalar, default 0.05) if PARAM is comprised between 0 and 1, it is
%      the percentage of multiscale residual squares unexplained by the subset
%      of critical scales selected by the MSTEPS procedure.
%      If PARAM is larger than 1, it is assumed to be an integer, which is
%      used directly to set the number of scales in MSTEPS.
%
%   TARGET_TSERIES
%      (string, default 'consensus') which partition to use to extract time series. 
%      Available options:
%          'consensus' : the consensus partition
%          'core' : the stability core of each consensus cluster
%          'adjusted' : the adjusted version of the consensus partition, based 
%              on the average stability with the core
%          'threshold' : same as adjusted, except that a threshold on the minimal 
%              acceptable average stability with the core is set.
%
%   FLAG_ROI
%      (boolean, default false) if the flag is true, the pipeline is only 
%      going to perform the region growing.
%
%   FLAG_IND
%      (boolean, default true) if the flag is true, build the individual stable
%      clusters, stable cores, adjusted clusters as well as associated stability
%      maps.
%
%   FLAG_GROUP
%      (boolean, default true) if the flag is true, perform the group level
%      analysis. This includes the analysis of stability, the generation of
%      group stable clusters, stable cores, adjusted clusters as well as
%      associated stability maps.
%
%   FLAG_MIXED
%      (boolean, default true) if the flag is true, generate the mixed stability maps,
%      which are based on the stable cores of the group-level clusters when evaluated for
%      the individual stability matrices. The adjusted clusters are generated as well.
%
%   FLAG_TSERIES_NETWORK
%      (boolean, default false) If the flag is true, generate some average time series 
%      for all networks and subjects (this will be done at each level, individual, group 
%      or mixed, depending on FLAG_IND, FLAG_MIXED and FLAG_GROUP).
%
%   REGION_GROWING
%      (structure) see the OPT argument of NIAK_PIPELINE_REGION_GROWING. 
%      The default parameters may work.
%
%   STABILITY_TSERIES
%      (structure, with 2 entries) see NIAK_BRICK_STABILITY_TSERIES. The 
%      default parameters may work.
%
%   STABILITY_GROUP
%      (structure, with 2 entries) see NIAK_BRICK_STABILITY_GROUP. The
%      default parameters may work.
%
%   STABILITY_MAPS
%      (structure) the options that will be passed to
%      NIAK_BRICK_STABILITY_MAPS
% 
%   STABILITY_FIGURE
%      (structure) the options that will be passed to
%      NIAK_BRICK_STABILITY_FIGURE
%
%   RAND_SEED
%      (scalar, default 0) The specified value is used to seed the random
%      number generator with PSOM_SET_RAND_SEED for each job. If left empty,
%      the generator is initialized based on the clock (the results will be
%      slightly different due to random variations in bootstrap sampling if
%      the pipeline is executed twice).
%
%   PSOM
%      (structure, optional) the options of the pipeline manager. See the
%      OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%      (boolean, default false) If FLAG_TEST is true, the pipeline will
%      just produce a pipeline structure, and will not actually process
%      the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%      data.
%
%   FLAG_VERBOSE
%      (boolean, default true) Print some advancement infos.
%
% _________________________________________________________________________
% OUTPUTS : 
%
% PIPELINE 
%   (structure) describe all jobs that need to be performed in the 
%   pipeline. This structure is meant to be use in the function
%   PSOM_RUN_PIPELINE.
%
% OPT
%   (structure) same as input, but updated for default values.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
% The steps of the pipeline are the following :
%  
%   1. Masking the brain in functional data
%   2. Performing region growing in each area independently based on fMRI
%      time series concatenated for all subjects.
%   3. Merging all regions of all areas into one mask of regions, along
%      with the corresponding time series for each functional run.
%   4. Individual-level and group-level stability analysis of resting-state
%      flucutations.
%      See NIAK_PIPELINE_STABILITY_MULTI
%
% NOTE 2:
% This pipeline assumes fully preprocessed fMRI data in stereotaxic space
% as inputs. See NIAK_PIPELINE_FMRI_PREPROCESS.
%
% NOTE 3:
% Please refer to the following publications for further details on the 
% method.
%
% Regarding the multi-scale BASC analysis :
% P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benali; A.C. Evans,
% Multi-level bootstrap analysis of stable clusters in resting-State fMRI. 
% Neuroimage 51 (2010), pp. 1126-1139
%
% Regarding the circular block boostrap for fMRI time series : 
% P. Bellec; G. Marrelec; H. Benali, A bootstrap test to investigate
% changes in brain connectivity for functional MRI. Statistica Sinica, 
% special issue on Statistical Challenges and Advances in Brain Science, 
% 2008, 18: 1253-1268. 
%
% Regarding the region-growing algorithm for data dimension reduction :
% P. Bellec; V. Perlbarg; S. Jbabdi; M. Pélégrini-Issac; J.L. Anton; H.
% Benali, Identification of large-scale networks in the brain using fMRI. 
% Neuroimage, 2006, 29: 1231-1243.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%              Centre de recherche de l'institut de Gériatrie de Montréal
%              Département d'informatique et de recherche opérationnelle
%              Université de Montréal, 2010.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, fMRI, clustering, stability

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

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_STABILITY_REST(FILES_IN,OPT).\n Type ''help niak_pipeline_stability_rest'' for more info.')
end

%% Checking that FILES_IN is in the correct format
list_fields   = {'atoms'           , 'data' , 'mask'            , 'areas'           , 'infos'           };
list_defaults = {'gb_niak_omitted' , NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

file_atoms = files_in.atoms;
infos      = files_in.infos;
mask       = files_in.mask;
areas      = files_in.areas;

%% converts the list of fmri runs into a cell
list_subject = fieldnames(files_in.data);
nb_subject = length(list_subject);
[cell_fmri,labels] = niak_fmri2cell(files_in.data);
labels_file = {labels.name};
labels_subject = {labels.subject};
[path_f,name_f,ext_f] = niak_fileparts(cell_fmri{1});
fmri = niak_fmri2struct(cell_fmri,labels);

%% Options
list_fields   = {'flag_tseries_network' , 'target_tseries' , 'folder_out' , 'grid_scales' , 'scales_maps' , 'neigh'       , 'param' , 'flag_mixed' , 'flag_group' , 'flag_ind' , 'flag_tseries' , 'flag_roi' , 'region_growing' , 'stability_tseries' , 'stability_group' , 'stability_maps' , 'stability_figure' , 'rand_seed' , 'psom'   , 'flag_test' , 'flag_verbose' };
list_defaults = {false                  , 'consensus'      , NaN          , []            , []            , [0.7 0.1 1.3] , 0.05    , true         , true         , true       , []             , false      , struct()         , struct()            , struct()          , struct()         , struct()           , 0           , struct() , false       , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
if ~strcmp(opt.folder_out(end),filesep)
    opt.folder_out = [opt.folder_out filesep];
end
opt.psom.path_logs = [opt.folder_out 'logs' filesep];
if isempty(opt.flag_tseries)
    opt.flag_tseries = strcmp(ext_f,'.mat');
end
if isempty(opt.grid_scales)&&~opt.flag_roi
    error('Please specify OPT.GRID_SCALES')
end

%% Region growing 
if strcmp(file_atoms,'gb_niak_omitted')
    clear files_in_tmp files_out_tmp opt_tmp
    files_in_tmp.fmri           = fmri;
    files_in_tmp.areas          = areas;
    files_in_tmp.mask           = mask;
    opt_tmp                     = opt.region_growing;
    opt_tmp.folder_out          = opt.folder_out;
    opt_tmp.flag_test           = 1;
    opt_tmp.flag_tseries        = false;    
    pipeline = niak_pipeline_region_growing(files_in_tmp,opt_tmp);
    file_atoms = pipeline.merge_part.files_out.space;
else % Copy the atoms    
    [path_f,name_f,ext_f] = niak_fileparts(file_atoms);
    pipeline.brain_atoms.command   = 'system([''cp '' files_in '' '' files_out]);';
    pipeline.brain_atoms.files_in  = file_atoms;    
    pipeline.brain_atoms.files_out = [opt.folder_out 'rois' filesep 'brain_atoms' ext_f];
end

%% Extract time series 
files_tseries = cell([nb_subject 1]);
if ~opt.flag_tseries
    for num_e = 1:length(cell_fmri)
        clear files_in_tmp files_out_tmp opt_tmp
        opt_tmp.flag_all = false;
        opt_tmp.flag_std = false;
        opt_tmp.correction.type = 'mean_var';
        name_job = ['tseries_atoms_' labels_file{num_e}];
        files_in_tmp.fmri = cell_fmri(num_e);
        files_in_tmp.mask = file_atoms;
        files_out_tmp.tseries{1} = [opt.folder_out 'rois' filesep 'tseries_rois_' labels_file{num_e} '.mat'];
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_tseries',files_in_tmp,files_out_tmp,opt_tmp,false);
        files_tseries{num_e} = files_out_tmp.tseries{1};        
    end
else
    for num_s = 1:nb_subject
        files_tseries = cell_fmri;
    end
end

%% Run the stability analysis 
if ~opt.flag_roi
    clear files_in_tmp files_out_tmp opt_tmp
    for num_s = 1:nb_subject
        files_in_tmp.data.(list_subject{num_s}) = files_tseries(ismember(labels_subject,list_subject{num_s}));
    end
    files_in_tmp.atoms               = file_atoms;
    files_in_tmp.infos               = infos;
    opt_tmp.folder_out               = opt.folder_out;
    opt_tmp.grid_scales              = opt.grid_scales;
    opt_tmp.scales_maps              = opt.scales_maps;
    opt_tmp.flag_ind                 = opt.flag_ind;
    opt_tmp.flag_group               = opt.flag_group;
    opt_tmp.flag_mixed               = opt.flag_mixed;
    opt_tmp.name_brick_stability_ind = 'niak_brick_stability_tseries';
    opt_tmp.neigh                    = opt.neigh;
    opt_tmp.param                    = opt.param;
    opt_tmp.stability_ind            = opt.stability_tseries;
    opt_tmp.stability_group          = opt.stability_group;
    opt_tmp.stability_maps           = opt.stability_maps;
    opt_tmp.stability_figure         = opt.stability_figure;
    opt_tmp.rand_seed                = opt.rand_seed;
    opt_tmp.flag_test                = true;
    opt_tmp.flag_verbose             = opt.flag_verbose;
    pipeline = psom_merge_pipeline(pipeline,niak_pipeline_stability_multi(files_in_tmp,opt_tmp));
end

%% Build individual time series based on individual clusters
nb_scales = size(opt.scales_maps,1);
partition_name = ['partition_' opt.target_tseries];
if opt.flag_ind&&~opt.flag_roi&&~isempty(opt.scales_maps)&&opt.flag_tseries_network
    for num_s = 1:nb_subject
        clear files_in_tmp files_out_tmp opt_tmp      
        tseries_subject = files_tseries(ismember(labels_subject,list_subject{num_s}));
        file_subject = labels_file(ismember(labels_subject,list_subject{num_s}));
        for num_sc = 1:nb_scales
            files_in_tmp.mask{num_sc} = pipeline.(['stability_maps_ind_' list_subject{num_s}]).files_out.(partition_name){num_sc};
            label_scale = ['sci' num2str(opt.scales_maps(num_sc,1)) '_scf' num2str(opt.scales_maps(num_sc,end))];           
            for num_r = 1:length(tseries_subject)                
                files_out_tmp.tseries{num_r,num_sc} = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'tseries_ind_' opt.target_tseries '_' label_scale '_' file_subject{num_r} '.mat'];
            end
        end
        files_in_tmp.fmri = tseries_subject;
        files_in_tmp.atoms = file_atoms;        
        opt_tmp.flag_all             = false;
        opt_tmp.flag_std             = true;
        opt_tmp.flag_test            = false;
        opt_tmp.correction.type      = 'mean_var';
        opt_tmp.name_tseries         = 'tseries';
        opt_tmp.flag_verbose         = opt.flag_verbose;
        pipeline = psom_add_job(pipeline,['tseries_ind_' list_subject{num_s}],'niak_brick_tseries',files_in_tmp,files_out_tmp,opt_tmp,false);
    end
end

%% Build individual time series based on group clusters
if opt.flag_group&&~opt.flag_roi&&~isempty(opt.scales_maps)&&opt.flag_tseries_network
     for num_s = 1:nb_subject
        clear files_in_tmp files_out_tmp opt_tmp                
        tseries_subject = files_tseries(ismember(labels_subject,list_subject{num_s}));
        file_subject = labels_file(ismember(labels_subject,list_subject{num_s}));        
        for num_sc = 1:nb_scales
            sci = opt.scales_maps(num_sc,1);
            scg = opt.scales_maps(num_sc,2);
            scf = opt.scales_maps(num_sc,3);
            label_scale = ['sci' num2str(sci) '_scg' num2str(scg) '_scf' num2str(scf)];
            files_in_tmp.mask{num_sc} = pipeline.(['stability_maps_group_' label_scale]).files_out.(partition_name){1};
            for num_r = 1:length(tseries_subject)                
                files_out_tmp.tseries{num_r,num_sc}     = [opt.folder_out 'stability_group' filesep label_scale filesep list_subject{num_s} filesep 'tseries_group_' opt.target_tseries '_' label_scale '_' file_subject{num_r} '.mat'];
            end
        end
        files_in_tmp.fmri = tseries_subject;
        files_in_tmp.atoms = file_atoms;        
        opt_tmp.flag_all             = false;
        opt_tmp.flag_std             = true;
        opt_tmp.flag_test            = false;
        opt_tmp.correction.type      = 'mean_var';
        opt_tmp.name_tseries         = 'tseries';
        opt_tmp.flag_verbose         = opt.flag_verbose;
        pipeline = psom_add_job(pipeline,['tseries_group_' list_subject{num_s}],'niak_brick_tseries',files_in_tmp,files_out_tmp,opt_tmp,false);
    end
end

%% Build individual time series based on mixed clusters
if opt.flag_mixed&&~opt.flag_roi&&~isempty(opt.scales_maps)&&opt.flag_tseries_network
     for num_s = 1:nb_subject
        clear files_in_tmp files_out_tmp opt_tmp                
        files_in_tmp.mask = pipeline.(['stability_maps_mixed_' list_subject{num_s}]).files_out.(partition_name);
        tseries_subject = files_tseries(ismember(labels_subject,list_subject{num_s}));
        file_subject = labels_file(ismember(labels_subject,list_subject{num_s}));        
        for num_sc = 1:nb_scales
            sci = opt.scales_maps(num_sc,1);
            scg = opt.scales_maps(num_sc,2);
            scf = opt.scales_maps(num_sc,3);
            label_scale = ['sci' num2str(sci) '_scg' num2str(scg) '_scf' num2str(scf)];            
            for num_r = 1:length(tseries_subject)                     
                files_out_tmp.tseries{num_r,num_sc}     = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'tseries_mixed_' opt.target_tseries '_' label_scale '_' file_subject{num_r} '.mat'];
            end
        end
        files_in_tmp.fmri = tseries_subject;
        files_in_tmp.atoms = file_atoms;        
        opt_tmp.flag_all             = false;
        opt_tmp.flag_std             = true;
        opt_tmp.flag_test            = false;
        opt_tmp.correction.type      = 'mean_var';
        opt_tmp.name_tseries         = 'tseries';
        opt_tmp.flag_verbose         = opt.flag_verbose;
        pipeline = psom_add_job(pipeline,['tseries_mixed_' list_subject{num_s}],'niak_brick_tseries',files_in_tmp,files_out_tmp,opt_tmp,false);
    end
end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
