function [p,model_w] = niak_white_test_hetero(model,opt)
% White's test of heteroscedasticity in a linear model
%
% SYNTAX:
% [p,model_w] = niak_white_test_hetero(model)
%
% _________________________________________________________________________
% INPUTS:
%
% MODEL
%   (structure) with the following fields:
%
%   Y
%      (2D array size T*N) each column of Y are observations of one variable.
%
%   X
%      (2D array size T*K) each column of X is a explaining factor with the 
%      same number of rows as Y.
%
%   LABELS_X
%      (cell of strings, optional) LABELS_X{T} is the label of observation T, 
%      associated with X(T,:) and Y(T,:). By default the label is 'sampT'
%
%   LABELS_Y
%      (cell of strings, optional) LABELS_Y{K} is the label of covariate K,
%      associated with X(:,K). By default the label is 'covK'.
%
%   MASK_TEST
%      (vector, boolean, size K*1, default true) a binary mask of the covariates 
%      that are suspected to cause heteroskedasticity. By default the whole model X
%      is used.
%
% _________________________________________________________________________
% OUTPUTS:
%
% P
%   (vector N*1) the p-value associated with the White's test at each variable.
%
% MODEL_W
%   (structure) the model used for the white's test, with the following fields:
%
%   X
%      (2D array) the covariates used to perform the white's test (i.e. intercept,
%      the covariates X(:,MASK_TEST), the square version of X_TEST, as well as all the 
%      interaction terms)
%
%   Y
%      (2D array size T*N) the square of the residuals of the ols regression with MODEL.
%
%   LABELS_X
%      (cell of strings, optional) Identical to MODEL.LABELS_X.
%
%   LABELS_Y
%      (cell of strings, optional) LABELS_Y{K} is the label of covariate K,
%      associated with MODEL_W.X(:,K). Labels are derived from MODEL.LABELS_X.
%      Interaction terms are noted LABEL1_x_LABEL2 and squared terms are 
%      labeled LABEL.^2. The intercept is labeled 'intercept'.
%
% _________________________________________________________________________
% REFERENCE:
%
% H. White, “A Heteroscedasticity Consistent Covariance Matrix Estimator and a 
% Direct Test of Heteroscedasticity,’’ Econometrica, vol. 48, 1980, pp. 817–818.
%
% See also:
% D. Gujarati. Basic Econometrics, 4th Ed. Chap. 11 p. 413.
%
% _________________________________________________________________________
% DEMO:
%  
% Generate samples with a gross heteroscedasticity:
%
% model.x = [ones(100,1) [zeros(50,1) ; ones(50,1)] randn([100 1])];
% model.y = model.x * rand(size(model.x,2),2000) + [0.1*randn(50,2000) ; randn(50,2000)];
% [p,model_w] = niak_white_test_hetero(model);
% hist(p,100)
%
% Now the same one for an homoscedastic model:
%
% model.x = [ones(100,1) [zeros(50,1) ; ones(50,1)] randn([100 1])];
% model.y = model.x * rand(size(model.x,2),2000) + randn(100,2000);
% [p,model_w] = niak_white_test_hetero(model);
% hist(p,100)
%_________________________________________________________________________
% COMMENTS:
%
% White's test consist in performing an ordinary least-squares linear regression
% with a model, and then try to regress the same model (or a subset of variables
% that can cause heteroskedasticity) on the squares of the residuals. The overall
% significance of this second regression is tested with a R square.
%
% The interaction terms are added one by one to the model, followed by the squared
% model. At every attempt to add a covariate, the function checks that the resulting
% model is not degenerate using RCOND on the cross-product matrix.
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : Statistics, General Linear Model, heteroskedasticity, White's test

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

%% Default model
list_fields    = { 'x' , 'y' , 'mask_test' , 'labels_x' , 'labels_y' };
list_defaults  = { NaN , NaN , []          , {}         , {}         };
model = psom_struct_defaults(model,list_fields,list_defaults);

if isempty(model.mask_test)
    model.mask_test = true(size(model.x,2),1);
end

if isempty(model.labels_x)
    model.labels_x = cell(size(model.x,1),1);
    for num_t = 1:size(model.x,1)
        model.labels_x{num_t} = sprintf('samp%i',num_t);
    end
end

if isempty(model.labels_y)
    model.labels_y = cell(size(model.x,2),1);
    for num_k = 1:size(model.x,2)
        model.labels_y{num_k} = sprintf('cov%i',num_k);
    end
end

%% Run an ordinary least-squares estimation of the residuals of the model
glm = rmfield(model,'mask_test');
opt_glm.flag_residuals = true;
res_glm = niak_glm(glm,opt_glm);

%% The white model_w
model_w.y = (res_glm.e).^2;
model_w.x = model.x(:,model.mask_test);
model_w.labels_x = model.labels_x;
model_w.labels_y = model.labels_y(model.mask_test);
model_w = sub_square_model(model_w);

%% Run an ordinary least-squares for the regression of the square model on the squares of the residuals
opt_glm = struct;
opt_glm.flag_rsquare = true;
res_w = niak_glm(model_w,opt_glm);

%% Test the rsquare
chi2_w = size(model.x,1)*res_w.rsquare
p = 1-chi2cdf(chi2_w,size(model_w.x,2)-1);

end

%% SUBFUNCTIONS

function model_s = sub_square_model(model)
% Add the square of the covariates as well as the interaction terms in a model. Always add an intercept. 
% That's equivalent to the x2fx function in Matlab. 

mask_intercept = min(model.x == repmat(model.x(1,:),[size(model.x,1) 1]),[],1);
model_s = model;
if any(mask_intercept)
    model_s.x = model.x;
    model_s.labels_y = model.labels_y;
else
    model_s.x = [ones(size(model.x,1),1) model.x];
    model_s.labels_y = [{'intercept'} ; model.labels_y(:)];
end

%% Initialize the model

%% Add interaction terms
k = size(model.x,2);
num_c = 0;
for num_k = 1:k
    for num_l = num_k+1:k
        model_tmp = [model_s.x model.x(:,num_k).*model.x(:,num_l)];
        if rcond(model_tmp'*model_tmp)>0.01
            model_s.x = model_tmp;
            model_s.labels_y{end+1} = [model.labels_y{num_k} '_x_' model.labels_y{num_l}];
        end
    end
end

%% Add squared terms
for num_e = 1:size(model.x,2)
    model_tmp = [model_s.x model.x(:,num_e).^2];
    if (rcond(model_tmp'*model_tmp)>0.01)&&(length(unique(model.x(:,num_e)))>2)
        model_s.x = model_tmp;
        model_s.labels_y{end+1} = [model.labels_y{num_e} '.^2'];
    end
end
end