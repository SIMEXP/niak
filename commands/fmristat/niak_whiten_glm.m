function [stats_vol] = niak_whiten_glm(vol,rho_vol,opt)
% _________________________________________________________________________
% SUMMARY NIAK_WHITEN_GLM
%
% Estimates the parameters of the GLM based on the whitened residuals
% obtained from a linear autoregressive model.
% 
% SYNTAX:
% [STATS_VOL] = NIAK_WHITEN_GLM(VOL,RHO_VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (4D array) a 3D+t dataset
%
% RHO_VOL      
%       (4D array) 3D + numlags dataset
%       Estimated parameters of the autoregressive lineal model.
%
% OPT         
%       structure with the following fields :
%
%       MATRIX_X
%            Full design matrix of the model, obtained from
%            nial_full_design
%
%       SPATIAL_AV
%            colum vector of the spatial average time courses, obtained
%            from niak_make_trends.
%
%       PCNT: 
%           if PCNT=1(Default), then the data is converted to percentages 
%           before analysis by dividing each frame by its spatial average,* 100%.
%
%       EXCLUDE: 
%           is a list of frames that should be excluded from the analysis. 
%           Default is [].
%
%       NUMLAGS
%           (integer, default 1) The order (p) of the autoregressive model.
%
%       NUM_HRF_BASES
%           row vector indicating the number of basis functions for the hrf 
%           for each response, either 1 or 2 at the moment. At least one basis 
%           functions is needed to estimate the magnitude, but two basis functions
%           are needed to estimate the delay.
%
%       NB_RESPONSE
%           number of respnses in the model, determined by the matrix x_cache
%           with niak_fmridesign.
%
%       NUMTRENDS
%           number of trends in the model.
%
%       CONTRASTS       
%       updated matrix of full contrasts of the model.
%
%       WHICH_STATS
%            Number of Contrasts X 9 binary matrix correspondings to the 
%            desired statistical outputs
%
%       CONTRAST_IS_DELAY
%            Binary vector specifying the desired contrasts for delays 
%            
% _________________________________________________________________________
% OUTPUTS:
%
% STATS_VOL      
%       (4D array) 3D + number of stats dataset
%       Estimated parameters of the autoregressive lineal model.
% _________________________________________________________________________
% COMMENTS:
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
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
gb_list_fields = {'matrix_x','spatial_av','pcnt','exclude','numlags',...
    'num_hrf_bases','nb_response','nb_trends','contrasts','which_stats','contrast_is_delay'};
gb_list_defaults = {NaN,[],0,[],1,NaN,NaN,NaN,NaN,NaN,NaN};
niak_set_defaults

matrix_x = opt.matrix_x;
spatial_av = opt.spatial_av;
ispcnt = opt.pcnt;
numlags = opt.numlags;
num_hrf_bases = opt.num_hrf_bases;
numresponses = opt.nb_response;
numtrends = opt.nb_trends(1) + opt.nb_trends(2);
contrasts = opt.contrasts;
which_stats = opt.which_stats;
contrast_is_delay = opt.contrast_is_delay;


[nx,ny,nz,nt] = size(vol);
allpts = 1:nt;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );
n = length(keep);
numpix = nx*ny;
numcontrasts = size(contrasts,1);

indk1=((keep(2:n)-keep(1:n-1))==1);
k1=find(indk1)+1;
  
vol = reshape(vol,[nx*ny*nz nt]);
vol = vol(:,keep);

if ispcnt
   spatial_av = spatial_av(keep);
   spatial_av = repmat(spatial_av',nx*ny*nz,1);
   vol = 100*(vol./spatial_av);
   clear spatial_av
end

vol = reshape(vol,[nx ny nz n]);
rho_vol = reshape(squeeze(rho_vol),[nx*ny nz numlags]);

if ~isempty(contrasts)
   % Set up for second loop:
   X_type=[ones(1,sum(num_hrf_bases==1))*1 ones(1,sum(num_hrf_bases==2))*2 ...
         ones(1,sum(num_hrf_bases==2))*3 ones(1,numtrends)*4 ];
   
   find_X_is_mag=[find(X_type==1) find(X_type==2) find(X_type==4)];
   
   find_contrast_is_mag=find(~contrast_is_delay);
   find_response_is_mag=[find(num_hrf_bases==1) find(num_hrf_bases==2) ...
         numresponses+(1:numtrends)];
   contr_mag=contrasts(find_contrast_is_mag,find_response_is_mag);
   isF=find(which_stats(find_contrast_is_mag,4));
   contr_mag_F=contr_mag(isF,:);
end


% Second loop over voxels to get statistics:
drho=0.01;
for k=1:nz
   X_k = squeeze(matrix_x(:,:,k));
   Df=n-rank(X_k);
   Xstar_k=X_k;
   Y = squeeze(vol(:,:,k,:));
   Y = (reshape(Y,nx*ny,n))';
   if numlags==1
      % bin rho to intervals of length drho, avoiding -1 and 1:
      irho=round(rho_vol(:,k)/drho)*drho;
      irho=min(irho,1-drho);
      irho=max(irho,-1+drho);
   else
      % use dummy unique values so every pixel is analysed seperately:
      irho=(1:numpix)';
   end
   
   for rho=unique(irho)'
      pix=find(irho==rho);
      Ystar=Y(:,pix);
      if numlags==1
         factor=1./sqrt(1-rho^2);
         Ystar(k1,:)=(Y(k1,pix)-rho*Y(k1-1,pix))*factor;
         Xstar_k(k1,:)=(X_k(k1,:)-rho*X_k(k1-1,:))*factor;
         if which_stats(1,8)
             A_slice(pix,1) = rho;
         end
      else
         Coradj_pix=squeeze(rho_vol(pix,k,:));
         [Ainvt posdef]=chol(toeplitz([1 Coradj_pix']));
         nl=size(Ainvt,1);
         A=inv(Ainvt');
         if which_stats(1,8)
            A_slice(pix,1:(nl-1))=-A(nl,(nl-1):-1:1)/A(nl,nl);
         end
         B=ones(n-nl,1)*A(nl,:);
         Vmhalf=spdiags(B,1:nl,n-nl,n);
         Ystar=zeros(n,1);
         Ystar(1:nl)=A*Y(1:nl,pix);
         Ystar((nl+1):n)=full(Vmhalf)*Y(:,pix);
         Xstar_k(1:nl,:)=A*X_k(1:nl,:);
         Xstar_k((nl+1):n,:)=Vmhalf*X_k;
      end
      pinvXstar=pinv(Xstar_k);
      betahat=pinvXstar*Ystar;
      resid=Ystar-Xstar_k*betahat;
      if which_stats(1,6)
         resid_slice(pix,:)=(Y(:,pix)-X_k*betahat)';
      end
      SSE=sum(resid.^2,1);
      sd=sqrt(SSE/Df);
      if which_stats(1,7) || which_stats(1,9)
         sdd=(sd>0)./(sd+(sd<=0));
         wresid_slice(pix,:)=(resid.*repmat(sdd,n,1))';
      end
      V=pinvXstar*pinvXstar';
     
      % estimate magnitudes:
      mag_ef=contr_mag*betahat(find_X_is_mag,:);
      VV=V(find_X_is_mag,find_X_is_mag);
      mag_sd=sqrt(diag(contr_mag*VV*contr_mag'))*sd;
      effect_slice(pix,find_contrast_is_mag)=mag_ef';
      sdeffect_slice(pix,find_contrast_is_mag)=mag_sd';
      tstat_slice(pix,find_contrast_is_mag)= ...
      (mag_ef./(mag_sd+(mag_sd<=0)).*(mag_sd>0))';
      if any(which_stats(:,4))
            cVcinv=pinv(contr_mag_F*VV*contr_mag_F');
            SST=sum((cVcinv*mag_ef(isF,:)).*mag_ef(isF,:),1);
            Fstat_slice(pix,1)=(SST./(SSE+(SSE<=0)).*(SSE>0)/p*Df)';
      end      
   end
   for k_cont=1:numcontrasts
      if which_stats(k_cont,1)
         tstat_slice = min(tstat_slice,100);
         stats_vol.t(:,:,k,k_cont) = reshape(tstat_slice(:,k_cont),nx,ny);
      end
      if which_stats(k_cont,2)
         stats_vol.ef(:,:,k,k_cont) = reshape(effect_slice(:,k_cont),nx,ny); 
      end
      if which_stats(k_cont,3)
         stats_vol.sd(:,:,k,k_cont) = reshape(sdeffect_slice(:,k_cont),nx,ny); 
      end
   end
   if any(which_stats(:,4))
      Fstat_slice=min(Fstat_slice,10000);
      stats_vol.f(:,:,k) = reshape(Fstat_slice,nx,ny); 
   end
   if which_stats(1,6)
      stats_vol.resid(:,:,k,:) = reshape(resid_slice,nx,ny,n);  
   end  
   if which_stats(1,7) 
      stats_vol.wresid(:,:,k,:) = reshape(wresid_slice,nx,ny,n);   
   end  
   if which_stats(1,8)
      stats_vol.ar(:,:,k,:) = reshape(A_slice,nx,ny,numlags);    
   end
end
