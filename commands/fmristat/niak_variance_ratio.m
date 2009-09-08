function [varatio_vol,opt] = niak_variance_ratio(vol,opt)
% _________________________________________________________________________
% SUMMARY NIAK_VARIANCE_RATIO
%
% Estimates the ratio between the standard deviation of the random effects
% and the standart deviation of the fixed effects. Additionally, it updates
% the structure OPT by adding an approximate value for the data
% fwhm.
% 
% SYNTAX:
% [VARATIO_VOL,OPT] = NIAK_VARIANCE_RATIO(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       structure with the following fields :
%
%       EF
%       (4D array) a 3D+n volumes of effects
%
%       SD
%       (4D array) a 3D+n volumes of standard deviations
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
%       VOXEL_SIZE
%           (vector 1*3, default [1 1 1]) Voxel size in mm.
%
%       DF
%
%           Structure with the following fields:
% 
%           RESID
%              degrees of freedom of the residuals.
%
%           FIXED
%              degrees of freedom of the residuals.
%
%           LIMIT
%              degrees of freedom of the residuals.
% 
% _________________________________________________________________________
% OUTPUTS:
%
% VARATIO_VOL
%       (3D array) the ratio of the random effects variance divided by the 
%       fixed effects variance.
% OPT   
%       Updated structure.
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
gb_list_fields = {'matrix_x','voxel_size','df','nb_iter'};
gb_list_defaults = {NaN,[1 1 1],NaN,10};
niak_set_defaults

matrix_x = opt.matrix_x;
X2 = matrix_x'.^2;
df = opt.df;
niter = opt.nb_iter;
p = rank(matrix_x);

[nx,ny,nz,n] = size(vol.ef);
numpix = nx*ny;
is_sd = isfield(vol,'sd');

Sreduction = 0.99;
for k=1:nz
    Y = squeeze(vol.ef(:,:,k,:));
    Y = (reshape(Y,numpix,n))';
    resid_slice = Y-matrix_x*pinv(matrix_x)*Y;
    sigma2 = sum((resid_slice).^2,1)/df.resid;
    if is_sd
       S = squeeze(vol.sd(:,:,k,:));
       S = (reshape(S,numpix,n))'; 
       S = S.^2;
       varfix = df.data*S/df.fixed;
       sdd = (varfix>0)./sqrt(varfix*df.resid+(varfix<=0));
       mask(:,:,k) = reshape(sqrt(varfix),nx,ny);
    else
       sdd =(sigma2>0)./sqrt(sigma2*df.resid+(sigma2<=0));
       mask(:,:,k) = reshape(sqrt(sigma2),nx,ny);
    end
    resid(:,k,:) = (resid_slice.*repmat(sdd,n,1))';
    if is_sd
        minS = min(S)*Sreduction;
        Sm = S-repmat(minS,n,1);
        if size(matrix_x,2)==1
           % When X is a vector, calculations can be done in parallel:
           for iter=1:niter
               Sms = Sm+repmat(sigma2,n,1);
               W = (Sms>0)./(Sms+(Sms<=0));
               X2W = X2*W;
               XWXinv = (X2W>0)./(X2W+(X2W<=0));
               betahat = XWXinv.*(matrix_x'*(W.*Y));
               R = W.*(Y-matrix_x*betahat);
               ptrS = p+sum(Sm.*W,1)-(X2*(Sm.*W.^2)).*XWXinv;
               sigma2 = (sigma2.*ptrS+(sigma2.^2).*sum(R.^2,1))/n; 
           end
           sigma2=sigma2-minS;
        else
            % Otherwise when X is a matrix, we have to loop over voxels:
            for pix = 1:numpix
                sigma2_pix = sigma2(pix);
                Sm_pix = Sm(:,pix);
                Y_pix = Y(:,pix);
                for iter = 1:niter
                    Sms = Sm_pix+sigma2_pix;
                    W = (Sms>0)./(Sms+(Sms<=0));
                    Whalf = diag(sqrt(W));
                    WhalfX = Whalf*matrix_x;
                    pinvX = pinv(WhalfX);
                    WhalfY = Whalf*Y_pix;
                    betahat = pinvX*WhalfY;
                    R = WhalfY-WhalfX*betahat;
                    SW = diag(Sm_pix.*W);
                    ptrS = p+sum(Sm_pix.*W,1)-sum(sum((SW*WhalfX).*pinvX'));
                    sigma2_pix=(sigma2_pix.*ptrS+ ...
                        (sigma2_pix.^2).*sum(W.*(R.^2),1))/n; 
                end
                sigma2(pix)=sigma2_pix-minS(pix);
            end
        end
    end
    varatio_vol(:,k)=(sigma2./(varfix+(varfix<=0)).*(varfix>0))';
end
clear vol
varatio_vol = reshape(varatio_vol,[nx,ny,nz]);
if nargout>=2
    resid = reshape(resid,[nx,ny,nz,n]);
    opt_fwhm.voxel_size = opt.voxel_size;
    opt_fwhm.df = opt.df;
    opt_fwhm = niak_quick_fwhm(resid,mask,opt_fwhm);
end
opt.fwhm = opt_fwhm.fwhm;