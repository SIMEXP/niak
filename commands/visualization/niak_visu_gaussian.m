function [] = niak_visu_gaussian(data,opt)
% Plot an histogram of data along with a fitter Gaussian distribution. 
% The parameters of the Gaussian ate initialized by the median and the median 
% absolute deviation to the median and further adjusted with fminsearch.
%
% SYNTAX:
% [] = NIAK_VISU_GAUSSIAN(DATA,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% DATA
%   (vector)
%
% OPT
%   (structure, optional) with the following fields:
%
%   NB_BINS
%      (integer, default length(DATA)/100) the number of bins used in the histogram.
%
%   BINS
%      (vector, default regular grid on min/max) the bins used to build 
%      the histogram. 
%
%   MEAN
%      (scalar, default estimated) the mean of the Gaussian distribution. 
%      By default it is fitted to the data.
%
%   STD
%      (scalar, default estimated) the standard deviation of the Gaussian 
%      distribution. By default it is fitted to the data.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : histogram, Gaussian distribution

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

fields   = { 'nb_bins'        , 'bins' , 'mean' , 'std' };
defaults = { length(data)/100 , []     , []     , []    };
if nargin > 1
    opt = psom_struct_defaults ( opt , fields , defaults );
else
    opt = psom_struct_defaults ( struct() , fields , defaults );
end
data = data(:);

global niak_gb_X niak_gb_Y

% Histogram computation and normalization
if ~isempty(opt.bins)
    [niak_gb_Y,niak_gb_X] = hist(data,opt.bins);
else
    [niak_gb_Y,niak_gb_X] = hist(data,length(data)/opt.nb_bins);
end
niak_gb_Y = niak_gb_Y/(length(data)*(max(niak_gb_X)-min(niak_gb_X)))*length(niak_gb_X);

% Initial values for mean/std
if ~isempty(opt.mean)
    im = opt.mean;
else
    im = median(data);
end

if ~isempty(opt.std)
    is = opt.std;
else
    is = niak_mad(data);
end

% Gaussian parameters fitting.
par = [im;is];
if exist('fminsearch','file')&&(isempty(opt.mean)||isempty(opt.std))
    par = fminsearch('niak_gaussian_fit',par);
end

%% Plot histogram + fit
[err,val] = niak_gaussian_fit(par);
bar(niak_gb_X,niak_gb_Y); hold on; plot(niak_gb_X,val,'r');
title(sprintf('Empirical distribution and fitted gaussian function mean %1.3f std %1.3f',par(1),par(2)));