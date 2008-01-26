function vol3d2 = niak_conv3_sep(vol3d,fx,fy,fz)

% 3D convolution of a volume with a separable kernel
%
% SYNTAX
% vol3d2 = niak_conv3_sep(vol3d,fx,fy,fz)
%
% INPUTS
% vol3d       (3D array) a volume
% fx,fy,fz    (1D arry) the respective kernels in dimensions x, y and z
%               respectively.
%
% OUTPUTS
% vol3d2      (3D array) the (3D) convolution (fz*fy*fz)*vol3d.
%
% SEE ALSO
% niak_smooth_vol
%
% COMMENTS
% 
% Copyright (c) Pierre Bellec 01/2008

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


[nx,ny,nz] = size(vol3d);

% Performing convolution along the x axis
vol3d2 = reshape(vol3d,[nx ny*nz]);
vol3d2 = sub_convfft(vol3d2,fx);

% Performing the convolution along the y axis
vol3d2 = reshape(vol3d2,[nx ny nz]);
vol3d2 = permute(vol3d2,[2 1 3]);
vol3d2 = reshape(vol3d2,[ny nx*nz]);
vol3d2 = sub_convfft(vol3d2,fy);

% Performing the convolution along the z axis
vol3d2 = reshape(vol3d2,[ny nx nz]);
vol3d2 = permute(vol3d2,[3 2 1]);
vol3d2 = reshape(vol3d2,[nz nx*ny]);
vol3d2 = sub_convfft(vol3d2,fz);

% Output
vol3d2 = reshape(vol3d2,[nz nx ny]);
vol3d2 = permute(vol3d2,[2 3 1]);

function sig2 = sub_convfft(sig,ker)
% 1-D convolution implemented through fft

flag_err = 0;
nbm = size(sig,1);
nbn = length(ker);

% Zeros-padding of the signals and kernel, and Fourier transform

fker = fft([ker(:) ; zeros([nbm-1 1])]);
fsig = fft([sig ; zeros([nbn-1 size(sig,2)])]);
% convolution by multiplication in the Fourier domain and inverse Fourier
% transform
sig2 = ifft((fker*ones([1 size(fsig,2)])).*fsig);
sig2 = real(sig2(1+ceil((nbn-1)/2):end-(floor((nbn-1)/2)),:));

