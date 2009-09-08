function opt = niak_regularized_df(opt)
% _________________________________________________________________________
% SUMMARY NIAK_REGULARIZED_DF
%
% Updates the values of df according to the required for smoothing 
% autocorrelations
% 
% SYNTAX:
% OPT = NIAK_REGULARIZED_DF(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT         
%       structure with the following fields :
%
%       FWHM       
%           Structure with the fields VARATIO and DATA.
%
%       DF
%           Structure with the field RESID, degrees of freedom of the
%           residuals.
%
%       VOXEL_SIZE
%           (vector 1*3, default [1 1 1]) Voxel size in mm.
%
%       NB_SLICES
%           number of slices.
% _________________________________________________________________________
% OUTPUTS:
%
% OPT         
%       Updated structure with the additional fields KER_X, KER_Y, KER_Z,
%       the kernels required for spatially smoothing of the variance ratio
%       volume.
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
gb_list_fields = {'fwhm','df','voxel_size','nb_slices'};
gb_list_defaults = {NaN,NaN,[1 1 1],NaN};
niak_set_defaults


df = opt.df;
fwhm_varatio = opt.fwhm.varatio;
fwhm_data = opt.fwhm.data;
Steps = opt.voxel_size;
numslices = opt.nb_slices;
D = 2 + (numslices>1);


if fwhm_varatio>0
   fwhm_x=fwhm_varatio/abs(Steps(1));
   ker_x=exp(-(-ceil(fwhm_x):ceil(fwhm_x)).^2*4*log(2)/fwhm_x^2);
   ker_x=ker_x/sum(ker_x);
   fwhm_y=fwhm_varatio/abs(Steps(2));
   ker_y=exp(-(-ceil(fwhm_y):ceil(fwhm_y)).^2*4*log(2)/fwhm_y^2);
   ker_y=ker_y/sum(ker_y);
   fwhm_z=fwhm_varatio/abs(Steps(3));
   ker_z=exp(-(0:(numslices-1)).^2*4*log(2)/fwhm_z^2);
   K=toeplitz(ker_z);
   K=K./(ones(numslices)*K);
   df_indep=df.resid/(sum(ker_x.^2)*sum(ker_y.^2)*sum(sum(K.^2))/numslices);
   df_correl=df.resid*(2*(fwhm_varatio/fwhm_data)^2+1)^(D/2);
   df.rfx=min(df_indep,df_correl);
   df.t=1/(1/df.rfx+1/df.fixed);
else
   ker_x=1;
   ker_y=1;
   K=eye(numslices);
   df.rfx=df.resid;
   df.t=df.resid;
end

opt.df = df;
opt.ker_x = ker_x;
opt.ker_y = ker_y;
opt.ker_z = K;