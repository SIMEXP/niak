function tseries_n = niak_correct_mean_var(tseries,type_correction)
% Correct time series to zero mean and unit variance
%
% SYNTAX:
% TSERIES_N = NIAK_CORRECT_MEAN_VAR(TSERIES,TYPE_CORRECTION)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES_N             
%       (2D array) each column of TSERIES is a time series.
%
% TYPE_CORRECTION       
%       (string, default 'mean_var') possible values :
%           'none' : no correction at all                       
%           'mean' : correction to zero mean.
%           'mean_var' : correction to zero mean and unit variance
%           'mean_var2' : same as 'mean_var' but slower, yet does not use 
%               as much memory).
%
% _________________________________________________________________________
% OUTPUTS :
%
% TSERIES_N             (2D array) same as data after mean/variance correction.
%
% _________________________________________________________________________
% COMMENTS :
%
% time series with zero variance are left as constant zeros.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : Statistics, Normalization, Variance

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

% Setting up default options
if nargin < 2
    type_correction = [];
end

if isempty(type_correction)
    type_correction = 'mean_var';
end

[nt,nn] = size(tseries); 

% Correction of mean and eventually variance
switch type_correction
    
    case 'none'
        tseries_n = tseries;

    case 'mean_var'
        
        mean_ts = mean(tseries,1);
        tseries_n = tseries - ones([nt 1])*mean_ts;
        std_ts = (1/sqrt(nt-1))*sqrt(sum(tseries_n.^2,1));        
        if max(std_ts)>0           
            tseries_n(:,std_ts~=0) = tseries_n(:,std_ts~=0)./(ones([nt 1])*std_ts(std_ts~=0));
        end

    case 'mean_var2'
        
        mean_ts = mean(tseries,1);
        tseries_n = zeros(size(tseries));
        
        for num_n = 1:nn
            tseries_n(:,num_n) = tseries(:,num_n) - mean_ts(num_n);
        end
        
        std_ts = (1/sqrt(nt-1))*sqrt(sum(tseries_n.^2,1));
        for num_n=1:nn
            if std_ts(num_n)~=0
                tseries_n(:,num_n) = tseries_n(:,num_n)/std_ts(num_n);
            end
        end

    case 'mean'
        
        mean_ts = mean(tseries,1);
        tseries_n = tseries - ones([nt 1])*mean_ts;
        
    otherwise        
        
        error('niak:statistics','%s: unknown type of correction',type_correction);

end