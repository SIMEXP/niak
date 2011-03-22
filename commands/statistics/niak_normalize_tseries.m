function tseries_n = niak_normalize_tseries(tseries,opt)
% Apply some temporal normalization rule to time series.
%
% SYNTAX:
% TSERIES_N = NIAK_NORMALIZE_TSERIES(TSERIES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES_N             
%       (2D array) each column of TSERIES is a time series.
%
% OPT
%       (structure or string) If string, see TYPE below. If structure, 
%       the following fields are supported :
%
%       TYPE
%           (string, default 'mean_var') 
%           the type of temporal normalization. Available options:
%
%               'none'
%                   Don't do anything
%
%               'mean'
%                   Translate the time series to a zero temporal mean.
%
%               'mean_var'          
%                   Correct the time series to zero mean and unit variance.
%
%              'mean_var2' : same as 'mean_var' but slower, yet does not 
%                   use as much memory.
%
%               'median_mad'
%                   Correct the time series to zero median and a
%                   median-absolute-deviation (MAD) corresponding to a
%                   standard-deviation of 1 for a Gaussian process (MAD = 0.6764).
%
%               'grand_mean'
%                   Express the time series as a percentage of the grand
%                   mean of all time series.
%
% _________________________________________________________________________
% OUTPUTS :
%
% TSERIES_N             
%       (2D array) same as data after temporal normalization.
%
% _________________________________________________________________________
% SEE ALSO :
% NIAK_CORRECT_MEAN_VAR
%
% _________________________________________________________________________
% COMMENTS :
%
% time series with zero variance are left as constant zeros.
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de geriatrie 
% de Montreal, Departement d'informatique et de recherche operationnelle, 
% Universite de Montreal, 2008-2010.
% Maintainer : pbellec@criugm.qc.ca
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax 
if ~exist('tseries','var')
    error('Syntax : TSERIES_N = NIAK_NORMALIZE_TSERIES(TSERIES,OPT) ; for more infos, type ''help niak_normalize_tseries''.')
end

if nargin < 2
    opt = 'mean_var';
end

if ischar(opt)
    opt2.type = opt;
    opt = opt2;
    clear opt2;
end

%% Setting up default values for the 'info' part of the header
gb_name_structure = 'opt';
gb_list_fields = {'type','ind_time'};
gb_list_defaults = {'mean_var',[]};
niak_set_defaults

if ismember(opt.type,{'fir','fir_shape'})
    if isempty(ind_time)
        error('please specify the time frames to estimate the mean in OPT.IND_TIME!')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the function starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[nt,nn] = size(tseries); 

switch opt.type
    
    case 'none'
        tseries_n = tseries;

    case {'mean','mean_var2','mean_var'}
        
        tseries_n = niak_correct_mean_var(tseries,opt.type);                
 
    case 'median_mad'
        
        median_ts = median(tseries,1);
        tseries_n = tseries - ones([nt 1])*median_ts;
        std_ts = 1.4785*median(abs(tseries_n),1);
        if ~isempty(tseries_n)&&(any(std_ts~=0))
            tseries_n(:,std_ts~=0) = tseries_n(:,std_ts~=0)./(ones([nt 1])*std_ts(std_ts~=0));
        end
        
    case 'grand_mean'
        
        grand_mean = mean(tseries(:));
        tseries_n = tseries/grand_mean;
                
    otherwise

        error('niak:statistics','%s: unknown type of correction',opt.type);
        
end