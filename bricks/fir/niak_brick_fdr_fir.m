function [files_in,files_out,opt] = niak_brick_fdr_fir(files_in,files_out,opt)
% Estimate the significance of an average fIR response as well as the significance of differences.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FDR_FIR(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%    (structure) with the following fields:
% 
%    FIR
%        (string or cell of strings) Each entry is the name of a .mat file, 
%        which contains the following variables:
%       (NETWORK).FIR(:,I,J) is the time series of region I at trial J. 
%       (NETWORK).NORMALIZE.TYPE and (NETWORK).NORMALIZE.TIME_SAMPLING are the 
%          OPT parameters of NIAK_NORMALIZE_FIR.
%       The name NETWORK can be changed with OPT.NETWORK below.
%
%    PARTITION
%        (string) the name of a file with a 3D volume defining a partition.
%
% FILES_OUT
%   (structure) with the following fields:
%
%   FDR
%       (string) A .mat file which contains two variables TEST_FIR
%       and TEST_DIFF.
%
% OPT           
%   (structure) with the following fields:
%
%   FDR
%       (scalar, default 0.05) the minimum acceptable false-discovery rate.
%
%   TYPE_FDR
%       (string, default 'BH') type of false-discovery rate procedure
%       Available options: 'LSL', 'TST', 'BH', 'BY'. See NIAK_FDR.
%       All procedures control for the global false discovery rate
%       over all tests (i.e. all time point and all regions for test
%       on the significance of the average FIR; all time points and 
%       all pairs of regions for test on the significance of the 
%       difference of the average FIR).
%
%   NETWORK
%       (string, default 'atoms') the name of the variable in FILES_IN.
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function 
%       prints some infos during the processing.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_FIR, NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, FIR

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

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FDR_FIR(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_fdr_fir'' for more info.')
end
   
%% Files in
list_fields   = {'fir' , 'partition' };
list_defaults = {NaN   , NaN         };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Files out
list_fields   = {'fdr'             };
list_defaults = {'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
list_fields   = {'fdr' , 'type_fdr' , 'network' , 'flag_verbose' , 'flag_test'  };
list_defaults = {0.05  , 'BH'       , 'atoms'   , true           , false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the FIR estimates
if opt.flag_verbose
    fprintf('Read the FIR estimates ...\n');
end
network = opt.network;
mask_ok = true(length(files_in.fir),1);
for num_e = 1:length(files_in.fir)
    if opt.flag_verbose
        fprintf('    %s\n',files_in.fir{num_e})
    end
    data = load(files_in.fir{num_e});
    mask_ok(num_e) = any(abs(data.(network).fir_mean(:)));
    if ~mask_ok(num_e)
        warning('The FIR did not have the minimum number of trials required in OPT.NB_MIN_FIR. I am going to use the data from this subject.')
        continue
    end        
    fir_net(:,:,num_e) = data.(network).fir_mean;
end    
if any(mask_ok)
    fir_net = fir_net(:,:,mask_ok);
else
    fir_net = zeros(0,0,0);
end

%% Read the partition
if opt.flag_verbose
    fprintf('Read the partition volume ...\n')
end
[hdr,vol_part] = niak_read_vol(files_in.partition);

%% Run the FDR tests: significance of the FIR
%% one sample t-test
df = size(fir_net,3);
test_fir.mean  = mean(fir_net,3);                           % mean
test_fir.std   = std(fir_net,[],3);                         % std
[test_fir.ttest,test_fir.pce,test_fir.mean,test_fir.std,test_fir.df] = niak_ttest(reshape(fir_net,[nt*nn ne])');  % one-sample t-test
test_fir.ttest = reshape(test_fir.ttest,[nt nn]);
test_fir.mean  = reshape(test_fir.mean,[nt nn]);
test_fir.std   = reshape(test_fir.std,[nt nn]);
test_fir.pce   = reshape(test_fir.pce,[nt nn]);
switch opt.type_fdr
    case {'LSL','TST'}
        [test_fir.fdr,test_fir.test] = niak_fdr(test_fir.pce,opt.type_fdr,opt.fdr);
    case {'BH','BY'}
        [test_fir.fdr,test_fir.test] = niak_fdr(test_fir.pce(:),opt.type_fdr,opt.fdr);
        test_fir.fdr = reshape(test_fir.fdr,size(test_fir.pce));
        test_fir.test = reshape(test_fir.test,size(test_fir.pce));
    otherwise
        error('%s is not a supported FDR procedure')
end

%% Run the FDR tests: significance of the differences in FIR
%% 2 samples t-test with unequal variance (yet equal sample size)
if opt.flag_verbose
    fprintf('Testing the significance of differences in FIR responses ...\n')
end

dmean  = zeros(nt,nn,nn); 
dstd   = zeros(nt,nn,nn); 
dttest = zeros(nt,nn,nn);
ddf    = zeros(nt,nn,nn); % degrees of freedom
dpce   = zeros(nt,nn,nn); % two-tailed p-values
for num_n = 1:nn
    [tttest,tpce,tmean,tstd,tdf] = niak_ttest(reshape(fir_net,[nt*nn,ne])',repmat(squeeze(fir_net(:,num_n,:))',[1 nn]));
    dttest(:,:,num_n) = reshape(tttest,[nt,nn]);
    dpce(:,:,num_n)   = reshape(tpce,[nt,nn]);
    dmean(:,:,num_n)  = reshape(tmean,[nt,nn]);
    dstd(:,:,num_n)   = reshape(tstd,[nt,nn]);
    ddf(:,:,num_n)    = reshape(tdf,[nt,nn]);
end

% Re-organize the results of the test
nn2 = nn*(nn-1)/2;
test_diff.mean  = zeros(nt,nn2); 
test_diff.std   = zeros(nt,nn2); 
test_diff.ttest = zeros(nt,nn2);
test_diff.df    = zeros(nt,nn2); % degrees of freedom
test_diff.pce   = zeros(nt,nn2); % two-tailed p-values
for num_t = 1:nt
    test_diff.mean(num_t,:)  = niak_mat2vec(squeeze(dmean(num_t,:,:)));
    test_diff.std(num_t,:)   = niak_mat2vec(squeeze(dstd(num_t,:,:)));
    test_diff.ttest(num_t,:) = niak_mat2vec(squeeze(dttest(num_t,:,:)));
    test_diff.df(num_t,:)    = niak_mat2vec(squeeze(ddf(num_t,:,:)));
    test_diff.pce(num_t,:)   = niak_mat2vec(squeeze(dpce(num_t,:,:)));
end

% The FDR test 
switch opt.type_fdr
    case {'LSL','TST'}
        [test_diff.fdr,test_diff.test] = niak_fdr(test_diff.pce,opt.type_fdr,opt.fdr);
    case {'BH','BY'}
        [test_diff.fdr,test_diff.test] = niak_fdr(test_diff.pce(:),opt.type_fdr,opt.fdr);
        test_diff.fdr = reshape(test_diff.fdr,size(test_diff.pce));
        test_diff.test = reshape(test_diff.test,size(test_diff.pce));
    otherwise
        error('%s is not a supported FDR procedure')
end

%% Save outputs
if opt.flag_verbose
    fprintf('Saving outputs ...\n')
end
if ~strcmp(files_out.fdr,'gb_niak_omitted')
    save(files_out.fdr,'test_fir','test_diff')
end