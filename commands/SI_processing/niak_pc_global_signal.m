function [pc_gs,av_gs,r] = niak_pc_global_signal(vol,mask)
% global signal estimation based on principal component analysis
%
% SYNTAX:
% PC_SPATIAL_AV = NIAK_PC_GLOBAL_SIGNAL(VOL,MASK)
%
% _________________________________________________________________________
% INPUTS
%
% VOL
%   (3D+t volume) a fMRI dataset
%
% MASK
%   (3D boolean volume) a mask of the brain
%
% _________________________________________________________________________
% OUTPUTS
%
% PC_GS
%   (vector) the estimator of the global signal based on PCA
%
% AV_GS
%   (vector) the estimator of the global signal based on averaging
%
% R
%   (scalar) the correlation between the two estimators
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PCA
%
% _________________________________________________________________________
% COMMENTS:
%
% See the following reference for the definition of the estimator:
%
% F. Carbonell, P. Bellec, A. Shmuel. Validation of a superposition model 
% of global and system-specific resting state activity reveals anti-correlated 
% networks.  To appear in Brain Connectivity.
%
% Copyright (c) Pierre Bellec, Felix Carbonell,
% Montreal Neurological Institute,
% & Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : Principal Component Analysis

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

% PCA
tseries = niak_vol2tseries(vol,mask);
tseries = niak_normalize_tseries(tseries,'mean');
[eigenvalues,eigenvariates,weights] = niak_pca(tseries');

% Spatial Average
av_gs = niak_normalize_tseries(mean(tseries,2));
eigenvariates = niak_normalize_tseries(eigenvariates);

% Determine PC to be removed
r = (1/(length(av_gs)-1))*(av_gs'*eigenvariates);
[r,ind_pca] = max(abs(r));
pc_gs  = eigenvariates(:,ind_pca);
pc_gs = pc_gs*sign((pc_gs'*av_gs));
