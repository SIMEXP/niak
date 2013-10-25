function [fd,mask] = niak_build_frame_displacement(transf,thresh);
% Generate measures of frame displacement, and a mask of scrubbed time points
%
% SYNTAX:
% [FD,MASK] = NIAK_BUILD_FRAME_DISPLACEMENT(TRANSF,THRESH)
%
% _________________________________________________________________________
% INPUTS:
%
% TRANSF
%   (4*4*N array) TRANSF(:,:,n) is an lsq6 transformation, usually seen 
%   as a "voxel-to-world" space transform.
%
% THRESH
%   (scalar, default 0.5) the threshold on acceptable frame displacement.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FD             
%   (vector N-1x1) the frame displacement between successive frames
%
% MASK
%   (binary vector N*1) a mask of the time points that survive scrubbing.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_REGRESS_CONFOUNDS
%
% _________________________________________________________________________
% COMMENTS:
%
% For an overview of the "scrubbing" of volumes with excessive motion, see:
%
%   J. D. Power, K. A. Barnes, Abraham Z. Snyder, B. L. Schlaggar, S. E. Petersen
%   Spurious but systematic correlations in functional connectivity MRI networks 
%   arise from subject motion
%   NeuroImage Volume 59, Issue 3, 1 February 2012, Pages 2142–2154
%
%   Note that the scrubbing is based solely on the FD index, and that DVARS is not
%   derived. The paper of Power et al. included both indices.
%
% Copyright (c) Pierre Bellec 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : scrubbing, motion

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
    thresh = 0.5;
end

[rot,tsl] = niak_transf2param(transf);
rot_d = 50*(rot/360)*pi*2; % adjust rotation parameters to express them as a displacement for a typical distance from the center of 50 mm
rot_d = rot_d(:,2:end) - rot_d(:,1:(end-1));
tsl_d = tsl(:,2:end) - tsl(:,1:(end-1));
fd = sum(abs(rot_d)+abs(tsl_d),1)';
mask = false(length(transf),1);
if nargout > 1
    mask(2:end) = (fd>thresh);
    mask2 = mask;
    mask2(1:(end-1)) = mask2(1:(end-1))|mask(2:end);
    mask2(2:end) = mask2(2:end)|mask(1:(end-1));
    mask2(3:end) = mask2(3:end)|mask(1:(end-2));
    mask = mask2;    
end
