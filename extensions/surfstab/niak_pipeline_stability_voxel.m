function [pipeline,opt] = niak_pipeline_stability_voxel(files_in,opt)
% Multi-level, multi-scale analysis of stable clusters in resting-state fMRI
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_STABILITY_VOXEL(FILES_IN,OPT)
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
%   PART
%       (cell of strings, default empty) the target partitions for each 
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
% OPT
%   (structure) with the following fields :
%
%   FOLDER_OUT
%      (string) where to write the results of the pipeline. 
%
%   SCALE
%       (integer, default same as IN.PART, otherwise 
%       floor(logspace(1,3,10)) ) the target scale (i.e. number of final 
%       clusters). If you specify a partition in FILES_IN.PART, any value
%       in OPT.SCALE will be ignored. This means that if your partition in
%       FILES_IN.PART does not contain a dedicated scale variable, the
%       scale of the stochastic clusters for the vertex level stability
%       estimation will be equal to the scale of your partitions. See
%       NIAK_BRICK_STABILITY_SURF for details.
%
%   REGION_GROWING
%       (structure, optional) the options of NIAK_REGION_GROWING.
%
%   SAMPLING
%       (structure) Selects the sampling strategy for the atom and vertex
%       level. See NIAK_PIPELINE_STABILITY_SURF for defaults.
%
%   STABILITY_ATOM
%       (structure, optional) the options for
%       niak_pipeline_stability_estimate. See NIAK_PIPELINE_STABILITY_SURF
%       for defaults.
%
%   CONSENSUS
%       (structure, optional) See NIAK_PIPELINE_STABILITY_SURF for defaults
%
%   STABILITY_VERTEX
%       (structure, optional) the options for the stability replication
%       using niak_brick_stability_surf. See NIAK_PIPELINE_STABILITY_SURF
%       for default values
%
%   TARGET_TYPE
%       (string, default 'cons') specifies the type of the target
%       clustering. Possible values are:
%
%           'cons'   : Consensus clustering based on the estimated stability
%                      of the data in IN.DATA. The scale space for the consensus
%                      clusters will be taken from OPT.SCALE
%           'plugin' : Plugin clustering based on a single pass of
%                      hierarchical clustering on the data in IN.DATA. The
%                      scale space for the plugin clustering will be taken
%                      from OPT.SCALE
%           'manual' : The target cluster will be supplied by the user. If
%                      this option is selected by the user, an appropriate
%                      target partition must be supplied in IN.PART.
%                      Alternatively, if IN.PART contains a file path,
%                      OPT.TARGET_TYPE will automatically be set to MANUAL.
%
%   PSOM
%       (structure, optional) the options of the pipeline manager. See the
%       OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%       MAX_QUEUED
%           (integer, default 2) Determines how many jobs are submitted at
%           the same time. 
%
%   FLAG_CORES
%       (boolean, default true) If this is set, we use the stable clusters
%       of the consensus partition.
%
%   FLAG_RAND
%       (boolean, default false) if the flag is true, the random number 
%       generator is initialized based on the clock. Otherwise, the seeds of 
%       the random number generator are set to fix values, and the pipeline is 
%       fully reproducible. 
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
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_STABILITY_VOXEL(FILES_IN,OPT).\n Type ''help niak_pipeline_stability_voxel'' for more info.')
end

% IN
list_fields   = { 'data' , 'mask'            , 'part'            , 'areas'           , 'infos'           };
list_defaults = { NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

% OPT
list_fields     = { 'folder_out' , 'scale' , 'region_growing' , 'sampling' , 'stability_atom' , 'consensus' , 'cores'  , 'stability_vertex' , 'target_type' , 'psom' , 'flag_cores' , 'flag_rand' , 'flag_test' , 'flag_verbose' };
list_defaults   = { NaN          , NaN     , struct()         , struct()   , struct()         , struct()    , struct() , struct()           , 'cons'        , struct , false        , true        , false       , true           };
opt = psom_struct_defaults(opt, list_fields, list_defaults);
opt.folder_out = niak_full_path(opt.folder_out);

% Setup PSOM defaults
opt.psom = psom_struct_defaults(opt.psom,...
           { 'max_queued' , 'logs'                  },...
           { 2            , [opt.folder_out 'logs'] });
       
% Set the values for the tseries extraction
opt.tseries = psom_struct_defaults(struct(),...
           { 'flag_all' , 'flag_std' },...
           { true       , false      });
opt.tseries.correction.type = 'mean_var';

% Set the values for the tseries extraction
opt.pipeline = rmfield(opt, {'folder_out', 'psom', 'flag_test', 'flag_verbose', 'tseries'});
opt.pipeline.name_data = 'tseries_1';
opt.pipeline.name_neigh = 'neig';
opt.pipeline.psom.flag_pause = false;
opt.pipeline.flag_test = true;

% Flag for partition
is_part = 0;

%% converts the list of fmri runs into a cell
list_subject = fieldnames(files_in.data);
nb_subject = length(list_subject);
% Turn the input structure into a cell array 
[cell_fmri,labels] = niak_fmri2cell(files_in.data);
labels_file = {labels.name};
labels_subject = {labels.subject};

opt.folder_out      = niak_full_path(opt.folder_out);
opt.psom.path_logs  = niak_full_path([opt.folder_out 'logs']);

% Check mask
if strcmp(files_in.areas, 'gb_niak_omitted')
    niak_gb_vars;
    files_in.areas = [gb_niak_path_template 'roi_aal_3mm.mnc.gz'];
end

if strcmp(files_in.mask, 'gb_niak_omitted')
    files_in.mask = files_in.areas;
end

%% Begin building pipeline
pipeline = struct;
% Get the neighbourhood from the mask
neigh_in = files_in.mask;
neigh_out = [opt.folder_out 'neighbourhood.mat'];
neigh_opt = struct;
pipeline = psom_add_job(pipeline, 'neighbour', 'niak_brick_neighbour',...
                        neigh_in, neigh_out, neigh_opt);

% If target partition(s) are supplied, load them and store them in a mat
% file - unless they are already in a mat file
if ~strcmp(files_in.part, 'gb_niak_omitted')
    is_part = 1;
    % Take the first partition and check the file extenstion
    if ischar(files_in.part)
        [~, ~, ext_part] = niak_fileparts(files_in.part);
    elseif iscell(files_in.part)
        [~, ~, ext_part] = niak_fileparts(files_in.part{1});
    else
        error('I don''t know what to make of the input in files_in.part.\n');
    end
    if ~strcmp(ext_part, '.mat');
        is_part = 2;
        part_in.part = files_in.part;
        part_in.mask = files_in.mask;
        part_out = [opt.folder_out 'target_partition.mat'];
        part_opt = struct;
        pipeline = psom_add_job(pipeline, 'target_part',...
                                'niak_brick_read_part', part_in, part_out,...
                                part_opt);
    end
end

% Get the timeseries - Prepare time series storage
files_tseries = cell([nb_subject 1]);

for num_e = 1:length(cell_fmri)
    name_job = ['tseries_atoms_' labels_file{num_e}];
    files_in_tseries.fmri = cell_fmri(num_e);
    files_in_tseries.mask = files_in.mask;
    files_out_tseries.tseries{1} = [opt.folder_out 'tseries' filesep 'tseries_rois_' labels_file{num_e} '.mat'];
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_tseries', files_in_tseries, files_out_tseries, opt.tseries, false);
    files_tseries{num_e} = pipeline.(name_job).files_out;

end

%% New things
% Get the file for the correct subject in order to run the pipeline -
% currently, multiple files are not implemented and we have to deal with
% them somehow
for num_s = 1:nb_subject
    % This is a temporary workaround until I have implemented some way to
    % deal with more than one run per subject
    sub_name = list_subject{num_s};
    sub_data = files_tseries(ismember(labels_subject,sub_name));
    sub_dir = niak_full_path([opt.folder_out sub_name]);
    if length(sub_data) > 1
        warning(['There are more than one timeseries for subject %s.' ...
                 'I''ll use only the first one!\n'], list_subject{num_s});
    end
    
    in.data = sub_data{1}.tseries{1};
    in.neigh = pipeline.neighbour.files_out;
    % Check if a partition has been generated
    if is_part
        if is_part == 1
            in.part = files_in.part;
        elseif is_part == 2
            in.part = pipeline.target_part.files_out;
        end
    end
    
    % Set up pipeline parameters
    opt.pipeline.folder_out = sub_dir;
    % Generate the pipeline
    pipeline = psom_merge_pipeline(pipeline,...
                                   niak_pipeline_stability_surf(in,...
                                   opt.pipeline), ['sub_' sub_name '_']);

end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
