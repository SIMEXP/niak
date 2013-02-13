function [results,opt] = niak_glm(model,opt)
% Least-square estimates in a linear model Y = X.BETA + E 
%
% [RESULTS,OPT] = NIAK_GLM( MODEL , [OPT] )
%
% _________________________________________________________________________
% INPUTS:
%
% MODEL
%   (structure) with the following fields:
%
%   Y
%      (2D array size T*N) each column of Y are samples of one variable.
%
%   X
%      (2D array size T*K) each column of X is a explaining factor with the 
%      same number of rows as Y.
%
%   C
%      (vector, size K*1) is a contrast vector (necessary unless OPT.TEST
%      is 'none').
%
% OPT
%   (structure, optional) with the following fields:
%
%   TEST 
%      (string, default 'none') the type of test to be applied.
%      Available options: 'ttest' , 'ftest', 'none'
%
%   FLAG_RSQUARE
%      (boolean, default false) if the flag is true, the R2 statistics of the
%      regression is added to RESULTS (see below).
%
%   FLAG_RESIDUALS 
%      (boolean, default false) if the flag is true, the residuals E of the 
%      regression are added to RESULTS (see below).
%
%   FLAG_EFF
%      (boolean, default false) if the flag is true, the estimated effects are 
%      added to RESULTS (i.e. the regression coefficients times the contrast).
%
%   FLAG_BETA 
%      (boolean, default false) if the flag is true, the regression coefficients
%      BETA are added to RESULTS (see below).
%
% _________________________________________________________________________
% OUTPUTS:
%
% RESULTS
%   (stucture) with the following fields:
%
%   BETA
%      (vector size K*N) BETA(k,n) is the estimated coefficient regression 
%      estimate of X(:,k) on Y(:,n), using the least-square criterion.
%      See OPT.FLAG_BETA above.
%
%   E
%      (2D array, size T*N) residuals of the regression
%      See OPT.FLAG_RESIDUALS above.
%
%   STD_E
%      (vector, size [1 N]) STD_E(n) is an estimate of the standard deviation of
%      the noise Y(:,n). It is simply derived from the residual sum-of-squares
%      after correction for the number of degrees of freedom in the model.
%      (only available if OPT.TEST is 'ttest')
%
%   TTEST
%      (vector, size [1 N]) TTEST(n) is a t-test associated with the estimated
%      weights and the specified contrast (see C above). (only available if 
%      OPT.TEST is 'ttest')
%
%   FTEST
%      (vector, size [1 N]) TTEST(n) is a F test associated with the estimated
%      weights and the specified contrast (see C above). (only available if 
%      OPT.TEST is 'ftest')
%
%   PCE
%      (vector,size [1 N]) PCE(n) is the per-comparison error associated with 
%      TTEST(n) (bilateral test). (only available if OPT.TEST is 'ttest')
%
%   EFF
%      (vector, size [1 N]) the effect associated with the contrast and the 
%      regression coefficients (only available if OPT.TEST is 'ttest')
%
%   STD_EFF
%      (vector, size [1 N]) STD_EFF(n) is the standard deviation of the effect
%      EFF(n).
%
%   RSQUARE
%      (vector, size 1*N) The R2 statistics of the model (percentage of sum-of-squares
%      explained by the model).
%
% _________________________________________________________________________
% REFERENCES:
%
% On the estimation of coefficients and the t-test:
%
%   Statistical Parametric Mapping: The Analysis of Functional Brain Image.
%   Edited By William D. Penny, Karl J. Friston, John T. Ashburner,
%   Stefan J. Kiebel  &  Thomas E. Nichols. Springer, 2007.
%   Chapter 7: "The general linear model", S.J. Kiebel, A.P. Holmes.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : Statistics, General Linear Model, t-test, f-test

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
if (nargin<2)||(isempty(opt))
    opt = struct([]);
end

%% Default options
list_fields    = { 'flag_rsquare' , 'flag_eff' , 'flag_residuals' , 'flag_beta', 'test' };
list_defaults  = {  false         , false     , false           , false      , 'none' };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

y = model.y;
x = model.x;
[N,S] = size(y);
K = size(x,2);
if size(x,1)~=N
    error('X should have the same number of rows as Y');
end

beta = (x'*x)^(-1)*x'*y;         % Regression coefficients
e = y-x*beta;                    % Residuals

if isfield(opt,'test')
    switch opt.test

        case 'ttest'

            %% Perform a t-test
            if ~isfield(model,'c')
                error('Please specify MODEL.C for performing a t-test')
            end
            c = model.c;
            std_e = sqrt(sum(e.^2,1)/(N-K));        % Standard deviation of the noise

            d     = sqrt(c'*(x'*x)^(-1)*c);         % Intermediate result for the t-test
            ttest = (c'*beta)./(std_e*d);           % t-test
            pce = 2*(1-niak_cdf_t(abs(ttest),size(x,1)-size(x,2))); % two-tailed p-value
            eff = c'*beta;                          % The effect matrix

            std_eff = std_e*sqrt(c'*(x'*x)^(-1)*c); % The standard deviation of effect
            
            results.std_e = std_e;
            results.ttest = ttest;
            results.pce = pce;
            results.eff = eff;
            results.std_eff = std_eff;

        case 'ftest'

            %% Perform a F test
            if ~isfield(model,'c')
                error('Please specify MODEL.C for performing a F test')
            end
            c = model.c;
            s  = sum(e.^2,1);  % Estimate of the residual sum-of-square of the full model
            x0 = x(:,~model.c);
            p0 = size(x0,2);
            if p0>0
                beta0 = (x0'*x0)^(-1)*x0'*y; % Regression coefficients (restricted model)
                e0 = y-x0*beta0;             % Residuals (restricted model)
                s0 = sum(e0.^2,1); % Estimate of the residual sum-of-square of the restricted model
            else 
                s0 = sum(y.^2,1);
            end
            results.ftest=((s0-s)/(K-p0))./(s/(N-K)); % F-Test
            
        case 'none'
            
            % Do nothing
            results = struct();
            
        otherwise,
            error('This test is not supported');
    end
end


%% flags
if opt.flag_rsquare
    results.rsquare = 1 - (sum(e.^2,1)./sum((y-repmat(mean(y,1),[size(y,1) 1])).^2,1));
end
if opt.flag_residuals
    results.e = e;       % Residuals
end

if opt.flag_beta
    results.beta = beta; % Beta
end

if opt.flag_eff
    if ~isfield(model,'c')
        error('Please specify MODEL.C to estimate the effects')
    end        
    eff = (model.c)'*beta;                          % The effect matrix
    results.eff = eff; % Beta
end