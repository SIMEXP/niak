function matrix_x = niak_full_design(x_cache,trend,opt)
% Contructs the full design matrix of the model 
% (concatenates the information in x_cache and trends)
% 
% SYNTAX:
% [MATRIX_X] = NIAK_FULL_DESIGN(X_CACHE,TREND,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% X_CACHE 
%   (structure) with fields TR, X ,and W. See NIAK_FMRI_DESIGN.
%
% TREND       
%   (3D array) temporal, spatial trends and additional confounds for 
%   every slice. See NIAK_MAKE_TRENDS.
% 
% OPT         
%   (structure, optional) with the following fields :
%
%   EXCLUDE: 
%       a list of frames that should be excluded from the analysis. 
%       Default is [].
%
%   NUM_HRF_BASES
%       row vector indicating the number of basis functions for the hrf 
%       for each response, either 1 or 2 at the moment. At least one basis 
%       functions is needed to estimate the magnitude, but two basis functions
%       are needed to estimate the delay.
%     
%   BASIS_TYPE 
%       selects the basis functions for the hrf used for delay
%       estimation, or whenever NUM_HRF_BASES = 2. These are convolved 
%       with the stimulus to give the responses in Dim 3 of X_CACHE.X:
%           'taylor' - use hrf and its first derivative (components 1 and 2), or 
%           'spectral' - use first two spectral bases (components 3 and 4 of Dim 3).
%           Default is 'spectral'. 
% _________________________________________________________________________
% OUTPUTS:
%
% MATRIX_X      
%   (3D array) of the full design matrix, a different matrix for each
%   slice.
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
gb_list_fields = {'exclude','num_hrf_bases','basis_type'};
gb_list_defaults = {[],NaN,'spectral'};
niak_set_defaults


switch lower(opt.basis_type)
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


nt = size(x_cache.x,1);
allpts = 1:nt;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );

if ~isempty(x_cache.x)
    matrix_x = cat(2,squeeze(x_cache.x(keep,num_hrf_bases==1,1,:)),...
        squeeze(x_cache.x(keep,num_hrf_bases==2,basis1,:)),...
        squeeze(x_cache.x(keep,num_hrf_bases==2,basis2,:)),trend);
else
    matrix_x = trend;
end
