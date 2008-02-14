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

%% Fourier transform of the kernels
ffx = fft([fx(:) ; zeros([nx-1 1])]);
ffy = fft([fy(:) ; zeros([ny-1 1])]);
ffz = fft([fz(:) ; zeros([nz-1 1])]);

%% Performing convolution along the x axis
vol_c = reshape(vol,[nx ny*nz]);
clear vol % VOL is not necessary anymore

vol_c = [vol_c ; zeros([length(fx)-1 size(vol_c,2)])];
vol_c = fft(vol_c);
vol_c = diag(ffx)*vol_c;
vol_c = ifft(vol_c);
vol_c = real(vol_c(1+ceil((length(fx)-1)/2):end-(floor((length(fx)-1)/2)),:));

%% Performing the convolution along the y axis
vol_c = reshape(vol_c,[nx ny nz]);
vol_c = permute(vol_c,[2 1 3]);
vol_c = reshape(vol_c,[ny nx*nz]);
vol_c = [vol_c ; zeros([length(fy)-1 size(vol_c,2)])];
vol_c = fft(vol_c);
vol_c = diag(ffy)*vol_c;
vol_c = ifft(vol_c);
vol_c = real(vol_c(1+ceil((length(fy)-1)/2):end-(floor((length(fy)-1)/2)),:));

%% Performing the convolution along the z axis
vol_c = reshape(vol_c,[ny nx nz]);
vol_c = permute(vol_c,[3 2 1]);
vol_c = reshape(vol_c,[nz nx*ny]);
vol_c = [vol_c ; zeros([length(fz)-1 size(vol_c,2)])];
vol_c = fft(vol_c);
vol_c = diag(ffz)*vol_c;
vol_c = ifft(vol_c);
vol_c = real(vol_c(1+ceil((length(fz)-1)/2):end-(floor((length(fz)-1)/2)),:));

% Output
vol_c = reshape(vol_c,[nz nx ny]);
vol_c = permute(vol_c,[2 3 1]);