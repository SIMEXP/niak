function [model_n,opt] = niak_normalize_model (model, opt)
% Prepare a model for regression analysis: interaction, selection, projection, etc
%
% SYNTAX:
% [MODEL_N,OPT] = NIAK_NORMALIZE_MODEL (MODEL,OPT).
% _________________________________________________________________________________
% INPUTS:
%
% MODEL 
%   (structure) with the following fields:
%    
%   X   
%      (matrix M*K) the covariates (observations x covariates)
%
%   Y 
%      (matrix M*N, default []) the data (observations x units)
% 
%   LABELS_X
%      (cell of strings 1xM) LABELS_X{M} is the label of the Mth observation.
%
%   LABELS_Y
%      (cell of strings 1*K) LABELS_Y{K} is the label of the Kth covariate
%
% OPT
%   (structure) with the following fields:
%
%   CONTRAST
%      (structure, with arbitray fields <NAME>, which needs to correspond to the 
%      label of one column in the file FILES_IN.MODEL.GROUP) The fields found in 
%      CONTRAST will determine which covariates enter the model:
%
%      <NAME>
%         (scalar) the weight of the covariate NAME in the contrast.
% 
%   INTERACTION
%      (structure, optional) with multiple entries and the following fields :
%          
%      LABEL
%         (string) a label for the interaction covariate.
%
%      FACTOR
%         (cell of string) covariates that are being multiplied together to build the
%         interaction covariate.  There should be only one covariate associated with 
%         each label.
%
%      FLAG_NORMALIZE_INTER
%         (boolean,default true) if FLAG_NORMALIZE_INTER is true, the factor of interaction 
%         will be normalized to a zero mean and unit variance before the interaction is 
%         derived (independently of OPT.<LABEL>.GROUP.NORMALIZE below).
%
%   PROJECTION
%      (structure, optional) with multiple entries and the following fields :
%
%      SPACE
%         (cell of strings) a list of the covariates that define the space to project 
%         out from (i.e. the covariates in ORTHO, see below, will be projected 
%         in the space orthogonal to SPACE).
%
%      ORTHO
%         (cell of strings, default all the covariates except those in space) a list of 
%         the covariates to project in the space orthogonal to SPACE (see above).
%
%      FLAG_INTERCEPT
%         (boolean, default true) if the flag is true, add an intercept in SPACE (even 
%         when the model does not have an intercept).
%
%   NORMALIZE_X
%      (structure or boolean, default true) If a boolean and true, all covariates of the 
%      model are normalized to a zero mean and unit variance.  
%      If a structure, the fields <NAME> need to correspond to the label of a column in the 
%      file FILES_IN.MODEL.GROUP):
%
%      <NAME>
%         (arbitrary value) if <NAME> is present, then the covariate is normalized
%         to a zero mean and a unit variance. 
%
%   NORMALIZE_Y
%      (boolean, default false) If true, the data is corrected to a zero mean and unit variance.
%
%   NORMALIZE_TYPE
%      (string, default 'mean') Available options:
%         'mean': correction to a zero mean (for each column)
%         'mean_var': correction to a zero mean and unit variance (for each column)
%
%   FLAG_INTERCEPT
%      (boolean, default true) if FLAG_INTERCEPT is true, a constant covariate will be
%      added to the model.
%
%   SELECT
%      (structure, optional) with multiple entries and the following fields:           
%
%      LABEL
%         (string) the covariate used to select entries *before normalization*
%
%      VALUES
%         (vector, default []) a list of values to select (if empty, all entries are retained).
%
%      MIN
%         (scalar, default []) only values higher (or equal) than MIN are retained.
%
%      MAX
%         (scalar, default []) only values lower (or equal) than MAX are retained. 
%
%      OPERATION
%         (string, default 'or') the operation that is applied to select the frames.
%         Available options:
%         'or' : merge the current selection SELECT(E) with the result of the previous one.
%         'and' : intersect the current selection SELECT(E) with the result of the previous one.
%
%   FLAG_FILTER_NAN
%      (boolean, default true) if the flag is true, any observation associated with a NaN in 
%      MODEL.X is removed from the model. 
%
%   LABELS_X
%      (cell of strings, default {}) The list of entries (rows) used 
%      to build the model (the order will be used as well). If left empty, 
%      all entries are used (but they are re-ordered based on alphabetical order). 
%      Contrary to MODEL.LABELS_X, the labels listed in OPT.LABELS_X need to be unique. 
%      For example, OPT.LABELS_X = { 'motion' , 'confounds' }; will first put all the 
%      covariates labeled 'motion' in the model and then all the covariates labeled 
%      'confounds', regardless of their numbers.
%
%_________________________________________________________________________________________
% OUTPUTS:
%
%   MODEL_N
%      (structure) Same as MODEL after the specified normalization (and generation of
%      covariates) procedure was applied. An additional field is added with a vectorized
%      version of the contrast:
% 
%      C
%         (vector 1*K) C(K) is the contrast associated with the covariate MODEL_N.X(:,K)
%
% ________________________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________________________
% COMMENTS:
%
% In the selection process, if more than covariate are associated with OPT.SELECT.LABEL, 
% the final selection will be the intersection of all selections performed with individual
% covariates associated with the label.
%
% The operations are applied in the following order:
%   1. Select a subset of entries
%   2. Orthogonalization of covariates
%   3. Add interaction terms
%   4. Normalization (standardization) of the covariates. 
%
% Copyright (c) Pierre Bellec, Jalloul Bouchkara
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : general linear model

%% Check the model
list_fields   = { 'x' , 'y' , 'labels_x' , 'labels_y' };
list_defaults = { NaN , []  , NaN        , NaN        };
model = psom_struct_defaults(model,list_fields,list_defaults);

%% Check the options
list_fields   = { 'flag_filter_nan' , 'select' , 'contrast' , 'projection' , 'flag_intercept' , 'interaction' , 'normalize_x' , 'normalize_y' , 'normalize_type' , 'labels_x' };
list_defaults = { true              , struct   , struct()   , struct       , true             , {}            , true          , false         , 'mean'           ,{}         };
if nargin > 1
   opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
   opt = psom_struct_defaults(struct,list_fields,list_defaults);
end

%% Filter out the NaN entries
if (opt.flag_filter_nan)&&~isempty(model.x)
    mask_nan = max(isnan(model.x),[],2);
    model.x = model.x(~mask_nan,:);
    if any(mask_nan)
        warning('The following entries were suppressed because they were associated to NaNs')
        char(model.labels_x{mask_nan})
    end
    model.labels_x = model.labels_x(~mask_nan,:);
end

%% Reorder (and reduce) the model using opt.labels_x 
if ~isempty(opt.labels_x)
    if length(unique(opt.labels_x))~=length(opt.labels_x)
        error('The labels provided in OPT.LABELS_X should be unique')
    end
    [mask_x,ind_m] = ismember(opt.labels_x,model.labels_x) ; 
    if any(ind_m==0)
        ind_0 = find(ind_m == 0);
        fprintf('Warning: the following entries that were specified in the CSV were not associated with any data and will be omitted:\n')
        for num_m = 1:length(ind_0)
            fprintf('    %s\n',opt.labels_x{ind_0(num_m)});
        end
    end
    ind_m = ind_m(ind_m~=0);

    labx_tmp = {};
    x_tmp = [];
    y_tmp = [];
    model.labels_x = model.labels_x(:);
    model.labels_y = model.labels_y(:);

    for num_m = 1:length(ind_m)
        mask_tmp = ismember(model.labels_x,model.labels_x{ind_m(num_m)});
        labx_tmp = [ labx_tmp ; model.labels_x(mask_tmp)];
        if ~isempty(model.x)
            x_tmp = [x_tmp ; model.x(mask_tmp,:)];
        end
        if ~isempty(model.y)
            y_tmp = [y_tmp ; model.y(mask_tmp,:)];
        end
    end
    model.x = x_tmp;
    model.y = y_tmp;
    model.labels_x = labx_tmp;
end

%% Select a subset of entries
if isfield(opt.select(1),'label')
    for num_s = 1:length(opt.select)
        if ~isfield(opt.select(num_s),'label')
           continue
        end
        opt_s = psom_struct_defaults(opt.select(num_s),{'label','values','min','max','operation'},{NaN,[],[],[],'or'}); 
        if isempty(opt_s.operation)
            opt_s.operation = 'or';
        end
        if strcmp(opt_s.operation,'or')
            mask = false([size(model.labels_x,1) 1]);
        else
            mask = true([size(model.labels_x,1) 1]);
        end
        ind = find(ismember(model.labels_y,opt_s.label));
        if isempty(ind)
            error('I could not find the "%s" covariate in the model to select a subset of observations',opt_s.label)
        end
        switch opt_s.operation
            case 'or'
                if ~isempty(opt_s.values)           
                    mask = mask|min(ismember(model.x(:,ind),opt_s.values),[],2);
                end
                if ~isempty(opt_s.min)
                   mask = mask|min(model.x(:,ind)>opt_s.min,[],2);
                end
                if ~isempty(opt_s.max)
                   mask = mask|min((model.x(:,ind)<opt_s.max),[],2);
                end
            case 'and'
                if ~isempty(opt_s.values)           
                    mask = mask&min(ismember(model.x(:,ind),opt_s.values),[],2);
                end
                if ~isempty(opt_s.min)
                   mask = mask&min(model.x(:,ind)>opt_s.min,[],2);
                end
                if ~isempty(opt_s.max)
                   mask = mask&min((model.x(:,ind)<opt_s.max),[],2);
                end
            otherwise
                error('%s is an unkown operation in SELECT',opt_s.operation)
        end
    end
    if ~isempty(model.x)
        model.x = model.x(mask,:);
    end
    if ~isempty(model.y)
        model.y = model.y(mask,:);
    end
    model.labels_x = model.labels_x(mask);    
end

%% Orthogonalization of covariates
if ~isempty(opt.projection)&&isfield(opt.projection(1),'space')
   for num_e = 1:length(opt.projection)  
       if ~ismember('intercept',opt.projection(num_e).space)&&(~isfield(opt.projection(num_e),'flag_intercept')||opt.projection(num_e).flag_intercept)
           if ismember('intercept',model.labels_y)
               opt.projection(num_e).space = [opt.projection(num_e).space(:) ; {'intercept'}];
               mask_space = ismember(model.labels_y,opt.projection(num_e).space);
               x_space = x(:,mask_space);
           else
               mask_space = ismember(model.labels_y,opt.projection(num_e).space);
               x_space = [ones(size(model.x,1),1) model.x(:,mask_space)];
           end
       end
       if any(~ismember(opt.projection(num_e).space,model.labels_y))
           error('Could not find the covariates %s to perform a regression',opt.projection(num_e).space{1})
       end
       
       if ~isfield(opt.projection(num_e),'ortho')||isempty(opt.projection(num_e).ortho)
           opt.projection(num_e).ortho = setdiff(model.labels_y,opt.projection(num_e).space);
       end
       mask_ortho = ismember(model.labels_y,opt.projection(num_e).ortho);
       if any(~ismember(opt.projection(num_e).ortho,model.labels_y))
           error('Could not find the covariates %s to perform a regression',opt.projection(num_e).ortho{1})
       end       
       [B,E] = niak_lse(model.x(:,mask_ortho),x_space);
       model.x(:,mask_ortho) = E ;
       % normalization of covariates (again)
       model = sub_normalize(model,opt);
    end
end

%% Compute the interaction(s)
if ~isempty(opt.interaction)       
   for num_i = 1:length(opt.interaction)
       if iscellstr(opt.interaction(num_i).factor) && (length(opt.interaction(num_i).factor) > 1)      
          for num_u = 1:length(opt.interaction(num_i).factor)
              factor = opt.interaction(num_i).factor{num_u};
              mask   = strcmpi(factor, model.labels_y) ;
              ind    = find(mask == 1);
              if length(ind)>1
                  error('Attempt to define an interaction term using the label %s, which is associated with more than one covariate',factor)
              end
              % Optional : normalisation of the covariate, which is involved in this interaction, BEFORE building the crossproduct
              if isfield(opt.interaction(num_i),'flag_normalize_inter') && ~opt.interaction(num_i).flag_normalize_inter
                  fac_ind = model.x(:,ind);   
              else
                  opt_m.type = 'mean_var';
                  fac_ind = niak_normalize_tseries(model.x(:,ind));                
              end
              if num_u == 1 
                  col_inter = fac_ind;
              else              
                  col_inter = fac_ind.*col_inter ;
              end 
          end
          % Check if the column exist before adding a new column 
          mask = strcmpi(opt.interaction(num_i).label,model.labels_y);
          if ~any(mask) 
              model.labels_y{end+1} = opt.interaction(num_i).label;
              model.x = [model.x col_inter];      
          else 
             error('Attempt to define a new interaction term %s which was already found in the model',opt.interaction(num_i).label)
          end
      else 
          error('factor should be a cell of string and choose more than 1 factor ');
      end
   end
end 

%% Standardization of the model
model = sub_normalize(model,opt);

%% Additional intercept covariate
if opt.flag_intercept
    mask = strcmpi('intercept',model.labels_y);
    if ~any(mask) ||  isempty(mask) % mask =0 or when the model.labels_y= {} !
        model.labels_y = [{'intercept'}; model.labels_y(:)];
    end 
    if ~isempty(model.x)
        model.x = [ones([size(model.x,1) 1]) model.x];
    else
        model.x = ones(length(model.labels_x),1); 
    end       
end

%% Build the contrast vector and extract the associated covariates
list_cont = fieldnames(opt.contrast);
if opt.flag_intercept && ~isfield(opt.contrast,'intercept')
    list_cont = [{'intercept'} ; list_cont(:)];
    opt.contrast.intercept = 0;
end
x_cont = zeros(size(model.x,1),sum(ismember(model.labels_y,list_cont)));
model.c = zeros(size(x_cont,2),1);
labels_cont = cell(size(x_cont,2),1);
num_cov = 0;
for num_c = 1:length(list_cont)
    mask = strcmpi(list_cont{num_c},model.labels_y);
    if ~any(mask)
        error('Could not find the covariate %s listed in the contrast',list_cont{num_c});
    end
    x_cont(:,(num_cov+1):(num_cov+sum(mask))) = model.x(:,mask);
    model.c((num_cov+1):(num_cov+sum(mask))) = opt.contrast.(list_cont{num_c});
    labels_cont((num_cov+1):(num_cov+sum(mask))) = list_cont(num_c);
    num_cov = num_cov+sum(mask);
end
model.x = x_cont;
model.labels_y = labels_cont;

% Return
model_n = model;

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

function model = sub_normalize(model,opt)
%% Optional: normalization of covariates

if islogical(opt.normalize_x)&&opt.normalize_x
    opt_n.type = opt.normalize_type;  

    % because the normalization will give 0 il the nbr of rows = 1
    if (size(model.x,1) ~= 1)&&~isempty(model.x)
        model.x = niak_normalize_tseries(model.x,opt_n);
    end
elseif ~islogical(opt.normalize_x)
    opt_n.type = opt.normalize_type;  
    mask = ismember(model.labels_y,fieldnames(opt.normalize_x));
    model.x(:,mask) = niak_normalize_tseries(model.x(:,mask),opt_n);
end
mask = ismember(model.labels_y,'intercept');
model.x(:,mask) = 1;

if opt.normalize_y && isfield ( model, 'y' ) &&  (size(model.y,1) > 2) && ~isempty(model.x)
    opt_n.type = opt.normalize_type;  
    model.y = niak_normalize_tseries(model.y,opt_n);
end
