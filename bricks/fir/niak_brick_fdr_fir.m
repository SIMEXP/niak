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
%    FIR_ALL
%        (string or cell of strings) The name of a .mat file, which contains 
%        one variable FIR_ALL. FIR_ALL(:,I,J) is the time series of region I 
%        at trial J. If FIR_ALL is a cell of strings, The FIR_ALL variables 
%        will be averaged across all entries.
%
%    ATOMS
%        (string) the name of a file with a 3D volume defining the atoms for 
%        analysis.
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
%       (string, default 'LSL') type of false-discovery rate procedure
%       Available options: 'LSL', 'TST', 'BH', 'BY'. See NIAK_FDR.
%       All procedures control for the global false discovery rate
%       over all tests (i.e. all time point and all regions for test
%       on the significance of the average FIR; all time points and 
%       all pairs of regions for test on the significance of the 
%       difference of the average FIR).
%
%   NB_SAMPS
%       (integer, default 100) the number of samples to use in the 
%       bootstrap approximation of the cumulative distribution functions
%       and the FDR.
%
%   NORMALIZE.TYPE
%       (string, default 'fir_shape') the type of normalization to apply on the 
%       FIR estimates. See NIAK_NORMALIZE_FIR.
%
%   NB_MIN_FIR
%       (integer, default 3) the minimal acceptable number of FIR to run
%       the FDR analysis. If this number is not met, TEST_FIR and TEST_DIFF
%       are both set to empty structures.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
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
list_fields   = {'fir_all' , 'atoms' , 'partition' };
list_defaults = {NaN       , NaN     , NaN         };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Files out
list_fields   = {'fdr'             };
list_defaults = {'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
opt_normalize.type = 'fir_shape';
list_fields   = {'fdr' , 'type_fdr' , 'nb_min_fir' , 'rand_seed' , 'normalize'   , 'nb_samps' , 'flag_verbose' , 'flag_test'  };
list_defaults = {0.05  , 'LSL'      , 3            , []          , opt_normalize , 100        , true           , false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the FIR estimates
if opt.flag_verbose
    fprintf('Read the FIR estimates ...\n');
end
if ischar(files_in.fir_all)
    load(files_in.fir_all)
    if ~any(abs(fir_all(:)))
        warning('The FIR is filled with zero. I am going to assume the data from this subject was not usable')
        test_fir = struct([]);
        test_diff = struct([]);
        if ~strcmp(files_out.fdr,'gb_niak_omitted')
            save(files_out.fdr,'test_fir','test_diff')
        end
        return
    end
else
    mask_ok = true(length(files_in.fir_all),1);
    for num_e = 1:length(files_in.fir_all)
        if opt.flag_verbose
            fprintf('    %s\n',files_in.fir_all{num_e})
        end
        data = load(files_in.fir_all{num_e});
        if num_e == 1
            [nt,nr,ne] = size(data.fir_all);
            fir_all = zeros([nt,nr,length(files_in.fir_all)]);
            time_samples = data.time_samples;
            time_sampling = time_samples(2)-time_samples(1); % The TR of the temporal grid (assumed to be regular) 
            opt.normalize.time_sampling = time_sampling;
        end
        mask_ok(num_e) = any(abs(data.fir_all(:)));
        if ~mask_ok(num_e)
            warning('The FIR is filled with zero. I am going to assume the data from this subject was not usable')
            continue
        end        
        if (ndims(data.fir_all)==3)
            fir_all(:,:,num_e) = mean(data.fir_all,3);
        else 
            fir_all(:,:,num_e) = data.fir_all;
        end
        if strcmp(opt.normalize.type,'fir_shape')
            fir_all(:,:,num_e) = niak_normalize_fir(fir_all(:,:,num_e),[],opt.normalize);
        end
    end
    clear data
    fir_all = fir_all(:,:,mask_ok);
end
[nt,nr,ne] = size(fir_all);
if ne < opt.nb_min_fir
    warning('The minimal number of FIR samples is not reached. I am going to assume that this dataset is not usable. See OPT.NB_MIN_FIR')
    test_fir = struct([]);
    test_diff = struct([]);
    if ~strcmp(files_out.fdr,'gb_niak_omitted')
        save(files_out.fdr,'test_fir','test_diff')
    end
    return
end
time_sampling = time_samples(2)-time_samples(1); % The TR of the temporal grid (assumed to be regular)

%% Read the atoms 
if opt.flag_verbose
    fprintf('Read the volume of atoms ...\n');
end
[hdr,atoms] = niak_read_vol(files_in.atoms);

%% Read the partition
if opt.flag_verbose
    fprintf('Read the partition volume ...\n')
end
[hdr,vol_part] = niak_read_vol(files_in.partition);

%% Extract average FIR responses
list_networks = unique(vol_part(:));
list_networks = list_networks(list_networks~=0);
nn = length(list_networks);
fir_net = zeros([nt nn ne]);
for num_n = 1:nn
    list_a = unique(atoms(vol_part==list_networks(num_n)));
    list_a = list_a(list_a~=0);
    fir_net(:,num_n,:) = mean(fir_all(:,list_a,:),2); 
end

%% Run the FDR tests: significance of the FIR
%% one sample t-test
df = size(fir_net,3);
test_fir.mean  = mean(fir_net,3);                           % mean
test_fir.std   = std(fir_net,[],3);                         % std
test_fir.ttest = sqrt(df)*(test_fir.mean)./(test_fir.std);  % t-test
test_fir.df    = df;                                        % degrees of freedom
test_fir.pce   = 2*(1-niak_cdf_t(abs(test_fir.ttest),n-1)); % two-tailed p-value
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

diff_mean  = zeros(nt,nn,nn); 
diff_std   = zeros(nt,nn,nn); 
diff_ttest = zeros(nt,nn,nn);
diff_df    = zeros(nt,nn,nn); % degrees of freedom
diff_pce   = zeros(nt,nn,nn); % two-tailed p-values
for num_n = 1:nn
    diff_mean(:,:,num_n)  = test_fir.mean - repmat(test_fir.mean(:,num_n),[1 nn]);
    diff_std(:,:,num_n)   = sqrt((test_fir.std).^2  + repmat((test_fir.std(:,num_n)).^2,[1 nn]));
    diff_ttest(:,:,num_n) = sqrt(df)*(diff_mean)./(diff_std);
    diff_df(:,:,num_n)    = (df-1) * (diff_ttest(:,:,num_n).^4) ./ ((test_fir.std).^4  + repmat((test_fir.std(:,num_n)).^4,[1 nn])); % Welch-Satterwaite approximation for degrees of freedom
    diff_pce(:,:,num_n)   = 2*(1-niak_cdf_t(abs(diff_ttest),diff_df)); % two-tailed p-value
end

% Re-organize the results of the test
nn2 = nn*(nn-1)/2;
test_diff.mean  = zeros(nt,nn2); 
test_diff.std   = zeros(nt,nn2); 
test_diff.ttest = zeros(nt,nn2);
test_diff.df    = zeros(nt,nn2); % degrees of freedom
test_diff.pce   = zeros(nt,nn2); % two-tailed p-values
for num_t = 1:nt
    test_diff.mean(num_t,:)  = niak_mat2vec(squeeze(diff_mean(num_t,:,:)));
    test_diff.std(num_t,:)   = niak_mat2vec(squeeze(diff_std(num_t,:,:)));
    test_diff.ttest(num_t,:) = niak_mat2vec(squeeze(diff_ttest(num_t,:,:)));
    test_diff.df(num_t,:)    = niak_mat2vec(squeeze(diff_df(num_t,:,:)));
    test_diff.pce(num_t,:)   = niak_mat2vec(squeeze(diff_pce(num_t,:,:)));
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
