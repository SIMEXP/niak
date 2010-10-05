function vol_m = niak_pad_vol(vol,opt)
% Pad a 3D volume with a single value or copies of extreme slices.
%
% SYNTAX :
% VOL_M = NIAK_PAD_VOL(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% VOL
%       (3D array) a 3D volume.
%
% OPT
%       (structure) optional, with the following fields :
%
%       PAD_SIZE
%           (integer) add PAD_SIZE elements at the begining/end of each 
%           dimension of the volume.
%
%       PAD_ORDER
%           (vector, default [3 2 1]) the order in which dimensions are
%           padded. 
%
%       PAD_VAL
%           (scalar, default []) the value used for padding. If left empty,
%           copies of the last slices of the volume are made.
%
% _________________________________________________________________________
% OUTPUTS :
%
% VOL_M
%       (3D array) same as VOL, but padded.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_UNPAD_VOL
%
% _________________________________________________________________________
% COMMENTS :
%
% PAD_ORDER has an impact only if PAD_VAL is left empty, i.e. when
% duplicating the extreme values, the order in which they are replicated
% matters. 
%
% Copyright (c) Pierre Bellec, Centre de Recherche de l'institut de
% geriatrie de Montreal, Universite de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : volume, padding

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.
% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'pad_size','pad_order','pad_val'};
gb_list_defaults = {NaN,[3 2 1],[]};
niak_set_defaults

flag_pad = ~isempty(pad_val);

vol_m = zeros(size(vol)+2*pad_size);
vol_m(pad_size+1:pad_size+size(vol,1),pad_size+1:pad_size+size(vol,2),pad_size+1:pad_size+size(vol,3)) = vol;
for num_d = pad_order
    if num_d == 1
        if flag_pad
            vol_m(1:pad_size,:,:) = pad_val;
            vol_m((size(vol_m,1)-pad_size+1):size(vol_m,1),:,:) = pad_val;
        else
            vol_m(1:pad_size,:,:) = repmat(vol_m(pad_size+1,:,:),[pad_size 1 1]);
            vol_m((size(vol_m,1)-pad_size+1):size(vol_m,1),:,:) = repmat(vol_m(pad_size+size(vol,1),:,:),[pad_size 1 1]);
        end
    elseif num_d == 2
        if flag_pad
            vol_m(:,1:pad_size,:) = pad_val;
            vol_m(:,(size(vol_m,2)-pad_size+1):size(vol_m,2),:) = pad_val;
        else
            vol_m(:,1:pad_size,:) = repmat(vol_m(:,pad_size+1,:),[1 pad_size 1]);
            vol_m(:,(size(vol_m,2)-pad_size+1):size(vol_m,2),:) = repmat(vol_m(:,pad_size+size(vol,2),:),[1 pad_size 1]);
        end
    elseif num_d == 3
        if flag_pad
            vol_m(:,:,1:pad_size) = pad_val;
            vol_m(:,:,(size(vol_m,3)-pad_size+1):size(vol_m,3)) = pad_val;
        else
            vol_m(:,:,1:pad_size) = repmat(vol_m(:,:,pad_size+1),[1 1 pad_size]);
            vol_m(:,:,(size(vol_m,3)-pad_size+1):size(vol_m,3)) = repmat(vol_m(:,:,pad_size+size(vol,3)),[1 1 pad_size]);
        end
    end
end