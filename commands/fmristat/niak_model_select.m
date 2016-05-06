function [labels_x,ind_x,model_select] = niak_model_select (model, opt)
% Select entries in a linear model
% [LABELS_X,IND_X] = NIAK_MODEL_SELECT( MODEL , OPT )
%
% MODEL.X        (matrix M*K) the covariates (observations x covariates)
% MODEL.Y        (matrix M*N, default []) the data (observations x units)
% MODEL.LABELS_X (cell of strings 1xM) LABELS_X{M} is the label of the Mth observation.
% MODEL.LABELS_Y (cell of strings 1*K) LABELS_Y{K} is the label of the Kth covariate
%
% OPT.SELECT
%   (structure, optional) with multiple entries and the following fields:           
%   LABEL  (string) the covariate used to select entries *before normalization*
%   VALUES (vector, default []) a list of values to select (if empty, all entries are retained).
%   MIN (scalar, default []) only values higher (strictly) than MIN are retained.
%   MAX (scalar, default []) only values lower (strictly) than MAX are retained. 
%   OPERATION (string, default 'or') the operation that is applied to select the frames.
%      Available options:
%      'or' : merge the current selection SELECT(E) with the result of the previous one.
%      'and' : intersect the current selection SELECT(E) with the result of the previous one.
% OPT.FLAG_FILTER_NAN (boolean, default true) if the flag is true, any observation associated with a NaN in 
%   MODEL.X is removed from the model. 
% OPT.LABELS_X (cell of strings, default {}) The list of entries (rows) used 
%   to build the model (the order will be used as well). If left empty, 
%   all entries are used. 
% OPT.LABELS_Y (cell of strings) the list of covariates (columns) to be included in the model. 
%   If left empty, all covariates are used.
%
% LABELS_X (cell of strings) same as MODEL.LABELS_X, but filtered and re-ordered based 
%   on OPT.
% IND_X (vector) the indices of extracted rows, i.e. LABELS_X = MODEL.LABELS_X(IND_X);
% MODEL_SELECT (array) same as MODEL.X, but filtered and re-ordered based
%   on OPT.
%
% COMMENTS:
%   In the selection process, if several covariates are associated with OPT.SELECT.LABEL, 
%   the final selection will be the intersection of all selections performed with individual
%   covariates associated with the label.
%
%   For each entry in select, the VALUES, MIN and MAX filtering are applied sequentially, 
%   in that order. The different entries of select are aso applied sequentially in the 
%   specified order. 
%
% Copyright (c) Pierre Bellec, Jalloul Bouchkara
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : general linear model

%% Check the model
list_fields   = { 'x' , 'y' , 'labels_x' , 'labels_y' };
list_defaults = { NaN , []  , NaN        , NaN        };
model = psom_struct_defaults(model,list_fields,list_defaults);

%% Check the options
list_fields   = { 'flag_filter_nan' , 'select' , 'labels_y' , 'labels_x' };
list_defaults = { true              , struct   , {}         , {}         };
if nargin > 1
   opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
   opt = psom_struct_defaults(struct,list_fields,list_defaults);
end

%% Reorder (and reduce) the model using opt.labels_x 
labels_x_raw = model.labels_x;
if ~isempty(opt.labels_x)
    if length(unique(opt.labels_x))~=length(opt.labels_x)
        error('The labels provided in OPT.LABELS_X should be unique')
    end
    [mask_x,ind_m] = ismember(opt.labels_x,model.labels_x) ; 
    if any(ind_m==0)
        ind_0 = find(ind_m == 0);
        fprintf('Warning: the following entries (rows) in the model were not associated with any data and will be omitted:\n')
        for num_m = 1:length(ind_0)
            fprintf('    %s\n',opt.labels_x{ind_0(num_m)});
        end
    end
    ind_m = ind_m(ind_m~=0);

    labels_x = {};
    ind_x = [];
    x_tmp = [];
    y_tmp = [];
    model.labels_x = model.labels_x(:);
    model.labels_y = model.labels_y(:);

    for num_m = 1:length(ind_m)
        mask_tmp = ismember(model.labels_x,model.labels_x{ind_m(num_m)});
        ind_x = [ ind_x ; find(mask_tmp) ];
        labels_x = [ labels_x ; model.labels_x(mask_tmp)];
        if ~isempty(model.x)
            x_tmp = [x_tmp ; model.x(mask_tmp,:)];
        end
        if ~isempty(model.y)
            y_tmp = [y_tmp ; model.y(mask_tmp,:)];
        end
    end
else 
    labels_x = model.labels_x(:);
    ind_x = (1:length(labels_x))';
end

%% Select a subset of entries
model.labels_x = labels_x;
if ~isempty(model.x);
    model.x = model.x(ind_x,:);
end
if ~isempty(model.y)
    model.y = model.y(ind_x,:);
end
if isfield(opt.select(1),'label')
    for num_s = 1:length(opt.select)
        if ~isfield(opt.select(num_s),'label')
           continue
        end
        opt_s = psom_struct_defaults(opt.select(num_s),{'label','values','min','max','operation'},{NaN,[],[],[],'or'}); 
        if isempty(opt_s.operation)
            opt_s.operation = 'or';
        end
        if strcmp(opt_s.operation,'or')&&(num_s==1)
            mask = false([size(model.labels_x,1) 1]);
        elseif strcmp(opt_s.operation,'and')&&(num_s==1)
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
    labels_x = labels_x(mask);
    ind_x = ind_x(mask);
end

%% Keep only variables of interest in the model
if isempty(opt.labels_y)
    list_cont = model.labels_y;
else 
    list_cont = opt.labels_y;
end
mask_var = ismember(model.labels_y,list_cont);
model.x = model.x(:,mask_var);
model.labels_y = model.labels_y(mask_var);

model_select = model.x;

%% Filter out the NaN entries
if (opt.flag_filter_nan)&&~isempty(model.x)
    mask_nan = max(isnan(model.x),[],2);    
    if any(mask_nan)
        warning('The following entries were suppressed because they were associated to NaNs')
        char(model.labels_x{mask_nan})
    end    
    labels_x = labels_x(~mask_nan);
    ind_x = ind_x(~mask_nan);
end