function [sil,intra,inter] = niak_build_avg_silhouette(mat,hier,flag_verbose)
% Estimate the average silhouette at all levels of a hierarchy. 
%
% SYNTAX:
% [SIL,INTRA,INTER] = NIAK_BUILD_AVG_SILHOUETTE(MAT,HIER,[FLAG_VERBOSE])
%
% _________________________________________________________________________
% INPUTS:
%
% MAT
%       (array, size N*N) MAT(I,J) is the similarity between units I and J.
%
% HIER
%       (matrix) a hierarchy. See NIAK_HIERARCHICAL_CLUSTERING for a
%       description.
%
% FLAG_VERBOSE
%       (boolean, default true) Print some advancement infos.
%           
% _________________________________________________________________________
% OUTPUTS :
%
% SIL
%   (vector, size N*1) SIL(I) is the average silhouette of the partition 
%   with I clusters.
%
% INTRA
%   (vector, size N*A) INTRA(I) is the average within-cluster stability of
%   the partition with I clusters.
%
% INTER
%   (vector, size N*A) INTER(I) is the average between-cluster stability of
%   the partition with I clusters.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_SILHOUETTE, NIAK_CONSENSUS_CLUSTERING
%
% _________________________________________________________________________
% COMMENTS:
%
% The similarity matrix MAT needs to be symmetrical.
% See NIAK_BUILD_SILHOUETTE for a definition of the silhouette criterion
% (it is the unnormalized silhouette that is implemented here).
%
% _________________________________________________________________________
% REFERENCES:
%
% Peter J. Rousseuw (1987). "Silhouettes: a Graphical Aid to the
% Interpretation and Validation of Cluster Analysis". Computational and
% Applied Mathematics 20: 53–65.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008-2010.
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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

%% Syntax
if ~exist('mat','var')||~exist('hier','var')
    error('Syntax : SIL = NIAK_BUILD_AVG_SILHOUETTE(MAT,HIER) ; for more infos, type ''help niak_build_avg_silhouette''.')
end

if nargin < 3
    flag_verbose = true;
end

N = size(mat,1);

if (size(mat,1)~=N)||(size(mat,2)~=N)
    error('MAT should be a square N*N matrix where N is the length of PART')
end

S = zeros([N 1]); % total similarity within each cluster
B = mat; % region-to-cluster average similarity
B(eye(size(B))>0) = -Inf;
[score_nn,list_nn] = max(B,[],2); % clostest between-cluster similarity and corresponding indices
sil = zeros([N 1]); % vector of average silouhette
intra = zeros([N 1]); % vector of average within-cluster stability
inter = zeros([N 1]); % vector of average between-cluster stability
intra(N) = 0;
inter(N) = mean(score_nn);
sil(N) = -inter(N);
part = 1:N; % current partition
siz = ones([N 1]); % size vector
labels = 1:N;
mask_clust = true([N 1]);

if flag_verbose
    perc_verb = 0.05;
    fprintf('     Percentage done : 0');
end

for num_i = 1:N-2
    
    num_c = N-num_i;
    
    if flag_verbose
        if floor(perc_verb^(-1)*num_i/(N-1))>floor(perc_verb^(-1)*(num_i-1)/(N-1))
            fprintf(' %1.0f',100*(num_i/(N-1)));
        end
    end
  
    % Get the fusion info
    cx = hier(num_i,2);
    cy = hier(num_i,3);
    cz = hier(num_i,4);
    
    mask_x = part == cx;
    mask_y = part == cy;
    mask_z = mask_x|mask_y;
    
    indx = find(labels==cx,1);
    indy = find(labels==cy,1);
    
    % update the partition and labels
    part(mask_z) = cz;
    labels(indx) = cz;
    labels(indy) = NaN;    
    
    % update size
    nx = siz(indx);
    ny = siz(indy);
    siz(indx) = nx+ny;
    siz(indy) = NaN;
    mask_clust(indy) = false;
    
    % update the within-cluster total similarity
    S(indx) = S(indx) + S(indy) + sum(sum(mat(mask_x,mask_y)));
    
    % update the region-to-cluster average similarity
    B(:,indx) = (nx*B(:,indx) + ny*B(:,indy))/(nx+ny);
    B(:,indy) = -Inf;
    
    mask_up = (list_nn==indx)|(list_nn==indy);    
    [score_nn(mask_up),list_nn(mask_up)] = max(B(mask_up,mask_clust),[],2);
    list_clust = find(mask_clust);
    list_nn(mask_up) = list_clust(list_nn(mask_up));
    
    % Compute the average silhouette    
    weig = siz(mask_clust);
    weig(weig==1) = 0;
    weig(weig>0) = (weig(weig>1)-1).^(-1);   
    intra(num_c) = 2*sum(weig.*S(mask_clust))/N;
    inter(num_c) = sum(score_nn)/N;
    sil(num_c) = intra(num_c) - inter(num_c);
    
end

if flag_verbose
    fprintf(' Done ! \n');
end

        
