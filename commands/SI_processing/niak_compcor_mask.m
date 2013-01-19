function mask = niak_compcor_mask(vol,perc,method);
% Compute the 't' mask of the compcor method (based on temporal standard deviation)
%
% SYNTAX:
% MASK = NIAK_COMPCOR_MASK( VOL , [PERC] , [METHOD] )
%
% INPUTS:
%   VOL (3D+t array) an fMRI dataset
%   PERC (scalar, default 0.02) the proportion of voxels considered to have a 
%      "high" standard deviation (in time).
%   METHOD (string, default 'slice') how to define "high" standard deviation. 
%      'slice': top PERC of voxels per slice
%      'global': top PERC of voxels globally
%
% OUTPUTS
%   MASK (3D array) a binary mask of high standard deviation voxels 
%
% REFERENCE
%   Behzadi, Y., Restom, K., Liau, J., Liu, T. T., Aug. 2007. A component based 
%   noise correction method (CompCor) for BOLD and perfusion based fMRI. 
%   NeuroImage 37 (1), 90-101. http://dx.doi.org/10.1016/j.neuroimage.2007.04.042
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
if nargin < 2
    perc = 0.02;
end
if nargin < 3
    method = 'slice';
end
std_vol = std(vol,[],4);
[nx,ny,nz,nt] = size(vol);
switch method
    case 'slice'
        mask = false([nx ny nz]);
        for iz = 1:nz % loop over slices
            slice = std_vol(:,:,iz);
            val = sort(slice(:),'descend');
            mask(:,:,iz) = std_vol(:,:,iz)>= val(floor(perc*length(val)));
        end
    case 'global'
        val = sort(std_vol(:),'descend');
        mask = std_vol >= val(floor(perc*length(val)));
    otherwise
        error('%s is an unknown method',method)
end