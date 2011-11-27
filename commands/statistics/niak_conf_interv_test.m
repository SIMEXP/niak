function tests = niak_conf_interv_test(data,null,opt)
% Perform a test based on a bootstrap confidence interval.
%
% SYNTAX:
% TESTS = NIAK_CONF_INTERV_TEST(DATA,NULL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% DATA   
%    (any) DATA is a dataset. Its type depends on OPT.MEASURE and OPT.BOOTSTRAP
%
% NULL
%    (vector) The (multivariate) value of the measure which defines the null 
%    hypothesis (see COMMENTS below).
%
% OPT    
%   (structure) describe the statistical tests to perform on data. The 
%   following fieds will be used :
%
%   NB_SAMPS
%       (integer, default 1000) the number of bootstrap samples.
%
%   BOOTSRAP
%   (structure) describes the bootstrap scheme that will be applied
%   to the database. The structure has the following fields : 
%
%       NAME_BOOT
%           (string) the name of a function. The data will be resampled
%           by invoking the command :
%               >> data_boot = feval(NAME_BOOT,DATA,OPT.BOOTSTRAP.OPT_BOOT)
%           FUNCTION_NAME can be for example 'niak_bootstrap_data'.
%
%       OPT_BOOT
%           (any type, default []) the option of the resampling scheme.
%           See the description of OPT.BOOTSTRAP.NAME_BOOT above.
%
%   MEASURE
%       (structure) describe which measure will be estimated on the 
%       data. The structure has the following fields : 
%   
%       NAME_MES
%           (string) the name of a function, the measure will be 
%           estimated by invoking the command : 
%               >> mes = feval(NAME_MES,DATA,OPT.MEASURE.OPT_MES)
%           The output (MES) has to be a vector.
%
%       OPT_MES
%           (any type, default []) the option of the measure estimation. 
%           See the description of OPT.MEASURE.NAME_MES above.
%
%   TYPE_FDR
%       (string, default 'BY') how to estimate the false-discovery rate
%       associated with each test. Available options:
%       'BY' : The Benjamini-Yekutieli procedure, appropriate for dependent tests
%       'BH' : The Benjamini-Hochberg procedure, appropriate for independent tests 
%              (or positively correlated tests).
%
%   SIDE
%       (string, default 'two-sided') the type of per-comparison error.
%       Available options : 'two-sided', 'left-sided', 'right-sided'
%       See the COMMENTS section below for a description.
% 
%   FLAG_VERBOSE 
%       (boolean, default true) print messages to indicate which 
%       computation are being done.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TESTS
%   (structure) with the following fields :
%
%   PCE  
%       (vector) PCE(M) is the per-comparison error for the Mth
%       component of the measure. The exact definition of the PCE
%       depends on OPT.SIDE (either left-, right- or two-sided
%       hypothesis).
%
%   FDR  
%       (vector) FDR(M) is the false discovery rate associated with PCE(M)
%
%   MEAN
%       (vector) the bootstrap estimate of the mean of the estimated
%       measure.
%
%   STD
%       (vector) the bootstrap estimate of the standard deviation of
%       the estimated measure
%
% _________________________________________________________________________
% REFERENCES:
%
% On bootstrap estimates of confidence intervals:
%   Efron, B., Tibshirani, R. J., May 1994. An Introduction to the Bootstrap 
%   (Chapman & Hall/CRC Monographs on Statistics & Applied Probability), 
%   1st Edition. Chapman and Hall/CRC.
%
% On the estimation of the false-discovery rate for independent tests:
%   Benjamini, Y., Hochberg, Y., 1995. Controlling the false-discovery rate: 
%   a practical and powerful approach to multiple testing. 
%   J. Roy. Statist. Soc. Ser. B 57, 289-300.
%
% On the estimation of the false-discovery rate for dependent tests:
%   Benjamini, Y., Yekutieli, D., 2001. The control of the false discovery 
%   rate in multiple testing under dependency. 
%   The Annals of Statistics 29 (4), 1165-1188.
%
% About bootstrap hypothesis test for time series:
%   P. Bellec; G. Marrelec; H. Benali, A bootstrap test to investigate 
%   changes in brain connectivity for functional MRI.Statistica Sinica, 
%   special issue on Statistical Challenges and Advances in Brain Science.
%
% _________________________________________________________________________
% COMMENTS:
%
% Let y be a dataset, m(y) is a multivariate measure estimated on the 
% dataset :
%    y -> m(y) = (m_i(y))_{i=1...I}
% The null hypothesis takes the form:
%    (H0) m(y) = n
% A bootstrap sampling scheme is designed to approximate the distribution of 
% m(y):
%    y -> y* -> m(y*)
% The Bootstrap hypothesis test consists in estimating one of the following 
% quantities : 
%   * Left-sided per-comparison error  p_i- = Pr(m_i(y*) <= n_i | y -> y* )
%   * Right-sided per-comparison error p_i+ = Pr(m_i(y*) >= n_i | y -> y* )
%   * Two-sided per-comparison error   p_i  = min(2 min(p_i-,p_i+) , 1)
%
% Copyright (c) Pierre Bellec
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : bootstrap, hypothesis testing, null distribution

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

%% set default arguments

list_fields    = { 'nb_samps' , 'bootstrap' , 'measure' , 'side'      , 'type_fdr' , 'flag_verbose' };
list_defaults  = { 1000       , NaN         , NaN       , 'two-sided' , 'BY'       , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

list_fields   = { 'name_mes' , 'opt_mes' };
list_defaults = { NaN        , []        };
opt.measure = psom_struct_defaults(opt.measure,list_fields,list_defaults);

list_fields   = { 'name_boot' , 'opt_boot' };
list_defaults = { NaN         , []         };
opt.bootstrap = psom_struct_defaults(opt.bootstrap,list_fields,list_defaults);

%% Bootstrap confidence interval
if opt.flag_verbose
    fprintf('Bootstrap confidence interval ...\n     Percentage done : ');
    curr_perc = -1;
end

for num_s = 1:opt.nb_samps
    if opt.flag_verbose
        new_perc = 5*floor(20*num_s/opt.nb_samps);
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
            
    data_boot = feval(opt.bootstrap.name_boot,data,opt.bootstrap.opt_boot);
    mes = feval(opt.measure.name_mes,data_boot,opt.measure.opt_mes);
    mes = mes(:);
    if num_s == 1
        p_left = zeros(size(mes));
        p_right = zeros(size(mes));
        mean_v = zeros(size(mes));
        std_v = zeros(size(mes));
    end
    p_left(mes<=null) = p_left(mes<=null) + 1;
    p_right(mes>=null) = p_right(mes>=null) + 1;
    mean_v = mean_v + mes;
    std_v = std_v + mes.^2;
end
mean_v = mean_v / opt.nb_samps;
std_v = std_v / opt.nb_samps - mean_v.^2;
std_v = sqrt(std_v);      
p_left = p_left/opt.nb_samps;
p_right = p_right/opt.nb_samps;
if opt.flag_verbose
    fprintf(' Done \n');
end

switch opt.side
    case 'left-sided'
        pce = p_left;
    case 'right-sided'
        pce = p_right;
    case 'two-sided'
        pce = min(1,2*min(p_left,p_right));
    otherwise
        error('%s is an unknown type of test',opt.side)
end

%% FDR estimation
if opt.flag_verbose
    fprintf('FDR estimation ...\n')
end
[val,order] = sort(pce,'ascend');
fdr = zeros(size(pce));
switch opt.type_fdr    
    case 'BY'
       fdr(order) = sum((1:length(pce)).^(-1))*(length(pce)./(1:length(pce)))'.*val;
    case 'BH'
       fdr(order) = (length(pce)./(1:length(pce)))'.*val;
    otherwise
        error('%s is an unkown procedure for FDR estimation')
end

%% Format outputs
tests.pce = pce;
tests.fdr = fdr;
tests.mean = mean_v;
tests.std = std_v;
