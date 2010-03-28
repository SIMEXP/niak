function tseries_n = niak_normalize_tseries(tseries,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_NORMALIZE_TSERIES
%
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
%       (structure) with the following fields :
%
%       TYPE
%           (string) the type of temporal normalization. Available options:
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
%               'grand_mean'
%                   Express the time series as a percentage of the grand
%                   mean of all time series.
%
%               'fir'
%                   Correct the mean of the time samples OPT.IND_TIME to 
%                   zero.
%
%               'shape_fir'
%                   Same as 'fir*', except that the 2-norm of the time
%                   series are normalized to 1.
%                   
%       If OPT.TYPE = 'fir'
%
%           IND_TIME
%               (vector of integers) the indices of the time samples
%               considered in the shift to zero mean.
%
% _________________________________________________________________________
% OUTPUTS :
%
% TSERIES_N             
%       (2D array) same as data after temporal normalization.
%
% _________________________________________________________________________
% SEE ALSO :
%
% NIAK_CORRECT_MEAN_VAR
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax 
if ~exist('tseries','var')||~exist('opt','var')
    error('Syntax : TSERIES_N = NIAK_NORMALIZE_TSERIES(TSERIES,OPT) ; for more infos, type ''help niak_normalize_tseries''.')
end

%% Setting up default values for the 'info' part of the header
gb_name_structure = 'opt';
gb_list_fields = {'type','ind_time'};
gb_list_defaults = {NaN,[]};
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
        
        mean_ts = mean(tseries,1);
        tseries_n = tseries - ones([nt 1])*mean_ts;
        std_ts = (1/sqrt(nt-1))*sqrt(sum(tseries_n.^2,1));        
        if ~isempty(tseries_n)&&(any(std_ts~=0))
            tseries_n(:,std_ts~=0) = tseries_n(:,std_ts~=0)./(ones([nt 1])*std_ts(std_ts~=0));
        end
 
    case 'grand_mean'
        
        grand_mean = mean(tseries(:));
        tseries_n = tseries/grand_mean;
        
    case 'fir'
        
        mean_ts = mean(tseries(opt.ind_time,:),1);
        tseries_n = tseries - ones([nt 1])*mean_ts;

    case 'fir_shape'
        
        mean_ts = mean(tseries(opt.ind_time,:),1);
        tseries_n = tseries - ones([nt 1])*mean_ts;
        norm2_ts = sqrt(sum(tseries_n.^2,1)/(nt-1));
        tseries_n(:,norm2_ts~=0) = tseries_n(:,norm2_ts~=0) ./ (ones([nt 1])*norm2_ts(:,norm2_ts~=0));
        
    otherwise

        error('niak:statistics','%s: unknown type of correction',opt.type);
        
end