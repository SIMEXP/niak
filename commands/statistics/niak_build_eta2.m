function E2 = niak_build_eta2(maps,method);
% Derive an eta-square matrix from a set of maps.
%
% SYNTAX:
% E2 = NIAK_BUILD_ETA2( MAPS , [METHOD] )
%
% _________________________________________________________________________
% INPUTS:
%
% MAPS
%   (matrix K*L) MAPS(:,l) is a vectorized brain map.
%
% METHOD
%   (string, default 'vec') the numerical method used to derive the
%   eta-square maps. Available options are 'cohen', 'huang' and 'vec'. See 
%   the COMMENTS section below for details.
%
% _________________________________________________________________________
% OUTPUTS:
%
% E2
%   (matrix L*L) E2(l,l') is the eta-square distance between MAPS(:,l) and
%   MAPS(:,l')
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_CORRELATION, NIAK_VEC2MAT, NIAK_MAT2VEC
%
% _________________________________________________________________________
% REFERENCE:
%
% A. Cohen, et al. (2008). `Defining functional areas in individual human
% brains using resting functional connectivity MRI'. NeuroImage 41(1):45-57
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   If MAPS is a square matrix (for example a full brain correlation 
%   matrix), MAPS can also be entered in vector form (assuming a symmetric
%   matrix with ones on the diagonal though). The command NIAK_VEC2MAT will 
%   be used to get it back to a square form. Note that in this case the 
%   output E2 will be automatically vectorized using NIAK_MAT2VEC.
%
% NOTE 2:
%   The eta2 metric is defined as follows. Let i and j be two indices in
%   the matrix R. eta2(i,j) will measure the similarity of the columns 
%   R(:,i) and R(:,j), as as functional connectivity maps.
%   The within-sum-of-squares SSW is defined as :
%
%   SSW = sum_k { (R(k,i)-M(i,j,k))^2 + R(k,j)-M(i,j,k))^2 },
%
%   where M(i,j,k) is the mean (R(k,i)+R(k,j))/2
%
%   The total-sum-of-squares SST is 
%
%   SST = sum_k { (R(k,i)-Mb(i,j))^2 + R(k,j)-Mb(i,j))^2 },
%
%   where Mb(i,j) is the average of all M(i,j,k).
%
%   The eta-square (comprised between 0, the most dissimilar, and 1, 
%   perfectly similar) is defined as :
%
%   eta2 = 1 - SSW/SST.
%
%   Some vectorized versions of these formula are used to derive eta-square
%   maps for the method 'cohen'. This is quite slow, and the outcome will
%   be identical to the methods 'vec' and 'huang' described below (up to 
%   computer precision) which are much faster.
%
%   See the Cohen's paper referenced above for more details.
%
% NOTE 3:
%   The 'huang' method is based on a kronecker product rewriting of the
%   eta-square metric. It has been designed and coded by Lei Huang, New
%   York University with some inputs from Clare Kelly, New York
%   University.
%
% NOTE 4:
%   The 'vec' method is a fully vectorized code based on the following
%   equations:
%
%   SSW = (sum_k (R(k,i))^2)/2 + (sum_k (R(k,j))^2)/2 - sum_k ( R(k,i)*R(k,j) )
%
%   and
%
%   SST = (sum_k (R(k,i))^2) + (sum_k (R(k,j))^2) - 2*K*(Mb(i,j))^2
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2011
%
% Copyright (c) Clare Kelly, 
% New York University, 2011
%
% Copyright (c) Lei Huang, 
% New York University, 2011
%
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : statistics, correlation, eta2

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
    method = 'vec';
end

if (size(maps,1)==1)||(size(maps,2)==1)
    flag_vec = true;
    maps = niak_vec2mat(maps);
else
    flag_vec = false;
end

K = size(maps,1);
K2 = size(maps,2);
E2 = zeros(size(maps));

switch method
    case 'cohen'
        
        for num_k = 1:K                        
            maps2 = repmat(maps(:,num_k),[1 K]);
            M = (maps + maps2)/2;
            Mb = repmat(mean(M,1),[K 1]);
            SSW = sum((maps-M).^2+(maps2-M).^2,1);
            SST = sum((maps-Mb).^2+(maps2-Mb).^2,1);
            E2(:,num_k) = 1 - (SSW./SST);
        end
        
    case 'vec'
        
        sR  = sum(maps,1);
        sR  = (repmat(sR,[K2 1]) + repmat(sR',[1 K2])).^2;
        sR2 = sum(maps.^2,1);
        sR2 = repmat(sR2,[K2 1]) + repmat(sR2',[1 K2]);
        pR  = maps'*maps;
        SSW = sR2/2 - pR;   
        SST = sR2 - sR/(2*K);
        E2  = 1 - (SSW./SST);
       
    case 'huang'
        
        E2=zeros(size(maps,1), size(maps,1));
        nnMat=ones(size(maps,1));
        nMat=ones(size(maps,1),1);
        lMat=ones(size(maps,2),1);
        n=size(maps,1);
        l=size(maps,2);
        T= kron(transpose(nMat), ((maps.*maps)*lMat));
        TTU= (T - 2*maps*transpose(maps) + transpose(T))/2;
        M = (l/2) * (kron(transpose(nMat), ((1/l)*maps*lMat).^2));
        TTD = T + transpose(T) - M -transpose(M) - ((1/l)*maps*lMat)*transpose(maps*lMat);
        E2 = nnMat-(TTU./TTD);
        E2=tril(E2,-1);
        E2=E2+E2';
        E2=E2+eye(size(E2));

    otherwise
        error('%s is an unknown method to derive an eta-square matrix',method);
end

if flag_vec
    E2 = niak_mat2vec(E2);
end