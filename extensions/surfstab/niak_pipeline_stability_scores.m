function [pipeline, opt] = niak_pipeline_stability_scores(files_in, opt)
% Pseudocode of the pipeline:
% Load the files
%   Pull in a structure of fmri files where each field is a subject and
%   either contains a string or a cell of strings
% Check the options
%   - OPT is prety much a forward, no changes there
%   - Decide which files should be saved? Needs a separate thingy that is
%     either empty to save all or a structure to save only specific stuff.
%     Each file needs to be defined here with the default being yes.
%   - Maybe a folder that we want to store everything in
%
% OPT.FLAG_VERBOSE (boolean, default true) turn on/off the verbose.
% OPT.FLAG_TARGET (boolean, default false)
%       If FILES_IN.PART has a second column, then this column is used as a binary mask to define 
%       a "target": clusters are defined based on the similarity of the connectivity profile 
%       in the target regions, rather than the similarity of time series.
%       If FILES_IN.PART has a third column, this is used as a parcellation to reduce the space 
%       before computing connectivity maps, which are then used to generate seed-based 
%       correlation maps (at full available resolution).
% OPT.FLAG_FOCUS (boolean, default false)
%       If FILES_IN.PART has a two additional columns (three in total) then the
%       second column is treated as a binary mask of an ROI that should be
%       clustered and the third column is treated as a binary mask of a
%       reference region. The ROI will be clustered based on the similarity
%       of its connectivity profile with the prior partition in column 1 to
%       the connectivity profile of the reference.
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does not do anything
%      but update FILES_IN, FILES_OUT and OPT.

% FILES IN DEFAULTS
files_in = psom_struct_defaults(files_in, ...
           { 'fmri' , 'part' }, ...
           { NaN    , NaN    });
% DEFAULTS
opt = psom_struct_defaults(opt,...
      { 'folder_out'      , 'files_out' , 'scores' , 'psom' , 'flag_test' },...
      { 'gb_niak_omitted' , struct      , struct   , struct , false       });
  
opt.psom = psom_struct_defaults(opt.psom,...
           { 'max_queued' , 'path_logs'             },...
           { 2            , [opt.folder_out filesep 'logs'] });

opt.files_out = psom_struct_defaults(opt.files_out,...
                { 'stability_maps' , 'partition_cores' , 'stability_intra' , 'stability_inter' , 'stability_contrast' , 'partition_thresh' , 'extra' , 'rmap_part', 'rmap_cores', 'dual_regression' },...
                { true             , true              , true              , true              , true                 , true               , true    , true       , true        , true              });

opt.scores = psom_struct_defaults(opt.scores, ...
             { 'type_center' , 'nb_iter' , 'folder_out' , 'thresh' , 'rand_seed' , 'nb_samps' , 'sampling' , 'flag_focus' , 'flag_target' , 'flag_verbose' , 'flag_test' } , ...
             { 'median'      , 1         , ''           ,  0.5      , []          , 100        , struct()  , false        , false         , true           , false       });

opt.scores.sampling = psom_struct_defaults(opt.scores.sampling, ...
                      { 'type' , 'opt'    }, ...
                      { 'CBB'  , struct() });
         
%% Sanity checks
files_out_set = false;
o_names = fieldnames(opt.files_out);
for o_id = 1:length(o_names)
    o_name = o_names{o_id};
    if opt.files_out.(o_name) && ~ischar(opt.files_out.(o_name))
        files_out_set = true;
    end
end

if strcmp('gb_niak_omitted' , opt.folder_out) && files_out_set
    error(['Please specify either OPT.FOLDER_OUT, set unwanted files to '...
           '''false'' or specify their output path individually']);
end

%% Begin the pipeline
pipeline = struct;

% Find out how many jobs we have to run
j_names = fieldnames(files_in.fmri);
j_number = length(j_names);
% Run the jobs
for j_id = 1:j_number
    % Get the name of the subject
    s_name = j_names{j_id};
    j_name = sprintf('job_of_%s', s_name);
    s_in.fmri = files_in.fmri.(s_name);
    if ischar(s_in.fmri)
        [~,~,ext] = niak_fileparts(s_in.fmri);
    else
        [~,~,ext] = niak_fileparts(s_in.fmri{1});
    end
    s_in.part = files_in.part;
    s_out = struct;
    % Set the paths for the requested output files
    for out_id = 1:length(o_names)
        out_name = o_names{out_id};
        if opt.files_out.(out_name) && ~ischar(opt.files_out.(out_name))
            s_out.(out_name) = [opt.folder_out filesep out_name filesep sprintf('%s_%s%s',s_name, out_name, ext)];
        elseif ~opt.files_out.(out_name)
            s_out.(out_name) = 'gb_niak_omitted';
            continue
        elseif ischar(opt.files_out.(out_name))
            s_out.(out_name) = [opt.files_out.(out_name) filesep sprintf('%s_%s%s',s_name, out_name, ext)];
        end
        if ~isdir(s_out.(out_name))
                psom_mkdir(s_out.(out_name));
        end
    end
    s_opt = opt.scores;
    pipeline = psom_add_job(pipeline, j_name, 'niak_brick_scores_fmri',...
                            s_in, s_out, s_opt);
end

%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline, opt.psom);
end