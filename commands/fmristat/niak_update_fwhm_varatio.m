function opt = niak_update_fwhm_varatio(opt)
% _________________________________________________________________________
% SUMMARY NIAK_UPDATE_FWHM_VARATIO
%
% Updates the values of fwhm and df required for smoothing autocorrelations
% 
% SYNTAX:
% OPT = NIAK_UPDATE_FWHM_VARATIO(OPT)
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
%       Updated structure.
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

fwhm = opt.fwhm;
Steps = opt.voxel_size;
numslices = opt.nb_slices;

df_target = -fwhm.varatio;
fwhm_varatio_limit=50;
ff=0:1:100;
dfs=[];
for f=ff
    opt_reg.df = opt.df;
    opt_reg.fwhm.varatio = f;
    opt_reg.voxel_size = Steps;
    opt_reg.fwhm.data = fwhm.data;
    opt_reg.nb_slices = numslices;
    opt_reg = niak_regularized_df(opt_reg);
    dfs = [dfs opt_reg.df.t];
end
fwhm.varatio = interp1(dfs,ff,df_target);
if (isnan(fwhm.varatio)) || (fwhm.varatio > fwhm_varatio_limit)
   fwhm.varatio = Inf;
end
opt.fwhm = fwhm;
  