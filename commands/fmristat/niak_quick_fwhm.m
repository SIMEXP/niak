function fwhm = niak_quick_fwhm(resid_vol,mask,opt)

% _________________________________________________________________________
% SUMMARY NIAK_QUICK_FWHM
%
% Estimate the FWHM from a 4D data
% 
% SYNTAX:
% FWHM = NIAK_QUICK_FWHM(RESID_VOL,MASK,OPT)
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
%       NUMLAGS
%           (integer, default 1) The order (p) of the autoregressive model.
%        
%       VOX
%           (vector 1*3, default [1 1 1]) Voxel size in mm.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FWHM       
%       (real number) Estimated value of the FWHM. 
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%##########################################################################
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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'numlags','vox'};
gb_list_defaults = {1,[1 1 1]};
niak_set_defaults

Steps = opt.vox;
[nx,ny,nz,n] = size(resid_vol);

if nargin < 2
    mask = true([nx ny nz]);
end

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
      