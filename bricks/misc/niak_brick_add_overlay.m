function [in,out,opt] = niak_brick_add_overlay(in,out,opt)
% Add an image overlay to another image
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_ADD_OVERLAY(IN,OUT,OPT)
%
% IN.BACKGROUND (string) an image. 
% IN.OVERLAY (string) another image.
% OUT (string) the merged image. 
% OPT.FLAG_TEST (boolean, default false) if the flag is false, 
%   don't do anything but update default parameters. 
% OPT.THRESHOLD (scalar) set a threshold on the overlay, to set
%   transparency. Note that the threshold actually applies to 
%   the image intensity. 
% OPT.TRANSPARCENCY (scalar, default 0.5) the level of transparency.
%
% See lincense information in the code. 

% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
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

% Set defaults
in = psom_struct_defaults( in , { 'background' , 'overlay' }, { NaN , NaN });
if ~ischar(out); error('OUT should be a string'); end; 
opt = psom_struct_defaults( opt , { 'flag_test' , 'threshold' , 'transparency' }, { false , NaN , 0.5});
if opt.flag_test; return; end

% Read images
img1 = imread(in.background);
img2 = imread(in.overlay);
if ndims(img1)==2
    img1 = repmat(img1,[1 1 3]);
end
if ndims(img2)==2
    img2 = repmat(img2,[1 1 3]);
end
img2_i = mean(img2,3); % Generate intensity
img2_i = img2_i / max(img2_i(:)); % Express intensity as a fraction of the max intensity
mask = img2_i > opt.threshold;
mask = repmat(mask,[1 1 size(img2,3)]);
img12 = img1;
img12(mask) = (1-opt.transparency) * img2(mask) + opt.transparency * img1(mask); 
imwrite(img12,out);