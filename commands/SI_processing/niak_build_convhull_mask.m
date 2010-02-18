function mask_c = niak_build_convhull_mask(mask,opt);
%
% _________________________________________________________________________
% SUMMARY NIAK_BUILD_CONV_HULL_MASK
%
% Build the convex hull of a binary mask.
%
% SYNTAX:
% MASK_C = NIAK_BUILD_CONVHULL_MASK(MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% MASK
%       (3D array) a binary volume
%
% OPT
%       (structure, optional) with the following fields:
%
%       FLAG_VERBOSE
%           (boolean, default true) print info about the progress.
%
%       NB_SPLITS
%           (integer, default 20) if NB_SPLITS>1, the volume is splitted in
%           equal chunks along the y axis before extracting the hull.
%
%       MEMORY_BLOCK
%           (integer, default 1e7) the size of memory blocks used to
%           derive the mask
%
% _________________________________________________________________________
% OUTPUTS:
%
% MASK_C
%       (3D array) a binary volume including the points wihtin the convex
%       hull of MASK.
%
% _________________________________________________________________________
% SEE ALSO:
% CONVHULLN
% _________________________________________________________________________
% COMMENTS:
%
% This is a simple wrapper around the great code written by John D'Errico
% under a BSD license (see the subfunction below).
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, standard deviation, MAD, robust estimation

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

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'memory_block','flag_verbose','nb_splits'};
gb_list_defaults = {1e7,true,20};
niak_set_defaults

% ind = find(mask);
% [x,y,z] = ind2sub(size(mask),ind);
% mask2 = false(size(mask));
% mask2(min(x):max(x),min(y):max(y),min(z):max(z)) = 1;
% mask2 = mask2&~mask;
% ind2 = find(ones(size(mask2)));
% [x2,y2,z2] = ind2sub(size(mask),ind2);
% mask_c = sub_inhull([x2,y2,z2],[x,y,z],[],[],memory_block,flag_verbose);
% mask_c = reshape(mask_c,size(mask));
if nb_splits>1
    ny = size(mask,2);
    ind = find(mask);
    [x,y,z] = ind2sub(size(mask),ind);
    y0 = max(1,min(y)-2);
    y1 = min(size(mask,2),max(y)+2);    
    dy = floor((y1-y0)/nb_splits);
    chunks = y0:dy:y1;
    chunks(end) = y1;    
    mask_c = zeros(size(mask));
    opt.nb_splits = 1;
    opt.flag_verbose = false;
    if flag_verbose
        fprintf('   Percentage completed : 0 - ')
        perc = 0;
    end
    for num_c = 1:(length(chunks)-1)
        if flag_verbose
            if ceil(100*num_c/(length(chunks)-1))-perc>=10;
                perc = ceil(100*num_c/(length(chunks)-1));
                fprintf('%i - ',perc);
            end
        end        
        mask_c(:,chunks(num_c):chunks(num_c+1),:) = niak_build_convhull_mask(mask(:,chunks(num_c):chunks(num_c+1),:),opt);
    end
    
    if flag_verbose
        fprintf('\n')
    end
else
    ind = find(mask);
    [x,y,z] = ind2sub(size(mask),ind);
    mask2 = false(size(mask));
    mask2(min(x):max(x),min(y):max(y),min(z):max(z)) = 1;
    mask2 = mask2&~mask;
    ind2 = find(mask2);
    [x2,y2,z2] = ind2sub(size(mask),ind2);
    mask_in = sub_inhull([x2,y2,z2],[x,y,z],[],10^(-15),memory_block,flag_verbose);
    mask_c = mask;
    mask_c(mask2) = mask_in;
end

function in = sub_inhull(testpts,xyz,tess,tol,memblock,flag_verbose)
% inhull: tests if a set of points are inside a convex hull
% usage: in = inhull(testpts,xyz)
% usage: in = inhull(testpts,xyz,tess)
% usage: in = inhull(testpts,xyz,tess,tol)
%
% arguments: (input)
%  testpts - nxp array to test, n data points, in p dimensions
%       If you have many points to test, it is most efficient to
%       call this function once with the entire set.
%
%  xyz - mxp array of vertices of the convex hull, as used by
%       convhulln.
%
%  tess - tessellation (or triangulation) generated by convhulln
%       If tess is left empty or not supplied, then it will be
%       generated.
%
%  tol - (OPTIONAL) tolerance on the tests for inclusion in the
%       convex hull. You can think of tol as the distance a point
%       may possibly lie outside the hull, and still be perceived
%       as on the surface of the hull. Because of numerical slop
%       nothing can ever be done exactly here. I might guess a
%       semi-intelligent value of tol to be
%
%         tol = 1.e-13*mean(abs(xyz(:)))
%
%       In higher dimensions, the numerical issues of floating
%       point arithmetic will probably suggest a larger value
%       of tol.
%
%       DEFAULT: tol = 0
%
% arguments: (output)
%  in  - nx1 logical vector
%        in(i) == 1 --> the i'th point was inside the convex hull.
%
% Example usage: The first point should be inside, the second out
%
%  xy = randn(20,2)
%  tess = convhull(xy(:,1),xy(:,2));
%  testpoints = [ 0 0; 10 10];
%  in = inhull(testpts,xyz,tess)
%
% in =
%      1
%      0
%
% A non-zero count of the number of degenerate simplexes in the hull
% will generate a warning (in 4 or more dimensions.) This warning
% may be disabled off with the command:
%
%   warning('off','inhull:degeneracy')
%
% See also: convhull, convhulln, delaunay, delaunayn, tsearch, tsearchn
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 3.0
% Release date: 10/26/06
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

% get array sizes
% m points, p dimensions

p = size(xyz,2);
[n,c] = size(testpts);
if p ~= c
    error 'testpts and xyz must have the same number of columns'
end
if p < 2
    error 'Points must lie in at least a 2-d space.'
end

% was the convex hull supplied?
if (nargin<3) || isempty(tess)
    tess = convhulln(xyz);
end
[nt,c] = size(tess);
if c ~= p
    error 'tess array is incompatible with a dimension p space'
end

% was tol supplied?
if (nargin<4) || isempty(tol)
    tol = 0;
end

% build normal vectors
switch p
    case 2
        % really simple for 2-d
        nrmls = (xyz(tess(:,1),:) - xyz(tess(:,2),:)) * [0 1;-1 0];
        
        % Any degenerate edges?
        del = sqrt(sum(nrmls.^2,2));
        degenflag = (del<(max(del)*10*eps));
        if sum(degenflag)>0
            warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
                ' degenerate edges identified in the convex hull'])
            
            % we need to delete those degenerate normal vectors
            nrmls(degenflag,:) = [];
            nt = size(nrmls,1);
        end
    case 3
        % use vectorized cross product for 3-d
        ab = xyz(tess(:,1),:) - xyz(tess(:,2),:);
        ac = xyz(tess(:,1),:) - xyz(tess(:,3),:);
        nrmls = cross(ab,ac,2);
        degenflag = repmat(false,nt,1);
    otherwise
        % slightly more work in higher dimensions,
        nrmls = zeros(nt,p);
        degenflag = repmat(false,nt,1);
        for i = 1:nt
            % just in case of a degeneracy
            nullsp = null(xyz(tess(i,2:end),:) - repmat(xyz(tess(i,1),:),p-1,1))';
            if size(nullsp,1)>1
                degenflag(i) = true;
                nrmls(i,:) = NaN;
            else
                nrmls(i,:) = nullsp;
            end
        end
        if sum(degenflag)>0
            warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
                ' degenerate simplexes identified in the convex hull'])
            
            % we need to delete those degenerate normal vectors
            nrmls(degenflag,:) = [];
            nt = size(nrmls,1);
        end
end

% scale normal vectors to unit length
nrmllen = sqrt(sum(nrmls.^2,2));
nrmls = nrmls.*repmat(1./nrmllen,1,p);

% center point in the hull
center = mean(xyz,1);

% any point in the plane of each simplex in the convex hull
a = xyz(tess(~degenflag,1),:);

% ensure the normals are pointing inwards
dp = sum((repmat(center,nt,1) - a).*nrmls,2);
k = dp<0;
nrmls(k,:) = -nrmls(k,:);

% We want to test if:  dot((x - a),N) >= 0
% If so for all faces of the hull, then x is inside
% the hull. Change this to dot(x,N) >= dot(a,N)
aN = sum(nrmls.*a,2);

% test, be careful in case there are many points
in = repmat(false,n,1);

% if n is too large, we need to worry about the
% dot product grabbing huge chunks of memory.
blocks = max(1,floor(n/(memblock/nt)));
aNr = repmat(aN,1,length(1:blocks:n));
if flag_verbose
    fprintf('   Percentage completed : ')
    perc = 0;
end
for i = 1:blocks
    if flag_verbose
        if ceil(100*i/blocks)-perc>10;
            perc = ceil(100*i/blocks);
            fprintf('%1.2f - ',perc);
        end
    end
    j = i:blocks:n;
    if size(aNr,2) ~= length(j),
        aNr = repmat(aN,1,length(j));
    end
    in(j) = all((nrmls*testpts(j,:)' - aNr) >= -tol,1)';
end

if flag_verbose
    fprintf('\n')
end



