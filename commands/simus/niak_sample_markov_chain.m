function S = niak_sample_markov_chain(opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SAMPLE_MARKOV_CHAIN
%
% Generate a sample from a Markov chain.
%
% SYNTAX : 
% [S,OPT] = NIAK_SAMPLE_MARKOV_CHAIN(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT
%       (structure) with fields:
%       
%       NB_UNITS
%           (integer) The number of units in the Markov chain.
%
%       NB_SAMPS
%           (integer) The number of samples of the chain. 
%
%       NB_STATES
%           (integer, default 2) The number of states.
%
%       ORDER
%           (integer, default 1) the order of the Markov chain.
%
%       FUNC_TRANS
%           (string) the name of a function used to estimate the
%           probability of transition using the command :
%             >> p = feval(FUNC_TRANS,s,OPT.OPT_TRANS)
%           where s is an array of the ORDER previous states of the Markov 
%           chain (units are in column) and p(k,n) is the probability that
%           unit n will be in state k at the next step. 
%
%       OPT_TRANS
%           (any type, default []) if empty, no options is passed when
%           calling the FUNC_TRANS
%
%       INIT
%           (default random) INIT can either be an ORDER*NB_UNITS array
%           of the initial states of the chain. If absent or left empty, a
%           random value is used.
%
% _________________________________________________________________________
% OUTPUTS:
%
% S 
%       (array, size NB_SAMPS*NB_UNITS) the simulated Markov chain
%
% OPT
%       (structure) same as the input, but with default values updated.
%
% _________________________________________________________________________
% COMMENTS:
%
% States are coded by integers started at 0. For example, with NB_STATES =
% 2, S will be a binary array.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : simulation, linear model

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

%%%%%%%%%%%%%%%%%%%%%%%
%% Setting up inputs %%
%%%%%%%%%%%%%%%%%%%%%%%


% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'nb_units','nb_samps','nb_states','order','func_trans','opt_trans','init'};
gb_list_defaults = {NaN,NaN,2,1,NaN,[],[]};
niak_set_defaults

S = zeros([nb_samps,nb_units]);

if isempty(opt.init)
    S(1:order,:) = floor(nb_states*rand([order,nb_units]));
else
    S(1:order,:) = init;   
end

for num_t = order+1:nb_samps
    if isempty(opt_trans)
        p = feval(func_trans,S(num_t-order:num_t-1,:));
    else
        p = feval(func_trans,S(num_t-order:num_t-1,:),opt_trans);
    end
    pcum = cumsum(p,1);

    for num_u = 1:nb_units
        S(num_t,num_u) = find(pcum(:,num_u)>=rand(1),1)-1;
    end
end    