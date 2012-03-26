function [eigenvariates,eigenvalues] = niak_pca_fmristat(vol,mask,opt)
% _________________________________________________________________________
% SUMMARY NIAK_PCA
%
% Create spatial average from a volume
% 
% SYNTAX:
% [EIGENVARIATES,EIGENVALUES] = NIAK_PCA(VOL,MASK,OPT)
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
%       EXCLUDE 
%             (vector, default []) 
%             A list of frames that should be excluded from the analysis. 
%             This must be used with Siemens EPI scans to remove the
%             first few frames, which do not represent steady-state images.
%
%       ISCOV
%            1 for PCA on covariances(default), 0 for PCA on correlations.
%
%       X_REMOVE
%            Design matrix with a row for each frame of the covariates to be 
%            removed from the data before doing the PCA. 
%            Default is ones(numX,1), i.e. removing the mean image over time; 
%            use [ones(numX,1) (1:numX)'] to remove a linear drift as well.
%
%       X_INTEREST
%            Design matrix with a row for each frame of the covariates of interest. 
%            The PCA is done on the effects for these covariates,
%            i.e. a Partial Least-Squares (PLS) analysis. 
%            Default is eye(numX), i.e. a PCA on all the frames or files.
%
% _________________________________________________________________________
% OUTPUTS:
%
%   EIGENVARIATES 
%        matrix of column vectors representing eigenvariates.
%
%   EIGENVALUES 
%        vector of eigenvalues.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is a NIAKIFIED port of a part of the PCA_IMAGE function of the
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

[nx,ny,nz,nt] = size(vol);
iscov = opt.iscov;
X_remove = opt.X_remove;
X_interest = opt.X_interest;

tot = sum(mask(:));
for i=1:nt
    temp = vol(:,:,:,i).*mask;
    spatial_av(i) = sum(temp(:));
end
spatial_av = spatial_av/tot;
spatial_av = spatial_av(:);

% Defaults:

if nargin < 2
   exclude=[]
end

numpix = nx*ny;
numslices = size(mask,3);

if ~isempty(mask)
   xf = find(max(max(mask,[],2),[],3));
   xr = min(xf):max(xf);
   yf = find(max(max(mask,[],1),[],3));
   yr = min(yf):max(yf);
   mask = reshape(mask,numpix,numslices);
   N = sum(sum(mask));
else
   xr = 1:nx;
   yr = 1:ny;
   N = numpix*nz;
end

numX = nt;
if length(opt.exclude)==numX
   keep = find(exclude==0);
else
   keep = setxor(1:numX,opt.exclude);
end
n=length(keep);

X = X_interest(keep,:);
if ~isempty(X_remove)
   Z = X_remove(keep,:);
   XZ = X-Z*(pinv(Z)*X);
else
   XZ = X;
end
[UX,SX,VX] = svd(XZ);
n1 = rank(XZ);
UX = UX(:,1:n1);

A = zeros(n1);
for slice = 1:nz
   Y = zeros(numpix,n);
   sumin = 0;
   sumframes = 0;
   keepin = intersect(1:nt,keep);
   Y(:,(1:length(keepin))) = reshape(vol(:,:,slice,keepin),numpix,length(keepin));
   if ~isempty(mask)
      Y = Y(mask(:,slice),:);
   end
   YX = Y*UX;
   if ~iscov
      if ~isempty(X_remove)
         S = sum((Y-(Y*pinv(Z)')*Z').^2,2);
      else
         S = sum(Y.^2,2);
      end
      Smhalf = (S>0)./sqrt(S+(S<=0));
      for i = 1:n1
         YX(:,i)=YX(:,i).*Smhalf;
      end
   end
   A = A+YX'*YX;
   clear Y YX
end
[Vs,D] = eig(A);
[ds,is] = sort(-diag(D));
p = rank(A);

VX = UX*Vs(:,is(1:p));
D = diag(D);
eigenvalues = sqrt(D(is(1:p)));
eigenvariates = VX;
 
