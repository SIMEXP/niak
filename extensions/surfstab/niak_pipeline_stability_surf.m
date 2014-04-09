function [pipe,opt] = niak_pipeline_stability_surf(in,opt)
% Estimation of surface space cluster stability
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_STABILITY_SURF(IN,OPT)
% ______________________________________________________________________________
%
% INPUTS:
%
% IN.DATA
%   (string) full path to the structure containing the case by vertex value
%   matrix of surface measures (i.e. cortical thickness). The values must be
%   kept in a field with the name OPT.NAME_DATA
%   
% IN.PART
%   (string, optional, default 'gb_niak_omitted') path to .mat file that
%   contains a matrix of VxK where V is the number of verteces on the
%   surface and K is the number of scales to be computed.
%
% IN.NEIGH
%   (string, optional, default 'gb_niak_omitted') path to .mat file, with a 
%   variable called OPT.NAME_NEIGH. This is a VxW matrix, where each the 
%   v-th row is the list of neighbours of vertex v (potentially paded with 
%   zeros). If unspecified, the neighbourhood matrix is generated for the 
%   standard MNI surface with ~80k vertices.
%
% OPT
%   (structure, optional) with the following fields:
%
%   NAME_DATA
%       (string, default 'data') the name of the fieldname in IN.DATA that 
%       contains the data.
%
%   NAME_PART
%       (string, default 'part') the name of the fieldname in IN.PART that
%       contains the partition if one is provided.
%
%   NAME_NEIGH
%       (string, default 'neigh') if IN.NEIGH is specified, the name 
%       of the variable coding for the neighbour matrix.
%
%   SCALE
%       (integer, default same as IN.PART, otherwise 
%       floor(logspace(1,3,10)) ) the target scale (i.e. number of final 
%       clusters). If you specify a partition in IN.PART, any value
%       in OPT.SCALE will be ignored. This means that if your partition in
%       IN.PART does not contain a dedicated scale variable, the
%       scale of the stochastic clusters for the vertex level stability
%       estimation will be equal to the scale of your partitions. See
%       NIAK_BRICK_STABILITY_SURF for details.
%
%   FOLDER_OUT
%       (string, must be set) where to write the default outputs.
%
%   SAMPLING
%       (structure)
%
%       TYPE
%           (string, default 'bootstrap') how to resample the time series.
%           Available options : 'bootstrap' , 'jacknife'
%
%       OPT
%           (structure) the options of the sampling. Depends on
%           OPT.SAMPLING.TYPE :
%               bootstrap : None.
%               jacknife  : OPT.PERC is the percentage of observations
%                           retained in each sample (default 60%)
%
%   REGION_GROWING
%       (structure, optional) the options of NIAK_REGION_GROWING. The most
%       useful parameter is:
%
%       THRE_SIZE
%           (integer,default 80) threshold on the maximum region size
%           before merging (measured in number of vertices).
%
%   STABILITY_ATOM
%       (structure, optional) the options for niak_pipeline_stability_estimate
%
%       NB_SAMPS
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%       NB_BATCH
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability matrices.
%
%       SAMPLING
%           (structure, default OPT.SAMPLING)
%
%           TYPE
%               (string, default 'bootstrap') how to resample the time series.
%               Available options : 'bootstrap' , 'jacknife'
%
%           OPT
%               (structure, optional) the options of the sampling. Depends 
%               on OPT.SAMPLING.TYPE:
%                   bootstrap : None.
%                   jacknife  : OPT.PERC is the percentage of observations
%                               retained in each sample (default 60%)
%
%   CONSENSUS
%       (structure, optional) with the following fields
%
%       SCALE_TARGET
%           (vector, default []) The range of the scales for the target
%           clusters L. If this vector is not empty, then optimal
%           stochastic clusters K will be determined for each L during the
%           consensus clustering brick (See 'help
%           niak_brick_stability_consensus'). Additionally
%
%       RAND_SEED
%           (scalar, default 2) The specified value is used to seed the random
%           number generator with PSOM_SET_RAND_SEED. If left empty, no action
%           is taken.
%
%   MSTEPS
%       (structure, optional) with the following fields
%
%       PARAM
%           (scalar, default 0.05) if PARAM is comprised between 0 and 1, it is
%           the percentage of residual squares unexplained by the model.
%           If PARAM is larger than 1, it is assumed to be an integer, which is 
%           used directly to set the number of components of the model.
%
%       NEIGH
%           (vector, default [0.7 1.3]) defines the local neighbourhood of
%           a number of clusters. If NEIGH has more than two elements, the
%           first and last element will be used to define the neighbourhood.
%
%   CORES
%       (structure, optional) with the following fields
%
%       TYPE
%           (string, default 'kmeans') defines the method used to generate
%           stable clusters. 
%           Avalable options: 'highpass', 'kmeans'
%
%       OPT
%           (structure, optional) the options of the stable cluster method.
%           Depends on OPT.CORES.TYPE.
%           
%           highpass : THRE (scalar, default 0.5) THRE constitutes the 
%                           high-pass percentage cutoff for stability
%                           values (range 0 - 1)
%                      CONF (scalar, default 0.05) defines the confidence 
%                           interval with respect to the stability
%                           threshold in percent (range 0 - 1)
%                           
%           kmeans   : None
%
%   STABILITY_VERTEX
%       (structure, optional) the options for the stability replication
%       using niak_brick_stability_surf.
%
%       NB_SAMPS
%           (integer, default 10) the number of replications per batch. The 
%           final effective number of bootstrap samples is NB_SAMPS x NB_BATCH 
%           (see below).
%
%       NB_BATCH
%           (integer, default 100) how many random initializations will be
%           run and subsequently averaged to generate the stability maps.
%
%   PSOM
%       (structure) the options of the pipeline manager. See the OPT 
%       argument of PSOM_RUN_PIPELINE. Default values can be used here.
%       Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   TYPE_TARGET
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
%                      OPT.TYPE_TARGET will automatically be set to MANUAL.
%
%   FLAG_CONS
%       (boolean, default true) If this is false, we use plugin clustering,
%       provided no partition is supplied
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
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do
%       anything but updating the values of IN, OUT and OPT. 
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
%
% See licensing information in the code.
% Keywords : clustering, surface analysis, cortical thickness, stability
%            analysis, bootstrap, jacknife.

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
if ~exist('in','var')||~exist('opt','var')
    error('niak:pipeline','syntax: [IN,OPT] = NIAK_PIPELINE_STABILITY_SURF(IN,OPT).\n Type ''help niak_pipeline_stability_surf'' for more info.')
end

% IN
list_fields   = { 'data' , 'part'            , 'neigh'           };
list_defaults = { NaN    , 'gb_niak_omitted' , 'gb_niak_omitted' };
in = psom_struct_defaults(in,list_fields,list_defaults);

% OPT
list_fields     = { 'name_data' , 'name_part' , 'name_neigh' , 'scale'                  ,  'folder_out' , 'sampling' , 'region_growing' , 'stability_atom' , 'consensus' , 'msteps' , 'cores'  , 'stability_vertex' , 'psom'   , 'type_target' , 'flag_cores' , 'flag_rand' , 'flag_verbose' , 'flag_test' };
list_defaults   = { 'data'      , 'part'      , 'neigh'      , floor(logspace(1,3,10))' ,  NaN          , struct()   , struct()         , struct()         , struct()    , struct() , struct() , struct()           , struct() , 'manual'      , false        , false       , true           , false       };
opt = psom_struct_defaults(opt, list_fields, list_defaults);
opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs'];

% Setup Region Growing Thresholds
opt.region_growing.region_growing = psom_struct_defaults(opt.region_growing,...
                                    { 'thre_size' },...
                                    { 80          });

% Setup Sampling Defaults
opt.sampling = psom_struct_defaults(opt.sampling,...
               { 'type'     , 'opt'    },...
               { 'jacknife' , struct() });

% Setup Stability Atom Defaults
opt.stability_atom = psom_struct_defaults(opt.stability_atom,...
                     { 'nb_samps' , 'nb_batch' , 'sampling'   },...
                     { 100        , 100        , opt.sampling });
opt.stability_atom.estimation = rmfield(opt.stability_atom, 'sampling');
opt.stability_atom = rmfield(opt.stability_atom, {'nb_samps' , 'nb_batch'});
opt.stability_atom.folder_out = opt.folder_out;
opt.stability_atom.flag_test = true;
opt.stability_atom.estimation.nb_classes = opt.scale;
opt.stability_atom.estimation.name_data = 'data_roi';
opt.stability_atom.average.name_job = 'average_atom';
opt.stability_atom.sampling = opt.sampling;

% Setup Consensus Clustering Defaults
opt.consensus = psom_struct_defaults(opt.consensus,...
                { 'scale_target' , 'rand_seed' },...
                { []             , 2           });
opt.consensus.name_roi = 'part_roi';
opt.consensus.scale = opt.scale;

% Setup Mstep Defaults
opt.msteps = psom_struct_defaults(opt.msteps,...
             { 'param' , 'neigh'   },...
             { 0.05    , [0.7 1.3] });
opt.msteps.name_nb_classes = 'scale';

% Setup Cores Defaults - put them in stacked hierarchy because this is what
% niak_brick_stability_surf_cores expects
opt.cores.cores = psom_struct_defaults(opt.cores,...
                  { 'type'   , 'opt'    },...
                  { 'kmeans' , struct() });

% Setup Stability Vertex Defaults
opt.stability_vertex = psom_struct_defaults(opt.stability_vertex,...
                       { 'nb_samps' , 'nb_batch' },...
                       { 10         , 100        });
opt.stability_vertex.name_data = opt.name_data;
opt.stability_vertex.name_part = opt.name_part;
opt.stability_vertex.name_neigh = opt.name_neigh;
opt.stability_vertex.region_growing = opt.region_growing.region_growing;
opt.stability_vertex.sampling = opt.sampling;

% A number of sanity checks for the configuration
if ~isempty(opt.scale) && ~strcmp(in.part, 'gb_niak_omitted')
    % The user supplied a scale and a partition. Announce that the scale
    % will be discarded
    if ~ischar(in.part)
        error('IN.PART should be a string!');
    end
    warning('You supplied a scale AND a partition file. Please note that the scale you supplied will be overwritten by whatever is in the partition file (%s).\n', in.part);
    opt.scale = [];

elseif isempty(opt.scale) && strcmp(in.part, 'gb_niak_omitted')
    error('You did not supply a scale in opt.scale and you also did not specify a partition in in.part.\n Please supply either a partition or a scale.\n');

end

if ~strcmp(in.part, 'gb_niak_omitted') && ~strcmp(opt.type_target, 'manual')
    % A partition has been supplied, the target type will be forced to
    % manual
    warning('A target partition was supplied by the user. Target cluster type will be forced to manual!\n    old target type: %s\n    target: %s\n', opt.target_type, in.part);
    opt.target_type = 'manual';
    
elseif strcmp(in.part, 'gb_niak_omitted') && strcmp(opt.type_target, 'manual')
    % User does not provide a target partition but wants to use manual mode
    error('A target partition was expected because of OPT.TYPE_TARGET = ''manual'' but none was supplied by the user!\n');

end

% Set up the pipeline
pipe = struct;

%% Start assembling the pipeline
% Get the neighbourhood matrix if none has been specified
if strcmp(in.neigh,'gb_niak_omitted')
    pipe.adjacency_matrix.command = sprintf(['ssurf = niak_read_surf('''','...
                                             'true,true); %s = ssurf.neigh;'...
                                             'save(out,''%s'');'],...
                                            opt.name_neigh, opt.name_neigh);
    pipe.adjacency_matrix.files_out = [opt.folder_out 'neighbourhood.mat'];

else
    input = in.neigh;
    output = [opt.folder_out 'neighbourhood.mat'];
    pipe.adjacency_matrix.command = sprintf('copyfile(''%s'',''%s'');',...
                                            input, output);
    pipe.adjacency_matrix.files_out = output;
end

in.neigh = pipe.adjacency_matrix.files_out;

% Run Region Growing
reg_in = in;
reg_out = [opt.folder_out sprintf('%s_region_growing_thr%d.mat',...
           opt.name_data, opt.region_growing.thre_size)];
reg_opt.region_growing = opt.region_growing;
reg_opt.name_data = opt.name_data;
pipe = psom_add_job(pipe, 'region_growing', ...
                    'niak_brick_stability_surf_region_growing',...
                    reg_in, reg_out, reg_opt);

% Check if we need to run the stability estimation
if opt.flag_cores || strcmp(opt.type_target, 'cons')
    % We need to run the stability estimation
    fprintf('Stability Estimation will be run\n');
    
    % Stability Estimation
    stab_est_in = pipe.region_growing.files_out;
    stab_est_opt = opt.stability_atom;
    pipe_stab_est = niak_pipeline_stability_estimate(stab_est_in, stab_est_opt);
    % Merge back the stability estimation pipeline with this pipeline
    pipe = psom_merge_pipeline(pipe, pipe_stab_est);
    
end

% See which target option is requested
switch opt.type_target
    case 'cons'
        % Perform Consensus Clustering
        fprintf('Consensus Clustering selected\n'); 

        % Consensus Clustering
        cons_out = sprintf('%sconsensus_partition.mat',opt.folder_out);
        cons_in.stab = pipe.average_atom.files_out;
        cons_in.roi = pipe.region_growing.files_out;
        cons_opt = opt.consensus;
        pipe = psom_add_job(pipe, 'consensus', ...
                            'niak_brick_stability_consensus', ...
                            cons_in, cons_out, cons_opt);
        sil_in.part = pipe.consensus.files_out;
        core_in.part = pipe.consensus.files_out;
        core_in.stab = pipe.consensus.files_out;
        
        % See if mstep should run
        if isempty(opt.consensus.scale_target)
            % Perform Consensus Clustering
            fprintf(['Mstep will run since OPT.CONSENSUS.SCALE_TARGET '...
                      'is emtpy\n']);
            
            % Run MSTEPS
            mstep_in = pipe.consensus.files_out;
            mstep_out.msteps = sprintf('%smsteps.mat',opt.folder_out);
            mstep_out.table = sprintf('%smsteps_table.mat',opt.folder_out);
            mstep_opt = opt.msteps;
            mstep_opt.rand_seed = 1;

            pipe = psom_add_job(pipe,'msteps',...
                                'niak_brick_msteps',...
                                mstep_in, mstep_out, mstep_opt);

            % Create partition from mstep
            mpart_in.cons       = pipe.consensus.files_out;
            mpart_in.roi        = pipe.region_growing.files_out;
            mpart_in.msteps     = pipe.msteps.files_out.msteps;
            mpart_out = sprintf('%smsteps_part.mat',opt.folder_out);
            mpart_opt = struct;

            pipe = psom_add_job(pipe, 'msteps_part',...
                                'niak_brick_stability_surf_msteps_part',...
                                mpart_in, mpart_out, mpart_opt);

            in.part = pipe.msteps_part.files_out;
            sil_in.part = pipe.msteps_part.files_out;
            core_in.stab = pipe.msteps_part.files_out;
        end
        
    case 'plugin'
        % Perform Plugin Clustering
        fprintf('Plugin Clustering selected\n'); 
        
        % Plugin Clustering
        plug_in = pipe.region_growing.files_out;
        plug_opt.scale = opt.scale;
        plug_out = sprintf('%splugin_partition.mat',opt.folder_out);
        pipe = psom_add_job(pipe, 'plugin', ...
                            'niak_brick_stability_surf_plugin',...
                            plug_in, plug_out, plug_opt);
        in.part = pipe.plugin.files_out;
        sil_in.part = pipe.plugin.files_out;
        core_in.stab = pipe.average_atom.files_out;
        
    case 'manual'
        % Manual Partition was supplied
        fprintf('An external partition was supplied\n');
        core_in.stab = pipe.average_atom.files_out;

end

% Check if stable cores are to be performed
if opt.flag_cores
    % Run Stable Cores
    core_in.roi = pipe.region_growing.files_out;
    core_out = sprintf('%sstab_core.mat',opt.folder_out);
    core_opt = struct;

    pipe = psom_add_job(pipe, 'stable_cores', ...
                        'niak_brick_stability_surf_cores',...
                        core_in, core_out, core_opt);
    in.part = pipe.stable_cores.files_out;
    sil_in.part = pipe.stable_cores.files_out;
end

% Run the vertex level stability estimation
for boot_batch_id = 1:opt.stability_vertex.nb_batch
    % Options
    boot_batch_opt = rmfield(opt.stability_vertex, 'nb_batch');
    
    if ~opt.flag_rand
        boot_batch_opt.rand_seed = boot_batch_id;
    end

    % Add job
    boot_batch_out = sprintf('%sstab_vertex_%d.mat',...
                             opt.folder_out, boot_batch_id);
    batch_name = sprintf('stab_vertex_%d', boot_batch_id);
    batch_clean_name = sprintf('clean_%s', batch_name);
    pipe = psom_add_job(pipe,batch_name, ...
                        'niak_brick_stability_surf',...
                        in,boot_batch_out,boot_batch_opt);
    pipe = psom_add_clean(pipe,batch_clean_name,pipe.(batch_name).files_out);
    avg_in{boot_batch_id} = boot_batch_out;
end

% Average over the results
avg_out = [opt.folder_out 'surf_stab_average.mat'];
avg_opt.flag_verbose = opt.flag_verbose;
avg_opt.name_scale = 'scale_tar';
avg_opt.name_data = 'scale_name';
pipe = psom_add_job(pipe,'average','niak_brick_stability_average', ...
                    avg_in, avg_out, avg_opt);

% And connect the outputs to the silhouette criterion machine
sil_in.stab = pipe.average.files_out;
sil_out = [opt.folder_out 'surf_silhouette.mat'];
sil_opt.flag_verbose = opt.flag_verbose;
pipe = psom_add_job(pipe, 'silhouette', 'niak_brick_stability_surf_contrast',...
                    sil_in, sil_out, sil_opt);

                % Run the pipeline
if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end