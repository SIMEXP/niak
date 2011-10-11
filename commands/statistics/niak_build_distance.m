function D = niak_build_distance(tseries,type,tseries_std)
% Compute a distance matrix between time series
%
% SYNTAX:
% D = NIAK_BUILD_DISTANCE(TSERIES,TYPE);
%
% _________________________________________________________________________
% INPUTS:
%
% TSERIES       
%       (2D array) time series. First dimension is time.
%
% TYPE
%       (string, default 'norm2') the distance type. Available options are: 
%           'norm2' : the euclidian distance
%           'norm1' : the sum of absolute differences
%
% _________________________________________________________________________
% OUTPUTS:
%
% D
%       (square matrix) D(I,J) is the distance between the vectors
%       TSERIES(:,I) and TSERIES(:,J).
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2007.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : statistics, euclidian distance

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

if ~exist('tseries','var')
    error('Syntax : D = NIAK_BUILD_DISTANCE(TSERIES,TYPE), type ''help niak_build_distance'' for more infos.');
end

if ~exist('type','var')
    type = 'norm2';
end

[T,N] = size(tseries);
switch type
    
    case 'norm1'
        
        D = zeros([N N]);
        for num_t = 1:T
            D = D + abs(repmat(tseries(num_t,:),[N 1]));
        end
            
    case 'norm2'
        
        vec_energy = sum(tseries.^2,1)';
        D = sqrt(abs((ones([N 1]) * vec_energy') + (vec_energy * ones([1 N])) - 2 * tseries' * tseries));
        D(eye(size(D))>0) = 0;
        
    case 'z'
        D = zeros([N N]);
        for num_x = 2:N            
            D(num_x,1:(num_x-1)) = mean(((repmat(tseries(:,num_x),[1 num_x-1])-tseries(:,1:(num_x-1))))./sqrt(repmat(tseries_std(:,num_x),[1 num_x-1]).^2+tseries_std(:,1:(num_x-1)).^2),1);
            D(1:(num_x-1),num_x) = -D(num_x,1:(num_x-1));            
        end        
        
    case 'mahalanobis'
        D = zeros([N N]);        
        for num_x = 1:N
            D(num_x,1:(num_x-1)) = sqrt(2*sum( (repmat(tseries(:,num_x),[1 num_x-1])-tseries(:,1:(num_x-1))).^2 ./ (repmat(tseries_std(:,num_x),[1 num_x-1]).^2+tseries_std(:,1:(num_x-1)).^2),1));
            D(1:(num_x-1),num_x) = D(num_x,1:(num_x-1));            
        end        
        
    case 'mahalanobis_full'
        
        [T,N,K] = size(tseries);
        mu = mean(tseries,3);
        sigma = zeros(T,T,N);
        for num_r = 1:N        
            sigma(:,:,num_r) = niak_build_covariance(squeeze(tseries(:,num_r,:))');
        end
        D = zeros([N N]);
        for num_x = N:-1:1
            num_x
            diff = repmat(mu(:,num_x),[1 num_x-1]) - mu(:,1:(num_x-1));
            for num_y = 1:(num_x-1)
                %D(num_x,num_y) = 0.5*(diff(:,num_y))'*pinv(sigma(:,:,num_x)+sigma(:,:,num_y))*(diff(:,num_y));
                D(num_x,num_y) = 0.5*(diff(:,num_y))'*(sigma(:,:,num_x)+sigma(:,:,num_y))*(diff(:,num_y));
            end
            D(1:(num_x-1),num_x) = D(num_x,1:(num_x-1));
        end
        
    otherwise
        
        error('%s is an unkown distance type',type);
end
