function [Y,X] = niak_visu_spectrum(tseries,tr,flag_visu);
% Visualization of the power spectrum of one or multiple time series.
%
% SYNTAX:
% [SPCTM,FREQ] = NIAK_VISU_SPECTRUM(TSERIES,TR,FLAG_VISU)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES 
%    (1D array T*N) one or multiple 1D signal (1st dimension is samples)
%
% TR            
%    (real number, default 1) the repetition time of the time series. This 
%    function assumes a regular sampling).
%
% FLAG_VISU
%    (boolean, default true) if FLAG_VISU is true, display the power spectrum
%    in the current window.
%
% _________________________________________________________________________
% OUTPUTS:
%
% SPCTM
%    (vector) the spectrum of TSERIES.
%
% FREQ
%    (vector) SPCTM(I) is associated with the FREQ(I) frequency.
%
% _________________________________________________________________________
% EXAMPLE:
% tseries = randn([100 1]) + (1:100)';
% [spctm,freq] = niak_visu_spectrum(tseries);
%
% _________________________________________________________________________
% COMMENTS:
%
% The function plots the power spectrum of the signal on the current figure.
% Multiple time series lead to subplots.
%
% The spectrum is normalized by the energy of the signal (sum of the energy 
% at all frequencies equals 1).
%
% Copyright (c) Pierre Bellec, 
% McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008-2010.
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2010-2011.
% Maintainer : pierre.bellec@criugm.qc.ca
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
if nargin<3
    flag_visu = true;
end

M = ceil(sqrt(n));
N = ceil(n/M);
T = linspace(0,tr*nt,nt);
X = linspace(0,1/(2*tr),nt/2+1);

for num_f = 1:n
    if (n>1)&&flag_visu
        subplot(M,N,num_f);
    end
    ftseries = abs(fft(tseries(:,num_f))).^2;
    ftseries = ftseries(1:length(X));    
    if num_f == 1
        Y = zeros([size(ftseries,1) n]);
    end
    Y(:,num_f) = ftseries/sum(ftseries);
    if flag_visu
        plot(X,Y(:,num_f),'*-');        
        xlabel('Relative energy')
        xlabel('Frequency')
        axis([min(X),max(X),0,1]);    
    end
end
