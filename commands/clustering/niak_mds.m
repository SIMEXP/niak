function coord = niak_mds(dist_mat,opt)
% Multi-dimensional scaling on a distance matrix.
%
% SYNTAX:
% COORD = NIAK_MDS(DIST_MAT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% DIST_MAT
%       (square matrix N*N) a distance matrix, e.g. the Euclidian distance
%       built through NIAK_BUILD_DISTANCE.
%
% OPT
%       (structure, optional) has the following fields:
%
%       NB_DIM
%           (integer, default 2) the number of dimensions to be used in the
%           representation.
%
%       RATE
%           (scalar, default 1) 
%
%       NB_CYCLES
%           (scalar, default 10) This value should lie between 10 and 5000, 
%           depending on number of data vectors. The more data vectors, the 
%           less cycles are necessary.
%
%       INIT
%           (matrix NB_DIM*N, default auto-init) an initial configuration
%           for COORD.
%
%       FLAG_DISP
%           (boolean, default 1) if FLAG_DISP is true, a representation of 
%           the MDS results will be produced along the optimization
%
%       FLAG_NORM
%           (boolean, default 1) if the flag is true, normalize 
%           shift/scale/rotation invariant scatter plots by PCA
%
% _________________________________________________________________________
% OUTPUTS:
%
% COORD
%       (array NB_DIM*N) the coordinates of N points in a space with NB_DIM
%       dimensions which best approximate the configuration in DIST_MAT
%
% _________________________________________________________________________
% COMMENTS:
%
% This function implements the High-Throughput Multidimensional Scaling
% method, which is markedly faster than the traditional MDS implemented in
% the mdscale matlab command. Details can be found online at :
% http://dig.ipk-gatersleben.de/hitmds/hitmds.html
%
% _________________________________________________________________________
% REFERENCES:
%
% Marc Strickert, Nese Sreenivasulu, Björn Usadel and Udo Seiffert. 
% Correlation-maximizing surrogate gene space for visual mining of gene
% expression patterns in developing barley endosperm tissue.
% BMC Bioinformatics 2007, 8:165
% doi:10.1186/1471-2105-8-165
%
% M. Strickert and F.-M. Schleif and U. Seiffert and T. Villmann. 
% Derivatives of Pearson Correlation for Gradient-based Analysis of
% Biomedical Data. Inteligencia Artificial, Revista Iberoamericana de IA
% 2088, 12: 37-44.
% http://cabrillo.lsi.uned.es:8080/aepia/articulosPorNumeroVer.do?id_numero=42
%
% _________________________________________________________________________
% EXAMPLE:
%
% a = randn([100 200]) + 1;
% b = randn([100 200]) - 1;
% data = [a b];
% opt.flag_disp = true;
% dist_mat = niak_build_distance(data);
% coord = niak_mds(dist_mat,opt);
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_DISTANCE, NIAK_VISU_MDS
%
% Copyright (c) Marc Strickert, 
% Leibniz-Institute of Crop Plant Research, IPK-Gatersleben, 2009.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : multi-dimensional scaling, clustering

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

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'nb_dim','rate','nb_cycles','init','flag_disp','flag_norm'};
gb_list_defaults = {2,1,10,[],false,true};
niak_set_defaults

% Running MDS
if ~exist('OCTAVE_VERSION','builtin')
    
    % this is matlab
    coord = sub_hitmds_cpu2_sparse(dist_mat,init,nb_dim,nb_cycles,rate,flag_disp);
        
else
    
    % this is octave
    coord = sub_hitmds_cpu2_sparse_octave(dist_mat,init,nb_dim,nb_cycles,rate,flag_disp);
    
end

if flag_norm
    coord = sub_stdscatter(coord);
end

coord = coord';

%% SUBFUNCTIONS 
%__________________________________________________________________________
function Y = sub_hitmds_cpu2_sparse(D, Y, n_dim, n_cycles, rate, plt)
%
%HITMDS High-Throughput Dimensional Scaling (HiT-MDS)
%
% Y = hitmds_cpu2_sparse(D, Y, n_dim, n_cycles, rate)
%
% Embed dissimilarity matrix D into n_dim -dimensional Euclidean vector space.
%
% Arguments:
% D - source dissimilarity matrix
% Y  - initial target point configuration, leave empty [] for auto-init
% rate - try values {0.1 1 10 100} for optimum embedding, start using rate=1
% n_cycles - value between 10 and 5000, depending on number of data vectors;
%            the more data vectors, the less cycles are necessary.
% plt - 0: no plot, 1: plot intermediate configurations in 2D during processing
%
% Return:
% Y - non-standardized embedded points (for standardization, apply PCA to Y)
%
% Watch value output after each iteration. The higher, the better.
% 0 means perfect mismatch of embedded data relations with D
% 1 means perfect reconstruction, i.e. most trustful embedding result.
%
% Severals runs are advisable for selecting optimum embedding results.
%
%
%
% Author:      Marc Strickert
% Institution: Leibniz-Institute of Crop Plant Research, IPK-Gatersleben
% Time-stamp:  Sun May 17 10:50:13     2009
% Lizence:     GPLv2; NOT FOR USE IN CRITICAL APPLICATIONS
%


Y = single( Y );
D = single( D ) ;
n_cycles = single( n_cycles );
rate = single( rate );

[n_data n_datainvs] = size(D);

if(n_data ~= n_datainvs)
  error('error: dissimilarity matrix non-square!');
end

zers = find(D == 0);
n_datainvs = 1. / (n_data * n_data - length(zers));

if(sum(size(Y)) == 0) 
  Y = randn(n_data, n_dim);
end

mn_D =  sum(sum(D)) * n_datainvs;
D = D - mn_D;
D(zers) = 0;
mo_D =  sum(sum(D .* D));

pnt_del = Y;
T = D;

if(plt>0)
  figure(1);
end


for i = n_cycles:-1:1 

  % distance matrix
  for j = 1:n_dim
    tmp2 = repmat(Y(:,j).', n_data, 1);  % all pairs of differences between first attrib in points
    tmp = repmat(Y(:,j), 1, n_data); 
    tmp = tmp - tmp2;
    if(j > 1) 
      T = T + tmp .* tmp;
    else 
      T = tmp .* tmp; 
    end
  end

  T(zers) = 0; % cancel unknowns
 
  T = sqrt(T); % costly operation

  mn_T = sum(sum(T)) * n_datainvs;
  T = T - mn_T;
  T(zers) = 0; % unknowns: zero force
  
  
  mi_T =  sum(sum(T .* D));
  mo_T =  sum(sum(T .* T));

  f = 2 / (abs(mi_T) + abs(mo_T));
  mi_T = mi_T * f;
  mo_T = mo_T * f;

    
  % correlation quality output log
  sqrt(mi_T * mi_T / (mo_D * mo_T * f));

  tmpT = T * mi_T - D * mo_T;
  T = T + (0.1 + mn_T);
  tmpT = tmpT ./ T;
 
  % calc point i update strength 
  for j = n_dim:-1:1
    if(j < n_dim) % else recycle value from loop above
      tmp2 = repmat(Y(:,j).', n_data, 1);  % all pairs of differences between first attrib in points
      tmp = repmat(Y(:,j), 1, n_data); 
      tmp = tmp - tmp2;
    end
    tmp = tmp .* tmpT;
    pnt_del(:,j) = sum(tmp);
  end

%  Y = Y + rate * i / n_cycles * pnt_del ./ sqrt(abs(pnt_del)+.001);
  Y = Y + rate * i * .25 * (1+mod(i,2)) / n_cycles * pnt_del ./ sqrt(abs(pnt_del)+.001);

  if(plt>0) 
    set(0,'current',1);
    plot(Y(:,1),Y(:,2),'*');
% 1D plot:   plot(1:size(Y,1),Y,'*');
    drawnow;
  end

end

%__________________________________________________________________________
function Y = sub_hitmds_cpu2_sparse_octave(D, Y, n_dim, n_cycles, rate, plt)
%
%HITMDS High-Throughput Dimensional Scaling (HiT-MDS)
%
% Y = hitmds_cpu2_sparse_octave(D, Y, n_dim, n_cycles, rate)
%
% Embed dissimilarity matrix D into n_dim -dimensional Euclidean vector space.
%
% Arguments:
% D - source dissimilarity matrix
% Y  - initial target point configuration, leave empty [] for auto-init
% rate - try values {0.1 1 10 100} for optimum embedding, start using rate=1
% n_cycles - value between 10 and 5000, depending on number of data vectors;
%            the more data vectors, the less cycles are necessary.
% plt - 0: no plot, 1: plot intermediate configurations in 2D during processing
%
% Return:
% Y - non-standardized embedded points (for standardization, apply PCA to Y)
%
% Watch value output after each iteration. The higher, the better.
% 0 means perfect mismatch of embedded data relations with D
% 1 means perfect reconstruction, i.e. most trustful embedding result.
%
% Severals runs are advisable for selecting optimum embedding results.
%
%
%
% Author:      Marc Strickert
% Institution: Leibniz-Institute of Crop Plant Research, IPK-Gatersleben
% Time-stamp:  Sun May 17 10:50:13     2009
% Lizence:     GPLv2; NOT FOR USE IN CRITICAL APPLICATIONS
%

[n_data n_datainvs] = size(D);

if(n_data ~= n_datainvs)
  error('error: dissimilarity matrix non-square!');
end

zers = find(D == 0);
n_datainvs = 1. / (n_data * n_data - length(zers));

if(sum(size(Y)) == 0) 
  Y = randn(n_data, n_dim);
end

mn_D =  sum(sum(D)) * n_datainvs;
D = D - mn_D;
D(zers) = 0;
mo_D =  sum(sum(D .* D));

pnt_del = Y;
T = D;

if(plt>0)
  figure(1);
end


for i = n_cycles:-1:1 

  % distance matrix
  for j = 1:n_dim
    tmp2 = repmat(Y(:,j).', n_data, 1);  % all pairs of differences between first attrib in points
    tmp = repmat(Y(:,j), 1, n_data); 
    tmp = tmp - tmp2;
    if(j > 1) 
      T = T + tmp .* tmp;
    else 
      T = tmp .* tmp; 
    end
  end

  T(zers) = 0; % cancel unknowns
 
  T = sqrt(T); % costly operation

  mn_T = sum(sum(T)) * n_datainvs;
  T = T - mn_T;
  T(zers) = 0; % unknowns: zero force
  
  
  mi_T =  sum(sum(T .* D));
  mo_T =  sum(sum(T .* T));

  f = 2 / (abs(mi_T) + abs(mo_T));
  mi_T = mi_T * f;
  mo_T = mo_T * f;

    
  % correlation quality output log
  sqrt(mi_T * mi_T / (mo_D * mo_T * f));

  tmpT = T * mi_T - D * mo_T;
  T = T + (0.1 + mn_T);
  tmpT = tmpT ./ T;
 
  % calc point i update strength 
  for j = n_dim:-1:1
    if(j < n_dim) % else recycle value from loop above
      tmp2 = repmat(Y(:,j).', n_data, 1);  % all pairs of differences between first attrib in points
      tmp = repmat(Y(:,j), 1, n_data); 
      tmp = tmp - tmp2;
    end
    tmp = tmp .* tmpT;
    pnt_del(:,j) = sum(tmp);
  end

%  Y = Y + rate * i / n_cycles * pnt_del ./ sqrt(abs(pnt_del)+.001);
  Y = Y + rate * i * .25 * (1+mod(i,2)) / n_cycles * pnt_del ./ sqrt(abs(pnt_del)+.001);

  if(plt>0) 
    plot(Y(:,1),Y(:,2),'*');
% 1D plot:   plot(1:size(Y,1),Y,'*');
    drawnow;
  end

end

%__________________________________________________________________________
function y = sub_stdscatter(x)
%STDSCATTER - normalize shift/scale/rotation invariant scatter plots by PCA

 [nol ndi] = size(x);

% move to origin
 y = x - repmat(mean(x), nol, 1);

% get PCA projection (=rotation) using left eigenvectors of SVD
 [u x x] = svd(y.', 'econ');
 y = y * u(:,1:ndi);

% flip heavier (larger) second moment to the left (in general: to minus)
% and rescale dimensions by overall maximum coordinate veriance
 x = sign(sum(sign(y) .* y .* y, 1));
 y = y .* repmat(x,nol,1) / sqrt(max(var(y)));
