function [results,opt] = niak_glm_multisite(model,opt)
% Least-square estimates in a linear model Y = X.BETA + E 
%
% [RESULTS,OPT] = NIAK_GLM_MULTISITE( MODEL , [OPT] )
%
% _________________________________________________________________________
% INPUTS:
%
% MODELS (multiple models can be provided)
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
%   MULTISITE
%      (vector optional) When provided this vector code for the various
%      sites and the glm will be corrected in function of those sites. 0 is
%      an excluded entry and all other values are considered as sites id's.
%
% _________________________________________________________________________
% OUTPUTS:
%
% RESULTS
%   (stucture) with the following fields:
%
%   SINGLE_SITE
%      (structure) Containing the output of niak_glm for each site.
%
%   E
%      (2D array, size T*N) residuals of the regression
%      See OPT.FLAG_RESIDUALS above.
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
% Copyright (c) Christian L. Dansereau, Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2014.
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
list_fields    = { 'flag_verbose', 'test' , 'multisite'};
list_defaults  = {  true         , 'ttest', []         };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% y = model.y;
% x = model.x;
% [N,S] = size(y);
% K = size(x,2);
% if size(x,1)~=N
%     error('X should have the same number of rows as Y');
% end
  
if ~isempty(opt.multisite) && size(model,2)<2
    
    list_site = unique(opt.multisite);
    list_site = list_site(list_site>0); % remove site zero  corresponding to excluded site

    %% make the models
    k=0;
    for ss = 1:length(list_site)

        site = list_site(ss);
        mask_site = (opt.multisite == site);

        x1 = model.x(mask_site,:);
        %% Normalize
        x1 = niak_normalize_tseries(x1,'mean');
        x1 = [ones(size(x1,1),1),x1]; % add intercept;
        c  = model.c;
        c = [0;c];

        if(sum(x1(:,2)==x1(:,4))/size(x1,1)) < 1 % to prevend degenerated model
            
            k=k+1;
            multisite.model(k).c = c;
            multisite.model(k).x = x1;
            multisite.model(k).y = model.y(mask_site,:);
            
        end

    end
    model = multisite.model;
end
    
%% Compute the models
for ss = 1:size(model,2)
    if opt.flag_verbose
        fprintf('Estimate model site %i ...\n',ss)
    end
    opt_glm_gr = rmfield(opt,{'flag_verbose','multisite'});
    %% Estimate the group-level model -- single site data
    y_x_c.x = model(ss).x;
    y_x_c.y = model(ss).y;
    y_x_c.c = model(ss).c; 
    [multisite.results(ss), opt_glm_gr] = niak_glm(y_x_c , opt_glm_gr);
end
       
    if size(model,2)>1
        
        eff = zeros(size(multisite.results(ss).eff));
        std_eff = zeros(size(multisite.results(ss).std_eff));

        for ss = 1:size(model,2)
            eff = eff + (multisite.results(ss).eff./(multisite.results(ss).std_eff).^2);
            std_eff = std_eff + (1./(multisite.results(ss).std_eff).^2);
        end

        %% Multisite stats
        eff     = eff ./ std_eff;
        std_eff = sqrt(1./std_eff);
        ttest   = eff./std_eff;
        pce     = 2*(1-normcdf(abs(ttest)));
        
        results.ttest   = ttest;
        results.pce     = pce;
        results.eff     = eff;
        results.std_eff = std_eff;
        
    else
        %% Single site
        results = multisite.results;
    end
    
    
    results.single_site = multisite;
   

