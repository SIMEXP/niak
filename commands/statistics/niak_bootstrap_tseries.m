function tseries_boot = niak_bootstrap_tseries(tseries,opt)
% Generate bootstrap samples from time series.
%
% SYNTAX:
% TSERIES_BOOT = NIAK_BOOTSTRAP_TSERIES(TSERIES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES
%   (matrix, size T*N) TSERIES(:,i) is the time series of region I.
%
% OPT
%   (structure) with the following fields:
%
%   DGP
%       (string, default 'CBB') the method used to resample the data. 
%       Available options : 'CBB' (recommended), 'AR1B', 'AR1G'
%
%   BLOCK_LENGTH (if OPT.DGP == 'CBB')
%       (integer, default [2*ceil(sqrt(T)) 3*ceil(sqrt(T))]) window width 
%       used in the circular block bootstrap. If multiple values are 
%       specified, a random parameter is selected in the list.
%
%   T_BOOT
%       (integer, default same as TSERIES) the number of time frames of the 
%       bootstrap time series.
%
%   INDEPENDENCE
%       (boolean, default 0) if INDEPENDENCE == 1, then the distributions 
%       of the time series associated with different regions are 
%       independent.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TSERIES_BOOT
%   (matrix, size T*N) TSERIES_BOOT(:,i) is a bootstrap samples from the 
%   time series of region i.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
% The different resampling methods are :
%
% 'AR1B' : 
%   Bootstrap sample of multiple time series based on a semi-paramteric 
%   scheme mixing an auto-regressive temporal model and i.i.d. bootstrap of 
%   the "innovations"
%
% 'AR1G' : 
%   Boostrap sample of multiple time series based on a parametric model of 
%   Gaussian data with arbitrary spatial correlations and first-order 
%   auto-regressive temporal correlations.
%
% 'CBB' : 
%   Circular-block-bootstrap sample of multiple time series.
%
% More details about the resampling schemes can be found in the following
% reference :
% P. Bellec; G. Marrelec; H. Benali, A bootstrap test to investigate
% changes in brain connectivity for functional MRI. Statistica Sinica, 
% special issue on Statistical Challenges and Advances in Brain Science, 
% 2008, 18: 1253-1268. 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010.
% Maintainer : pbellec@crigum.qc.ca
% See licensing information in the code.
% Keywords : bootstrap, time series, hypothesis testing, functional
% connectivity

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

%% Setting up default inputs
if ~isfield(opt,'dgp')
    opt.dgp = 'CBB';
end

if strcmp(opt.dgp,'CBB')
    if ~isfield(opt,'block_length')
        block_length = [2*ceil(sqrt(size(tseries,1))) 3*ceil(sqrt(size(tseries,1)))];
    else
        block_length = opt.block_length;
    end
    if length(block_length)>1
        block_length = block_length(ceil(length(block_length)*rand(1)));
    end
else
    block_length = [];
end

if isfield(opt,'t_boot')
    t_boot = opt.t_boot;
else
    t_boot = [];
end

if isempty(t_boot)
    t_boot = size(tseries,1);
end

if ~isfield(opt,'independence')
    opt.independence = false;
end
flag_ind = opt.independence;

%% In the case an AR1 model is used, estimate the AR1 coefficients
if strcmp(opt.dgp,'AR1B')|strcmp(opt.dgp,'AR1G')
    [AR_coeff,res] = sub_estimate_AR(tseries);
    AR_coeff = mean(AR_coeff)*ones(size(AR_coeff));
end

%% In the case a Gaussian model is used, estimate the temporal and 
%% spatial correlations.
if strcmp(opt.dgp,'AR1G')
    Dt = abs(meshgrid(1:t_boot)-meshgrid(1:t_boot)');
    Rt = AR_coeff(1).^Dt;
    sqrtRt = chol(Rt)';
    if ~flag_ind
        Rs = niak_build_correlation(tseries);
        sqrtRs = chol(Rs);    
    end
end

%% Perform the resampling
switch opt.dgp
    case 'CBB'
        if ~flag_ind
            tseries_boot = sub_CBB_tseries(tseries,t_boot,block_length);
        else
            tseries_boot = sub_CBB_tseries_ind(tseries,t_boot,block_length);
        end
        
    case 'AR1B'
        if ~flag_ind
            tseries_boot = sub_AR1B_tseries(tseries,t_boot,AR_coeff,res);
        else
            tseries_boot = sub_AR1B_tseries_ind(tseries,t_boot,block_length);
        end

    case 'AR1G'  
        if ~flag_ind
            tseries_boot = sub_AR1G_tseries(sqrtRt,sqrtRs,t_boot,size(tseries,2));
        else
            tseries_boot = sub_AR1G_tseries(sqrtRt,eye([size(tseries,2) size(tseries,2)]),t_boot,size(tseries,2));
        end
        
    otherwise
        error(cat(2,opt.dgp,' : unknown data-generating process'))
end


%%%%%%%%%%%%%%%%%%
%% Subfunctions %%
%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [AR_coeff,res] = sub_estimate_AR(tseries,flag_sItC)

% Estimate first-order auto-regressive coefficients of multiple time
% series.

if nargin < 2
    flag_tIsC = 1;
end

AR_coeff = zeros([size(tseries,2) 1]);
res = zeros([size(tseries,1)-1 size(tseries,2)]);

for num_r = 1:size(tseries,2)
    y = tseries(2:end,num_r);
    x = tseries(1:end-1,num_r);
    AR_coeff(num_r) = (x'*x)^(-1)*x'*y;
    res(:,num_r) = y - x*AR_coeff(num_r);
end

if(flag_tIsC)
    AR_coeff = mean(AR_coeff)*ones(size(AR_coeff));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tseries_boot = sub_CBB_tseries(tseries,t_boot,block_length)

% Generate a circular-block-bootstrap sample of multiple time series.

T = size(tseries,1);

nb_b = ceil(t_boot/block_length);
tp = floor(rand([1,nb_b])*T);
tp = ((0:(block_length-1))')*ones([1,length(tp)]) + ones([block_length 1])*tp;
tp = mod(tp(:),T)+1;
tp = tp(1:t_boot);

tseries_boot = tseries(tp,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tseries_boot = sub_CBB_tseries_ind(tseries,t_boot,block_length)

% Generate a circular-block-bootstrap sample of multiple time series.

[T,N] = size(tseries);
nb_b = ceil(t_boot/block_length);
tseries_boot = zeros([t_boot,N]);

for num_n = 1:N
    tp = floor(rand([1,nb_b])*T);
    tp = ((0:(block_length-1))')*ones([1,length(tp)]) + ones([block_length 1])*tp;
    tp = mod(tp(:),T)+1;
    tp = tp(1:t_boot);
    tseries_boot(:,num_n) = tseries(tp,num_n);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tseries_boot = sub_AR1B_tseries(tseries,t_boot,AR_coeff,res);

% Generate a bootstrap sample of multiple time series based on a
% semi-paramteric scheme mixing an auto-regressive temporal model and
% i.i.d. bootstrap of the "innovations"

T = size(res,1)+1;
tp = floor(rand([t_boot 1])*(T-1))+1;
res_boot = res(tp,:);

tseries_boot = zeros([t_boot size(tseries,2)]);
tseries_boot(1,:) = res_boot(1,:);

for num_t = 2:t_boot
    tseries_boot(num_t,:) = tseries_boot(num_t-1,:).*AR_coeff' + res_boot(num_t,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tseries_boot = sub_AR1G_tseries(sqrtRt,sqrtRs,t_boot,nb_rois);

% Generate a boostrap sample of multiple time series based on a parametric
% model of Gaussian data with arbitrary spatial correlations and
% first-order auto-regressive temporal correlations.

if size(sqrtRt,3)>1
    tseries_boot = zeros([t_boot sum(nb_rois)]);
    for num_r = 1:sum(nb_rois)
        tseries_boot(:,num_r) = sqrtRt(:,:,num_r) * randn([t_boot 1]);
    end
    tseries_boot = tseries_boot *  sqrtRs;
else
    tseries_boot = sqrtRt * randn([t_boot sum(nb_rois)]) * sqrtRs;
end
