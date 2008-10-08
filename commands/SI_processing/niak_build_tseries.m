function [tseries,all_tseries] = niak_build_tseries(vol,mask,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_TSERIES
%
% Extract time series of one or multiple ROI from a 3D+t dataset.
%
% TSERIES = NIAK_BUILD_TSERIES(VOL,MASK,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL       
%       (3D+t array) the fMRI data. 
%
% MASK      
%       (3D volume) binary mask. The second dimension of TSERIES
%       corresponds to the voxel in FIND(MASK(:))
%
% OPT       
%       (structure, optional) each field of OPT is used to specify an 
%       option. If a field was not specified, then the default value is
%       assumed.
%
%       TYPE_CORRECTION 
%           (string, default 'none') the correction to apply on the time 
%           series. Available options : 'none' (do nothing),'mean', 
%           'mean_var', 'mean_var2' (see NIAK_CORRECT_MEAN_VAR for details)
%
%       TYPE_TSERIES 
%           (string, default 'all') the type of time series to build. 
%           case 'mean' : 
%               the mean time series within each roi of MASK is
%               extracted (voxels in roi i are defined by FIND(MASK==i)).
%               TSERIES is a 2D array (time * space).
%           case 'all' : 
%               all time series in MASK are extracted (voxels in
%               MASK are defined by FIND(MASK>0). TSERIES is a 2D array 
%               (time * space).
%           case 'cell' : 
%             one or multiple rois are define in MASK. TSERIES{i} is a 2D 
%             array of all time series of voxels in region i (defined by 
%             FIND(MASK==i)). TSERIES is a cell of arrays.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES   
%       (array or cell of arrays) see the description of OPT.TYPE_TSERIES.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
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
gb_name_structure = 'opt';
gb_list_fields = {'type_correction','type_tseries'};
gb_list_defaults = {'none','all'};
niak_set_defaults

%% Extracting the labels of regions and reorganizing the data 
[nx,ny,nz,nt] = size(vol);
labels_roi = unique(mask(:));
labels_roi = labels_roi(labels_roi~=0);
nb_rois = length(labels_roi);
tseries_mask = reshape(vol,[nx*ny*nz nt])';
tseries_mask = tseries_mask(:,mask>0);

if ~strcmp(type_correction,'none')
    tseries_mask = niak_correct_mean_var(tseries_mask,type_correction);
end

switch type_tseries

    case 'mean'
        tseries = zeros([size(tseries_mask,1) nb_rois]);
        mask_v = mask(mask>00);
        
        for num_r = 1:nb_rois
            tseries(:,num_r) = mean(tseries_mask(:,mask_v == labels_roi(num_r)),2);            
        end
        
    case 'cell'        
        mask_v = mask(mask~=0);
        tseries = cell([nb_rois 1]);
        for num_r = 1:nb_rois
            tseries{num_r} = tseries_mask(:,mask_v == labels_roi(num_r));                        
        end
        
    case 'all'
        tseries = tseries_mask;
        
end
