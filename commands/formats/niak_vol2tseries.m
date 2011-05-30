function tseries = niak_vol2tseries(vol,mask)
%
% _________________________________________________________________________
% SUMMARY NIAK_VOL2TSERIES
%
% Convert a 3D+t dataset into a time*space array.
%
% SYNTAX :
% TSERIES = NIAK_VOL2TSERIES(VOL,MASK)
%
% _________________________________________________________________________
% INPUTS :
%
% VOL         
%       (4D array) A 3D+t dataset.
%
% MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       will be included in the time*space array.
%
% _________________________________________________________________________
% OUTPUTS :
%
% TSERIES
%       (2D array) a time*space array with the time series of the voxel in
%       MASK (in the same order as in find(MASK)).
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

if ~exist('vol','var')
    error('Syntax : TSERIES = NIAK_VOL2TSERIES(VOL,MASK) . Type ''help niak_vol2tseries'' for more info');
end

[nx,ny,nz,nt] = size(vol);

if ~exist('mask','var')
    mask = ones([nx,ny,nz]);
end
mask = mask > 0;
[nx2,ny2,nz2] = size(mask);
if (nx~=nx2)||(ny~=ny2)||(nz~=nz2)
    error('The mask should have the same spatial dimensions as the space-time dataset');
end
tseries = reshape(vol,[nx*ny*nz nt]);
tseries = tseries(mask,:)';
