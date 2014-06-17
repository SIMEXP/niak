function [files_in,files_out,opt] = niak_brick_glm_connectome_perm(files_in,files_out,opt)
% Estimate the significance of the number of discoveries in a multiscale GLM on connectomes
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_CONNECTOME_PERM(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN 
%   (cell of string) a series of .mat files (each one corresponding to one scale) with the 
%   following variables:
%
%   MODEL_GROUP.X
%      (matrix) the covariates of the model.
%
%   MODEL_GROUP.Y
%      (matrix) the individual connectomes
%
%   MODEL_GROUP.C
%      (vector) the contrast vector
%
%   NB_DISCOVERY
%      (vector) the number of discoveries made starting from each possible seed.
%
% FILES_OUT
%   (string) A .mat file which contains the following variables :
%
%   NB_DISC
%      (scalar) the total number of discoveries across all scales.
%
%   NB_DISC_NULL
%      (vector) NB_DISC_NULL(S) is the number of discoveries under the null 
%      hypothesis of no association for the Sth permutation sample.
%
%   P_NB_DISC
%      (scalar) the probability to observe NB_DISC discoveries under the null
%      hypothesis.
%
% OPT
%   (structure) with the following fields:
%
%   FDR
%      (scalar, default 0.05) the level of acceptable false-discovery rate 
%      for the t-maps.
%
%   TYPE_FDR
%      (string, default 'LSL_sym') how the FDR is controled. 
%      See the TYPE argument of NIAK_GLM_FDR.
%
%   NB_SAMPS
%      (integer, default 1000) the number of samples under the null hypothesis
%      used to test the significance of the number of discoveries.
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
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_GLM_CONNECTOME, NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% The input files are generated with NIAK_BRICK_GLM_CONNECTOME
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : GLM, connectome, permutation test

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
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_CONNECTOME_PERM(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_glm_connectome_perm'' for more info.')
end

%% Files in 
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings')
end

%% Files out
if ~ischar(files_out)
    error('FILES_OUT should be a string!')
end

%% Options
list_fields   = { 'nb_samps' , 'fdr' , 'type_fdr' , 'rand_seed' , 'flag_verbose' , 'flag_test'  };
list_defaults = { 1000       , 0.05  , 'LSL_sym'  , []          , true           , false        };
if nargin < 3
    opt = psom_struct_defaults(struct,list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the inputs
vol_disc = 0;
nb_disc_scale = zeros(length(files_in),1);
perc_disc_scale = zeros(length(files_in),1);
vol_disc_scale = zeros(length(files_in),1);
q_hetero = Inf;
for num_e = 1:length(files_in);
    d = load(files_in{num_e},'flag_multisite');
    if d.flag_multisite
        results = load(files_in{num_e},'multisite','nb_discovery','perc_discovery','type_measure','vol_discovery');
        glm(num_e,:) = results.multisite.model;
    else
        results = load(files_in{num_e},'model_group','nb_discovery','perc_discovery','type_measure','vol_discovery');        
        glm(num_e) = results.model_group;
    end    
    nb_disc_scale(num_e) = sum(results.nb_discovery);
    perc_disc_scale(num_e) = mean(results.perc_discovery);
    vol_disc_scale(num_e) = results.vol_discovery;
    vol_disc = vol_disc + vol_disc_scale(num_e);    
    if num_e == 1
        type_measure = results.type_measure;
    end
end

%% Generate samples under the null 
if opt.nb_samps>0
    if opt.flag_verbose
        fprintf('Estimate the significance of the number of findings ...\n')
    end
    p_vol_disc = 0;
    vol_disc_null = zeros([opt.nb_samps 1]);
    opt_glm.test = 'ttest';
    for num_s = 1:opt.nb_samps
        if opt.flag_verbose
            niak_progress(num_s,opt.nb_samps);
        end
        if d.flag_multisite
            res_null = struct();
            for ss = 1:length(glm)
                glm_null(:,ss) = niak_permutation_glm(glm(:,ss));                
            end
            for num_e = 1:size(glm_null,1)                            
                for ss = 1:length(results.multisite.list_site)
                    res_null(ss) = niak_glm(glm_null(num_e,ss),opt_glm);
                    if ss == 1
                        eff = zeros(size(res_null(1).eff));
                        std_eff = zeros(size(res_null(1).std_eff));
                    end
                    eff = eff + res_null(ss).eff./(res_null(ss).eff).^2;
                    std_eff = std_eff + 1./(res_null(ss).eff).^2;
                end
                eff = eff ./ std_eff;
                std_eff = sqrt(1./std_eff);
                ttest = eff./std_eff;
                pce = 2*(1-normcdf(abs(ttest)));
                [fdr_null,test_null] = niak_glm_fdr(pce,opt.type_fdr,opt.fdr,type_measure);    
                switch type_measure
                    case 'correlation'
                        ttest_mat = niak_lvec2mat (ttest);        
                    case 'glm'
                        ttest_mat = reshape (ttest,[sqrt(length(ttest)),sqrt(length(ttest))]);
                    otherwise
                        error('%s is an unkown type of measure',type_measure)
                end
                if any(test_null(:))
                    vol_disc_null(num_s) = vol_disc_null(num_s) + sum(ttest_mat(test_null(:)).^2);
                else
                    vol_disc_null(num_s) = vol_disc_null(num_s) + max(ttest_mat(:).^2);
                end 
            end            
        else
            glm_null = niak_permutation_glm(glm);        
            for num_e = 1:length(glm_null)
                res_null = niak_glm(glm_null(num_e),opt_glm);            
                [fdr_null,test_null] = niak_glm_fdr(res_null.pce,opt.type_fdr,opt.fdr,type_measure);
                switch type_measure
                    case 'correlation'
                        ttest_mat = niak_lvec2mat (res_null.ttest);        
                    case 'glm'
                        ttest_mat = reshape (res_null.ttest,[sqrt(length(res_null.ttest)),sqrt(length(res_null.ttest))]);
                    otherwise
                        error('%s is an unkown type of measure',type_measure)
                end
                if any(test_null(:))
                    vol_disc_null(num_s) = vol_disc_null(num_s) + sum(ttest_mat(test_null(:)).^2);
                else
                    vol_disc_null(num_s) = vol_disc_null(num_s) + max(ttest_mat(:).^2);
                end            
            end
        end
        p_vol_disc = p_vol_disc + double(vol_disc_null(num_s)>=vol_disc);
    end
    p_vol_disc = p_vol_disc / opt.nb_samps;
else
    p_vol_disc = NaN;
    vol_disc_null = NaN;    
end

%% Save the results 
save(files_out,'vol_disc','nb_disc_scale','perc_disc_scale','vol_disc_scale','p_vol_disc','vol_disc_null');
