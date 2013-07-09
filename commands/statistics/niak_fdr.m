function [fdr,test] = niak_fdr(pce,method,q)
% Estimate the false-discovery rate in multiple families of tests 
%
% SYNTAX:
% [FDR,TEST] = NIAK_FDR( PCE , [METHOD] , [Q] )
%
% _________________________________________________________________________
% INPUTS:
%
% PCE
%   (array) A set of family of tests. PCE(i,j) is the per-comparison error of the 
%   ith test in the j-th family (aka the uncorrected p-value).
%
% METHOD
%   (string, default 'BY') the method to estimate the false-discovery rate.
%   Available options:
%       'BY' : The Benjamini-Yekutieli procedure, appropriate for dependent tests
%       'BH' : The Benjamini-Hochberg procedure, appropriate for independent tests 
%              (or positively correlated tests).
%       'TST' : The two-stage adaptative group BH procedure, with the two stage 
%               (TST) estimator of the number of discoveries.
%       'LSL' : The two-stage adaptative group BH procedure, with the least-slope
%               (LSL) estimator of the number of discoveries.
%
% Q
%   (scalar, default 0.05) the threshold on an acceptable level of false-discovery
%   rate.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FDR
%   (array) FDR(i,j) is the false-discovery rate associated with a threshold of 
%   PCE(i,j) in the j-th family (for 'BY' and 'BH'), or a global FDR after 
%   weighting each family by the number of potential discoveries ('GBH')
%
% TEST
%   (array) TEST(i,j) is 1 if FDR(i,j)<=Q, and 0 otherwise.
% 
% _________________________________________________________________________
% REFERENCES:
%
% On the estimation of the false-discovery rate for independent tests (BH):
%
%   Benjamini, Y., Hochberg, Y., (1995), "Controlling the false-discovery rate: 
%   a practical and powerful approach to multiple testing." 
%   J. Roy. Statist. Soc. Ser. B 57, 289-300.
%
% On the estimation of the false-discovery rate for dependent tests (BY):
%
%   Benjamini, Y., Yekutieli, D., (2001), "The control of the false discovery 
%   rate in multiple testing under dependency." 
%   The Annals of Statistics 29 (4), 1165-1188.
%
% On the least-slope estimator of the number of discoveries:
%
%   Benjamini, Y., Hochberg, Y., (2000), “On the Adaptive Control of the 
%   False Discovery Rate in Multiple Testing with Independent Statistics,” 
%   Journal of Educational and Behavioral Statistics, 25, 60-83.
% 
% On the two-stage estimator of the number of discoveries:
%
%   Benjamini, Y., Krieger, M. A., and Yekutieli, D. (2006), “Adaptive Linear 
%   Step-up Pocedures That Control the False Discovery Rate,” 
%   Biometrika, 93, 3, 491-507.
%
% On the group Benjamini-Hochberg procedure:
%
%   Hu, J. X., Zhao, H., Zhou, H. H. (2010), "False discovery rate control 
%   with groups". Journal of the American Statistical Association 105 (491), 
%   1215-1227. URL http://dx.doi.org/10.1198/jasa.2010.tm09329
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : false-discovery rate, false-positive rate

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
if nargin < 2
    method = 'BY';
end

if strcmp(method,'TST')
    method = 'GBH';
end

if nargin < 3
    q = 0.05;
end

if strcmp(method,'GBH')||strcmp(method,'LSL')

    n = size(pce,1);
    m = size(pce,2);
    % estimate the number of discoveries

    switch method
        case 'GBH'

            % The two-stage method: family-wise BH procedure
            q = q/(1+q);
            [fdr_bh,test_bh] = niak_fdr(pce,'BH',q); 
            pi_g_0 = (n-sum(test_bh,1))/n;        
  
        case 'LSL'

            % The least-slope method
            [val,order] = sort(pce,1,'ascend');            
            l = repmat((n+1-(1:n)'),[1 m]);
            l(val~=1) = l(val~=1)./(1-val(val~=1));
            l(val==1) = Inf;          
            dl = l(2:end,:) - l(1:(end-1),:);            
            pi_g_0 = zeros(m,1);
            for num_c = 1:m               
                ind_c = find(dl(:,num_c)>0,1);
                if isempty(ind_c)
                    ind_c = n-1;
                end
                pi_g_0(num_c) = min((floor(l(ind_c+1,num_c))+1)/n,1);
            end            
    end
    
    % weight the p-values based on the estimated number of discoveries
    pi_g_1 = 1-pi_g_0;
    pi_0 = mean(pi_g_0);
    w = zeros(1,m);
    w(pi_g_0~=1) = (1-pi_0) * pi_g_0(pi_g_0~=1)./pi_g_1(pi_g_0~=1);   
    w(pi_g_0==1) = Inf;    
    pce = pce.*repmat(w,[n 1]);
    
    % run a standard (global) BH procedure, with weighted p-values and modified FDR threshold
    if pi_0 == 1
       fdr = ones(size(pce));
       test = zeros(size(pce));
    else
       [fdr,test] = niak_fdr(pce(:),'BH',q);
       fdr = reshape(fdr,size(pce));
       test = reshape(test,size(pce));
    end
    return
end

[val,order] = sort(pce,1,'ascend');
n = size(pce,1);
fdr = zeros(size(pce));
ind = n./(1:n)';
w = sum((1:n).^(-1));
if nargout>1
    test = zeros(size(fdr));
end
for num_c = 1:size(pce,2)
    switch method
        case 'BY'
           fdr_c = w * ind.*val(:,num_c);
           fdr(order(:,num_c),num_c) = fdr_c;
        case 'BH'
           fdr_c = ind.*val(:,num_c);
           fdr(order(:,num_c),num_c) = fdr_c;
        otherwise
            error('%s is an unknown procedure for FDR estimation',method)
    end
    if nargout>1
        ind_c = find(fdr_c>q,1);
        if ind_c>1
            test(order(1:(ind_c-1),num_c),num_c) = 1;
        elseif isempty(ind_c)
            test(:,num_c) = 1;
        end
    end
end