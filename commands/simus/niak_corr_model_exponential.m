function r = niak_corr_model_exponential(h,rho);
%
% _________________________________________________________________________
% SUMMARY NIAK_CORR_MODEL_EXPONENTIAL
%
% Generates a temporal correlation matrix following an exponential model
% (equivalent to an auto-regressive structure of order 1):
%
% R_(I,J) = RHO^H_(I,J)
%
% SYNTAX:
% R = NIAK_CORR_MODEL_EXPONENTIAL(PAR)
%
% _________________________________________________________________________
% INPUTS:
%
% H
%       (vector) list of temporal lags
%
% RHO
%       (scalar) the parameter of the exponential model.
%
% _________________________________________________________________________
% OUTPUTS:
%
% R
%       (vector) R(I) is the temporal correlation corresponding to the
%       temporal lag H(I)
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_SAMPLE_GSST
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : 

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

r = rho.^h;