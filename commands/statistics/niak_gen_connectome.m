function [R_ind]=niak_gen_connectome(vol,brain_rois,order)
% Extract the connectome from a 3D+t dataset.
%
% [R_IND] = NIAK_GEN_CONNECTOME(VOL,BRAIN_ROIS,ORDER)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL       
%   (3D+t array) the fMRI data. 
%
% BRAIN_ROIS      
%   (3D volume) mask or ROI coded with integers. ROI #I is defined by 
%   MASK==I
%
% ORDER       
%   (optional) the order of eahc index of the connectome index
%
% _________________________________________________________________________
% OUTPUTS:
%
% R_IND   
%   (array) The connectome of the 3D+t dataset
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal,
% 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : connectome, fMRI

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

[tseries_rois,std_tseries_rois] = niak_build_tseries(vol,brain_rois);

%% Correcting the mean of the time series

fprintf('Correction of the mean of time series ...\n');
opt_norm.type = 'mean_var';
tseries_rois = niak_normalize_tseries(tseries_rois,opt_norm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% connectome computation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Computing the connectome from the time series ...\n');
R_ind = corrcoef(tseries_rois);

% If order is specified
if exist('order')
    R_ind = R_ind(order,order);
end

