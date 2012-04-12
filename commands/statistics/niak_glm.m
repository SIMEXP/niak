function [results,opt] = niak_glm(model,opt)
% Least-square estimates in a linear model Y = X.BETA + E 
%
% [RESULTS,OPT] = NIAK_GLM( MODEL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   MODEL
%
%       Y
%           (2D array size T*N) each column of Y are samples of one variable.
%
%       X
%           (2D array size T*K) each column of X is a explaining factor with the 
%           same number of rows as Y.
%
%       C
%           (vector, size K*1) is a contrast matrix for the f-test and a
%           vector for the t-test.
%
% _________________________________________________________________________
% OUTPUTS:
%
% RESULTS
%
%    BETA
%        (vector size K*N) BETA(k,n) is the estimated coefficient regression 
%        estimate of X(:,k) on Y(:,n), using the least-square criterion.
%
%    E
%        (2D array, size T*N) residuals of the regression
%
%    STD_E
%        (vector, size [1 N]) STD_E(n) is an estimate of the standard deviation of
%        the noise Y(:,n). It is simply derived from the residual sum-of-squares
%        after correction for the number of degrees of freedom in the model.
%
%    TTEST
%        (vector, size [1 N]) TTEST(n) is a t-test associated with the estimated
%        weights and the specified contrast (see C above).
%
%    PCE
%        (vector,size [1 N]) PCE(n) is the per-comparison error associated with 
%        TTEST(n) (bilateral test).
%
%    EFF
%        (vector, size [1 N]) the effect associated with the contrast and the 
%        regression coefficients.
%
%    STD_EFF
%        (vector, size [1 N]) STD_EFF(n) is the standard deviation of the effect
%        EFF(n).
%
% _________________________________________________________________________
% OPT:
%
%   TEST (default, ttest) specify the test to be applied (ttest,ftest)
%
%   FLAG_RESIDUALS (default, false)
%
%   FLAG_BETA (default, false)
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
% Copyright (c) Christian L. Dansereau, 
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
if isempty(opt)
    opt = struct([]);
end

list_fields    = { 'flag_residuals' , 'flag_beta', 'test'};
list_defaults  = {  false           , false      , ''    };
opt = psom_struct_defaults(opt,list_fields,list_defaults);



y = model.y;
x = model.x;

[N,S] = size(y);
K = size(x,2);
if isfield(model,'c') && ~isempty(model.c)
    c = model.c;
end

if size(x,1)~=N
    error('X should have the same number of rows as Y');
end

beta = (x'*x)^(-1)*x'*y;         % Regression coefficients
e = y-x*beta;                    % Residuals

if isfield(opt,'test')
    switch opt.test

        case 'ttest',
            if ~isfield(model,'c') || isempty(model.c)
                c=ones(size(x,2),1);
            end
            
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

        case 'ftest',
            if ~isfield(model,'c') || isempty(model.c)
                c = [zeros(K-1,1),eye(K-1)];
            end
            
            x0 = x*c';
            [p0]=size(x0,2);

            beta0 = (x0'*x0)^(-1)*x0'*y;       % Regression coefficients
            e0 = y-x0*beta0;                   % Residuals
            s0 = sqrt(sum(e0.^2,1)/(N-p0))+eps;    % Estimate of the std0
            s = sqrt(sum(e.^2,1)/(N-K))+eps;       % Estimate of the std
            
%            s0 = sqrt(e0'*e0/(N-p0));         % Estimate of the std0
%            s = sqrt(e'*e/(N-K));             % Estimate of the std
        
            results.ftest=(s0-s)./(s.^2);      % F-Test
            

        case '',
            
            % Do nothing
            
        otherwise,
            error('This test is not supported');
    end
end


%% flags
if opt.flag_residuals
    results.e = e;       % Residuals
end

if opt.flag_beta
    results.beta = beta; % Beta
end

