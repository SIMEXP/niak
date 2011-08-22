function [beta,e,std_e,ttest] = niak_lse(y,x,c,flag_james_stein)
% Least-square estimates in a linear model Y = X*BETA + E 
%
% [BETA,E,STD_E,TTEST] = NIAK_LSE(Y,X,C)
%
% _________________________________________________________________________
% INPUTS:
%
% Y
%   (2D array size T*N) each column of Y are samples of one variable.
%
% X
%   (2D array size T*K) each column of X is a explaining factor with the 
%   same number of rows as Y.
%
% C
%   (vector, size K*1, default ones([K 1])) C(K) is the weight of
%   X(:,K) in the t-test (see TTEST below).
%
% FLAG_JAMES_STEIN
%   (boolean, default false) if FLAG_JAMES_STEIN is true and the number
%   of covariates is larger (or equal) than 3, a James-Stein correction
%   will be applied on the regression coefficients.
%
% _________________________________________________________________________
% OUTPUTS:
%
% BETA
%   (vector size K*N) BETA(k,n) is the estimated coefficient regression 
%   estimate of X(:,k) on Y(:,n), using the least-square criterion.
%
% E
%   (2D array, size T*N) residuals of the regression
%
% STD_E
%   (vector, size [1 N]) STD_E(n) is an estimate of the standard deviation of
%   the noise Y(:,n). It is simply derived from the residual sum-of-squares
%   after correction for the number of degrees of freedom in the model.
%
% TTEST
%   (vector, size [1 N]) TTEST(n) is a t-test associated with the estimated
%   weights and the specified contrast (see C above).
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
% On the James-Stein shrinkage correction:
%
%   Judge GG, Hill CR, Bock ME. An adaptive empirical Bayes estimator
%   of the multivariate normal mean under quadratic loss. J Econom
%   1990;44:189–213.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : Statistics, General Linear Model

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

[N,S] = size(y);
K = size(x,2);
if (nargin < 3) || isempty(c)
    c = ones([K 1]);
end
if nargin < 4
    flag_james_stein = false;
end
if size(x,1)~=N
    error('X should have the same number of rows as Y');
end
beta = (x'*x)^(-1)*x'*y; % Regression coefficients
if nargout > 1
    e = y-x*beta; % Residuals
end
if (nargout > 2) || flag_james_stein
    std_e = sqrt(sum(e.^2,1)/(N-K)); % Standard deviation of the noise
end
if (nargout > 3)
    d     = sqrt(c'*(x'*x)^(-1)*c);  % Intermediate result for the t-test
    ttest = (c'*beta)./(std_e*d);       % t-test
end
if (K>=3) && flag_james_stein
    % If there are more than 3 covariates and the user specified so, apply a James-Stein correction
    a = 1-((K-2)*(N-K)*std_e.^2)./((N-K+2)*sum(beta.*(x'*x*beta),1));
    a = max(0,a);
    beta = repmat(a,[K 1]).*beta;
end
