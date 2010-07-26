function [] = niak_seed_rand(seed)
% Change the seed of the uniform and Gaussian rand number generator
%
% SYNTAX:
% [] = NIAK_SEED_RAND(SEED)
%
% _________________________________________________________________________
% INPUTS:
%
% SEED
%       (scalar, default sum(100*clock))) the seed of the random number 
%       generator.
%       
% _________________________________________________________________________
% OUTPUTS:
%         
% _________________________________________________________________________
% SEE ALSO:
% RAND, RANDN, RANDSTREAM
%
% _________________________________________________________________________
% COMMENTS:
%
%   This function, in general, simply equivalent to :
%   >> rand('state',seed)
%   >> randn('state',seed)
%
%   The exact method however depends on the version of Matlab and/or
%   Octave. 
%   This version should work for every version and language.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : random number generator, simulation

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

if nargin == 0
    seed = sum(100*clock);
end

try
    RandStream.setDefaultStream(RandStream('mt19937ar','seed',seed)); % matlab 7.9+
catch
    rand('state',seed); % Matlab 5+
    randn('state',seed);
end