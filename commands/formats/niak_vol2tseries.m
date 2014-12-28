function tseries = niak_vol2tseries(vol,mask)
% Convert a 3D+t dataset into a time*space array.
%
% TSERIES = NIAK_VOL2TSERIES(VOL,MASK)
%
% VOL      (4D array) A 3D+t dataset.
% MASK     (3D volume, default all voxels) a binary mask of the voxels that 
%          will be included in the time*space array.
% TSERIES  (2D array) a time*space array with the time series of the voxel in
%          MASK (in the same order as in find(MASK)).
% Copyright (c) Pierre Bellec, See licensing information in the code.
% Maintainer : pierre.bellec@criugm.qc.ca

% Montreal Neurological Institute, 2008-2010.
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2010-2014
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
