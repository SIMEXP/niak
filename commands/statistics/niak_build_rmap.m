function rmap = niak_build_rmap(vol,seed);
% Compute a functional connectivity map from a seed
%
% SYNTAX:
% R = NIAK_BUILD_RMAP(VOL,SEED)
%
% INPUTS:
%   VOL (3D+t array) an fMRI dataset
%   SEED (3D array, same size as VOL(:,:,:,1) ) a binary mask of the seed
%
% OUTPUTS
%   RMAP (3D array) the functional connectivity map, starting from the seed
%
% Copyright (c) Pierre Bellec, 
%   Centre de recherche de l'institut de 
%   Gériatrie de Montréal, Département d'informatique et de recherche 
%   opérationnelle, Université de Montréal, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : functional connectivity map, fMRI

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

[nx,ny,nz,nt] = size(vol);
fov = true(nx,ny,nz);
y = niak_normalize_tseries(niak_vol2tseries(vol,fov));
x = niak_normalize_tseries(mean(y(:,seed(:)),2));
rmap = sum(y.*x,1)/(nt-1);
rmap = niak_tseries2vol	(rmap,fov);