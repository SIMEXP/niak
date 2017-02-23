function [files_in,files_out,opt] = niak_brick_connectome_multiscale(files_in,files_out,opt)
% Build connectomes based on multiple runs, brain partitions, and parameters
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CONNECTOME_MULTISCALE(FILES_IN,FILES_OUT,OPT)
% ______________________________________________________________________________________________________
% INPUTS:
%
% FILES_IN  
%   (structure) with the following fields : 
%
%   FMRI.(SESSION).(RUN)
%      (string) a 3D+t fMRI dataset. The fields <SESSION> and <RUN> can be any arbitrary 
%      string. 
%
%   NETWORKS.(NETWORK)
%      (string) a file name of a mask of brain networks (network I is filled 
%      with Is, 0 is for the background). The analysis will be done at the level 
%      of these networks.
%
%   MODEL
%      (structure, optional) with the following fields : 
%
%      INTRA_RUN.(SESSION).(RUN)
%          (structure, optional) with the following fields : 
%
%          COVARIATE
%              (string, optional) the name of a CSV file describing the covariates at the 
%              intra-run level. Example:
%              MOTION_X , MOTION_Y , MOTION_Z
%              0.03     , 0.02     , 0.8
%              0.05     , 0.9      , 0.6
%              Note that the labels of each column will be used as the names of the coavariates 
%              in the model. Each row corresponds to one time frames in the time series. When the 
%              fMRI time series have been scrubbed (i.e. some time frames are missing), missing 
%              time frames should be specified anyway.If some initial volumes have been suppressed, 
%              missing time frames should also be specified and OPT.SUPPRESS_VOL should be specified. 
%
%          EVENT
%              (string, optional) the name of a CSV file describing
%              the event model. Example :
%                       , TIMES , DURATION , AMPLITUDE 
%              'motor'  , 12    , 5        , 1  
%              'visual' , 12    , 5        , 1  
%              The first column defines the names of the condition that can be used as covariates in 
%              the model. The times have to be specified in seconds, with the beginning of the acquisition
%              starting at 0. 
%       
%      INTER_RUN
%          (string, default intercept) the name of a CSV file describing the  
%          covariates for intra-subject inter-run analysis. Example:
%                          , DAY 
%          <SESSION>_<RUN> , 1   
%          <SESSION>_<RUN> , 2   
%          This type of file can be generated with Excel (save under CSV).
%          Each column defines a covariate that can be used in a linear model.
%          The labels <RUN> have to be consistent with MODEL.INTRA_RUN and FMRI
%
% FILES_OUT.(NETWORK)
%   (string) a .mat file with the following matlab variables (LABEL is a field of OPT.PARAM, and 
%   NETWORK is a field of FILES_IN.NETWORKS):
%      
%   (LABEL).PARAM
%      (structure) the parameters OPT.PARAM.(LABEL), see below.
%
%   (LABEL).MODEL.INTRA_RUN.(SESSION).(RUN)
%      (structure) the model used for the intra-run analysis of session SESSION and run RUN.
%      If OPT.PARAM.(LABEL).TYPE is 'correlation' and OPT.(LABEL).PARAM.SELECT_DIFF is specified 
%      (i.e. the connectome is on a difference between the correlation coefficients at two conditions), 
%      then MODEL.INTRA_RUN.(SESSION).(RUN) has two entries, one for each condition. 
%
%   (LABEL).MODEL.INTER_RUN
%      (structure) the model used for the inter-run analysis.
%
%   (LABEL).CONNECTOME
%      (vector 1*W) vectorized version of the statistical parametric connectome
%
% OPT
%   (structure) with the following fields:
%
%   PARAM.(LABEL)
%      (stucture) a series of parameters to generate different connectomes, with fields:
%
%      INTER_RUN
%         (structure, optional) By default the contrast is on the intercept 
%         (average of all connectomes across all runs). The following 
%         fields are supported:
%
%         CONTRAST
%            (structure, with arbitray fields <NAME>, which needs to correspond to the 
%            label of one column in the file FILES_IN.MODEL.INTER_RUN, default: intercept) 
%            The fields found in CONTRAST will determine which covariates enter the model:
%
%            <NAME>
%                (scalar) the weight of the covariate NAME in the contrast.
% 
%         INTERACTION
%            (structure, optional) with multiple entries and the following fields :
%          
%            LABEL
%               (string) a label for the interaction covariate.
%
%            FACTOR
%               (cell of string) covariates that are being multiplied together to build the
%               interaction covariate. 
%
%            FLAG_NORMALIZE_INTER
%               (boolean,default true) if FLAG_NORMALIZE_INTER is true, the factor of interaction 
%               will be normalized to a zero mean and unit variance before the interaction is 
%               derived (independently of OPT.<LABEL>.INTER_RUN.NORMALIZE below.
%
%         PROJECTION
%            (structure, optional) with multiple entries and the following fields :
%
%            SPACE
%               (cell of strings) a list of the covariates that define the space to project 
%               out from (i.e. the covariates in ORTHO, see below, will be projected 
%               in the space orthogonal to SPACE).
%
%            ORTHO
%               (cell of strings, default all the covariates except those in space) a list of 
%               the covariates to project in the space orthogonal to SPACE (see above).
%
%            FLAG_INTERCEPT
%               (boolean, default true) if the flag is true, add an intercept in SPACE (even 
%               when the model does not have an intercept).
%
%         NORMALIZE_X
%            (structure or boolean, default true) If a boolean and true, all covariates of the 
%            model are normalized to a zero mean. If a structure, the fields <NAME> need to 
%            correspond to the label of a column in the file FILES_IN.MODEL.INTER_RUN):
%
%            <NAME>
%                (arbitrary value) if <NAME> is present, then the covariate is normalized
%                to a zero mean. 
%
%         NORMALIZE_Y
%             (boolean, default false) If true, the data is corrected to a zero mean,
%             in this case across subjects.
%
%         FLAG_INTERCEPT
%            (boolean, default true) if FLAG_INTERCEPT is true, a constant covariate will be
%            added to the model.
%
%         SELECT
%            (structure, optional) with multiple entries and the following fields:           
%
%            LABEL
%               (string) the covariate used to select entries *before normalization*
%
%            VALUES
%               (vector, default []) a list of values to select (if empty, all entries are retained).
%
%            MIN
%               (scalar, default []) only values higher (or equal) than MIN
%               are retained.
%
%            MAX
%               (scalar, default []) only values lower (or equal) than MAX are retained. 
%
%            OPERATION
%               (string, default 'or') the operation that is applied to select the frames.
%               Available options:
%               'or' : merge the current selection SELECT(E) with the result of the previous one.
%               'and' : intersect the current selection SELECT(E) with the result of the previous one.
%
%      INTRA_RUN
%         (structure, optional) with the following fields:
%
%         TYPE
%            (string, default 'correlation') The other fields depend on this parameter. 
%            Available options:
%               'correlation' : simple Pearson's correlation coefficient (the average correlation intra
%                  network is kept on the diagonal).
%               'glm' : run a general linear model estimation
%
%         case 'correlation'
%
%            FLAG_FISHER
%               (boolean, default true) if the flag is on, the correlation values are normalized
%               using a Fisher's transform. 
%
%            PROJECTION
%               (cell of strings) a list of the covariates that will be regressed out from the 
%               time series (an intercept will be automatically added).
%
%            SELECT
%               (structure, optional) The correlation will be derived only on the selected volumes. 
%               By default all the volumes are used. See OPT.PARAM.<LABEL>.INTER_RUN.SELECT above.
%
%            SELECT_DIFF
%               (structure, optional) If SELECT_DIFF is specified has two entries, the 
%               measure will be the difference in correlations between the two subsets of time frames 
%               SELECT_DIFF-SELECT, instead a single correlation coefficient. 
%               See OPT.PARAM.<LABEL>.INTER_RUN.SELECT above.
%
%         case 'glm'
%
%            same as OPT.MODEL.INTER_RUN except that (1) there is a covariate called 'seed' in the model_group
%            which will be iterated over all possible seeds; and (2) the default test is a contrast on the 
%            seed. Note that the default for the NORMALIZE_Y parameter is true at the run level.
%
%   MIN_NB_VOL
%       (integer, default 10) the minimal number of volumes in a run allowed to estimate a connectome. 
%       This is assessed after the SELECT field of OPT.PARAM.(LABEL).INTRA_RUN is applied. 
%       Subjects who have a run that does not meet this criterion are automatically excluded
%       from the analysis. 
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% To apply the same model to all the runs of a subject, specify it in 
% FILES_IN.MODEL.INTRA_RUN, without using fields for <SESSION> and <RUN>.
%
% When some of the models are not specified, a model with all runs and an 
% intercept is used at inter-run level. The correlation between full time series
% is used at the intra-run level. 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Griatrie de Montral, Dpartement d'informatique et de recherche 
% oprationnelle, Universit de Montral, 2010-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : GLM, functional connectivity, connectome, PPI.

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%mode
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CONNECTOME_MULTISCALE(FILES_IN,FILES_OUT,OPT). \n  Type ''help niak_brick_connectome_MULTISCALE'' for more info.')
end

%% Files in
list_fields   = { 'fmri' , 'model'  , 'networks' };
list_defaults = {  NaN   , struct() ,  NaN       };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

files_in.model = psom_struct_defaults(files_in.model,{'inter_run','intra_run'},{'gb_niak_omitted','gb_niak_omitted'});
[fmri,label_fmri] = niak_fmri2cell(files_in.fmri,false); % reformat FILES_IN.FMRI into a cell

%% Files out 
if ~isstruct(files_out)
    error('FILES_OUT should be a structure')
end
if ~psom_cmp_var(fieldnames(files_out),fieldnames(files_in.networks))
    error('FILES_OUT and FILES_IN.NETWORKS should have the same fields');
end

%% Options
list_fields   = { 'min_nb_vol' , 'param' , 'flag_verbose' , 'flag_test' };
list_defaults = { 10           , NaN     , true           ,   false     };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

list_param = fieldnames(opt.param); % Defaults for opt.param
def_contrast.intercept = 1;
list_fields   = { 'select' , 'contrast'   , 'projection' , 'flag_intercept' , 'interaction' , 'normalize_x' , 'normalize_y' };
list_defaults = { struct() , def_contrast , struct()     , true             , {}            , true          , false         };

for pp = 1:length(list_param) 
    param = list_param{pp};
    opt.param.(param) = psom_struct_defaults(opt.param.(param),{ 'inter_run' , 'intra_run' },{ struct()    , struct()    });
    opt.param.(param).inter_run = psom_struct_defaults(opt.param.(param).inter_run,list_fields,list_defaults);
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the networks
if opt.flag_verbose
    fprintf('Reading the networks ...\n');
end
list_network = fieldnames(files_in.networks);
for nn = 1:length(list_network); %% loop over networks
    network = list_network{nn};    
    [hdr,networks.(network)] = niak_read_vol(files_in.networks.(network)); % read networks        
end

%% Read the intra-run models
if opt.flag_verbose
    fprintf('Reading the intra-run models ...\n');
end
for rr = 1:length(fmri)    
    session = label_fmri(rr).session;
    run = label_fmri(rr).run;
    if ~ischar(files_in.model.intra_run)&&isfield(files_in.model.intra_run,session)
        file_run = files_in.model.intra_run.(session).(run);
    elseif ~ischar(files_in.model.intra_run)&&(isfield(files_in.model.intra_run,'covariate')||isfield(files_in.model.intra_run,'event'))
        file_run = files_in.model.intra_run;
    else
        file_run = struct();
    end
    file_run = psom_struct_defaults(file_run,{'covariate','event'},{'gb_niak_omitted','gb_niak_omitted'});
        
    if ~strcmp(file_run.covariate,'gb_niak_omitted')
        [covariate.x,covariate.labels_x,covariate.labels_y] = niak_read_csv(file_run.covariate);
        intra_run.(session).(run).covariate = covariate;
    else 
        intra_run.(session).(run).covariate = struct();
    end
        
    if ~strcmp(file_run.event,'gb_niak_omitted')
        [event.x,event.labels_x] = niak_read_csv(file_run.event);      
        intra_run.(session).(run).event = event;
    else 
        intra_run.(session).(run).event = struct();
    end
end

%% Read the inter-run model 
if opt.flag_verbose
    fprintf('Reading the inter-run model ...\n');
end
inter_run_raw = struct;
if ~strcmp(files_in.model.inter_run,'gb_niak_omitted')
    [inter_run_raw.x,inter_run_raw.labels_x,inter_run_raw.labels_y] = niak_read_csv(files_in.model.inter_run);
else
    inter_run_raw.x        = [];
    inter_run_raw.labels_x = {label_fmri.name};
    inter_run_raw.labels_y = {};
end
    
for pp = 1:length(list_param); %% loop over parameters to generate SPC
    param = list_param{pp};    
    inter_run.(param) = niak_normalize_model(inter_run_raw,opt.param.(param).inter_run);
    x = inter_run.(param).x;
    c = inter_run.(param).c;
    inter_run.(param).p = c'*(x'*x)^(-1)*x';
end

%% Read the fMRI runs and generate the intra-run spc connectome
if opt.flag_verbose
    fprintf('Generation of a statistical parametric connectome ...\n');
end
spc_inter_run = struct();
flag_ok = true(length(list_param),1); % for each set of parameters, flag if there is enough data for the estimation
for num_r = 1:length(fmri) %% loop over runs
    session = label_fmri(num_r).session;
    run = label_fmri(num_r).run;
    name = label_fmri(num_r).name;
    model_tseries = intra_run.(session).(run);
    model_tseries = psom_merge_pipeline(model_tseries,sub_read_time_series(fmri{num_r})); % load raw time series
    if opt.flag_verbose 
        fprintf('    %s \n',fmri{num_r});
    end
    for num_p = 1:length(list_param); %% loop over parameters to generate SPC
        param = list_param{num_p};
        if ~isfield(spc_inter_run,param) % save the parameters of the connectomes in the output structure
           spc_inter_run.(param).param.inter_run = opt.param.(param).inter_run;
        end
        
        %% Check that all the data is present to estimate the connectome
        flag_data_ok = ~any(~ismember(inter_run.(param).labels_x,{label_fmri.name}));
        if ~flag_data_ok
            warning('I could not generate the connectome with parameters %s because some runs were missing',param);
            spc_inter_run.(param).param.intra_run = opt.param.(param).intra_run;
            spc_inter_run.(param).model.inter_run = inter_run.(param);
            spc_inter_run.(param).model.intra_run = struct;
            for num_n = 1:length(list_network)
                network = list_network{num_n};
                spc_inter_run.(param).connectome.(network).value = NaN;
            end
            continue
        end
        ind_r = find(strcmp(inter_run.(param).labels_x,name));
        if isempty(ind_r)
            continue
        end        
        
        for num_n = 1:length(list_network); %% loop over networks
            network = list_network{num_n};    
            model_tseries.network = networks.(network);
                                
            %% Compute the statistical parametric connectome at the level of intra run        
            [spc_intra_run,intra_run_n,opt.param.(param).intra_run] = niak_glm_connectome_run(model_tseries,opt.param.(param).intra_run);
            
            %% Store the updated intra-run parameters to generate the connectome
            if ~isfield(spc_inter_run.(param).param,'intra_run')
                spc_inter_run.(param).param.intra_run = opt.param.(param).intra_run;
            end
            
            %% Test if enough time points satisfied the selection criteria
            flag_ok(num_p) = flag_ok(num_p)&&(size(intra_run_n(1).y,1)>=opt.min_nb_vol)&&(size(intra_run_n(end).y,1)>=opt.min_nb_vol);
            if ~flag_ok(num_p)
                warning('There was not enough data fitting the selection criteria in session %s, run %s, for parameters %s, I am going to generate a degenerate connecome.',session, run, param);                            
            end
            
            %% Compute the connectome associated with the run
            switch opt.param.(param).intra_run.type
                case 'glm'
                    spc_intra_run = spc_intra_run(:);
                case 'correlation'
                    spc_intra_run = niak_mat2lvec(spc_intra_run);            
            end
            if ~isfield(spc_inter_run,param)||~isfield(spc_inter_run.(param),'connectome')||~isfield(spc_inter_run.(param).connectome,network)
                spc_inter_run.(param).connectome.(network).value = zeros([1 length(spc_intra_run)]);
            end
            
            if flag_ok(num_p)
                spc_inter_run.(param).connectome.(network).value = spc_inter_run.(param).connectome.(network).value+inter_run.(param).p(:,ind_r)*spc_intra_run(:)';
            else
                spc_inter_run.(param).connectome.(network).value = NaN;
            end
            
            %% Save intra-run model 
            intra_run_n(1).nb_vol = size(intra_run_n(1).y,1);
            intra_run_n(end).nb_vol = size(intra_run_n(end).y,1);
            intra_run_n(1).y = []; % Do not save individual time series to save memory
            intra_run_n(end).y = []; % Do not save individual time series to save memory
            if ~isfield(spc_inter_run.(param),'model')                
                spc_inter_run.(param).model.inter_run = inter_run.(param);
            end
            spc_inter_run.(param).model.intra_run.(session).(run) = intra_run_n;
       end % end of networks
    end % end of parameters 
end % enf of runs

%% Save results in mat form
for nn = 1:length(list_network)
    network = list_network{nn};
    if opt.flag_verbose
       fprintf('Saving the results in %s ...\n',files_out.(network));
    end
    res = struct();    
    for pp = 1:length(list_param)
        param = list_param{pp};
        res.(param).connectome = spc_inter_run.(param).connectome.(network).value;
        res.(param).model.intra_run = spc_inter_run.(param).model.intra_run;
        res.(param).model.inter_run = spc_inter_run.(param).model.inter_run;
        res.(param).param = spc_inter_run.(param).param;
    end
    save(files_out.(network),'-struct','res')
end

function intra_run = sub_read_time_series(file_run)
%% Read time series into a structure
%% MODEL_RUN.TIME_SERIES : array of time series (column-wise)
%% MODEL_RUN.TIME_FRAMES : time associated with each sample
%% MODEL_RUN.MASK_SUPPRESSED : a boolean mask of the volumes that were suppressed in the original time series
%% MODEL_RUN.CONFOUNDS : a matrix of confounds that were regressed out of time series (column-wise)
%% MODEL_RUN.LABELS_CONFOUNDS : a cell of strings with the labels of the confounds

[hdr_fmri,vol] = niak_read_vol(file_run);
intra_run.tseries = niak_vol2tseries(vol);
if isfield(hdr_fmri,'extra')
    if isfield(hdr_fmri.extra,'mask_scrubbing')
        mask_scrubbing = hdr_fmri.extra.mask_scrubbing;
        intra_run.mask_suppressed = mask_scrubbing;
    else
        mask_scrubbing = false(size(intra_run.tseries,1),1);
        if isfield(hdr_fmri.extra,'mask_suppressed')
            intra_run.mask_suppressed = hdr_fmri.extra.mask_suppressed;
        else
            intra_run.mask_suppressed = false(size(intra_run.tseries,1),1);
        end
    end
    intra_run.time_frames = hdr_fmri.extra.time_frames(~mask_scrubbing);
    if isfield(hdr_fmri.extra,'confounds')
        intra_run.confounds = hdr_fmri.extra.confounds(~mask_scrubbing,:);
        intra_run.labels_confounds = hdr_fmri.extra.labels_confounds;
    else
        intra_run.confounds = [];
        intra_run.labels_confounds = {};
    end 
else
    intra_run.time_frames = (0:(size(intra_run.tseries,1)-1))*hdr_fmri.info.tr;
    intra_run.confounds   = [];
    intra_run.labels_confounds = {};
    intra_run.mask_suppressed  = false(size(intra_run.tseries,1),1);
    mask_scrubbing = false(size(intra_run.tseries,1),1);
end
intra_run.tseries = intra_run.tseries(~mask_scrubbing,:);