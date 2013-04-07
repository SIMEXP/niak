function map = niak_build_coord_map(coord,hdr,fwhm)
% Build a 3D volume summary of the distribution of multiple 3D coordinates
% 
% SYNTAX:
% MAP = NIAK_BUILD_COORD_MAP(COORD,HDR,fwhm)
%
% _________________________________________________________________________
% INPUTS:
% 
% COORD
%   (array Vx3) a list of 3D coordinates (in world space)
% 
% HDR 
%   (structure) the header of a 3D (or 4D) volume defining the space.
%   See NIAK_READ_VOL
%
% FWHM
%   (scalar, default 3) the FWHM of the kernel. 
%
% _________________________________________________________________________
% OUTPUTS:
%
% MAP
%   (3D volume) for each coordinate, a Gaussian kernel centered at this coordinate 
%   is added to the volume (and normalized to have a max of 1).
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : meta-analysis

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('coord','var')||~exist('hdr','var')
    error('Syntax : MAP = NIAK_BUILD_COORD_MAP(COORD,HDR,OPT) ; for more infos, type ''help niak_build_coord_map''.')
end

if nargin < 3
    fwhm = 3;
end

sig = fwhm./hdr.info.voxel_size;
ker = sub_build_ker(sig);
ker = ker/max(ker(:));
[kx,ky,kz] = size(ker);
wx = (kx-1)/2;
wy = (ky-1)/2;
wz = (kz-1)/2;
coord_v = niak_coord_world2vox(coord,hdr.info.mat);
nx = hdr.info.dimensions(1);
ny = hdr.info.dimensions(2);
nz = hdr.info.dimensions(3);
map = zeros(hdr.info.dimensions(1:3));
for num_c = 1:size(coord_v,1)
    x = coord_v(num_c,1);
    y = coord_v(num_c,2);
    z = coord_v(num_c,3);        
    map(max(x-wx,1):min(x+wx,nx),max(y-wy,1):min(y+wy,ny),max(z-wz,1):min(z+wz,nz)) = map(max(x-wx,1):min(x+wx,nx),max(y-wy,1):min(y+wy,ny),max(z-wz,1):min(z+wz,nz)) + ker((((x-wx):(x+wx))>0)&(((x-wx):(x+wx))<=nx),(((y-wy):(y+wy))>0)&(((y-wy):(y+wy))<=ny),(((z-wz):(z+wz))>0)&(((z-wz):(z+wz))<=nz));
end

function ker = sub_build_ker(sig)

% Defines the size of the kernel in relation with the Gaussian properties
ww=ceil(3*max(sig));

% Initialise the volume where the kernel is to be drawn
[X,Y,Z]=meshgrid(-ww:1:ww);

% Put it in columns
mu=mean([X(:) Y(:) Z(:)],1);

% Define the output size
outsize=size(X);

% Calculates the amplitude of the PSF
AmplitudePSF=1/((2*pi)^(3/2)*prod(sig)^(1/2));
c_coord=[X(:)-mu(1) Y(:)-mu(2) Z(:)-mu(3)];

% Apply the equation of the Gaussian distribution
T_hand=AmplitudePSF*exp(-0.5*((c_coord(:,1).^2/sig(1))+(c_coord(:,2).^2/sig(2))+(c_coord(:,3).^2/sig(3))));
    
% Reshape to volume
ker=reshape(T_hand,outsize);

