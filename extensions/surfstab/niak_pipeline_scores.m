function [pipeline, opt] = niak_pipeline_scores(files_in, opt)
% Estimation of stable cores
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_SCORES(FILES_IN,OPT)
% ______________________________________________________________________________
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
%   MASK
%       (string) path to a 3D volume that contains non-zero values at all voxels
%       that are to be included in the scores analysis. 
%       IMPORTANT: if FILES_IN.MASK covers different voxels than FILES_IN.PART
%                  then the pipeline is going to use the union of the two
%
%   PART
%       (string) path to a 3D volume that contains non-zero integer values between
%       1 and M where M is the maximum value of the volume. The values are 
%       interpreted as partition labels such that the nonzero value P(i) indicates
%       that voxel i is a member of partition P. 
%       The pipeline expects the values to be continuous between 1 and N where N is
%       the number of partitions (unique values) in the volume. If the values are 
%       not continuous or don't start at 1, they will be remapped to 1 to N and 
%       the correspondence of values in FILES_IN.PART to the partitions in the 
%       output is specified in part_order/part_order.csv
%
% OPT
%   (structure, optional) with the following fields:
%
%   FILES_OUT
%       STABILITY_MAPS
%           (boolean, default true) creates a 4D volume, where 
%           the k-th volume is the stability map of the k-th cluster.
%       PARTITION_CORES
%           (boolean, default true) creates a 3D volume where the 
%           k-th cluster based on stable cores is filled with k's.
%       STABILITY_INTRA
%           (boolean, default true) creates a 3D volume where each 
%           voxel is filled with the stability in its own cluster.
%       STABILITY_INTRA
%           (boolean, default true) creates a 3D volume where each 
%           voxel is filled with the stability with the closest cluster
%           outside of its own.
%       STABILITY_CONTRAST
%           (boolean, default true) creates a 4D volume containing
%           the difference between the intra- and inter- cluster stability.
%       PARTITION_THRESH
%           (boolean, default true) creates a 3D volume containing the
%           FILES_OUT.PARTITION_CORES but thresholded by stability
%       RMAP_PART
%           (boolean, default true) creates a 4D volume containing the
%           correlation maps using the partition FILES_IN.PART as seeds.
%       RMAP_CORES
%           (boolean, default true) creates a 4D volume containing the 
%           correlation maps using the partition FILES_OUT.PARTITION_CORES 
%           as seeds.
%       DUAL_REGRESSION
%           (boolean, default true) creates a 4D volume containing the
%           "dual regression" maps using FILES_IN.PART as seeds.
%       EXTRA
%           (boolean, default true)
%
%   FLAG_RAND 
%       (boolean, default false) if the flag is false, the pipeline is 
%       deterministic. Otherwise, the random number generator is initialized
%       based on the clock for each job.
%
%   FLAG_VERBOSE 
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TARGET 
%       (boolean, default false) If FILES_IN.PART has a second column, 
%       then this column is used as a binary mask to define a "target": 
%       clusters are defined based on the similarity of the connectivity profile 
%       in the target regions, rather than the similarity of time series.
%       If FILES_IN.PART has a third column, this is used as a parcellation to reduce the space 
%       before computing connectivity maps, which are then used to generate seed-based 
%       correlation maps (at full available resolution).
%
%   FLAG_DEAL
%       (boolean, default false)
%       If the partition supplied by the user does not have the appropriate
%       number of columns, this flag can force the brick to duplicate the
%       first column. This may be useful if you want to use the same mask
%       for the OPT.FLAG_TARGET flag as you use in the cluster partition.
%       Use with care.
%
%   FLAG_FOCUS 
%       (boolean, default false) If FILES_IN.PART has a two additional 
%       columns (three in total) then the second column is treated as a 
%       binary mask of an ROI that should be clustered and the third column 
%       is treated as a binary mask of a reference region. The ROI will be 
%       clustered based on the similarity of its connectivity profile with the 
%       prior partition in column 1 to the connectivity profile of the reference.
%
%   FLAG_TEST 
%       (boolean, default false) if the flag is true, the brick does not do anything
%       but update FILES_IN, FILES_OUT and OPT.

% FILES IN DEFAULTS
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2015
%   Montreal Neurological Institute, 2015
% Maintainer : sebastian.urchs@mail.mcgill.ca
%
% See licensing information in the code.
% Keywords : clustering, stability analysis, 
%            bootstrap, jacknife, scores.

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
% ______________________________________________________________________________

%% Seting up default arguments
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_SCORES(IN,OPT).\n Type ''help niak_pipeline_scores'' for more info.');
end

files_in = psom_struct_defaults(files_in, ...
           { 'data' , 'part' , 'mask' }, ...
           { NaN    , NaN    , NaN    });
% DEFAULTS
opt = psom_struct_defaults(opt,...
      { 'flag_rand' , 'folder_out'      , 'files_out' , 'scores' , 'psom' , 'flag_test' },...
      { false       , 'gb_niak_omitted' , struct      , struct   , struct , false       });
  
opt.psom = psom_struct_defaults(opt.psom,...
           { 'max_queued' , 'path_logs'             },...
           { 2            , [opt.folder_out filesep 'logs'] });

opt.files_out = psom_struct_defaults(opt.files_out,...
                { 'stability_maps' , 'partition_cores' , 'stability_intra' , 'stability_inter' , 'stability_contrast' , 'partition_thresh' , 'rmap_part', 'rmap_cores', 'dual_regression' , 'extra' , 'part_order' },...
                { true             , true              , true              , true              , true                 , true               , true       , true        , true              , true    , true         });

opt.scores = psom_struct_defaults(opt.scores, ...
             { 'type_center' , 'nb_iter' , 'folder_out' , 'thresh' , 'rand_seed' , 'nb_samps' , 'sampling' , 'flag_focus' , 'flag_target' , 'flag_deal' , 'flag_verbose' , 'flag_test' } , ...
             { 'median'      , 1         , ''           ,  0.5      , []          , 100        , struct()  , false        , false         , false       , true           , false       });

opt.scores.sampling = psom_struct_defaults(opt.scores.sampling, ...
                      { 'type' , 'opt'    }, ...
                      { 'CBB'  , struct() });

%% Turn the input structure into a cell array that will be used in the rest of
% the pipeline
list_subject = fieldnames(files_in.data);
% Get the number of subjects
nb_subject = length(list_subject);
[cell_fmri,labels] = niak_fmri2cell(files_in.data);
% Find out how many jobs we have to run
j_names = {labels.name};
j_number = length(j_names);
labels_subject = {labels.subject};
[path_f,name_f,ext] = niak_fileparts(cell_fmri{1});
fmri = niak_fmri2struct(cell_fmri,labels);

%% Sanity checks
files_out_set = false;
o_names = fieldnames(opt.files_out);
for o_id = 1:length(o_names)
    o_name = o_names{o_id};
    if opt.files_out.(o_name) && ~ischar(opt.files_out.(o_name))
        files_out_set = true;
    end
end

if opt.scores.flag_deal
    warning('OPT.SCORES.FLAG_DEAL is set to true. Check your partition to make sure it does what you expect.');
end

if strcmp('gb_niak_omitted' , opt.folder_out) && files_out_set
    error(['Please specify either OPT.FOLDER_OUT, set unwanted files to '...
           '''false'' or specify their output path individually']);
end

%% Begin the pipeline
pipeline = struct;

% Resample the mask and the template partition
% We need to resample the partition
clear job_in job_out job_opt
job_in.source      = files_in.part;
[path_f,name_f,ext_f] = niak_fileparts(files_in.part);
job_in.target      = cell_fmri{1};
job_out            = [opt.folder_out 'template_partition' ext_f];
job_opt.interpolation    = 'nearest_neighbour';
pipeline = psom_add_job(pipeline,'scores_resample_part','niak_brick_resample_vol',job_in,job_out,job_opt);

clear job_in job_out job_opt
job_in.source      = files_in.mask;
[path_f,name_f,ext_f] = niak_fileparts(files_in.mask);
job_in.target      = cell_fmri{1};
job_out            = [opt.folder_out 'mask' ext_f];
job_opt.interpolation    = 'nearest_neighbour';
pipeline = psom_add_job(pipeline,'scores_resample_mask','niak_brick_resample_vol',job_in,job_out,job_opt);

% Run the jobs
for j_id = 1:j_number
    % Get the name of the subject
    s_name = j_names{j_id};
    j_name = sprintf('scores_%s', j_names{j_id});
    s_in.fmri = cell_fmri(j_id);
    s_in.part = pipeline.scores_resample_part.files_out;
    s_in.mask = pipeline.scores_resample_mask.files_out;
    s_out = struct;
    % Set the paths for the requested output files
    for out_id = 1:length(o_names)
        out_name = o_names{out_id};
        if opt.files_out.(out_name) && ~ischar(opt.files_out.(out_name))
            if strcmp(out_name, 'extra')
                s_out.(out_name) = [opt.folder_out filesep out_name filesep sprintf('%s_%s.mat',s_name, out_name)];
            elseif strcmp(out_name, 'part_order')
                s_out.(out_name) = [opt.folder_out filesep out_name filesep sprintf('%s_%s.csv',s_name, out_name)];
            else
                s_out.(out_name) = [opt.folder_out filesep out_name filesep sprintf('%s_%s%s',s_name, out_name, ext)];
            end 
        elseif ~opt.files_out.(out_name)
            s_out.(out_name) = 'gb_niak_omitted';
            continue
        elseif ischar(opt.files_out.(out_name))
            error('OPT.FILES_OUT can only have boolean values but not %s',class(opt.files_out.(out_name)));
        end
        if ~isdir([opt.folder_out filesep out_name])
                psom_mkdir([opt.folder_out filesep out_name]);
        end
    end
    s_opt = opt.scores;
    if ~opt.flag_rand
        s_opt.rand_seed = j_names{j_id};
    end
    pipeline = psom_add_job(pipeline, j_name, 'niak_brick_scores_fmri',...
                            s_in, s_out, s_opt);
end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline, opt.psom);
end