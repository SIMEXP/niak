function ovlp = niak_build_ovlp_partition(part1,part2,method);
% Compute the relative overlap between two partitions
%
% SYNTAX:
% OVLP = NIAK_BUILD_CORRELATION(PART1,PART2)
%
% _________________________________________________________________________
% INPUTS:
%
% PART1
%   (vector) PART1(I) is the number of the 1st partition for element I.
%
% PART2
%   (vector) PART2(I) is the number of the 2nd partition for element I.
%
% _________________________________________________________________________
% OUTPUTS:
%
% OVLP
%   (vector) OVLP(I) is the relative overlap between PART1 and PART2 at
%   element I (see COMMENTS below).
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Let K = PART1(I) and L = PART2(I). Let C = (PART1==K) be the cluster that
% contains I in the first partition, and D = (PART2==K) be the cluster that 
% contains I in the second partition. Finally, let #C (resp. #D) be the
% number of elements in C (resp. D). The relative overlap at I is defined
% as :
% 
% OVLP(I) = #(C&D)/max(#C,#D)
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, correlation

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
if nargin<3
    method = 'easy';
end
part1 = part1(:);
part2 = part2(:);
mask  = (part1==0)|(part2==0);
part1 = part1(~mask);
part2 = part2(~mask);

switch method
    case 'easy'
        N = length(part1);
        ovlp = zeros([N 1]);
        for n = 1:N
            C = part1 == part1(n);
            D = part2 == part2(n);            
            ovlp(n) = sum(C&D)/max(sum(C),sum(D));           
        end
    case 'fast'
        size1 = niak_build_size_roi(part1);
        size2 = niak_build_size_roi(part2);
        [pairs,I,J] = unique([part1 part2],'rows');
        den = max([size1(pairs(:,1)),size2(pairs(:,2))],[],2);
        den = den(J);
        num = niak_build_size_roi(J);
        num = num(J);
        ovlp = num./den;
end