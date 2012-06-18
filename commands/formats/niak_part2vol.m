function vol = niak_part2vol(part,mask);
% Convert a partition of N individual regions into 3D maps of clusters.
%
% SYNTAX:
% VOL = NIAK_PART2VOL(PART,MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% PART
%   (vector) PART(I) is the number of the cluster of region I.
%
% MASK
%   (3D volume) MASK==I is a binary mask of region I.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL
%   (3D volume) VOL==K is a binary mask of the Kth cluster.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function will work with any vector of scalar values PART. This means
% that in MASK, region K will be replaced by the values found in PART(K)
% whatever that value is, integer or scalar. 
%
% PART have multiple rows and columns. In this case, VOL will be a 4D array
% where each volume will correspond to one row of PART. (Think as colums of
% PART as time series and VOL as a 3D+t dataset).
%
% Copyright (c) Pierre Bellec
%   McConnell Brain Imaging Center, Montreal 
%   Neurological Institute, McGill University, 2007-2011.
%   Centre de recherche de l'institut de Gériatrie de Montréal, 
%   Département d'informatique et de recherche opérationnelle, 
%   Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : partition, roi

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
if size(part,1)>1 && size(part,2)>1
    vol = zeros([size(mask) size(part,1)]);
    for num_v = 1:size(part,1)
        vol_tmp = zeros(size(mask));
        vol_tmp(mask>0) = part(num_v,mask(mask>0));
        vol(:,:,:,num_v) = vol_tmp;
    end
else
    vol = zeros(size(mask));
    vol(mask>0) = part(mask(mask>0));
end
