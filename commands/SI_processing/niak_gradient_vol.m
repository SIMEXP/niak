function vol_g = niak_gradient_vol(vol,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_GRADIENT_VOL
%
% Estimate mean squared gradient on a 3D volume
%
% SYNTAX:
%   VOL_G = NIAK_GRADIENT_VOL(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL     
%       (3D array) 
%
% OPT     
%       (structure) with the following fields :
%
%       MASK    
%           (3D array, same size as VOL, default ones(size(VOL))) 
%           a binary mask of interest (0 outside the mask, 1 inside).
%
%       NEIGH   
%           (string, default '26-connexity') the type of neighborhood 
%           to include in the gradient calculation. Possible values :
%          '4-connexity','6-connexity','26-connexity'.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_G   
%       (3D array, same size as VOL) 
%       at each voxel, VOL_G is the mean square gradient of VOL at this 
%       voxel and along all the specified directions.
%
% _________________________________________________________________________
% SEE ALSO:
%
%  NIAK_MOTION_CORRECTION_WS
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : gradient, image processing

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FILES_OUT
gb_name_structure = 'opt';
gb_list_fields = {'mask','neigh'};
gb_list_defaults = {ones(size(vol)),'26-connexity'};
niak_set_defaults

switch neigh
    
    case '4-connexity'
        
        grad_dir = [0 -1 0; 0 1 0; -1 0 0; 1 0 0];
        
    case '6-connexity'
        
        grad_dir = [ 0 0 -1; 0 0 1; 0 -1 0; 0 1 0; -1 0 0; 1 0 0];

    case '26-connexity'
        
        grad_dir = [1 1 0; -1 1 0; 1 -1 0; -1 -1 0; 0 -1 0; 0 1 0; -1 0 0; 1 0 0;1 1 1; -1 1 1; 1 -1 1; -1 -1 1; 0 -1 1; 0 1 1; -1 0 1; 1 0 1; 0 0 1; 1 1 -1; -1 1 -1; 1 -1 -1; -1 -1 -1; 0 -1 -1; 0 1 -1; -1 0 -1; 1 0 -1; 0 0 -1];
        
end

[nx,ny,nz] = size(vol);
ind = find(mask(:));
[indx,indy,indz] = ind2sub(size(vol),ind);

vol_v = vol(mask(:)>0);
grad_v = zeros(size(vol_v));
nb_neigh = zeros(size(vol_v));

for num_d = 1:size(grad_dir,1)
    
    indx2 = indx + grad_dir(num_d,1);
    indy2 = indy + grad_dir(num_d,2);
    indz2 = indz + grad_dir(num_d,3);
    
    mask_lim = (indx2>0)&(indx2<=nx)&(indy2>0)&(indy2<=ny)&(indz2>0)&(indz2<=nz);
    
    indx2 = indx2(mask_lim);
    indy2 = indy2(mask_lim);
    indz2 = indz2(mask_lim);
    
    ind2 = sub2ind(size(vol),indx2,indy2,indz2);
    
    grad_v(mask_lim) = grad_v(mask_lim) + (vol(ind(mask_lim))-vol(ind2)).^2;
    
    nb_neigh(mask_lim) = nb_neigh(mask_lim)+1;

end

grad_v(nb_neigh~=0) = grad_v(nb_neigh~=0)./nb_neigh(nb_neigh~=0);

vol_g = zeros(size(vol));
vol_g(ind) = grad_v;