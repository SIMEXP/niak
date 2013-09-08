function dist = niak_stability_fir_distance(fir_all,opt);
% Euclidian distance between FIR responses
%
% SYNTAX:
% DIST = NIAK_STABILITY_FIR_DISTANCE(DATA,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FIR_ALL
%    (array T*N*R) T time samples, N regions, R repetitions. Each column is 
%    a sample of the response to a stimulus in a brain region.
%
% OPT
%    (structure) the options to normalize the average FIR. See the OPT 
%    argument in NIAK_NORMALIZE_FIR
%
% _________________________________________________________________________
% OUTPUTS:
%
% DIST
%    (vector) a vectorized version of l2-norm of the difference between 
%    average responses
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_STABILITY_FIR_NULL, NIAK_BRICK_STABILITY_FIR, NIAK_STABILITY_FIR
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

if strcmp(opt.type,'fir_shape')
    if ndims(fir_all) > 2
        fir_mean = niak_normalize_fir(mean(fir_all,3),[],opt);
    else
        fir_mean = niak_normalize_fir(fir_all,[],opt);
    end
else
    if ndims(fir_all) > 2
        fir_mean = mean(fir_all,3);
    else
        fir_mean = fir_all;
    end
end
dist = niak_build_distance(fir_mean);
dist = niak_mat2vec(dist);
