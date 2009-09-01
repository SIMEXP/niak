function [rho_vol,opt] = niak_autoregressive(vol,mask,opt)
% _________________________________________________________________________
% SUMMARY NIAK_AUTOREGRESSIVE
%
% Estimates an autoregressive model for each voxel time course and gives an
% approximate value for the fwhm based on the model residuals (optional).
% 
% SYNTAX:
% [RHO_VOL,OPT] = NIAK_AUTOREGRESSIVE(VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (4D array) a 3D+t dataset
%
% MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       will be included in the analysis. 
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
%           if PCNT=1, then the data is converted to percentages 
%           before analysis by dividing each frame by its spatial average,* 100%.
%
%       EXCLUDE: 
%           is a list of frames that should be excluded from the analysis. 
%           Default is [].
%
%       NUMLAGS
%           (integer, default 1) The order (p) of the autoregressive model.
%
%       VOXEL_SIZE
%           (vector 1*3, default [1 1 1]) Voxel size in mm.
%
% _________________________________________________________________________
% OUTPUTS:
%
% RHO_VOL      
%       (4D array) 3D + numlags dataset
%       Estimated parameters of the autoregressive lineal model.
%
% OPT         
%       Updated structure with the additional fields:
%
%       FWHM       
%          (real number) Estimated value of the FWHM. 
%
%       DF
%          Structure with the field 
%
%          RESID 
%              degrees of freedom of the residuals. 
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
%               Pierre Bellec, McConnell Brain Imaging Center, 2009.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
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
gb_list_fields = {'matrix_x','spatial_av','pcnt','exclude','numlags','voxel_size'};
gb_list_defaults = {NaN,[],0,[],1,[1 1 1]};
niak_set_defaults

spatial_av = opt.spatial_av;
numlags = opt.numlags;
ispcnt = opt.pcnt;
matrix_x = opt.matrix_x;


[nx,ny,nz,nt] = size(vol);
allpts = 1:nt;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );
n = length(keep);

indk1=((keep(2:n)-keep(1:n-1))==1);
k1=find(indk1)+1;
Diag1=diag(indk1,1)+diag(indk1,-1);
  
vol = reshape(vol,[nx*ny*nz nt]);
vol = vol(:,keep);

if ispcnt
   spatial_av = spatial_av(keep);
   spatial_av = repmat(spatial_av',nx*ny*nz,1);
   vol = 100*(vol./spatial_av);
   clear spatial_av
end
vol = reshape(vol,[nx ny nz n]);

for k=1:nz
    X_k = squeeze(matrix_x(:,:,k));
    dfs(k)=n-rank(X_k);
    pinvX = pinv(X_k);
    R = eye(n)-X_k*pinvX;
    if numlags==1
        M(1,1) = trace(R);
        M(1,2) = trace(R*Diag1);
        M(2,1) = M(1,2)/2;
        M(2,2) = trace(R*Diag1*R*Diag1)/2;
    else
        M=zeros(numlags+1);
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
clear vol

resid = reshape(resid,[nx*ny*nz,n]);

if numlags==1
   Cov0 = sum(resid.^2,2);
   Cov1 = sum(resid(:,k1).*resid(:,k1-1),2);
   Cov = [Cov0, Cov1];
else
   for lag=0:numlags
       Cov(:,lag+1)=sum(resid(:,1:n-lag).*resid(:,(lag+1):n),2);
   end
   Cov0 = Cov(:,1);
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

if nargout>=2
    sdd=(Cov0>0)./sqrt(Cov0+(Cov0<=0));
    resid = resid.*repmat(sdd,1,n);
    resid = reshape(resid,[nx,ny,nz,n]);
    opt_fwhm.voxel_size = abs(opt.voxel_size);
    opt_fwhm = niak_quick_fwhm(resid,mask,opt_fwhm);
    df.resid = round(mean(dfs));
end
opt.fwhm = opt_fwhm.fwhm;
opt.df = df;
