function [] = niak_visu_wft(tseries,tr);

% Visualization of the window Fourier transform of a 1D signal.
%
% SYNTAX:
% [] = NIAK_VISU_WFT(TSERIES,TR)
%
% INPUTS:
%
% TSERIES       (1D array T*1) one or multiple 1D signal (1st dimension is
%                   samples)
%
% TR            (real number, default 1) the repetition time of the time
%                   series (this is of course assuming a regular sampling).
%
% OUTPUTS:
% Draws the Fourier Window transform of the signal on the current figure.
% Multiple time series lead to subplots.
%
% COMMENTS:
% The core of this function is part of the Wavelab toolbox :
% http://www-stat.stanford.edu/~wavelab/
% See the code of subfunctions for licensing information.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, montage, visualization

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

[nt,n] = size(tseries);
if nargin<2
    tr = 1;
end
M = ceil(sqrt(n));
N = ceil(n/M);
for i = 1:n
    if n>1
        subplot(M,N,i);
    end
    WFT(tseries(:,i),floor(nt*tr/(8)),1,'Gaussian',tr);
end

colormap('jet')

function win=MakeWindow(Name,n)
% MakeWindow -- Make artificial Window
%  Usage
%    wig = MakeWindow(Name,n)
%  Inputs
%    Name   string: 'Rectangle', 'Hanning', 'Hamming',
%            'Gaussian', 'Blackman';
%    n      desired half Window length
%  Outputs
%    win    1-d Window, with length 2n+1;
%  Description
%    Rectangle		1
%    Hanning 		cos(pi*t)^2
%    Hamming		.54 + .46cos(2pi*t)
%    Gaussian		exp(-18 * t^2/2)
%    Blackman		.42 + .50*cos(2pi*t) + .08cos(4.*pi.*t)
%  Examples
%     win = MakeWindow('Rectangle',17);	plot(win);
%     win = MakeWindow('Hanning',  17);	plot(win);
%     win = MakeWindow('Hamming',  17);	plot(win);
%     win = MakeWindow('Gaussian', 17);	plot(win);
%     win = MakeWindow('Blackman', 17);	plot(win);
%  See Also
%
%  Algorithm
%    Easy to implement.
%  References
%    Mallat, "Wavelet Signal Processing"; 4.2.2 Choice of Window.
%
t = ((1:(2*n+1))-(n+1))./n./2;

if strcmp(Name,'Rectangle'),
    win = ones(size(t));
elseif strcmp(Name,'Hanning'),
    win = realpow(cos(pi.*t),2);
elseif strcmp(Name,'Hamming'),
    win = .54 + .46*cos(2.*pi.*t);
elseif strcmp(Name,'Gaussian'),
    win = exp(-realpow(t,2)*18);
elseif strcmp(Name,'Blackman'),
    win = .42 + .50*cos(2.*pi.*t) + .08*cos(4.*pi.*t);
end;

%


%
% Copyright (c) 1996. Xiaoming Huo
%
% Modified by Maureen Clerc and Jerome Kalifa, 1997
% clerc@cmapx.polytechnique.fr, kalifa@cmapx.polytechnique.fr


%
% Part of WaveLab Version 802
% Built Sunday, October 3, 1999 8:52:27 AM
% This is Copyrighted Material
% For Copying permissions see COPYING.m
% Comments? e-mail wavelab@stat.stanford.edu
%

function [specgm,specgmShow,T,F] = WFT(sig,w,m,Name,tr,trace)
% WindowFT -- Window Fourier Transform
%  Usage
%    specgm = WindowFT(sig,w,m,Name,tr)
%  Inputs
%    sig      1-d signal
%    w        window half-length, default = n/2
%    m        inter-window spacing, default=1
%    Name     string: 'Rectangle', 'Hanning', 'Hamming',
%             'Gaussian', 'Blackman'; Default is 'Rectangle'
%    tr       inter-scan time.
%  Outputs
%    specgm   Window Fourier Transform of sig, n+1 by n complex matrix
%  Side Effects
%    Image Plot of the Window Fourier Transform
%  Algorithm
%     supposes signal is non-periodic, i.e. zero-padded
%  Example
%    sig = ReadSignal('Caruso');
%    sig = sig(1:128);
%    specgm = WindowFT(sig);
%  See Also
%    MakeWindow IWindowFT
%  References
%    Mallat, "A Wavelet Tour in Signal Processing";
%            4.2.3 Discrete Windowed Fourier Transform.
%
sig = sig(:);
n = length(sig);
f = [zeros(n,1); sig; zeros(n,1)];

% Default parameters,
if nargin<6
    trace=1;
end
% Initialize output matrix,
nw     = floor(n ./ m);
specgm = zeros(n,nw);
ix     = ((-w):w);
win    = MakeWindow(Name,w);
win    = win(:);

% Computing Window Fourier Transform
for l=1:nw,
    totseg = zeros(1,3*n);
    t = 1+ (l-1)*m;
    tim = n + t + ix;
    seg = f(tim);
    seg = seg.*win;

    totseg(tim) = seg;

    localspec = fft(totseg(n+1:2*n));
    specgm(:,l)  = localspec(1:n)';
end

% Make Window Fourier Transform Display

specgmShow = abs(specgm((1:(n/2+1))',:));
spmax = max(max(specgmShow));
spmin = min(min(specgmShow));
T = linspace(0,tr*n,n);
F = linspace(0,1/(2*tr),n/2+1);

if trace
    colormap(1-gray(256))

    imagesc(linspace(0,tr*n,n),linspace(0,1/(2*tr),n/2+1),specgmShow);
    %hold on
    %contour(linspace(0,tr*n,n),linspace(0,1/(2*tr),n/2+1),specgmShow,'k-');

    axis('xy')
    xlabel('')
    ylabel('Frequency')
end

if nargout==0,
    specgm = [];
end

%
% Copyright (c) 1996. Xiaoming Huo
%
% Modified by Maureen Clerc and Jerome Kalifa, 1997
% clerc@cmapx.polytechnique.fr, kalifa@cmapx.polytechnique.fr
% Modified by Pierre Bellec and Vincent Perlbarg 2003
% pierre.bellec@imed.jussieu.fr, vincent.perlbarg@imed.jussieu.fr
