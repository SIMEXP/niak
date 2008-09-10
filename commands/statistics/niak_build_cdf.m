function [cdfs,bins] = niak_build_cdf(samps,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_CDF
%
% Build a cumulative distribution function (cdf) from samples.
%
% SYNTAX:
% [CDFS,BINS] = NIAK_BUILD_CDF(SAMPS,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% * SAMPS     
%       (matrix) each column of samps is a series of samples.
% 
% * OPT       
%       (structure) with the following fields:
%           
%           BINS   
%               (vector, default [min(SAMPS) max(SAMPS)] with 100 points)
%               Points were the cdf is estimated through linear
%               interpolation. if BINS has only one column, the same points 
%               are used for all columns of samps.
%
%           VALX 
%               (vector, default []) add a constraint on interpolations
%               for coordinate VALX
%           VALY
%               (vector, default []) add a constraint on interpolations
%               setting value VALY for coordinates VALX
%
% _________________________________________________________________________
% OUTPUTS:
%
% * CDFS      
%       (matrix) each column of CDFS is the estimated cdf of the
%       distribution of the corresponding column of SAMPS, 
%       at the points specified in the corresponding column of BINS.
%       The values described in (VALX,VALY) are added as constraints in
%       the interpolation.
%
% _________________________________________________________________________
% COMMENTS:
% For a bounded statistics, e.g. correlation coefficient, VALX and VALY are 
% typically the bound, e.g. VALX = [-1 1] and VALY = [0 1].
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, cumulative distribution function

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

%%% Connectivity measure options
gb_name_structure = 'opt';
gb_list_fields = {'bins','valx','valy'};
gb_list_defaults = {[],[],[]};
niak_set_defaults

[nb_samps M] = size(samps);

if isempty(bins)
    nb_points = 100;
    bins = zeros([nb_points M]);
    for num_m = 1:M
        bins(:,num_m) = min(samps(:,num_m)):(max(samps(:,num_m))-min(samps(:,num_m)))/(nb_points-1):max(samps(:,num_m));
    end
end
   
cdfs = zeros([length(bins) M]);

for num_m = 1:M    
    [val,order] = sort(samps(:,num_m));
    probas = (1:length(order))/(length(order)+1);    
    [val,I] = unique(val);
    probas = probas(I)';
    
    if size(bins,2)>1
        cdfs(:,num_m) = interp1([valx(valx<val(1)) ; val ; valx(valx>val(end))],[valy(valx<val(1)) ; probas ; valy(valx>val(end))],bins(:,num_m));
    else
        cdfs(:,num_m) = interp1([valx(valx<val(1)) ; val ; valx(valx>val(end))],[valy(valx<val(1)) ; probas ; valy(valx>val(end))],bins);
    end
end
