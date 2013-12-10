function proba = niak_trans_binary_sym(S,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_TRANS_BINARY_SYM
%
% Return the probability of transition between states for binary symmetric
% and independent Markov chains of order 1.
%
% SYNTAX : 
% P = NIAK_TRANS_BINARY_SYM(S,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% S
%       (binary vector, size 1*NB_CHAINS) S(N) is the (binary) state of 
%       chain number N.
%   
% OPT
%       (vector, size 1*NB_CHAINS) OPT(N) is the probability that chain N
%       stays in its current state. If OPT is a scalar, the same
%       probability will be used for all chains.
%          
% _________________________________________________________________________
% OUTPUTS:
%
% PROB
%       (array, size 2*NB_UNITS) PROB(K,N) is the probability that chain N
%       will be in state K at next sample.
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

N = length(S);

proba = zeros([2 N]);
proba(1,S==0) = opt;
proba(1,S==1) = 1-opt;
proba(2,:) = 1-proba(1,:);