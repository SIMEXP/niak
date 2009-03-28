function fwhm = niak_quick_fwhm(resid_vol,mask,opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_TRENDS
%
% Estimates the FWHM from the a 4D data
% 
% SYNTAX:
% Trend = NIAK_QUICK_FWHM(RESID_VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% RESID_VOL         
%       (4D array) a 3D+t dataset
% 
% MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       will be included in the analysis.
%
% OPT         
%       (structure, optional) with the following fields :
%
%       FWHM_COR:
%       The fwhm in mm of a 3D Gaussian kernel used to smooth the
%       autocorrelation of residuals. Setting it to Inf smooths the auto-
%       correlation to 0, i.e. it assumes the frames are uncorrelated 
%       (useful for TR>10 seconds). Setting it to 0 does no smoothing.
%       If FWHM_COR is negative, it is taken as the desired df, and the 
%       fwhm is chosen to achive this df, or 90% of the residual df, 
%       whichever is smaller, for every contrast, up to 50mm. 
%       If a second component is supplied, it is the fwhm in mm of the data, 
%       otherwise this is estimated quickly from the least-squares residuals. 
%       Default is -100, i.e. the fwhm is chosen to achieve 100 df.
%
%       NUMLAGS:
%       The order (p) of the autoregressive model. Default is 1.

%       VOX:
%       Voxel size in mm. Default is [1 1 1].
% _________________________________________________________________________
% OUTPUTS:
%
% FWHM       
%       Estimated value of the FWHM. 
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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'FWHM_COR','numlags','vox'};
gb_list_defaults = {-100,1,[1 1 1]};
niak_set_defaults

Steps = opt.vox;
[nx,ny,nz,n] = size(resid_vol);
resid_vol = reshape(resid_vol,[nx*ny*nz n]);

if opt.numlags==1
   Cov0=sum(resid_vol.^2,2);
else
   for lag=0:opt.numlags
       Cov(:,lag+1)=sum(resid_vol(:,1:(n-lag)).*resid_vol(:,(lag+1):n),2);
   end
   Cov0=Cov(:,1);
end
sdd=(Cov0>0)./sqrt(Cov0+(Cov0<=0));
wresid_vol = resid_vol.*repmat(sdd,1,n); 
clear resid_vol
wresid_vol = reshape(wresid_vol,[nx,ny,nz,n]);

% Quick fwhm of data
for slice=1:nz
    if length(FWHM_COR)==2
         if slice==numslices
            fwhm = FWHM_COR(2);
         end
    else
         wresid_slice = squeeze(wresid_vol(:,:,slice,:));
         if slice==1
            D=2+(nz>1);
            sumr=0;
            i1=1:(nx-1);
            j1=1:(ny-1);
            nxy=conv2(ones(nx-1,ny-1),ones(2));
            u = wresid_slice;
            if D==2
               ux=diff(u(:,j1,:),1,1);
               uy=diff(u(i1,:,:),1,2);
               axx=sum(ux.^2,3);
               ayy=sum(uy.^2,3);
               axy=sum(ux.*uy,3);
               detlam=(axx.*ayy-axy.^2);
               r=conv2((detlam>0).*sqrt(detlam+(detlam<=0)),ones(2))./nxy;
            else
               r=zeros(nx,ny);
            end
            mask_slice = mask(:,:,slice);
            tot=sum(mask_slice(:));
         else 
            uz=wresid_slice-u;
            ux=diff(u(:,j1,:),1,1);
            uy=diff(u(i1,:,:),1,2);
            uz=uz(i1,j1,:);
            axx=sum(ux.^2,3);
            ayy=sum(uy.^2,3);
            azz=sum(uz.^2,3);
            axy=sum(ux.*uy,3);
            axz=sum(ux.*uz,3);
            ayz=sum(uy.*uz,3);
            detlam=(axx.*ayy-axy.^2).*azz-(axz.*ayy-2*axy.*ayz).*axz-axx.*ayz.^2;
            mask1=mask_slice;
            mask_slice = mask(:,:,slice);
            tot=tot+sum(mask_slice(:));
            r1=r;
            r=conv2((detlam>0).*sqrt(detlam+(detlam<=0)),ones(2))./nxy;
            sumr=sumr+sum(sum((r1+r)/(1+(slice>2)).*mask1));
            u = wresid_slice;
         end
         if slice==nz
            sumr=sumr+sum(sum(r.*mask_slice));
            fwhm = sqrt(4*log(2))*(prod(abs(Steps(1:D)))*tot/sumr)^(1/3);
         end
    end
end
      