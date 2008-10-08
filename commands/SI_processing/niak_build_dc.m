function [tseries_dc,list_freq] = niak_build_dc(opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_DC
%
% Create a Discrete-Cosine (DC) basis of signals which cover a given
% frequency window for a given sampling frequency and signal length.
% 
% SYNTAX:
% TSERIES_DC = NIAK_BUILD_DC(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT           
%       (structure) with the following fields :
%
%       TR   
%           (real) the repetition time of the time series (s) which is the 
%           inverse of the sampling frequency (Hz).
%
%       NT   
%           (integer) the length of the time series. 
%
%       TYPE_FW 
%           (string) the type of frequency window (either 'low' or 'high')
%
%       CUTOFF 
%           (real value) the cut-off frequency. For low window, the window 
%           is [0,CUTOFF], and for a high window is is [CUTOFF,NF], where 
%           NF is the Nyquist frequency.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES_DC   
%       (2D array) each column is a discrete cosine.
%
% LIST_FREQ    
%       (VECTOR) LIST_FREQ(i) is the frequency associated to 
%       TSERIES_DC(:,i).
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_FILTER_TSERIES
%
% _________________________________________________________________________
% COMMENTS:
%
% The discrete cosine are normalized in such a way that their empirical
% mean is 0 and empirical variance is 1, except for the constant cosine which 
% is always equal to sqrt(1-1/nt)^(-1).
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : Discrete Cosine, Filtering

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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'tr','nt','type_fw','cutoff'};
gb_list_defaults = {NaN,NaN,NaN,NaN};
niak_set_defaults

tim = (0:nt-1)';

switch type_fw
    case 'low'

        num_dc = min(floor((2*nt*tr)*cutoff),nt-1);
        if num_dc < 0
            tseries_dc = [];
            freq_num = [];
        else
            freq_num = 0:num_dc;
            tseries_dc  = zeros([nt num_dc+1]);
            tseries_dc(:,2:num_dc+1) = cos(pi*tim*freq_num(2:end)/nt);
            tseries_dc(:,2:num_dc+1) = niak_correct_mean_var(tseries_dc(:,2:num_dc+1));
            tseries_dc(:,1) = sqrt((nt-1)/nt);
        end

    case 'high'
        
        num_dc = max(ceil((2*nt*tr)*cutoff),1);
        if num_dc > nt
            tseries_dc = [];
            freq_num = [];
        else
            freq_num = num_dc:nt;
            tseries_dc  = zeros([nt num_dc+1]);
            tseries_dc = cos(pi*tim*freq_num/nt);
            tseries_dc = niak_correct_mean_var(tseries_dc);

            if num_dc == 0
                tseries_dc(:,1) = sqrt((nt-1)/nt);
            end
        end
        
    otherwise

        error('niak:SI_processing','%s : unknown type of frequency window',type_fw)

end

list_freq = freq_num(:)/(2*nt*tr);