function [eig_val,eig_vec,weights] = niak_pca(data,nb_comp)
% Perform a principal component analysis on a 2D data array.
%
% SYNTAX:
% [EIG_VAL,EIG_VEC,WEIGHTS] = NIAK_PCA(DATA)
%
% _________________________________________________________________________
% INPUTS
%
% DATA
%   (2D array, size N*T) samples*variables data array. If data is a time 
%   series array, the time would be the second dimension for a spatial PCA 
%   (the variables here are the volumes), which corresponds to TSERIES' for 
%   the usual NIAK conventions for array of time series.
%
% NB_COMP 
%   (real number, default rank of TSERIES) 
%   If NB_COMP is comprised between 0 and 1, NB_COMP is assumed to be the 
%   percentage of the total variance that needs to be kept. If NB_COMP is 
%   an integer, greater than 1, NB_COMP is the number of components that 
%   will be generated (the procedure always consider the principal 
%   components ranked according to the energy they explain in the data). 
%           
% _________________________________________________________________________
% OUTPUTS
%
% EIG_VAL 
%   (vector, size NB_COMP*1) eigen values, which is also the energy
%   explained by each of the corresponding principal components.
%
% EIG_VEC 
%   (array, size T*NB_COMP) eigen vectors (in columns)
%
% WEIGHTS 
%   (array, size N*NB_COMP) the weights, i.e. the matrix such that
%   TSERIES = WEIGHT*EIG_VEC' in the case where NB_COMP == T, and
%   otherwise EIG_VEC*WEIGHT is simply the projection of TSERIES in the
%   PCA space of dimension NB_COMP with maximal energy.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_SPCA
%
% _________________________________________________________________________
% COMMENTS:
%
% The PCA is done on the matrix of scalar products in the second
% dimension, i.e. DATA'*DATA.
%
% _________________________________________________________________________
% Adapted from a code by Scott Makeig with contributions from Tony Bell, 
% Te-Won Lee, Tzyy-Ping Jung, Sigurd Enghoff, Michael Zibulevsky, 
% CNL/The Salk Institute, La Jolla, 1996-
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

%% Setting default value for the number of components
nb_comp_init = rank(data);

if nargin < 2 
    nb_comp = nb_comp_init;
else
    if nb_comp >= 1 
        nb_comp = min(nb_comp_init,ceil(nb_comp));
    end
    
    if nb_comp<0
        error('NB_COMP should be greater than zero');
    end
end

C = data'*data;
[V,D] = eig(C);
[eig_val,order] = sort(diag(D),1,'descend');
eig_vec = V(:,order);

if nb_comp < 1
    cum_energy = cumsum(eig_val)/sum(eig_val);
    nb_comp = min(find((1-cum_energy)<nb_comp));
end

eig_vec = eig_vec(:,1:nb_comp);
eig_val = eig_val(1:nb_comp);
weights = data*eig_vec;

