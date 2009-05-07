function [Y,X] = niak_visu_spectrum(tseries,tr);
%
% _________________________________________________________________________
% SUMMARY NIAK_VISU_SPECTRUM
%
% Visualization of the power spectrum of one or multiple time series.
%
% SYNTAX:
% [] = NIAK_VISU_SPECTRUM(TSERIES,TR)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (1D array T*N) one or multiple 1D signal (1st dimension is samples)
%
% TR            
%       (real number, default 1) the repetition time of the time series 
%       (this is of course assuming a regular sampling).
%
% _________________________________________________________________________
% OUTPUTS:
%
% Draws the power spectrum of the signal on the current figure.
% Multiple time series lead to subplots.
%
% _________________________________________________________________________
% COMMENTS:
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
T = linspace(0,tr*nt,nt);
X = linspace(0,1/(2*tr),nt/2+1);

for num_f = 1:n
    if n>1
        subplot(M,N,i);
    end
    ftseries = abs(fft(tseries(:,num_f))).^2;
    ftseries = ftseries(1:length(X));    
    Y = ftseries/sum(ftseries);
    plot(X,Y,'*-');        
    xlabel('Relative energy')
    xlabel('Frequency')
    axis([min(X),max(X),0,1]);    
end
