function vol_c = niak_conv3_sep(vol,fx,fy,fz)
%
% _________________________________________________________________________
% SUMMARY NIAK_CONV3_SEP
%
% 3D convolution of a volume with a separable kernel
%
% SYNTAX:
% VOL_C = NIAK_CONV3_SEP(VOL,FX,FY,FZ)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL         
%       (3D array) a volume
%
% FX,FY,FZ    
%       (1D array, odd length) the respective kernels in dimensions x, y 
%       and z respectively. The first sample is for t=0, and the function
%       is assumed to be periodic (typically, the kernel has non-zero 
%       values clustered in the extreme portions of the vector, and has 
%       zeros in the middle par). The length of the kernel needs to be odd.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL      
%       (3D array) the (3D) convolution (FZ*FY*FZ)*VOL, where * is 
%       convolution.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_SMOOTH_VOL
%
% _________________________________________________________________________
% COMMENTS:
% 
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : convolution, 3D, separable kernel

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
mx = length(fx); my = length(fy); mz = length(fz);
if (mx/2==floor(mx/2))|(my/2==floor(my/2))|(mz/2==floor(mz/2))
    error('niak:SI_processing','The kernel should be of the form 2*N+1')
end

%% Zero-padded Fourier transform of the kernels
ffx = fft([fx(1:floor(mx/2)+1) zeros([1 nx]) fx(floor(mx/2)+2:mx)]');
ffy = fft([fy(1:floor(my/2)+1) zeros([1 ny]) fy(floor(my/2)+2:my)]');
ffz = fft([fz(1:floor(mz/2)+1) zeros([1 nz]) fz(floor(mz/2)+2:mz)]');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Performing convolution along the x axis %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vol_c = reshape(vol,[nx ny*nz]); 
clear vol % VOL is not necessary anymore

%% 1D convolution via fft along the x-axis
vol_c = [vol_c ; zeros([mx size(vol_c,2)])]; % Zero-padding in the x direction
vol_c = fft(vol_c); % 1D Fourier transform along x direction
vol_c = diag(ffx)*vol_c; % Multiplying each column by the Fourier transform of the kernel. Doing it this way favors memory against computational time...
vol_c = ifft(vol_c); % Getting back to real values
vol_c = real(vol_c(1:nx,:)); % Extracting the part of the signal unspoiled by padding

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Performing the convolution along the y axis %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vol_c = reshape(vol_c,[nx ny nz]);
vol_c = permute(vol_c,[2 1 3]);
vol_c = reshape(vol_c,[ny nx*nz]);

%% 1D convolution via fft along the y-axis
vol_c = [vol_c ; zeros([my size(vol_c,2)])]; % Zero-padding in the y direction
vol_c = fft(vol_c); % 1D Fourier transform along y direction
vol_c = diag(ffy)*vol_c; % Multiplying each column by the Fourier transform of the kernel. Doing it this way favors memory against computational time...
vol_c = ifft(vol_c); % Getting back to real values
vol_c = real(vol_c(1:ny,:)); % Extracting the part of the signal unspoiled by padding

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Performing the convolution along the z axis %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vol_c = reshape(vol_c,[ny nx nz]);
vol_c = permute(vol_c,[3 2 1]);
vol_c = reshape(vol_c,[nz nx*ny]);

%% 1D convolution via fft along the z-axis
vol_c = [vol_c ; zeros([mz size(vol_c,2)])]; % Zero-padding in the z direction
vol_c = fft(vol_c); % 1D Fourier transform along z direction
vol_c = diag(ffz)*vol_c; % Multiplying each column by the Fourier transform of the kernel. Doing it this way favors memory against computational time...
vol_c = ifft(vol_c); % Getting back to real values
vol_c = real(vol_c(1:nz,:)); % Extracting the part of the signal unspoiled by padding

%%%%%%%%%%%%
%% Output %%
%%%%%%%%%%%%
vol_c = reshape(vol_c,[nz nx ny]);
vol_c = permute(vol_c,[2 3 1]);