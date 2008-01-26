function vol2 = niak_flip_vol(vol,type)

% Flip or rotate a 3D volume
%
% vol2 = niak_flip_vol(vol,type)
%
% ENTREES 
% vol       (3D array) 3D volume
% type      (string) a transform (possible values : 'rot90','rot180','rot270','fliplr')
%
% SORTIES
% vol2      (3D volume) volume vol after application of the transform.
%
% COMMENTS
%
% Copyright (c) Odile Jolivet 05/2005 Pierre Bellec 01/2008
%
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

nc=size(vol,3);
if nargin ~=2
    vol2=vol;
    return;
end
for z=1:nc
    switch lower(type)
        case 'rot90'
            vol2(:,:,z)=flipud(vol(:,:,z)');
        
        case 'rot180'
            vol2(:,:,z)=flipud(fliplr(vol(:,:,z)));   
            
        case 'rot270'
            vol2(:,:,z)=fliplr(vol(:,:,z)'); 
            
        case 'fliplr'
            vol2(:,:,z)=fliplr(vol(:,:,z));  
            
        otherwise
            vol2(:,:,z)=vol(:,:,z);   
    end
end