function int = niak_build_integration(tseries,part,flag_vec)
% Compute integration measures within and between networks,
% given a set of regional time series and a partition of regions into 
% networks.
%
% SYNTAX:
% INT = NIAK_BUILD_INTEGRATION(TSERIES,PART,FLAG_VEC)
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (2D array) TSERIES(:,i) is the time series of the ith region
%
% PART          
%       (vector) find(PART==j) is the list of region in network j. In other 
%       words, PART(i) is the number of the network of region i.
%
% FLAG_VEC
%       (boolean, default false) if FLAG_VEC == true, the output matrix is
%       "vectorized" and the redundant elements are suppressed. Use
%       NIAK_VEC2MAT to unvectorize it.
%
% _________________________________________________________________________
% OUTPUTS:
%
% INT           
%       (structure or vector, depending on FLAG_VEC) 
%
%       case structure
%
%           INT.TOTAL 
%               (scalar) the total integration of the system.
%
%           INT.INTRA
%               (scalar) the total intra-system integration.
%
%           INT.INTER
%               (scalar) the total inter-system integration.
%
%           INT.MAT
%               (matrix) the matrix of intra/inter system integration. 
%
%       case vector
%
%           the elements of the structure have been vectorized in an 
%           arbitrary order, and the redundant elements of MAT have been 
%           suppressed. See NIAK_VEC2INT to recover the structure version.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_MEASURE, NIAK_VEC2INT
%
% _________________________________________________________________________
% COMMENTS:
%
% Details on hierarchical measures of integration can be found in the
% following publication :
% G. Marrelec; P. Bellec; A. Krainik; H. Duffau; M. Pélégrini-Issac; S.
% Lehéricy;H. Benali; J. Doyon, 
% Regions, Systems, and the Brain: Hierarchical Measures of Functional 
% Integration in fMRI. 
% Medical Image Analysis, 2008, 4: 484-496.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : Mutual information, integration, time series

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

if nargin < 3
    flag_vec = false;
end

nb_class = max(part);
Mint = zeros([nb_class nb_class]);
R = niak_build_correlation(tseries);

% Computation of marginal inter-sub-networks integration.
if nb_class > 1
    for num1 = 2:nb_class
        for num2 = 1:num1-1
            Mint(num1,num2) = 0.5*log(det(R(part==num1,part==num1))*det(R(part==num2,part==num2))/det(R((part==num1)|(part==num2),(part==num1)|(part==num2))));            
            if ~flag_vec
                Mint(num2,num1) = Mint(num1,num2);
            end
        end
    end
end

% Computation of intra-sub-network integration
Iinter = 0;
for num = 1:nb_class
    Mint(num,num) = -0.5*log(det(R(part==num,part==num)));
end

Itot = -0.5*log(det(R));
Iintra = sum(diag(Mint));
Iinter = Itot-Iintra;

% output value
if flag_vec
    int = [Itot ; Iintra ; Iinter ; niak_mat2lvec(Mint)];
else
    int.total = Itot;
    int.intra = Iintra;
    int.inter = Iinter;
    int.mat = Mint;
end