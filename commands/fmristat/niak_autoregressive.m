function [rho_vol,df] = niak_autoregressive(vol,opt)
% _________________________________________________________________________
% SUMMARY NIAK_AUTOREGRESSIVE
%
% Estimates an autoregressive model for each voxel time course.
% 
% SYNTAX:
% [RHO_VOL,DF] = NIAK_AUTOREGRESSIVE(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (4D array) a 3D+t dataset
% 
% OPT         
%       (structure, optional) with the following fields :
%
%       X_CACHE 
%         structure with the fields TR, X ,and W, obtained from
%         niak_fmridesign 
%
%       TREND       
%           (3D array) of the temporal,spatial trends and additional 
%            confounds for every slice, obtained from niak_make_trends.
%
%       SPATIAL_AV
%            colum vector of the spatial average time courses, obtained
%            from niak_make_trends.
%
%       PERCENT: 
%           if PERCENT=1(Default), then the data is converted to percentages 
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
%       BASIS_TYPE 
%           selects the basis functions for the hrf used for delay
%           estimation, or whenever NUM_HRF_BASES = 2. These are convolved 
%           with the stimulus to give the responses in Dim 3 of X_CACHE.X:
%           'taylor' - use hrf and its first derivative (components 1 and 2), or 
%           'spectral' - use first two spectral bases (components 3 and 4 of Dim 3).
%           Default is 'spectral'. 
%
%
% _________________________________________________________________________
% OUTPUTS:
%
% RHO_VOL      
%       (4D array) 3D + numlags dataset
%       Estimated parameters of the autoregressive lineal model.
% DF
%       Structure with the field RESID, degrees of freedom of the residuals. 
%
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
gb_list_fields = {'x_cache','trend','spatial_av','percent','exclude','numlags','num_hrf_bases','basis_type'};
gb_list_defaults = {NaN,NaN,NaN,1,[],1,[],'spectral'};
niak_set_defaults

X_cache = opt.x_cache;
Trend = opt.trend;
spatial_av = opt.spatial_av;
num_hrf_bases = opt.num_hrf_bases;
numlags = opt.numlags;
ispcnt = opt.percent;

switch lower(basis_type)
case 'taylor',    
   basis1=1;
   basis2=2;
case 'spectral',    
   basis1=3;
   basis2=4;
otherwise, 
   disp('Unknown basis_type.'); 
   return
end

if ~isempty(X_cache.X)
   numresponses = size(X_cache.X,2);
else
   numresponses = 0;
end
if isempty(num_hrf_bases)
   num_hrf_bases=ones(1,numresponses);
end

[nx,ny,nz,nt] = size(vol);
allpts = 1:nt;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );
n = length(keep);

indk1=((keep(2:n)-keep(1:n-1))==1);
k1=find(indk1)+1;
Diag1=diag(indk1,1)+diag(indk1,-1);
if ~isempty(X_cache.X)
    X = cat(2,squeeze(X_cache.X(keep,num_hrf_bases==1,1,:)),...
        squeeze(X_cache.X(keep,num_hrf_bases==2,basis1,:)),...
        squeeze(X_cache.X(keep,num_hrf_bases==2,basis2,:)));
else
    X = [];
end
  
vol = reshape(vol,[nx*ny*nz nt]);
vol = vol(:,keep);
spatial_av = spatial_av(keep);

if ispcnt
   spatial_av = repmat(spatial_av',nx*ny*nz,1);
   vol = 100*(vol./spatial_av);
   clear spatial_av
end
vol = reshape(vol,[nx ny nz n]);


for k=1:nz
    X_k = cat(2,squeeze(X(:,:,k)),squeeze(Trend(:,:,k)));
    dfs(k)=n-rank(X_k);
    pinvX = pinv(X_k);
    R = eye(n)-X_k*pinvX;
    if numlags==1
        M(1,1) = trace(R);
        M(1,2) = trace(R*Diag1);
        M(2,1) = M(1,2)/2;
        M(2,2) = trace(R*Diag1*R*Diag1)/2;
    else
        M=zeros(numlags+1,nz);
         for i=1:numlags+1
            for j=1:numlags+1
               Di=(diag(ones(1,n-i+1),i-1)+diag(ones(1,n-i+1),-i+1))/(1+(i==1));
               Dj=(diag(ones(1,n-j+1),j-1)+diag(ones(1,n-j+1),-j+1))/(1+(j==1));
               M(i,j)=trace(R*Di*R*Dj)/(1+(i>1));
            end
         end
    end
    invM(:,:,k) = inv(M);
    Y = squeeze(vol(:,:,k,:));
    Y = (reshape(Y,nx*ny,n))';
    betahat_ls = pinvX*Y;
    resid(:,k,:) = (Y - X_k*betahat_ls)';
end

resid = reshape(resid,nx*ny*nz,n);
if numlags==1
   Cov0 = sum(resid.^2,2);
   Cov1 = sum(resid(:,k1).*resid(:,k1-1),2);
   Cov = [Cov0, Cov1];
else
   for lag=0:numlags
       Cov(:,lag+1)=sum(resid_vol(:,1:n-lag).*resid_vol(:,(lag+1):n),2);
   end
end
Cov = reshape(Cov',[numlags+1,nx*ny,nz]);
for k=1:nz
    Covadj(:,:,k) = squeeze(invM(:,:,k))*squeeze(Cov(:,:,k));
end
Covadj = reshape(Covadj,[numlags+1,nx*ny*nz]);
if numlags==1
   rho_vol = (Covadj(2,:)./ ...
            (Covadj(1,:)+(Covadj(1,:)<=0)).*(Covadj(1,:,:)>0))';
else
   rho_vol = ( Covadj(2:(numlags+1),:) ...
            .*( ones(numlags,1)*((Covadj(1,:)>0)./ ...
            (Covadj(1,:)+(Covadj(1,:)<=0)))) )';
end
rho_vol = reshape(rho_vol,[nx ny nz numlags]);

df.resid = round(mean(dfs));
    
