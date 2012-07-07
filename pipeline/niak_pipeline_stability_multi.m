function [pipeline,opt] = niak_pipeline_stability_multi(files_in,opt)
% Generic multi-level and multi-scale analysis of stable clusters
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_STABILITY_MULTI(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%   (structure) with the following fields :
%
%   DATA
%       (structure) with the following arbitrary fields :
%
%       <SUBJECT>
%           Whatever variable is here will be used as an entry of the
%           stability brick. Please refer to the description of FILES_IN of
%           the selected brick (see OPT.NAME_BRICK_STABILITY below).
%
%   ATOMS
%       (string) a 3D volume defining the space.
%
%   INFOS
%       (string, default 'gb_niak_omitted') the name of a CSV file. 
%       Example :
%                 , SEX , HANDEDNESS
%       <SUBJECT> , 0   , 0 
%       This type of file can be generated with Excel (save under CSV).
%       The infos will be used to "stratify" the data, i.e. resampling of
%       the data will be restricted within groups of subjects that share 
%       identical infos. All strata will be given equal weights to build
%       the consensus across subjects. If omitted, all subjects will belong
%       to the same strata.
%
% OPT
%   (structure) with the following fields :
%
%   FOLDER_OUT
%       (string) where to write the results of the pipeline.
%
%   GRID_SCALES
%       (vector) GRID_SCALES describes the grid of scale parameters that
%       will be investigated. GRID_SCALES(K) is more specifically the number
%       of individual clusters for test number K. Some combinations of scales
%       will be investigated at the individual and group levels. Basically
%       the group scales located in a neighbourhood of each individual scale
%       (see OPT.NEIGH below) will be tested, as well as all possible final
%       number of clusters, whether it be at the individual or the group levels.
%
%   SCALES_MAPS
%       (array, default []) SCALES_MAPS(K,:) is the list of scales that will
%       be used to generate stability maps (individual, group and mixed
%       levels, depending on the flags described below):
%           SCALES_MAPS(K,1) is the number of individual clusters
%           SCALES_MAPS(K,2) is the number of group clusters
%           SCALES_MAPS(K,3) is the number of final clusters
%       Usually the pipeline runs a first time to get the results of the MSTEPS
%       selection, and then the scale parameters selected by MSTEPS are used to
%       set SCALES_MAPS.
%
%   FLAG_IND
%       (boolean, default true) if the flag is true, build the individual stable
%       clusters, stable cores, adjusted clusters as well as associated stability
%       maps.
%
%   FLAG_GROUP
%       (boolean, default true) if the flag is true, perform the group level
%       analysis. This includes the analysis of stability, the generation of
%       group stable clusters, stable cores, adjusted clusters as well as
%       associated stability maps.
%
%   FLAG_MIXED
%       (boolean, default true) if the flag is true, generate the mixed stability maps,
%       which are based on the stable cores of the group-level clusters when evaluated for
%       the individual stability matrices. The adjusted clusters are generated as well.
%
%   NAME_BRICK_STABILITY_IND
%       (string) the brick used for the consensus analysis. Available
%       choices :
%           'niak_brick_stability_fir'
%           'niak_brick_stability_tseries'
%           'niak_brick_stability_group'
%
%   NEIGH
%       (vector, default [0.7 0.1 1.3]) defines the local neighbourhood of
%       a number of group clusters to derive local maxima in contrast
%       functions and explore the individual/group scales. More
%       specifically, for each group scale L, all individual scales in
%       ceil(neigh*L) will be tested. A number of clusters L will be
%       defined as local maximum if the associated summary measure of
%       stability is higher or equal than for any other scale in
%       [NEIGH(1)*L NEIGH(end)*L].
%
%   PARAM
%       (scalar, default 0.05) if PARAM is comprised between 0 and 1, it is
%       the percentage of multiscale residual squares unexplained by the subset
%       of critical scales selected by the MSTEPS procedure.
%       If PARAM is larger than 1, it is assumed to be an integer, which is
%       used directly to set the number of scales in MSTEPS.
%
%   STABILITY_IND
%       (structure, with 2 entries) the options that will be passed to the
%       stability brick. Entry 1 will be used for first pass
%       (quick), entry 2 for second pass (slow).
%
%   STABILITY_GROUP
%       (structure, with 2 entries) see NIAK_BRICK_STABILITY_GROUP. The
%       default parameters may work. Entry 1 will be used for first pass
%       (quick), entry 2 for second pass (slow).
%
%   STABILITY_MAPS
%       (structure) the options that will be passed to
%       NIAK_BRICK_STABILITY_MAPS
%
%   STABILITY_FIGURE
%       (structure) the options that will be passed to
%       NIAK_BRICK_STABILITY_FIGURE
%
%   RAND_SEED
%       (scalar, default 0) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED for each job. If left empty,
%       the generator is initialized based on the clock (the results will be
%       slightly different due to random variations in bootstrap sampling if
%       the pipeline is executed twice).
%
%   PSOM
%       (structure, optional) the options of the pipeline manager. See the
%       OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_TEST
%       (boolean, default false) If FLAG_TEST is true, the pipeline will
%       just produce a pipeline structure, and will not actually process
%       the data. Otherwise, PSOM_RUN_PIPELINE will be used to process the
%       data.
%
%   FLAG_VERBOSE
%       (boolean, default true) Print some advancement infos.
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
% SEE ALSO:
% NIAK_BRICK_STABILITY_TSERIES, NIAK_BRICK_STABILITY_FIR,
% NIAK_BRICK_STABILITY_GROUP, NIAK_BRICK_STABILITY_GLM,
% NIAK_BRICK_STABILITY_SUMMARY_IND, NIAK_BRICK_STABILITY_SUMMARY_GROUP,
% NIAK_BRICK_STABILITY_MAPS, NIAK_BRICK_STABILITY_FIGURE
% NIAK_PIPELINE_STABILITY_REST, NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS:
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, fMRI, clustering, stability, multiscale

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_STABILITY_MULTI(FILES_IN,OPT).\n Type ''help niak_pipeline_stability_multi'' for more info.')
end

%% Checking that FILES_IN is in the correct format
list_fields   = {'data' , 'atoms' , 'infos'           };
list_defaults = {NaN    , NaN     , 'gb_niak_omitted' };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

infos = files_in.infos;
list_subject = fieldnames(files_in.data);
nb_subject   = length(list_subject);

cell_tseries = cell([nb_subject 1]);
for num_s = 1:nb_subject
    cell_tseries{num_s} = files_in.data.(list_subject{num_s});
end

[path_f,name_f,ext_f] = niak_fileparts(files_in.atoms);

%% Options
list_fields   = {'param' , 'rand_seed' , 'name_brick_stability_ind' , 'flag_verbose' , 'flag_group' , 'flag_ind' , 'flag_mixed' , 'neigh'       , 'grid_scales' , 'scales_maps' , 'folder_out' , 'psom'   , 'flag_test' , 'stability_ind' , 'stability_group' , 'stability_maps'   , 'stability_figure' };
list_defaults = {0.05    , 0           , NaN                        , true           , true         , true       , true         , [0.7 0.1 1.3] , NaN           , []            , NaN          , struct() , false       , struct()        , struct()          , struct()           , struct()           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
if ~strcmp(opt.folder_out(end),filesep)
    opt.folder_out = [opt.folder_out filesep];
end
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

%% Re-arrange the grid of scales
if (size(opt.grid_scales,1)>1)&&(size(opt.grid_scales,2)>1)
    tab_scale   = opt.grid_scales;
    [list_scales_ind,list_scales_group] = niak_scales2cell(tab_scale);
else
    tab_scale = niak_scales2mat(opt.grid_scales,opt.neigh);
    [list_scales_ind,list_scales_group] = niak_scales2cell(tab_scale);
end
for num_sc = 1:size(opt.scales_maps,1)
    if ~ismember(opt.scales_maps(num_sc,1),list_scales_ind) || ~ismember(opt.scales_maps(num_sc,2),list_scales_group{list_scales_ind==opt.scales_maps(num_sc,1)})
        error('One of the requested set of scale parameters (sci %i scg %i scf %i) does not belong to the explored grid of scales',opt.scales_maps(num_sc,1),opt.scales_maps(num_sc,2),opt.scales_maps(num_sc,3));
    end
end

%% Individual stability analysis
pipeline = struct();
for num_s = 1:nb_subject  
    clear job_in job_out job_opt
    job_in  = cell_tseries{num_s};
    job_out = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep 'stability_ind_' list_subject{num_s} '.mat'];
    job_opt = opt.stability_ind;
    job_opt.rand_seed = opt.rand_seed;
    job_opt.nb_classes = list_scales_ind;    
    if num_s == 1
        pipeline = psom_add_job(pipeline,['stability_ind_' list_subject{num_s}],opt.name_brick_stability_ind,job_in,job_out,job_opt);
    else
        pipeline = psom_add_job(pipeline,['stability_ind_' list_subject{num_s}],opt.name_brick_stability_ind,job_in,job_out,pipeline.(['stability_ind_' list_subject{1}]).opt,false);
    end
end

%% Group-level stability analysis
if opt.flag_group
    for num_c = 1:length(list_scales_ind)
        clear job_in job_out job_opt
        name_scale_ind = num2str(list_scales_ind(num_c));
        for num_s = 1:nb_subject
            job_in.stability.(list_subject{num_s}) = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        end
        job_in.infos = infos;
        job_out      = [opt.folder_out 'stability_group' filesep 'stability_group_sci' name_scale_ind '.mat'];
        job_opt            = opt.stability_group;
        job_opt.rand_seed  = opt.rand_seed;
        job_opt.nb_classes_ind = list_scales_ind(num_c);
        job_opt.nb_classes = list_scales_group{num_c};
        pipeline = psom_add_job(pipeline,['stability_group_sci' name_scale_ind],'niak_brick_stability_group',job_in,job_out,job_opt);
    end
end

%% summary of average individual-level stability
clear job_in job_out job_opt
job_in = cell([nb_subject 1]);
for num_s = 1:nb_subject
    job_in{num_s} = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
end
job_out.sil_all        = [opt.folder_out 'stability_ind' filesep 'summary_stab_avg_ind.mat'];
job_out.figure_sil_max = [opt.folder_out 'stability_ind' filesep 'summary_stab_avg_ind_figure.pdf'];
job_out.table_sil_max  = [opt.folder_out 'stability_ind' filesep 'summary_stab_avg_ind_table.csv'];
job_opt.nb_classes   = list_scales_ind(:);
job_opt.neigh        = opt.neigh;
job_opt.flag_verbose = opt.flag_verbose;
pipeline = psom_add_job(pipeline,'summary_stability_avg_ind','niak_brick_stability_summary_ind',job_in,job_out,job_opt);

%% Summary of group-level stability
if opt.flag_group
    clear job_in job_out job_opt
    job_in = cell([length(list_scales_ind) 1]);
    for num_c = 1:length(list_scales_ind)
        name_scale_ind = num2str(list_scales_ind(num_c));
        job_in{num_c} = pipeline.(['stability_group_sci' name_scale_ind]).files_out;
    end
    job_out.sil_all        = [opt.folder_out 'stability_group' filesep 'summary_stab_group.mat'];
    job_out.figure_sil_max = [opt.folder_out 'stability_group' filesep 'summary_stab_group_figure.pdf'];
    job_out.table_sil_max  = [opt.folder_out 'stability_group' filesep 'summary_stab_group_table.csv'];
    job_opt.neigh            = opt.neigh;
    job_opt.flag_verbose     = opt.flag_verbose;
    pipeline = psom_add_job(pipeline,'summary_stability_group','niak_brick_stability_summary_group',job_in,job_out,job_opt);
end

%% MSTEPS - individual level
for num_s = 1:nb_subject
    clear job_in job_out job_opt
    job_in = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
    job_out.msteps = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep 'msteps_ind_' list_subject{num_s} '.mat'];
    job_out.table = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep 'msteps_ind_' list_subject{num_s} '_table.csv'];    
    job_opt.rand_seed = opt.rand_seed;
    job_opt.neigh        = opt.neigh;
    job_opt.param        = opt.param;
    job_opt.flag_verbose = opt.flag_verbose;
    if num_s == 1
        pipeline = psom_add_job(pipeline,['msteps_ind_' list_subject{1}],'niak_brick_msteps',job_in,job_out,job_opt);
    else
        pipeline = psom_add_job(pipeline,['msteps_ind_' list_subject{num_s}],'niak_brick_msteps',job_in,job_out,pipeline.(['msteps_ind_' list_subject{1}]).opt,false);
    end
end

%% MSTEPS - group level
if opt.flag_group
    clear job_in job_out job_opt
    job_in = cell([length(list_scales_ind) 1]);
    for num_c = 1:length(list_scales_ind)
        name_scale_ind = num2str(list_scales_ind(num_c));
        job_in{num_c} = pipeline.(['stability_group_sci' name_scale_ind]).files_out;
    end
    job_out.msteps = [opt.folder_out 'stability_group' filesep 'msteps_group.mat'];
    job_out.table = [opt.folder_out 'stability_group' filesep 'msteps_group_table.csv'];
    job_opt.rand_seed = opt.rand_seed;
    job_opt.neigh        = opt.neigh;
    job_opt.param        = opt.param;
    job_opt.flag_verbose = opt.flag_verbose;
    pipeline = psom_add_job(pipeline,'msteps_group','niak_brick_msteps',job_in,job_out,job_opt);
end

%% Derive cluster maps, stability maps & figures - individual level
nb_scales = size(opt.scales_maps,1);
if (opt.flag_ind)&&~isempty(opt.scales_maps)
    for num_s = 1:nb_subject
        clear job_in job_out job_opt
        job_in.stability = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        job_in.hierarchy = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        job_in.atoms = files_in.atoms;
        for num_sc = 1:nb_scales
            nb_cluster = opt.scales_maps(num_sc,end);
            label_scale = ['sci' num2str(opt.scales_maps(num_sc,1)) '_scf' num2str(opt.scales_maps(num_sc,end))];
            job_out.partition_consensus{num_sc}  = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_consensus_ind_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_core{num_sc}       = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_core_ind_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_adjusted{num_sc}   = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_adjusted_ind_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_threshold{num_sc}  = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_threshold_ind_' list_subject{num_s} '_' label_scale ext_f];
            job_out.stability_map_all{num_sc}    = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'compound_stability_map_ind_' list_subject{num_s} '_' label_scale ext_f];
            job_out.stability_maps{num_sc}       = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'stability_maps_ind_' list_subject{num_s} '_' label_scale ext_f];
        end
        job_opt = opt.stability_maps;
        job_opt.scales_maps = opt.scales_maps(:,[1 1 size(opt.scales_maps,2)]);
        if num_s == 1
            pipeline = psom_add_job(pipeline,['stability_maps_ind_' list_subject{1}],'niak_brick_stability_maps',job_in,job_out,job_opt);
        else
            pipeline = psom_add_job(pipeline,['stability_maps_ind_' list_subject{num_s}],'niak_brick_stability_maps',job_in,job_out,pipeline.(['stability_maps_ind_' list_subject{1}]).opt,false);
        end
        
        % Figures 
        clear job_in job_out job_opt
        job_in.stability = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        job_in.hierarchy = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        job_opt                = opt.stability_figure;
        job_opt.scales_maps    = opt.scales_maps(:,[1 1 size(opt.scales_maps,2)]);
        for num_sc = 1:nb_scales
            label_scale            = ['sci' num2str(opt.scales_maps(num_sc,1)) '_scf' num2str(opt.scales_maps(num_sc,end))];
            job_out{num_sc}  = [opt.folder_out 'stability_ind' filesep list_subject{num_s} filesep label_scale filesep 'figure_stability_ind_' list_subject{num_s} '_' label_scale '.pdf'];
            job_opt.labels{num_sc} = ['sci' num2str(opt.scales_maps(num_sc,1)) ' scf' num2str(opt.scales_maps(num_sc,end))];
        end
        if num_s == 1
            pipeline = psom_add_job(pipeline,['figure_stability_ind_' list_subject{1}],'niak_brick_stability_figure',job_in,job_out,job_opt);
        else
            pipeline = psom_add_job(pipeline,['figure_stability_ind_' list_subject{num_s}],'niak_brick_stability_figure',job_in,job_out,pipeline.(['figure_stability_ind_' list_subject{1}]).opt,false);
        end
    end
end


%% Derive cluster & stability maps - group level
if opt.flag_group&&~isempty(opt.scales_maps)
    for num_sc = 1:nb_scales
        clear job_in job_out job_opt
        sci = opt.scales_maps(num_sc,1);
        scg = opt.scales_maps(num_sc,2);
        scf = opt.scales_maps(num_sc,3);
        job_in.stability = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
        job_in.hierarchy = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
        job_in.atoms = files_in.atoms;
        label_scale = ['sci' num2str(sci) '_scg' num2str(scg) '_scf' num2str(scf)];
        job_out.partition_consensus{1}  = [opt.folder_out 'stability_group' filesep label_scale filesep 'brain_partition_consensus_group_' label_scale ext_f];
        job_out.partition_core{1}       = [opt.folder_out 'stability_group' filesep label_scale filesep 'brain_partition_core_group_' label_scale ext_f];
        job_out.partition_adjusted{1}   = [opt.folder_out 'stability_group' filesep label_scale filesep 'brain_partition_adjusted_group_' label_scale ext_f];
        job_out.partition_threshold{1}  = [opt.folder_out 'stability_group' filesep label_scale filesep 'brain_partition_threshold_group_' label_scale ext_f];
        job_out.stability_map_all{1}    = [opt.folder_out 'stability_group' filesep label_scale filesep 'compound_stability_map_group_' label_scale ext_f];
        job_out.stability_maps{1}       = [opt.folder_out 'stability_group' filesep label_scale filesep 'stability_maps_group_' label_scale ext_f];
        job_opt = opt.stability_maps;
        job_opt.scales_maps = [scg scg scf];        
        pipeline = psom_add_job(pipeline,['stability_maps_group_' label_scale],'niak_brick_stability_maps',job_in,job_out,job_opt);
        
        % Figures 
        clear job_in job_out job_opt
        job_in.stability = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
        job_in.hierarchy = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
        job_opt                = opt.stability_figure;
        job_opt.scales_maps    = [scg scg scf];        
        job_out{1}  = [opt.folder_out 'stability_group' filesep label_scale filesep 'figure_stability_group_' label_scale '.pdf'];
        job_opt.labels{1} = ['sci' num2str(sci) ' scg' num2str(scg) ' scf' num2str(scf)];        
        pipeline = psom_add_job(pipeline,['figure_stability_group_' label_scale],'niak_brick_stability_figure',job_in,job_out,job_opt);
    end
end

%% Derive cluster & stability maps - mixed level
if opt.flag_mixed&&~isempty(opt.scales_maps)
    for num_s = 1:nb_subject
        clear job_in job_out job_opt
        job_in.stability = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        for num_sc = 1:nb_scales
            sci = opt.scales_maps(num_sc,1);
            scg = opt.scales_maps(num_sc,2);
            scf = opt.scales_maps(num_sc,3);
            job_in.hierarchy{num_sc} = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
            job_in.atoms = files_in.atoms;
            label_scale = ['sci' num2str(sci) '_scg' num2str(scg) '_scf' num2str(scf)];
            job_out.partition_consensus{num_sc}  = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_consensus_mixed_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_core{num_sc}       = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_core_mixed_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_adjusted{num_sc}   = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_adjusted_mixed_' list_subject{num_s} '_' label_scale ext_f];
            job_out.partition_threshold{num_sc}  = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'brain_partition_threshold_mixed_' list_subject{num_s} '_' label_scale ext_f];
            job_out.stability_map_all{num_sc}    = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'compound_stability_map_mixed_' list_subject{num_s} '_' label_scale ext_f];
            job_out.stability_maps{num_sc}       = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'stability_maps_mixed_' list_subject{num_s} '_' label_scale ext_f];
        end
        job_opt = opt.stability_maps;
        job_opt.scales_maps = opt.scales_maps;
        pipeline = psom_add_job(pipeline,['stability_maps_mixed_' list_subject{num_s}],'niak_brick_stability_maps',job_in,job_out,job_opt);
        
        % Figures 
        clear job_in job_out job_opt
        job_in.stability = pipeline.(['stability_ind_' list_subject{num_s}]).files_out;
        job_opt                = opt.stability_figure;
        job_opt.scales_maps    = opt.scales_maps;     
        for num_sc = 1:nb_scales
            sci = opt.scales_maps(num_sc,1);
            scg = opt.scales_maps(num_sc,2);
            scf = opt.scales_maps(num_sc,3);
            label_scale = ['sci' num2str(sci) '_scg' num2str(scg) '_scf' num2str(scf)];
            job_in.hierarchy{num_sc} = pipeline.(['stability_group_sci' num2str(sci)]).files_out;
            job_out{num_sc}  = [opt.folder_out 'stability_mixed' filesep list_subject{num_s} filesep label_scale filesep 'figure_stability_mixed_' list_subject{num_s} '_' label_scale '.pdf'];
            job_opt.labels{num_sc} = ['sci' num2str(sci) ' scg' num2str(scg) ' scf' num2str(scf)];        
        end
        pipeline = psom_add_job(pipeline,['figure_stability_mixed_' list_subject{num_s}],'niak_brick_stability_figure',job_in,job_out,job_opt);
    end
end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
return
