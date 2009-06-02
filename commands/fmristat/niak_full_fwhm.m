function vol_fwhm = niak_full_fwhm(wresid_vol,mask,opt)

% _________________________________________________________________________
% SUMMARY NIAK_QUICK_FWHM
%
% Estimate the FWHM from a 4D data
% 
% SYNTAX:
% FWHM = NIAK_QUICK_FWHM(WRESID_VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% WRESID_VOL         
%       (4D array) a 3D+t dataset
% 
% MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       will be included in the analysis.
%
% OPT         
%       (structure, optional) with the following fields :
%
%       VOXEL_SIZE
%           (vector 1*3, default [1 1 1]) Voxel size in mm.
%
%       DF
%           Structure with the field RESID, degrees of freedom of the
%           residuals.
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_FWHM       
%       (4D array) a 3D+5 dataset with FWHM parameters 
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
gb_list_fields = {'voxel_size'};
gb_list_defaults = {[1 1 1]};
niak_set_defaults

df_limit = 4;
Steps = opt.voxel_size;
[nx,ny,nx,nt] = size(wresid_vol);

if nargin < 2
    mask = true([nx ny nz]);
end

% setup for estimating the FWHM:
I=numxs;
J=numys;
IJ=I*J;
Im=I-1;
Jm=J-1;
nx=conv2(ones(Im,J),ones(2,1));
ny=conv2(ones(I,Jm),ones(1,2));
nxy=conv2(ones(Im,Jm),ones(2));
f=zeros(I,J);
r=zeros(I,J);
Azz=zeros(I,J);
ip=[0 1 0 1];
jp=[0 0 1 1];
is=[1 -1  1 -1];
js=[1  1 -1 -1];
D=2+(nz>1);
alphaf=-1/(2*D);
alphar=1/2;
Step=abs(prod(Steps(1:D)))^(1/D);

 % bias corrections for estimating the FWHM:
Df = dfs(slice); 
df_resid=Df;
dr=df_resid/Df;
dv=df_resid-dr-(0:D-1);
if df_resid>df_limit
    % constants for arbitrary filter method:
    biasf=exp(sum(gammaln(dv/2+alphaf)-gammaln(dv/2)) ...
     +gammaln(Df/2-D*alphaf)-gammaln(Df/2))*dr^(-D*alphaf);
     biasr=exp(sum(gammaln(dv/2+alphar)-gammaln(dv/2)) ...
     +gammaln(Df/2-D*alphar)-gammaln(Df/2))*dr^(-D*alphar);
else
    % constants for filter aligned with axes method:
    biasf=exp((gammaln(dv(1)/2+alphaf)-gammaln(dv(1)/2))*D+ ...
     +gammaln(Df/2-D*alphaf)-gammaln(Df/2))*dr^(-D*alphaf);
     biasr=exp((gammaln(dv(1)/2+alphar)-gammaln(dv(1)/2))*D+ ...
     +gammaln(Df/2-D*alphar)-gammaln(Df/2))*dr^(-D*alphar);
end
consf=(4*log(2))^(-D*alphaf)/biasf*Step;
consr=(4*log(2))^(-D*alphar)/biasr;

 % Finds fwhm for the 8 cube corners surrounding a voxel, then averages. 
 for slice=1:numslices
    wresid_slice = squeeze(wresid_vol(:,:,slice,:));
    mask_slice = mask(:,:,slice);
    if slice==1
         u=wresid_slice;
         ux=diff(u,1,1);
         uy=diff(u,1,2);
         Axx=sum(ux.^2,3);
         Ayy=sum(uy.^2,3);
         dxx=([Axx; zeros(1,J)]+[zeros(1,J); Axx])./nx;
         dyy=([Ayy  zeros(I,1)]+[zeros(I,1)  Ayy])./ny;
         if D==2
            for index=1:4
               i=(1:Im)+ip(index);
               j=(1:Jm)+jp(index);
               axx=Axx(:,j);
               ayy=Ayy(i,:);
               if df_resid>df_limit
                  axy=sum(ux(:,j,:).*uy(i,:,:),3)*is(index)*js(index);
                  detlam=(axx.*ayy-axy.^2);
               else
                  detlam=axx.*ayy;
               end
               f(i,j)=f(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphaf;
               r(i,j)=r(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphar;
            end
         end
    else 
         uz=wresid_slice-u;
         dzz=Azz;
         Azz=sum(uz.^2,3);
         dzz=(dzz+Azz)/(1+(slice>1));
         % The 4 upper cube corners:
         for index=1:4
            i=(1:Im)+ip(index);
            j=(1:Jm)+jp(index);
            axx=Axx(:,j);
            ayy=Ayy(i,:);
            azz=Azz(i,j);
            if Df>df_limit
               axy=sum(ux(:,j,:).*uy(i,:,:),3)*is(index)*js(index);
               axz=sum(ux(:,j,:).*uz(i,j,:),3)*is(index);
               ayz=sum(uy(i,:,:).*uz(i,j,:),3)*js(index);
               detlam=(axx.*ayy-axy.^2).*azz-(axz.*ayy-2*axy.*ayz).*axz-axx.*ayz.^2;
            else
               detlam=axx.*ayy.*azz;
            end
            f(i,j)=f(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphaf;
            r(i,j)=r(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphar;
         end
         f=consf/((slice>2)+1)*f./nxy;
         r=consr/((slice>2)+1)*r./nxy;
         out.df=[df_resid df_resid];
         vol_fwhm(:,:,slice-1,1) = (f.*(f<50)+50*(f>=50)).*mask_slice;
         vol_fwhm(:,:,slice-1,2) = r.*mask_slice;
         vol_fwhm(:,:,slice-1,3) = (1-dxx/2).*mask_slice;
         vol_fwhm(:,:,slice-1,4) = (1-dyy/2).*mask_slice;
         vol_fwhm(:,:,slice-1,5) = (1-dzz/2).*mask_slice;
         f=zeros(I,J);
         r=zeros(I,J);
         u=wresid_slice;
         ux=diff(u,1,1);
         uy=diff(u,1,2);
         Axx=sum(ux.^2,3);
         Ayy=sum(uy.^2,3);
         dxx=([Axx; zeros(1,J)]+[zeros(1,J); Axx])./nx;
         dyy=([Ayy  zeros(I,1)]+[zeros(I,1)  Ayy])./ny;
         % The 4 lower cube corners:
         for index=1:4
            i=(1:Im)+ip(index);
            j=(1:Jm)+jp(index);
            axx=Axx(:,j);
            ayy=Ayy(i,:);
            azz=Azz(i,j);
            if Df>df_limit
               axy=sum(ux(:,j,:).*uy(i,:,:),3)*is(index)*js(index);
               axz=-sum(ux(:,j,:).*uz(i,j,:),3)*is(index);
               ayz=-sum(uy(i,:,:).*uz(i,j,:),3)*js(index);
               detlam=(axx.*ayy-axy.^2).*azz-(axz.*ayy-2*axy.*ayz).*axz-axx.*ayz.^2;
            else
               detlam=axx.*ayy.*azz;
            end
            f(i,j)=f(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphaf;
            r(i,j)=r(i,j)+(detlam>0).*(detlam+(detlam<=0)).^alphar;
         end
    end
      if slice==numslices
         f=consf*f./nxy;
         r=consr*r./nxy;
         vol_fwhm(:,:,slice,1) = (f.*(f<50)+50*(f>=50)).*mask_slice;
         vol_fwhm(:,:,slice,2) = r.*mask_slice;
         vol_fwhm(:,:,slice,3) = (1-dxx/2).*mask_slice;
         vol_fwhm(:,:,slice,4) = (1-dyy/2).*mask_slice;
         vol_fwhm(:,:,slice,5) = (1-Azz/2).*mask_slice;
      end
 end
out.df=[df_resid df_resid];