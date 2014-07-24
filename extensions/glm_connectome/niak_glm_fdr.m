function [fdr,test_q] = niak_glm_fdr(pce,method,q,type_measure)
% Estimate the false-discovery rate in a statistical parametric connectome
%
% SYNTAX:
% [FDR,TEST] = NIAK_GLM_FDR( PCE , [METHOD] , [Q] , [TYPE_MEASURE])
%
% _________________________________________________________________________
% INPUTS:
%
% PCE
%   (vector) A list of per-comparison error associated with different tests.
%
% METHOD
%   (string, default 'GBH-LSL+sym') the method to estimate the false-discovery rate.
%   Available options:
%      'BH-local' or 'family': a BH FDR procedure per map.
%      'BH-global' or 'global': a BH procedure on the full connectome.
%      'GBH-TST' or 'TST': a GBH procedure controlling the FDR on the full connectome
%         but using the grouping of tests into maps, with a two-step
%         estimation of the number of discoveries. See NIAK_FDR.
%      'GBH-LSL' or 'LSL': a GBH procedure controlling the FDR on the full connectome
%         but using the grouping of tests into maps, with a least-slope 
%         estimation of the number of discoveries. See NIAK_FDR.
%      'GBH-TST+sym' or 'TST_sym': a combination of group and family 
%          approaches, and the results of the test are made symmetric.
%      'GBH-LSL+sym' or 'LSL_sym': a combination of LSL and famil y 
%          approaches, and the results of the test are made symmetric.
%      'uncorrected': just threshold the p-values using Q as a threshold. No FDR estimation
%          is actually applied
%
% Q
%   (scalar, default 0.05) the threshold on an acceptable level of false-discovery
%   rate.
%
% TYPE_MEASURE
%   (string, default 'correlation') the type of measure which was used to derive the PCE.
%   This is used to vectorize/unvectorize the PCE matrix for the local/global/group
%   procedures. Available options:
%      'correlation': use NIAK_LVEC2MAT(PCE) to get back a matrix form.
%      'glm': use reshape(pce,[sqrt(length(pce)) sqrt(length(pce))]);
%
% _________________________________________________________________________
% OUTPUTS:
%
% FDR
%   (array) FDR(i,j) is the false-discovery rate associated with a threshold of 
%   PCE(i,j) in the j-th family (for 'BY' and 'BH'), or a global FDR after 
%   weighting each family by the number of potential discoveries ('GBH')
%
% TEST
%   (array) TEST(i,j) is 1 if FDR(i,j)<=Q, and 0 otherwise.
% 
% _________________________________________________________________________
% SEE ALSO:
% NIAK_FDR
%
% _________________________________________________________________________
% EXAMPLE:
%
% % Generate some per-comparison error under the null hypothesis (uniform distribution)
% % in a 100x100 connectome, and simulate effects at a 0.01 PCE for all connections
% % associated with the 20 first regions
% pce = rand(100,100);
% true_pos = false(size(pce));
% true_pos(1:20,1:20) = true;
% true_pos(eye(size(true_pos))>0) = false;
% pce(true_pos) = 0.0025*rand(size(pce(true_pos)));
% pce = niak_mat2lvec(pce);
% 
% method = 'LSL_sym';
% fprintf('%s procedure:\n',method)
% [fdr,test] = niak_glm_fdr(pce,method,0.05,'correlation');
% nb_true = sum(test&true_pos,1);
% nb_false = sum(test&~true_pos,1);
% nb_true_neg = sum(~test&~true_pos,1);
% sens = sum(nb_true)/sum(true_pos(:));
% spec = sum(nb_true_neg)/sum(~true_pos(:));
% gb_fdr = sum(nb_false)/max(sum(nb_true+nb_false),1);
% avg_lc_fdr_sig = mean(nb_false(max(true_pos,[],1))./max(nb_true(max(true_pos,[],1))+nb_false(max(true_pos,[],1)),1));
% avg_lc_fdr_noise = mean(nb_false(~max(true_pos,[],1))./max(nb_true(~max(true_pos,[],1))+nb_false(~max(true_pos,[],1)),1));
% fprintf('Sensitivity: %1.3f, Specificity: %1.3f, Global FDR: %1.3f ; Local FDR (in families with signal): %1.3f ; Local FDR (in family with noise): %1.3f\n\n',sens,spec,gb_fdr,avg_lc_fdr_sig,avg_lc_fdr_noise);
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2011-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : false-discovery rate, false-positive rate

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

if nargin < 2 
    method = 'GBH-LSL+sym';
end

if nargin < 3 
    q = 0.05;
end

if nargin < 4
    type_measure = 'correlation';
end

pce_m = sub_vec2mat(pce,type_measure);

switch method

    case {'family','BH-local'}
        [fdr,test_q] = niak_fdr(pce_m,'BH',q);
        
    case {'global','BH-global'}
        [fdr,test_q] = niak_fdr(pce(:),'BH',q);
        fdr = sub_vec2mat(fdr',type_measure);
        test_q = sub_vec2mat(test_q',type_measure)>0;
        
    case {'GBH-TST','TST','group'}
        [fdr,test_q] = niak_fdr(pce_m,'TST',q);
        
    case {'GBH-TST+sym','TST_sym'}        
        [fdr,test_q] = niak_fdr(pce_m,'TST',q/2);       
        test_q = test_q | test_q';
    
    case {'LSL','GBH-LSL'}
        [fdr,test_q] = niak_fdr(pce_m,'LSL',q);

    case {'GBH-LSL+sym','LSL_sym'}        
        [fdr,test_q] = niak_fdr(pce_m,'LSL',q/2);       
        test_q = test_q | test_q';
    
    case 'uncorrected'
        fdr = pce_m;
        test_q = fdr <= q;
        
    otherwise
        error('%s is an unknown procedure to control the FDR',method)
        
end

function pce_m = sub_vec2mat(pce,type_measure)

switch type_measure
    case 'correlation'
        pce_m = niak_lvec2mat(pce);
    case 'glm'
        pce_m = reshape(pce,[sqrt(length(pce)) sqrt(length(pce))]);
    otherwise
        error('%s is an unknown type of measure',type_measure)
end
