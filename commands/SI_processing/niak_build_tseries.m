function [tseries,std_tseries,labels_roi] = niak_build_tseries(vol,mask,opt)
% Extract the mean and std of time series of in multiple ROI 
% from a 3D+t dataset.
%
% [TSERIES,STD_TSERIES,LABELS_ROI] = NIAK_BUILD_TSERIES(VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL       
%   (3D+t array or timeXspace array) the fMRI data. 
%
% MASK      
%   (3D volume or vector) mask or ROI coded with integers. 
%   ROI #I is defined by MASK==I
%
% OPT       
%   (structure, optional) each field of OPT is used to specify an 
%   option. If a field was not specified, then the default value is
%   assumed.
%
%   CORRECTION
%      (structure, default CORRECTION.TYPE = 'none') the temporal 
%      normalization to apply on the individual time series before 
%      averaging in each ROI. See OPT in NIAK_NORMALIZE_TSERIES.
%
%   FLAG_ALL
%     (boolean, default false) if FLAG_ALL is true, the time series
%     of all voxels found in MASK>0 will be sent in TSERIES, rather
%     than the mean time series.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES   
%   (array) TSERIES(:,I) is the mean time series in the ROI MASK==I.
%   In this case, STD_TSERIES is a sparse matrix full of zeros.
%
% STD_TSERIES   
%   (arrays) STD_TSERIES(:,I) is the standard deviation of the time 
%   series in the ROI MASK==I.
%
% LABELS_ROI
%   (vector) LABELS_ROI is the labels of the Ith ROI.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
%   McConnell Brain Imaging Center,Montreal
%   Neurological Institute, McGill University, 2008-2010.
%   Research Centre of the Montreal Geriatric Institute
%   & Department of Computer Science and Operations Research
%   University of Montreal, Québec, Canada, 2010-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : ROI, time series, fMRI

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

%% Setting up default inputs
opt_norm.type = 'none';
gb_name_structure = 'opt';
gb_list_fields = {'flag_all','correction'};
gb_list_defaults = {false,opt_norm};
niak_set_defaults

%% Extracting the labels of regions and reorganizing the data 
if ndims(vol)>2
    tseries_mask = niak_vol2tseries(vol,mask>0);
    mask_v = mask(mask>0);
else
    tseries_mask = vol(:,mask>0);
    mask_v = mask(mask>0);
end

labels_roi = unique(mask(:));
labels_roi = labels_roi(labels_roi~=0);
nb_rois = length(labels_roi);

tseries_mask = niak_normalize_tseries(tseries_mask,opt.correction);

if flag_all
    tseries = tseries_mask;
    std_tseries = sparse(size(tseries));
else
    tseries = zeros([size(tseries_mask,1) nb_rois]);
    std_tseries = zeros([size(tseries_mask,1) nb_rois]);    

    for num_r = 1:nb_rois
        tseries(:,num_r) = mean(tseries_mask(:,mask_v == labels_roi(num_r)),2);
        std_tseries(:,num_r) = std(tseries_mask(:,mask_v == labels_roi(num_r)),0,2);
    end
end