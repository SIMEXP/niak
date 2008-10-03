function vol = niak_tseries2vol(tseries,mask)
%
% _________________________________________________________________________
% SUMMARY NIAK_TSERIES2VOL
%
% Convert a time*space array along with a binary mask of voxels into a 3D+t
% dataset.
%
% SYNTAX :
% VOL = NIAK_TSERIES2VOL(TSERIES,MASK)
%
% _________________________________________________________________________
% INPUTS :
%
% TSERIES
%       (2D array) a time*space array with the time series of the voxel in
%       MASK (in the same order as in find(MASK)).
%
% MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       are included in the time*space array.
%
% _________________________________________________________________________
% OUTPUTS :
%
% VOL         
%       (4D array) A 3D+t dataset.
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
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

if ~exist('tseries','var')|~exist('mask','var')
    error('Syntax : VOL = NIAK_TSERIES2VOL(TSERIES,MASK) . Type ''help niak_tseries2vol'' for more info');
end

[nx,ny,nz] = size(mask);

mask = mask>0;

nt = size(tseries,1);

if sum(mask(:))~= size(tseries,2)
    error('the space dimension in TSERIES should have the same size as the number of voxels in mask !');
end

vol = zeros([nx*ny*nz nt]);
vol(mask,:) = tseries';
vol = reshape(vol,[nx ny nz nt]);