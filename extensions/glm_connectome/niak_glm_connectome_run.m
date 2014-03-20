function [spc,model_n,opt] = niak_glm_connectome_run(model_tseries,opt)
% Estimation of a statistical parametric connectome based on a single fMRI run
%
% SYNTAX:
% [spc,model_n,opt] = niak_glm_connectome_run(model_tseries,opt)
%____________________________________________________________________________________
% INPUTS:
%
% MODEL_TSERIES
%   (structure) with the following fields :
%
%   TSERIES
%      (vector T*N) the time series data (by column)
%
%   TIME_FRAMES
%      (vector, default regular grid 1Hz sampling rate) TIME_FRAMES(T) is the time 
%      associated with Y(T,:).
%
%   MASK_SUPPRESSED
%      (vector TC*N, default no suppressed) MASK_SUPPRESSED(TC) indicates if the time frame 
%      number TC was suppressed from the original series (MASK_SUPPRESSED has T zeros elements, 
%      corresponding to the rows of TSERIES).
%
%   CONFOUNDS
%      (matrix T*C, default no condounds) CONFOUNDS(:,C) is a confound covariate that was 
%      regressed out from TSERIES
%
%   LABELS_CONFOUNDS
%      (cell of strings, default no labels) LABELS_CONFOUNDS{C} is the label of CONFOUNDS(:,C)
%
%   COVARIATE   
%      (structure, default no covariate) with the following fields:
%
%      X 
%         (matrix TC*K) covariates to include in the model.
%
%      LABELS_Y
%         (cell of strings 1*K) LABELS_Y{K} is the label of COVARIATE.X(:,K)
%           
%   EVENT
%      (structure, default no event) with the following fields:
%      
%      X
%         (matrix NE*3) X(E,1) is the time of an event (time 0 is the beginning of the scan)
%                       X(E,2) is the duration of the event
%                       X(E,3) is the amplitude of the event
%
%      LABELS_X
%         (cell of strings NE*1) LABELS_X{E} is the label of the event X(E,:). Note that the same
%         LABEL needs to be used for all events of the same type, and will be used for the 
%         associated covariate in the model.
% 
%   NETWORK
%       (3D array or vector, defaut 1:nb_voxel) 0 is the background (excluded) and network I is 
%       filled with Is. the signal will be averaged on these networks to generate the connectome.
%       The vectorized version of NETWORK should correspond to the spatial (second) dimension of 
%       MODEL_TSERIES.TSERIES.
%
% OPT
%   (structure, optional) with the following fields:
%
%   TYPE
%      (string, default 'correlation') The other fields depend on this parameter. 
%      Available options:
%         'correlation' : simple Pearson's correlation coefficient. 
%         'glm' : run a general linear model estimation
%
%   case 'correlation'
%
%      FLAG_FISHER
%         (boolean, default true) if the flag is on, the correlation values are normalized
%         using a Fisher's transform. 
%
%      PROJECTION
%         (cell of strings) a list of the covariates that will be regressed out from the 
%         time series (an intercept will be automatically added).
%
%      SELECT
%         (structure, optional) The correlation will be derived only on the selected volumes. 
%         By default all the volumes are used. See OPT.SELECT in the 'glm' case below.
%
%      SELECT_DIFF
%         (structure, optional) If SELECT_DIFF is specified has two entries, the 
%         measure will be the difference in correlations between the two subsets of time frames 
%         SELECT_DIFF-SELECT, instead a single correlation coefficient. See OPT.SELECT in the 'glm' 
%         case below for syntax.
%
%   case 'glm'
%
%      CONTRAST.<NAME>
%         (scalar, default contrast.seed = 1) with arbitray fields <NAME>, which needs to 
%         correspond to either 'seed' (the time series of a seed) or any of the covariates defined
%         in the model, typically as an interaction term. The fields found in CONTRAST will determine 
%         which covariates enter the model. CONTRAST.<NAME> is the weight of the covariate NAME in 
%         the contrast.
% 
%      INTERACTION
%         (structure, optional) with multiple entries and the following fields :
%       
%         LABEL
%            (string) a label for the interaction covariate.
%
%         FACTOR
%            (cell of string) covariates that are being multiplied together to build the
%            interaction covariate. 
%
%         FLAG_NORMALIZE_INTER
%            (boolean,default true) if FLAG_NORMALIZE_INTER is true, the factor of interaction 
%            will be normalized to a zero mean and unit variance before the interaction is 
%            derived (independently of OPT.<LABEL>.GROUP.NORMALIZE below.
%
%      PROJECTION
%         (structure, optional) with multiple entries and the following fields :
%
%         SPACE
%            (cell of strings) a list of the covariates that define the space to project 
%            out from (i.e. the covariates in ORTHO, see below, will be projected 
%            in the space orthogonal to SPACE).
%
%         ORTHO
%            (cell of strings, default all the covariates except those in space) a list of 
%            the covariates to project in the space orthogonal to SPACE (see above).
%
%         FLAG_INTERCEPT
%            (boolean, default true) if the flag is true, add an intercept in SPACE (even 
%            when the model does not have an intercept).
%
%      NORMALIZE_X
%         (structure or boolean, default false) If a boolean and true, all covariates of the 
%         model are normalized to a zero mean and unit variance. If a structure, the 
%         fields <NAME> need to correspond to the label of a column in the 
%         file FILES_IN.MODEL.GROUP):
%
%         <NAME>
%             (arbitrary value) if <NAME> is present, then the covariate is normalized
%             to a zero mean and a unit variance. 
%
%      NORMALIZE_Y
%          (boolean, default true) If true, the data is corrected to a zero mean and unit variance,
%          in this case in the time dimension.
%
%      FLAG_INTERCEPT
%         (boolean, default true) if FLAG_INTERCEPT is true, a constant covariate will be
%         added to the model.
%
%      SELECT
%         (structure, optional) with multiple entries and the following fields:           
%
%         LABEL
%            (string) the covariate used to select entries *before normalization*
%
%         VALUES
%            (vector, default []) a list of values to select (if empty, all entries are retained).
%
%         MIN
%            (scalar, default []) only values higher (or equal) than MIN are retained.
%
%         MAX
%            (scalar, default []) only values lower (or equal) than MAX are retained. 
% 
%         OPERATION
%            (string, default 'or') the operation that is applied to select the frames.
%            Available options:
%            'or' : merge the current selection SELECT(E) with the result of the previous one.
%            'and' : intersect the current selection SELECT(E) with the result of the previous one.
%
%________________________________________________________________________________
% OUTPUTS:
%  
% SPC       
%   (vector N*N) the statistical parametric connectome. 
%
% MODEL_N
%   (structure) the linear model used to generate the connectome.
%  
% OPT
%   (structure) same as the input, but updated with default values.
%
% _________________________________________________________________________
% COMMENTS:
%
% The full model contains an intercept, the seed that is used to derive one 
% column of the connectome, the events convolved with an hemodynamic response,
% the manyally specified covariates as well as the confounds that were regressed 
% out on the time series (typically during the preprocessing). Interaction terms
% can be derived by combination of all of the above.
%
% In 'glm' model, the confounds will be regressed out of all other covariates 
% (along with the intercept) before model estimation. 
%
% Copyright (c) Pierre Bellec, Jalloul Bouchkara, 
%               Centre de recherche de l'institut de 
%               Gériatrie de Montréal, Département d'informatique et de recherche 
%               opérationnelle, Université de Montréal, 2012.
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

%% Default model
list_fields   = { 'tseries' , 'time_frames' , 'mask_suppressed' , 'confounds' , 'labels_confounds' , 'event' , 'covariate' , 'network' };
list_defaults = { NaN       , []            , []                , []          , {}                 , struct  , struct      , []        };
model_tseries = psom_struct_defaults(model_tseries,list_fields,list_defaults);

if isempty(model_tseries.time_frames)
    model_tseries.time_frames = 0:(length(model_tseries.tseries)-1);
end

if isempty(model_tseries.mask_suppressed)
    if isfield(model_tseries.covariate.x)&&~isempty(model_tseries.covariate.x)
        model_tseries.mask_suppressed = false(size(model_tseries.covariate.x,1),1);
    else
        model_tseries.mask_suppressed = false(size(model_tseries.tseries,1),1);
    end
end

%% Default option
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults(opt,{'type'},{'correlation'},false);
switch opt.type
    case 'correlation'
        list_fields   = { 'type'        , 'flag_fisher' , 'projection' , 'select' , 'select_diff' };
        list_defaults = { 'correlation' , true          , {}           , struct() , struct()      };
        opt = psom_struct_defaults(opt,list_fields,list_defaults);
    case 'glm'
        def_contrast.seed = 1;
        list_fields   = { 'select' , 'contrast'   , 'projection' , 'flag_intercept' , 'interaction' , 'normalize_x' , 'type'        , 'normalize_y' };
        list_defaults = { {}       , def_contrast , struct()     , true             , {}            , false         , 'correlation' , true          };
        opt = psom_struct_defaults(opt,list_fields,list_defaults);
end    

%% Case of a difference in correlation
if strcmp(opt.type,'correlation') && isfield(opt.select_diff,'label')
    opt1 = rmfield(opt,'select_diff');    
    [spc1,model_n(1)] = niak_glm_connectome_run(model_tseries,opt1);
    opt2 = opt1;
    opt2.select = opt.select_diff;
    [spc2,model_n(2)] = niak_glm_connectome_run(model_tseries,opt2);
    if isnan(spc1)||isnan(spc2)
        spc = NaN;
    else
        spc = spc2-spc1;
    end
    return
end

%% Add the manually specified covariates in the model
conf = struct;
if isfield(model_tseries.covariate,'x')&&~isempty(model_tseries.covariate.x)
    conf.x = model_tseries.covariate.x(~model_tseries.mask_suppressed,:);
    conf.labels_y = model_tseries.covariate.labels_y;
else
    conf.x = [];
    conf.labels_y = {};
end
  
%% Add the events convolved with an hemodynamic response to the model
if isfield(model_tseries.event,'x')&&~isempty(model_tseries.event.x)
    [list_event,tmp,all_event]  = unique(model_tseries.event.labels_x); 
    opt_m.events = [all_event(:) model_tseries.event.x];
    opt_m.frame_times = model_tseries.time_frames;
    x_cache =  niak_fmridesign(opt_m); 
    conf.x = [conf.x x_cache.x(:,:,1,1)];
    conf.labels_y = [conf.labels_y(:) ; list_event(:)];
end

%% Add the confounds to the model
if ~isempty(model_tseries.confounds)&&~strcmp(opt.type,'correlation')
    if any(ismember(model_tseries.labels_confounds,conf.labels_y))
        error('Some labels of event/covariate are also found in the list of confounds. Do not use the same label twice !')
    end
    conf.x = [conf.x model_tseries.confounds];
    conf.labels_y = [conf.labels_y(:) ; model_tseries.labels_confounds(:)];
    for num_c = 1:length(model_tseries.labels_confounds)
        opt.contrast.(model_tseries.labels_confounds{num_c}) = 0;
    end
end

%% Add the time series in the model
conf.y = model_tseries.tseries;
lab_vol = find(~model_tseries.mask_suppressed);
conf.labels_x = cell([size(conf.y,1) 1]);
for num_v = 1:length(lab_vol)
    conf.labels_x{num_v} = sprintf('%i',lab_vol(num_v));
end

try
switch opt.type

    case 'correlation'
    
        %% the user wants to work with a simple correlation coefficient
        opt_n.select = opt.select;        
        if ~isempty(opt.projection)
            for num_f = 1:length(opt.projection)
                opt_n.contrast.(opt.projection{num_f}) = 1;
            end
        end
        model_n = niak_normalize_model(conf,opt_n);
        if ~isempty(opt.projection)
            model_proj.x = model_n.x;
            model_proj.y = model_n.y;
            opt_proj.flag_residuals = true;
            res_proj = niak_glm(model_proj,opt_proj);
            model_n.y = res_proj.e;
        end
        if ~isempty(model_tseries.network)
            opt_t.correction.type = 'mean_var';
            model_n.y = niak_build_tseries(model_n.y,model_tseries.network(:),opt_t);
            N = niak_build_size_roi(model_tseries.network);
        else
            model_n.y = niak_normalize_tseries(model_n.y);
            N = ones(size(model_n.y,2),1);
        end
        spc = niak_build_correlation(model_n.y);
        ir = var(model_n.y,[],1)';       
        mask_0 = (N==0)|(N==1);
        N(mask_0) = 10;
        ir = ((N.^2).*ir-N)./(N.*(N-1));
        ir(mask_0) = 0;
        spc(eye(size(spc))>0) = ir; % A tricky formula to add the average correlation within each network, at the voxel level, on the diagonal
        if opt.flag_fisher
            spc = niak_fisher(spc);
        end
        return    

    case 'glm'
    
        %% a general linear model estimation

        %% Average time series on networks
        if ~isempty(model.network)
            conf.y = niak_build_tseries(conf.y,model_tseries.network);
        end
        
        %% initialization of spc
        spc = zeros(size(conf.y,2),size(conf.y,2));
        opt_model = rmfield(opt,'type');
        opt_model.normalize_type = 'mean_var';
        
        % add the seed field to the labels_y, output an error if it is already present
        if ismember('seed',conf.labels_y)
            error('''seed'' was found as a label in the list of covariate/event/confound. This label is reserved for the seed region (which is iterated over the full connectome')
        end
        conf.labels_y = [{'seed'} ; conf.labels_y(:)];

        %% loop of the effects matrix 
        for num_i = 1:size(conf.y,2)            
            model_n = conf;
            model_n.x = [niak_normalize_tseries(model_tseries.tseries(:,num_i)) model_n.x];
            model_n = niak_normalize_model(model_n,opt_model);
            opt_o.test = 'ttest';
            results = niak_glm(model_n,opt_o); 
            spc(:,num_i) = results.eff ; 
        end  
        
    otherwise
    
        error('%s is an unkown type of statistical parametric connectome',opt.type)
end
catch
    warning('Huho, something went wrong with the estimation of the connectome. Likely not enough time points to build a connectome, or a missing covariate/condition in the csv file. I am returning a NaN connectome and an empty model.')
    model_n.x = [];
    model_n.y = [];
    model_n.labels_x = {};
    model_n.labels_y = {};
    model_n.c = [];
    spc = NaN;
end
