function [tseries_f,extras] = niak_filter_tseries(tseries,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_FILTER_TSERIES
%
% Filter time series using Discrete-Cosine (DC) least-square linear 
% regression.
%
% SYNTAX:
% TSERIES_F = NIAK_FILTER_TSERIES(TSERIES,OPT) 
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (2D array, size T*N) a time*space array of time series.
%
% OPT           
%       (structure) with the following fields:
%
%       TR 
%           (real) the repetition time of the time series (s)
%           which is the inverse of the sampling frequency (Hz).
%
%       HP 
%           (real, default -Inf) the cut-off frequency for high pass
%           filtering. opt.hp = -Inf means no high-pass filtering.
%           
%       LP 
%           (real, default Inf) the cut-off frequency for low pass
%           filtering. opt.lp = Inf means no low-pass filtering.
%
%       FLAG_MEAN
%           (boolean, default: 0) if FLAG_MEAN is 1, the funtion does leave
%           the mean of the time series after filtering (it is otherwise
%           suppressed as soon as a high-pass filter is applied with a
%           threshold greater than 0).
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES_F    
%       (2D array, size T*N) a time*space array of filtered tseries.
%
% EXTRAS       
%       (structure) with the following fields :
%
%       TSERIES_DC_LOW  
%           (2D array, size T*Kl) a (time*nb cosines)
%           array of discrete cosines covering the frequency window that is 
%           to be suppressed in high-pass filtering.
%
%       BETA_DC_LOW  
%           (2D ARRAY, size Kl*N) a (nb cosines * space)
%           array such that BETA_DC_LOW(k,n) is the weight of the
%           low-frequency discrete cosine number k at location n.
%           
%       FREQ_DC_LOW 
%           (vector, size Kl*1) FREQ_DC_LOW(k) is the frequency associated 
%           to cosine TSERIES_DC_LOW(:,k)
%           
%       TSERIES_DC_HIGH  
%           (2D array, size T*Kh) a (time*nb cosines)
%           array of discrete cosines covering the frequency window that is 
%           to be suppressed in low-pass filtering.
%           
%       BETA_DC_HIGH  
%           (2D ARRAY, size Kl*N) a (nb cosines * space)
%           array such that BETA_DC_HIGH(k,n) is the weight of the
%           high-frequency discrete cosine number k at location n.
%
%       FREQ_DC_HIGH 
%           (vector, size Kl*1) FREQ_DC_HIGH(k) is the frequency associated 
%           to cosine TSERIES_DC_HIGH(:,k)
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : Signal Processing, Filtering, Discrete Cosine, Time series

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up the defaults arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'flag_mean','tr','hp','lp'};
gb_list_defaults = {false,NaN,-Inf,Inf};
niak_set_defaults

if ~(isinf(opt.lp)==1)&((opt.lp<0)|(opt.lp>(1/(2*tr))))
    error('niak:SI_processing : Please specify a cut-off frequency for low-pass filtering that is larger than 0 and smaller than the Nyquist frequency %1.2f Hz\n',1/(2*tr))
    return
end
    
if ~(isinf(opt.hp)==1)&((opt.hp<0)|(opt.hp>(1/(2*tr))))
    error('niak:SI_processing : Please specify a cut-off frequency for high-pass filtering that is larger than 0 and smaller than the Nyquist frequency %1.2f Hz\n',1/(2*tr))   
end

nt = size(tseries,1);

% Building the low-frequency DC matrix
opt_dc.tr = tr;
opt_dc.nt = nt;
opt_dc.type_fw = 'low';
opt_dc.cutoff = opt.hp;
[Q_low,freq_low] = niak_build_dc(opt_dc);

if (flag_mean)&&(size(Q_low,2)>1)
    Q_low = Q_low(:,2:end);
    freq_low = freq_low(2:end);
end
% Building the high-frequency DC matrix
opt_dc.type_fw = 'high';
opt_dc.cutoff = opt.lp;
[Q_high,freq_high] = niak_build_dc(opt_dc);

%%% Exctracting residuals after linear regression
Q = [Q_low,Q_high];
if ~isempty(Q)
    [beta,tseries_f] = niak_lse(tseries,Q);
else
    beta = [];
    tseries_f = tseries;
end

if nargout > 1
    extras.tseries_dc_low = Q_low;
    extras.beta_dc_low = beta(1:size(Q_low,2),:);
    extras.freq_dc_low = freq_low;
    extras.tseries_dc_high = Q_high;
    extras.beta_dc_high = beta(size(Q_low,2)+1:end,:);
    extras.freq_dc_high = freq_high;
end

