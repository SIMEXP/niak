function [pipeline, opt] = niak_pipeline_subtype(files_in, opt)
% Estimation of stable cores
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_SUBTYE(FILES_IN,OPT)
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
%       
%
% OPT
%   (structure, optional) with the following fields:
%
%   FLAG_TEST 
%       (boolean, default false) if the flag is true, the brick does not do anything
%       but update FILES_IN, FILES_OUT and OPT.

% FILES IN DEFAULTS
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Griatrie de Montral
%   Dpartement d'informatique et de recherche oprationnelle
%   Universit de Montral, 2010-2016
%   Montreal Neurological Institute, 2016
% Maintainer : sebastian.urchs@mail.mcgill.ca
%
% See licensing information in the code.
% Keywords : subtype, clustering

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
% Check if all inputs are provided as required
if ~exist('files_in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_SUBTYE(IN,OPT).\n Type ''help niak_pipeline_subtype'' for more info.');
end

% Files in
files_in = psom_struct_defaults(files_in, ...
           { 'data' , 'part' , 'mask' }, ...
           { NaN    , NaN    , NaN    });
% Options
opt = psom_struct_defaults(opt,...
      { 'flag_rand' , 'folder_out'      , 'files_out' , 'scores' , 'psom' , 'flag_test' },...
      { false       , 'gb_niak_omitted' , struct      , struct   , struct , false       });
opt.folder_out = niak_full_path(opt.folder_out);
  
opt.psom = psom_struct_defaults(opt.psom,...
           { 'max_queued' , 'path_logs'             },...
           { 2            , [opt.folder_out filesep 'logs'] });

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

%% Preprocessing
% Load the input data for each network and regress confounds
clear job_in job_out job_opt







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