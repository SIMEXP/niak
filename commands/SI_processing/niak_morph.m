function vol_m = niak_morph(vol,arg,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_MORPH
%
% Apply morphomat transformations on a volume.
%
% SYNTAX:
% VOL_M = NIAK_MASK_MORPH(VOL,ARG,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL
%       (3D array) a 3D volume
%
% ARG
%       (string) The argument sent to MINCMORPH. Type "mincmorph -help" in
%       a terminal for available options.
%
% OPT
%       (structure) With the following fields :
%
%       VOXEL_SIZE
%           (vector of size [3 1] or [4 1], default [1 1 1]) the resolution
%           in the respective dimensions, i.e. the space in mmm between
%           two voxels in x, y, and z.
%
%       PAD_SIZE
%           (integer, default 0) add elements at the begining/end of each
%           dimension of the volume to deal with edges effects.
%
%       PAD_ORDER
%           (vector, default [3 2 1]) the order in which dimensions are
%           padded. If a single value is specified, then padding is
%           performed with that value rather than by replicating actual
%           slices of the volume.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_M
%       (3D array) The volume after morphomaths operations have been
%       applied.
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%    This is a simple wraper around MINCMORPH from the MINC tools.
%
% NOTE 2:
%   The padding of the volume proceeds by duplicating the first
%   (resp. last) slices of the volume at the beginning (resp. end) of the
%   volume. This is done to limit edges effect in certain transform, such
%   as the distance transform.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, MINC tools, mincmorph, morphomaths

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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'pad_size','pad_order','pad_val','voxel_size'};
gb_list_defaults = {0,[3 2 1],[],[1 1 1]'};
niak_set_defaults

[nx,ny,nz] = size(vol);
file_tmp = niak_file_tmp('_vol.mnc');
file_tmp2 = niak_file_tmp('_vol_m.mnc');
hdr.file_name = file_tmp;
hdr.type = 'minc1';
hdr.info.voxel_size = voxel_size;
if pad_size>0
    opt_pad.pad_size = pad_size;
    opt_pad.pad_val = pad_val;
    opt_pad.pad_order = pad_order;
    vol_m = niak_pad_vol(vol,opt_pad);
    niak_write_vol(hdr,vol_m);
    clear vol_m
else
    niak_write_vol(hdr,vol);
end

instr_morph = cat(2,'mincmorph -clobber ',arg,' ',file_tmp,' ',file_tmp2);
[status,result] = system(instr_morph);
if status
    if exist(file_tmp,'file')
        delete(file_tmp);
    end
    if exist(file_tmp2,'file')
        delete(file_tmp2);
    end
    error(result)
else
    [hdr,vol_m] = niak_read_vol(file_tmp2);    
    if pad_size>0
        vol_m = niak_unpad_vol(vol_m,opt_pad.pad_size);
    end
    delete(file_tmp);
    delete(file_tmp2);
end

