function [x,mask] = niak_compcor(vol,opt,mask_a);
% Compute components with the COMPCOR method 
%
% SYNTAX:
% [X,MASK] = NIAK_COMPCOR( VOL , [OPT] , [MASK_A])
%
% INPUTS:
%   VOL (3D+t array) an fMRI dataset
%   OPT.PERC (scalar, default 0.02) the proportion of voxels considered to have a 
%      "high" standard deviation (in time).
%   OPT.TYPE (string, default 'a') the type of mask used for compcor:
%         'a' : anatomical mask of white matter + ventricles
%         't' : mask of voxels with high standard deviation 
%         'at' : merging of the 'a' and 't' masks
%   OPT.NB_COMP (integer, default 5) the number of components to generate. If left 
%      empty a test is performed using Gaussian i.i.d. samples to determine 
%      "significant" components. 
%   OPT.NB_SAMPS (integer, default 100) the number of samples for the MC simulation
%   OPT.P (scalar, default 0.05) the significance level to accept a principal component
%   OPT.FLAG_VERBOSE (boolean, default 1) print progress
%   MASK_A (3D array) if OPT.TYPE is 'a' or 'at', mask of white matter+ventricles (necessary)
%
% OUTPUTS
%   X (2D array T x NB_COMP) each column is one (temporal) component
%   MASK (3D array) the binary mask used to run COMPCOR
%
% REFERENCES:
% The original paper:
%   Behzadi, Y., Restom, K., Liau, J., Liu, T. T., Aug. 2007. A component based 
%   noise correction method (CompCor) for BOLD and perfusion based fMRI. 
%   NeuroImage 37 (1), 90-101. http://dx.doi.org/10.1016/j.neuroimage.2007.04.042
%
% The default settings correspond to:
%   Chai, X. J., Castañón, A. N. N., Ongür, D., Whitfield-Gabrieli, S., Jan. 2012. 
%   Anticorrelations in resting state networks without global signal regression. 
%   NeuroImage 59 (2), 1420-1428. http://dx.doi.org/10.1016/j.neuroimage.2011.08.048
%   
% Copyright (c) Pierre Bellec, 
%   Centre de recherche de l'institut de 
%   Gériatrie de Montréal, Département d'informatique et de recherche 
%   opérationnelle, Université de Montréal, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI, noise, compcor

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

%% Set defaults
if nargin < 2
    opt = struct();
end

lfields = { 'nb_comp' , 'flag_verbose' , 'perc' , 'type' , 'nb_samps' , 'p'  };
ldefs   = { 5         , true           , 0.02   , 'a'    , 100        , 0.05 };
opt = psom_struct_defaults(opt,lfields,ldefs);

%% Check the presence of OPT.MASK if needed
if ismember(opt.type,{'a','at'})
    if nargin < 3
        error('Please specify MASK_A to use an anatomical mask')
    end
end

%% Generate the mask based on std if needed
if ismember(opt.type,{'t','at'})
    mask_t = niak_compcor_mask(vol,opt.perc);
end

%% Generate the analysis mask
switch opt.type
    case 'a'
        mask = mask_a;
    case 'at'
        mask = mask_a | mask_t;
    case 't'
        mask = mask_t;
    otherwise
        error('%s is an unknown type',opt.type);
end

%% Now run the pca
y = niak_vol2tseries(vol,mask);
y = niak_normalize_tseries(y);
[val,x] = niak_pca(y');

if ~isempty(opt.nb_comp)
    x = x(:,1:opt.nb_comp);
    return
end

%% Run a Monte-Carlo simulation of expected eigen values for i.i.d. Gaussian noise
valg = zeros([opt.nb_samps length(val)]);
for num_s = 1:opt.nb_samps
    if opt.flag_verbose
        niak_progress(num_s,opt.nb_samps);
    end
    yg = niak_normalize_tseries(randn(size(y)));
    samp = niak_pca(yg');
    samp = [samp ; ones([length(val) - length(samp)])];
    valg(num_s,:) = samp(1:length(val));
end

%% Estimate the pce (unilateral test)
valg = sort(valg,1,'ascend');
pce = sum(valg >= repmat(val(:)',[opt.nb_samps,1]),1)/opt.nb_samps;

%% Return the significant components
x = x(:,pce<=opt.p);
