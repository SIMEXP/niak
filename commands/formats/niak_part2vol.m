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
%   (array T x V) PART(t,I) is the number associated with region I for 
%   volume #i
%
% MASK
%   (array with arbitrary number of dimensions, coding for "space", with a 
%   total of V elements) 
%   MASK==I is a binary mask of region I.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL
%   (size of MASK x T) the VOL(:,...,:,t) corresponds to the volues of PART(t,:),
%   organized like MASK. In other words, the "t"th volume, the "i"th region of 
%   mask is "painted" with the value PART(t,i).
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
%   Université de Montréal, 2011-2013.
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
    vol = zeros(size(part,1),length(mask(:)));
    vol(:,mask>0) = part(:,mask(mask>0));
    vol = vol';
    if (ndims(mask)==2) && ( (size(mask,1) == 1) || (size(mask,2) == 1))
        vol = reshape(vol,[length(mask) size(part,1)]);    % It's a vector Joe !
    else
        vol = reshape(vol,[size(mask) size(part,1)]);    % That is a N-D N>=3 array
    end
else
    vol = zeros(size(mask));
    vol(mask>0) = part(mask(mask>0));
end
