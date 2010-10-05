function vol = niak_unpad_vol(vol_m,pad_size);
% Pad a 3D volume with a single value or copies of extreme slices.
%
% SYNTAX :
% VOL = NIAK_UNPAD_VOL(VOL_P,PAD_SIZE)
%
% _________________________________________________________________________
% INPUTS :
%
% VOL
%       (3D array) a 3D volume.
%
% PAD_SIZE
%       (integer) remove PAD_SIZE elements at the begining/end of each 
%       dimension of the volume.
%
% _________________________________________________________________________
% OUTPUTS :
%
% VOL
%       (3D array) same as VOL_M, but unpadded.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PAD_VOL
%
% _________________________________________________________________________
% COMMENTS :
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

siz_vol = size(vol_m)-2*pad_size;
vol = vol_m(pad_size+1:pad_size+siz_vol(1),pad_size+1:pad_size+siz_vol(2),pad_size+1:pad_size+siz_vol(3));
