function [model,labels_x,labels_y,contrast_vec] = niak_read_model(file_name,opt)
% Read a model from a CSV file and apply a number of preprocessing,
% such as centering covariates, adding an intercept, or othogonalizing
% parts of the model
%
% SYNTAX:
% [MODEL,LABELS_X,LABELS_Y,CONTRAST_VEC] = NIAK_READ_MODEL(FILE_NAME,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME
%    (string) the name of one or multiple CSV file. 
%    Example :
%              , SEX , HANDENESS
%    <SUBJECT> , 0   , 0 
%    This type of file can be generated with Excel (save under CSV).
%    Each column defines a covariate that can be used in a linear model.
% 
% OPT
%   (structure, optional) with the following fields:
%
%   LABELS_X
%	(cell of strings, default {}) The list of entries (rows) used 
%	to build the model. If left empty, all entries are used.
%
%   LABELS_Y
%       (cell of strings, default {}) a list of the covariates (columns)
%	involved in the model. If left empty, all covariates are used.
%
%   FLAG_INTERCEPT
%       (boolean, default true) if FLAG_INTERCEPT is true, a constant
%       covariate will be added to the model.
%
%   FLAG_NORMALIZE
%       (boolean, default true) if FLAG_NORMALIZE is true, the covariates
%       will be normalized to a zero mean and unit variance.
%
%   PROJECTION
%       (structure, optional) with multiple entries and the following 
%	    fields :
%
%       SPACE
%           (cell of strings) a list of the covariates that define the
%           space to project out from (i.e. the covariates in ORTHO, see 
%           below, will be projected in the space orthogonal to SPACE).
%
%       ORTHO
%           (cell of strings) a list of the covariates to project in
%           the space orthogonal to SPACE (see above).
%
%   CONTRAST
%       (structure, with the same fields as LABELS_Y)
%       OPT.CONTRAST is not used to build the model but it will be
%       re-arranged into a vector form compatible with MODEL (see
%       CONTRAST_VEC in the list of outputs below)
%
%       <NAME>
%          (scalar, default 0) the weight of the covariate NAME in the
%          contrast.
%
%   SELECT
%      (structure, optional) with multiple entries and the following
%      fields:
%
%      LABEL
%         (string) the covariate used to select entries.
%
%      VALUES
%         (vector, default []) a list of values to select (if empty, all
%         entries are retained).
%
%      MIN
%         (scalar, default []) only values higher (or equal) than MIN are 
%         retained.
%
%      MAX
%         (scalar, default []) only values lower (or equal) than MAX are 
%         retained. 
%
% _________________________________________________________________________
% OUTPUTS:
%
% MODEL
%   (matrix M*N) TAB(:,Y) is the Yth covariate of the model.
%
% LABELS_X
%   (cell of strings 1*M) LABELS_X{X} is the label of entry (line) X in the 
%   model.
%
% LABELS_Y
%	(cell of strings 1*N) LABELS_Y{Y} is the label of covariate Y in 
% 	the model
%
% CONTRAST_VEC
%   (vector, 1*K) CONTRAST_VEC(k) defines the weight of covariate number k in
%   the contrast of interest (see OPT.CONTRAST above).
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% The selection of entries by OPT.SELECT is applied iteratively, starting by
% OPT.SELECT(1), then OPT.SELECT(2), etc. Selection is performed on the raw
% values of the CSV file, not on normalized values.
%
% Copyright (c) Pierre Bellec, 
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : table, CSV

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

if ~exist(file_name,'file')
    error(cat(2,'Could not find any file matching the description ',file_name));
end

%% Options
list_fields   = { 'select' , 'contrast' , 'labels_x' , 'labels_y' , 'projection' , 'flag_intercept' , 'flag_normalize' };
list_defaults = { {}       , {}         , {}         , {}         , struct([])   , true             , true             };
if nargin > 1
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct,list_fields,list_defaults);
end

%% Read the model in CSV
[model_m,labels_m,labels_n] = niak_read_csv(file_name);

% Optional : select a subset of entries
if ~isempty(opt.select)
    for num_s = 1:length(opt.select)
        opt_s = psom_struct_defaults(opt.select(num_s),{'label','values','min','max'},{NaN,[],[],[]});
        mask = true([size(model_m,1) 1]);
        ind = find(ismember(labels_n,opt_s.label));
        if ~isempty(opt_s.values)
            mask = ismember(model_m(:,ind),opt_s.values);
        end
        if ~isempty(opt_s.min)
            mask = mask&(model_m(:,ind)>opt_s.min);
        end
        if ~isempty(opt_s.max)
            mask = mask&(model_m(:,ind)<opt_s.max);
        end
        model_m = model_m(mask,:);
        labels_m = labels_m(mask);
    end
end

% Default covariates/entries list
if isempty(opt.labels_x)
    labels_x = labels_m;
else
    labels_x = opt.labels_x;
end
if isempty(opt.labels_y)
    labels_y = labels_n;
else
    labels_y = opt.labels_y;
end
nx = length(labels_x);
ny = length(labels_y);

% Reorder the model using labels_x and labels_m
[mask_x,ind_m] = ismember(labels_x,labels_m);
[mask_y,ind_n] = ismember(labels_y,labels_n);
ind_err = find(mask_x == 0);
if ~isempty(ind_err)
    error('The following specified entry was not found in the model : %s',labels_x{ind_err(1)});
end
ind_err = find(mask_y == 0);
if ~isempty(ind_err)
    if (length(ind_err)>1)||~strcmp(labels_y{ind_err},'intercept')||~opt.flag_intercept
        error('The following specified covariate was not found in the model : %s',labels_y{ind_err(1)});
    end
end
ind_n = ind_n(ind_n~=0);
labels_y = labels_y(mask_y~=0);
model = model_m(ind_m,ind_n);

% Optional: additional intercept covariate
if opt.flag_intercept
    model = [ones([size(model,1) 1])/sqrt(size(model,1)) model];
    labels_y = [{'intercept'} ; labels_y(:)];
end

%% Optional: build the contrast vector
contrast_vec = zeros([length(labels_y) 1]);
for num_c = 1:length(labels_y)
    if isempty(opt.contrast)
        contrast_vec(num_c) = 1;
    else
        if isfield(opt.contrast,labels_y{num_c})
            contrast_vec(num_c) = opt.contrast.(labels_y{num_c});
        end
    end
end

% Optional: normalization of covariates
if opt.flag_normalize
    opt_n.type = 'mean_var';
    model = niak_normalize_tseries(model,opt_n);
    if opt.flag_intercept
        model(:,1) = 1/sqrt(size(model,1));
    end
end

% Optional: orthogonalization of covariates
if ~isempty(opt.projection)
    for num_e = 1:length(opt.projection);
        if isfield(opt.projection,'space')
            mask_space = ismember(labels_y,opt.projection(num_e).space);
            mask_ortho = ismember(labels_y,opt.projection(num_e).ortho);
            [B,E] = niak_lse(model(:,mask_ortho),model(:,mask_space));
            model(:,mask_ortho) = E;
            % Optional: normalization of covariates (again)
            if opt.flag_normalize
                opt_n.type = 'mean_var';
                model(:,mask_ortho) = niak_normalize_tseries(model(:,mask_ortho),opt_n);
                if opt.flag_intercept
                    model(:,1) = 1/sqrt(size(model,1));
                end
            end
        end
    end
end
