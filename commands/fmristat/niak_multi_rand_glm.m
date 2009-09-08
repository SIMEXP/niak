function [stats_vol] = niak_multi_rand_glm(vol,varatio_vol,opt)
% _________________________________________________________________________
% SUMMARY NIAK_MULTI_RAND_GLM
%
% Estimates a random effects linear model.
% 
% SYNTAX:
% STATS_VOL = NIAK_MULTI_RAND_GLM(VOL,VARATIO_VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (4D array) a 3D+t dataset
%
% VARATIO_VOL
%       (3D array) the ratio of the random effects variance divided by the 
%       fixed effects variance.
%
% OPT         
%     structure with the following fields :
%
%     MATRIX_X 
%           is the design matrix, whose rows are the files, and columns
%           are the explanatory (independent) variables of interest. 
%           Default is X=[1; 1; 1; ..1] which just averages the files. 
%           If the rank of X equals the number of files, e.g. if X is square, 
%           then the random effects cannot be estinmated, but the fixed effects
%           sd's can be used for the standard error. This is done very quickly.
%
%     CONTRAST 
%           is a matrix whose rows are contrasts for the statistic images.
%           Default is [1 0 ... 0], i.e. it picks out the first column of X.
%
%     WHICH_STATS
%           Number of contrasts x 9 binary matrix correspondings to the 
%           desired statistical outputs

% _________________________________________________________________________
% OUTPUTS:
%
% STATS_VOL      
%       (4D array) 3D + number of stats dataset
%       Estimated parameters of the random effect lineal model.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is a NIAKIFIED port of a part of the MULTISTAT function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, 2009.
% Maintainer : felix.carbonell@mail.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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

gb_name_structure = 'opt';
gb_list_fields = {'matrix_x','contrast','which_stats','df','fwhm'};
gb_list_defaults = {NaN,NaN,NaN,NaN,NaN};
niak_set_defaults

matrix_x = opt.matrix_x;
X2 = matrix_x'.^2;
contrast = opt.contrast;
which_stats = opt.which_stats;
df = opt.df;
fwhm = opt.fwhm;
numcontrasts = size(contrast,1);


[nx,ny,nz,n] = size(vol.ef);
numpix = nx*ny;

pinvX = pinv(matrix_x);
ncpinvX = sqrt(sum((contrast*pinvX).^2,2));

% Second loop over voxels to get statistics:
for k=1:nz
    Y = squeeze(vol.ef(:,:,k,:));
    Y = (reshape(Y,numpix,n))';
    if ~isempty(vol.sd)
       S = squeeze(vol.sd(:,:,k,:));
       S = (reshape(S,numpix,n))'; 
       S = S.^2;
       varfix = df.data*S/df.fixed;
       sigma2 = varatio_vol(:,k)'.*varfix;
       Sigma = S+repmat(sigma2,n,1);
       % To ensure that Sigma is always positive:
       if fwhm.varatio>0
           Sigma = max(Sigma,S*0.25);
       end
       W = (Sigma>0)./(Sigma+(Sigma<=0));
       if size(matrix_x,2)==1
           % Do calculations in parallel:
           X2W = X2*W;
           XWXinv = (X2W>0)./(X2W+(X2W<=0));
           betahat = XWXinv.*(matrix_x'*(W.*Y));
           sdeffect_slice = contrast*sqrt(XWXinv);
       else
           % Loop over pixels:
           betahat = zeros(size(matrix_x,2),numpix);
           sdeffect_slice = zeros(numcontrasts,numpix);
           for pix = 1:numpix
               Whalf = diag(sqrt(W(:,pix)));
               pinvX = pinv(Whalf*matrix_x);
               betahat(:,pix) = pinvX*Whalf*Y(:,pix);
               sdeffect_slice(:,pix) = sqrt(sum((contrast*pinvX).^2,2));
           end
       end
    else
       betahat = pinvX*Y;
       sigma2 = varatio_vol(:,k)';  
       sdeffect_slice = ncpinvX*sqrt(sigma2);
       Sigma = repmat(sigma2,n,1);
       W = (Sigma>0)./(Sigma+(Sigma<=0)); 
    end
    effect_slice = contrast*betahat;
    tstat_slice = effect_slice./(sdeffect_slice+(sdeffect_slice<=0)) ...
         .*(sdeffect_slice>0);
    sdratio_slice = sqrt(varatio_vol(:,k)+1);
    resid_slice = Y-matrix_x*betahat;
    wresid_slice= sqrt(W/df.resid).*resid_slice;
   for k_cont=1:numcontrasts
      if which_stats(k_cont,1)
         tstat_slice=min(tstat_slice,100);
         stats_vol.t(:,:,k,k_cont) = reshape(tstat_slice(k_cont,:),nx,ny);
      end
      if which_stats(k_cont,2)
         stats_vol.ef(:,:,k,k_cont) = reshape(effect_slice(k_cont,:),nx,ny); 
      end
      if which_stats(k_cont,3)
         stats_vol.sd(:,:,k,k_cont) = reshape(sdeffect_slice(k_cont,:),nx,ny); 
      end
   end
   if any(which_stats(:,4))
     stats_vol.rfx(:,:,k) = reshape(sdratio_slice,nx,ny); 
   end
   if any(which_stats(:,5))
     stats_vol.conj(:,:,k) = reshape(min(sqrt(W).*Y,[],1),nx,ny); 
   end
   if which_stats(1,6)
      stats_vol.resid(:,:,k,:) = reshape(resid_slice',nx,ny,n);  
   end  
   if which_stats(1,7) 
      stats_vol.wresid(:,:,k,:) = reshape(wresid_slice',nx,ny,n);   
   end
end
