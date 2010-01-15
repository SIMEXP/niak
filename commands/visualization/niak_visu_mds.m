function [coord stress disp] = niak_visu_mds(dist,opt)

%
% _________________________________________________________________________
% SUMMARY NIAK_VISU_MDS
%
% Multi-dimensional scaling representation of individuals based on a
% distance matrix
%
% SYNTAX:
% [COORD,STRESS,DISP] = NIAK_VISU_MDS(SIM,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% DIST
%       (square matrix N*N) a distance matrix, e.g. the square root of 1 -
%       a correlation matrix between multiple time series
%
% OPT
%       (structure, optional) has the following fields:
%
%       NB_DIM
%           (integer, default 2) the number of dimensions to be used in the
%           representation.
%
%       PART
%           (vector, default ones([N 1])) partition of the individuals into
%           a finite set of clusters. A different color will be used for
%           each cluster.
%
%       MARKER_SIZE
%           (real number, default 15) the size of the marker used in the
%           plot.
%
%       FLAG_DISP
%           (flag, default 1) if FLAG_DISP is true, a representation of the
%           MDS results will be produced.
%
% _________________________________________________________________________
% OUTPUTS:
%
% COORD
%       (array N*NB_DIM) the coordinates of N points in a space with NB_DIM
%       dimensions which best approximate the configuration in DIST.
%
% _________________________________________________________________________
% COMMENTS:
%
% This function is based on MDSCALE from the statistical toolbox.
%
% Only NB_DIM = 2 and NB_DIM = 3 are supported for visualization.
%
% DIST has to be a square matrix. MDSCALE supports linearized matrix, but
% not this function.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : multi-dimensional scaling, visualization

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
gb_list_fields = {'nb_dim','flag_disp','part','marker_size'};
gb_list_defaults = {2,true,[],15};
niak_set_defaults

N = size(dist,1);
if isempty(part)
    part = ones([N 1]);
end

% Running MDS
[coord stress disp] = mdscale(dist,nb_dim);

% Plot the MDS results
if flag_disp
    
    list_c = unique(part);
    nb_c = length(list_c);
    cm = jet(nb_c);
    
    if nb_dim == 2
        hold on
        for num_c = 1:nb_c
            ind_c = find(part==list_c(num_c));
            plot(coord(ind_c,1),coord(ind_c,2),'o','MarkerFaceColor',cm(num_c,:),'MarkerSize',15);
        end
                
    elseif nb_dim == 3
        hold on
        for num_c = 1:nb_c
            ind_c = find(part==list_c(num_c));
            plot3(coord(ind_c,1),coord(ind_c,2),coord(ind_c,3),'o','MarkerFaceColor',cm(num_c,:),'MarkerSize',15);
        end        
        
    end
end