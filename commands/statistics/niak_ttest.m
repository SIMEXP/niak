function [ttest_local,pvalues] = niak_ttest(X,Y,flag_two_tailed)

% Massively univariate t-tests.
%
% SYNTAX :
% [TTEST_LOCAL,PVALUES] = NIAK_TTEST(X,Y,FLAG_TWO_TAILED)
%
% _________________________________________________________________________
% INPUTS:
%
% X, Y
%   (data array, size T*N) Each column is a series of independent 
%   observations of a variable.
%   if only X is provided calculation are a One-sample t-test, if X and Y
%   are provided it's a two sample t-test with none equal variance and size. 
%
% FLAG_TWO_TAILED
%   
% _________________________________________________________________________
% OUTPUTS:
%
% TTEST_LOCAL
%   (data array, size T*N) a one sample t-test of significance of the mean 
%   of the columns of X against 0 (case where Y was not specified) OR a two
%   sample t-test on the difference of the mean of X and Y.
%
% PVALUES
%   (data array, size T*N) the probability of obtaining a test statistic at 
%   least as extreme as the one that was actually observed, assuming that 
%   the null hypothesis is true.
%
% _________________________________________________________________________
% COMMENTS:
%
% A positive t-test is for mean of Y greater than mean of X.
%
% Copyright (c) Christian L. Dansereau, Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : ttest
%
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

if nargin<3
    flag_two_tailed = true;
end

if nargin == 1
    t1 = size(X,1);
    ttest_local = (mean(X,1))./(std(X,[],1)./sqrt(t1));
    nans = isnan(ttest_local);
    ttest_local(nans)=0;
    
    if flag_two_tailed
        pvalues = 2*(1-niak_cdf_t(abs(ttest_local),t1-1)); % two-tailed p-value          
    else
        pvalues = niak_cdf_t(ttest_local,t1-1); % one-tailed p-value  
    end
    
    ttest_local(nans) = NaN;
    pvalues(nans) = NaN;
else
    t1 = size(X,1);
    t2 = size(Y,1);
    s1 = std(X,[],1); % unbiased variance estimatorof X
    s2 = std(Y,[],1); % unbiased variance estimatorof Y
    ttest_local = (mean(X,1)-mean(Y,1))./sqrt( (s1.^2)./t1 + (s2.^2)./t2 );
    nans = isnan(ttest_local);
    ttest_local(nans)=0;
    
    if nargout == 2
        df = ( ((s1.^2)./t1 + (s2.^2)./t2).^(2) ) ./ ( ((s1.^2)./t1 ).^(2) ./ (t1-1) + ((s2.^2)./t2 ).^(2) ./ (t2-1));
        if flag_two_tailed
            pvalues = 2*(1-niak_cdf_t(abs(ttest_local),df)); % two-tailed p-value 
        else
            pvalues = niak_cdf_t(ttest_local,df); % one-tailed p-value  
        end
    end
    ttest_local(nans) = NaN;
    pvalues(nans) = NaN;
end

    
