function rho_vol = niak_smooth_weighted_vol(rho_vol,vol,mask,opt)
% _________________________________________________________________________
% SUMMARY NIAK_SMOOTH_WEIGHTED_VOL
%
% Estimates an autoregressive model for each voxel time course and gives an
% approximate value for the fwhm based on the model residuals (optional).
% 
% SYNTAX:
% [RHO_VOL] = NIAK_AUTOREGRESSIVE(RHO_VOL,VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% RHO_VOL      
%       (4D array) 3D + numlags dataset
%       Estimated parameters of the autoregressive lineal model.
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
%       EXCLUDE: 
%         is a list of frames that should be excluded from the analysis. 
%         Default is [].
%
%       FWHM     
%         3-dimensional vector of FWHM values  
% _________________________________________________________________________
% OUTPUTS:
%
% RHO_VOL      
%       (4D array) 3D + numlags dataset
%       Smoothed autoregressive parameters
% _________________________________________________________________________
% COMMENTS
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
gb_list_fields = {'exclude','fwhm'};
gb_list_defaults = {[],NaN};
niak_set_defaults

fwhm_x = opt.fwhm(1);
fwhm_y = opt.fwhm(2);
fwhm_z = opt.fwhm(3);

[nx,ny,nz,nt] = size(vol);
numlags = size(rho_vol,4);
numpix = nx*ny;

allpts = 1:nt;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );

ker_x=exp(-(-ceil(fwhm_x):ceil(fwhm_x)).^2*4*log(2)/fwhm_x^2);
ker_x=ker_x/sum(ker_x);
ker_y=exp(-(-ceil(fwhm_y):ceil(fwhm_y)).^2*4*log(2)/fwhm_y^2);
ker_y=ker_y/sum(ker_y);

vol = vol(:,:,:,keep(1));
vol = vol.*mask;

rho_vol = reshape(rho_vol,[numpix nz numlags]);
      
mask_vol=zeros(numpix,nz);
for slice=1:nz
    data = vol(:,:,slice);
    mask_vol(:,slice)=reshape(conv2(ker_x,ker_y,data,'same'),numpix,1);  
    for lag=1:numlags
        rho_slice = reshape(rho_vol(:,slice,lag),nx,ny).*data;
        rho_vol(:,slice,lag) = reshape(conv2(ker_x,ker_y,rho_slice,'same'),numpix,1);   
    end
end
% Smoothing rho betwen slices is done by straight matrix multiplication
% by a toeplitz matrix K normalized so that the column sums are 1.
ker_z=exp(-(0:(nz-1)).^2*4*log(2)/fwhm_z^2);
K=toeplitz(ker_z);
K=K./(ones(nz)*K);
mask_vol=mask_vol*K;
for lag=1:numlags
    %rho_vol(:,:,lag)=(squeeze(rho_vol(:,:,lag))*K) ...
            %./(mask_vol+(mask_vol<=0)).*(mask_vol>0);
    rho_vol(:,:,lag)=(squeeze(rho_vol(:,:,lag))*K) ...
            ./(mask_vol+(mask_vol==0)).*(mask_vol~=0);
end

rho_vol = reshape(rho_vol,[nx ny nz numlags]);