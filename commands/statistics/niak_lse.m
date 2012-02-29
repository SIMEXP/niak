function [beta,e,std_e,ttest,pce,eff,std_eff] = niak_lse(y,x,c)
% Least-square estimates in a linear model Y = X.BETA + E 
%
% [BETA,E,STD_E,TTEST,PCE,EFF,STD_EFF] = NIAK_LSE( Y , X , [C] )
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
% PCE
%   (vector,size [1 N]) PCE(n) is the per-comparison error associated with 
%   TTEST(n) (bilateral test).
%
% EFF
%   (vector, size [1 N]) the effect associated with the contrast and the 
%   regression coefficients.
%
% STD_EFF
%   (vector, size [1 N]) STD_EFF(n) is the standard deviation of the effect
%   EFF(n).
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

if size(x,1)~=N
    error('X should have the same number of rows as Y');
end
beta = (x'*x)^(-1)*x'*y; % Regression coefficients
if nargout > 1
    e = y-x*beta; % Residuals
end

if (nargout > 2) 
    std_e = sqrt(sum(e.^2,1)/(N-K)); % Standard deviation of the noise
end

if (nargout > 3)
    d     = sqrt(c'*(x'*x)^(-1)*c);  % Intermediate result for the t-test
    ttest = (c'*beta)./(std_e*d);       % t-test
end

if (nargout > 4) % two-tailed p-value
    pce = 2*(1-niak_cdf_t(abs(ttest),size(x,1)-size(x,2)));
end

if (nargout > 5) % The effect matrix
    eff = c'*beta;
end

if (nargout > 6) % The standard deviation of effect
    std_eff = std_e*sqrt(c'*(x'*x)^(-1)*c);
end
