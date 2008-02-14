function vol_c = niak_conv3_sep(vol,fx,fy,fz)

% 3D convolution of a volume with a separable kernel
%
% SYNTAX:
% VOL_C = NIAK_CONV3_SEP(VOL,FX,FY,FZ)
%
% INPUTS:
% VOL         (3D array) a volume
% FX,FY,FZ    (1D arry) the respective kernels in dimensions x, y and z
%               respectively.
%
% OUTPUTS:
% VOL      (3D array) the (3D) convolution (FZ*FY*FZ)*VOL, where * is convolution.
%
% SEE ALSO:
% NIAK_SMOOTH_VOL
%
% COMMENTS
% 
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, convolution, fMRI

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


[nx,ny,nz] = size(vol);

% Performing convolution along the x axis
vol_c = reshape(vol,[nx ny*nz]);
vol_c = sub_convfft(vol_c,fx);

% Performing the convolution along the y axis
vol_c = reshape(vol_c,[nx ny nz]);
vol_c = permute(vol_c,[2 1 3]);
vol_c = reshape(vol_c,[ny nx*nz]);
vol_c = sub_convfft(vol_c,fy);

% Performing the convolution along the z axis
vol_c = reshape(vol_c,[ny nx nz]);
vol_c = permute(vol_c,[3 2 1]);
vol_c = reshape(vol_c,[nz nx*ny]);
vol_c = sub_convfft(vol_c,fz);

% Output
vol_c = reshape(vol_c,[nz nx ny]);
vol_c = permute(vol_c,[2 3 1]);

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

