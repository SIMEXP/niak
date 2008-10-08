function [vol_s,vol_t] = niak_build_autocorrelation(vol,mask)
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_AUTOCORRELATION
%
% Build spatial and temporal autocorrelation maps for a 3D+t dataset
%
% SYNTAX:
% [VOL_S,VOL_T] = NIAK_BUILD_AUTOCORRELATION(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  * VOL
%       (cell of strings 2*1) file names of two 3D+t dataset. 
%
%  * MASK
%       (volume, default all voxels) Binary mask. If specified, the
%       computation will be restricted to the inside of the mask.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_BRICK_HOMOGENEITY
%
% _________________________________________________________________________
% COMMENTS:
%
% The spatial autocorrelation is derived as the mean temporal correlation
% with the 6 spatial neighbours.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

if length(size(vol))==4
	vol = reshape(vol,[nx*ny*nz nt]);
end

%% Default mask
if nargin < 2
    mask = ones([nx,ny,nz])>0;
end

%% Correction of mean and variance of temporal vol
vol = niak_correct_mean_var(vol','mean_var');

% Initializing neighbour matrix
vois = [1 0 0 ; -1 0 0 ; 0 1 0 ; 0 -1 0; 0 0 1 ; 0 0 -1];

% Building list of coordinates of voxels in the mask
list_vox = find(mask>0);
[lx,ly,lz] = ind2sub(size(mask),list_vox);

% Computing spatial local auto correlation
vol_s = zeros(size(mask));
nb_vois = zeros(size(mask));

for num_vois = 1:size(vois,1)
    
    mx = lx + vois(num_vois,1); my = ly + vois(num_vois,2); mz = lz + vois(num_vois,3);
    in_vol = ones(size(mx));
    in_vol((mx<1)|(mx>size(mask,1))|(my<1)|(my>size(mask,2))|(mz<1)|(mz>size(mask,3))) = 0;
    in_vol2 = in_vol>0;

    ind_vois = zeros(size(mx));
    ind_vois(in_vol2) = sub2ind(size(mask),mx(in_vol2),my(in_vol2),mz(in_vol2));
    in_vol(in_vol2) = ismember(ind_vois(in_vol2),list_vox);
    in_vol = in_vol>0;

    vol_s(ind_vois(in_vol)) = vol_s(ind_vois(in_vol)) + (1/(size(vol,1)-1))*sum(vol(:,list_vox(in_vol)).*vol(:,ind_vois(in_vol)),1)';

    nb_vois(list_vox(in_vol)) = nb_vois(list_vox(in_vol))+1;
end

vol_s(nb_vois>0) = vol_s(nb_vois>0)./nb_vois(nb_vois>0);

%Measuring temporal auto-correlation
vol_t = zeros(size(mask));
vol1 = niak_correct_mean_var(vol(1:end-1,mask>0),'mean_var');
vol2 = niak_correct_mean_var(vol(2:end,mask>0),'mean_var');
vol_t(mask>0) = (1/(size(vol,1)-2))*sum(vol1.*vol2,1)';