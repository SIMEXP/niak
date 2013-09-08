function fir_boot = niak_stability_fir_null(fir_all,opt);
% permutation-based resampling under the null hypothesis of no significant FIR response
%
% SYNTAX:
% FIR_BOOT = NIAK_STABILITY_FIR_NULL(FIR_ALL)
%
% _________________________________________________________________________
% INPUTS:
%
% FIR_ALL
%    (array T*N*R) T time samples, N regions, R repetitions. Each column is 
%    a sample of the response to a stimulus in a brain region.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FIR_BOOT
%    (array T*N*R) replications of FIR_ALL under the null hypothesis of 
%    no significant average response.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_FIR, NIAK_STABILITY_FIR_DISTANCE
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2011-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : statistics, correlation

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
[nt,nn,ne] = size(fir_all);
fir_boot = zeros(size(fir_all));
for num_e = 1:ne
    fir_boot(:,:,num_e) = fir_all(mod(floor(nt*rand(1)) + (0:(nt-1)),nt)+1,:,num_e);
end
