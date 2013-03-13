function [pipeline,opt] = niak_pipeline_connectome(files_in,opt)
% Generation of connectome in resting-state fMRI
%
% SYNTAX:
% [PIPELINE,OPT] = NIAK_PIPELINE_CONNECTOME(FILES_IN,OPT)
%
% ___________________________________________________________________________________
% INPUTS
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   NETWORK
%      (string) a file name of a mask of brain networks (network I is filled 
%      with Is, 0 is for the background). The analysis will be done at the level 
%      of these networks.
%
%   FMRI
%      (structure) with the following fields :      
%
%      <SUBJECT>.<SESSION>.<RUN>
%         (string) a 3D+t fMRI dataset. The fields <SUBJECT>, <SESSION> and <RUN> can be any arbitrary 
%         string. Note that time series can be specified directly as variables in a .mat file. The file 
%         FILES_IN.ATOMS needs to be specified in that instance. The <SESSION> level can be skipped.
% 
%   SEEDS
%      (string, default 'gb_niak_omitted') the name of a .csv file with a list of seeds. This input is 
%      necessary to generate any local graph property, point-to-point correlation as well as 
%      seed-based functional connectivity maps. 
%      
% OPT
%   (structure) with the following fields : 
%
%   LABEL_NETWORK
%      (string, default 'rois') the label for the network.
%
%   CONNECTOME
%      (structure) see the OPT argument of NIAK_BRICK_CONNECTOME. 
%
%   GRAPH_PROP
%      (structure) see the OPT argument of NIAK_BRICK_GRAPH_PROP.
%
%   RMAP
%      (structure) see the OPT argument of NIAK_BRICK_RMAP
%
%   FOLDER_OUT 
%      (string) where to write the results of the pipeline. 
% 
%   PSOM
%      (structure, optional) the options of the pipeline manager. See the
%      OPT argument of PSOM_RUN_PIPELINE. Default values can be used here.
%      Note that the field PSOM.PATH_LOGS will be set up by the pipeline.
%
%   FLAG_RAND
%      (boolean, default false) some of the graph measures (such as the 
%      modularity) have some random components, which means that slight 
%      variations of the measure will be observed if the measure is repeated
%      multiple times. By default, NIAK will control the seeds of the random
%      number generator to guarantee that the measures are identical if the 
%      analysis were replicated. If FLAG_RAND is set to true, then the clock
%      is used to set the random number generator, and two runs of the pipeline
%      can generate different results. 
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
% SEE ALSO:
% NIAK_BRICK_CONNECTOME, NIAK_BRICK_GRAPH_PROP, NIAK_BRICK_RMAP
%
% _________________________________________________________________________
% COMMENTS:
%
% The parcellation into network will be automatically fed to 
% NIAK_BRICK_RMAP. The options OPT.RMAP should refer to this parcellation.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pipeline, fMRI, connectome

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

%% Checking that FILES_IN is in the correct format
list_fields   = { 'network' , 'fmri' };
list_defaults = { NaN       , NaN    };
files_in      = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
list_fields   = { 'flag_rand' , 'label_network' , 'rmap'   , 'graph_prop' , 'connectome' , 'psom'   , 'folder_out' , 'flag_verbose' , 'flag_test' };
list_defaults = { false       , 'rois'          , struct() , struct()     , struct()     , struct() , NaN          , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);
folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [folder_out 'logs' filesep];

%% Get the list of seeds
opt.rmap = psom_struct_defaults(opt.rmap,{'ind_seeds'},{struct()},false);
list_seed = fieldnames(opt.rmap.ind_seeds);

%% Loop over networks
pipeline = struct();
network = opt.label_network;

% Re-organize inputs
[files_tseries,list_subject] = sub_input(files_in);

%% Copy the networks
pipeline = struct();
in = files_in.network;
[path_f,name_f,ext_f] = niak_fileparts(in);
out = [folder_out 'network_' network ext_f];
pipeline.(['mask_' network]).command   = 'system([''cp '' files_in '' '' files_out]);';
pipeline.(['mask_' network]).files_in  = in;
pipeline.(['mask_' network]).files_out = out;

%% Run the estimation of connectomes
for num_s = 1:length(list_subject)
    clear in out jopt
    subject = list_subject{num_s};
    name_job = sprintf('connectome_%s',subject);
    in.fmri = files_tseries.(subject);    
    in.mask = pipeline.(['mask_' network]).files_out;
    out = [folder_out 'connectomes' filesep 'connectome_' network '_' subject '.mat'];    
    jopt = opt.connectome;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_connectome',in,out,jopt);
end
         
%% Generate graph properties
list_mes = fieldnames(opt.graph_prop);
list_mes = list_mes(~ismember(list_mes,{'flag_verbose','flag_test'}));
if ~isempty(list_mes)
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        name_job_in = sprintf('connectome_%s',subject);
        clear in out jopt        
        name_job = sprintf('graph_prop_%s_%s',network,subject);        
        in = pipeline.(name_job_in).files_out{1};
        out = [folder_out 'graph_prop' filesep name_job '.mat'];
        jopt = opt.graph_prop;
        if opt.flag_rand
            jopt.rand_seed = [];
        else
            jopt.rand_seed = double(niak_datahash(subject));
            jopt.rand_seed = opt_ind.rand_seed(1:min(length(opt_ind.rand_seed),625));
        end
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_graph_prop',in,out,jopt);        
    end
    
    clear in out jopt
    name_job = ['summary_graph_prop_' network];
    for num_s = 1:length(list_subject)
        subject = list_subject{num_s};
        in.(subject) = pipeline.(['graph_prop_' network '_' subject]).files_out;
    end
    out = [folder_out name_job '.csv'];
    jopt.flag_verbose = true;
    pipeline = psom_add_job(pipeline,name_job,'niak_brick_graph_summary',in,out,jopt);    
end

%% Generate functional connectivity maps
if ~isempty(list_seed)

    list_maps = cell(length(list_subject),length(list_seed));
    for num_s = 1:length(list_subject) 
        subject = list_subject{num_s};        
        clear in out jopt
        in.fmri = psom_files2cell(files_in.fmri.(subject));
        if num_s == 1
            [path_f,name_f,ext_f] = niak_fileparts(in.fmri{1});
        end
        for num_seed = 1:length(list_seed)
            seed = list_seed{num_seed};
            in.seeds.(seed) = pipeline.(['mask_' network]).files_out;
            if num_s == 1
                out.seeds.(seed) = [folder_out 'rmap_seeds' filesep 'mask_' seed ext_f];
            else
                out.seeds = 'gb_niak_omitted';
            end
            out.maps.(seed)  = [folder_out 'rmap_seeds' filesep 'rmap_' subject '_' seed ext_f];
            list_maps(num_s,num_seed) = out.maps.(seed);
        end        
        name_job = ['rmap_seeds_' subject];
        jopt = opt.rmap;
        pipeline = psom_add_job(pipeline,name_job,'niak_brick_rmap',in,out,jopt);
    end
    
    %% Compute the average map for each seed
    for num_seed = 1:length(list_seed)
        seed = list_seed{num_seed};
        clear in out jopt
        in = list_maps(:,num_seed);
        out = [folder_out 'rmap_seeds' filesep 'average_rmap_' seed ext_f];
        jopt.operation = 'vol = zeros(size(vol_in{1})); for num_m = 1:length(vol_in), vol = vol + vol_in{num_m}; end, vol = vol / length(vol_in);';
        pipeline = psom_add_job(pipeline,['average_rmap_' seed],'niak_brick_math_vol',in,out,jopt);
    end
end
   
%% Run the pipeline 
if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%
function [files_tseries,list_subject] = sub_input(files_in);
files_tseries = files_in.fmri;
list_subject = fieldnames(files_tseries);
for num_s = 1:length(list_subject)
    subject  = list_subject{num_s};
    files_subject = files_tseries.(subject);
    list_session = fieldnames(files_subject);       
    files_tmp = cell();
    nb_data = 1;
    for num_sess = 1:length(list_session)
        list_run = fieldnames(files_subject.(list_session{num_sess}));
        for num_r = 1:length(list_run)
             files_tmp{nb_data} = files_subject.(list_session{num_sess}).(list_run{num_r});
             nb_data = nb_data + 1;
        end
    end
    files_tseries.(subject) = files_tmp;    
end
