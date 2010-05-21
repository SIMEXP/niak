function coord = niak_visu_mds(dist_mat,opt)
% Multi-dimensional scaling representation of points in arbitrary dimension
%
% SYNTAX:
% COORD = NIAK_VISU_MDS(DIST_MAT,OPT)
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
%       PART
%           (vector, default ones([N 1])) partition of the individuals into
%           a finite set of clusters. A different marker will be used for
%           each cluster. Note that if the number of clusters is > 13, the
%           same marker will be used for more than one cluster, resulting
%           in possible confusion.
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
% This function is based on NIAK_MDS.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_DISTANCE
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

N = size(dist_mat,1);
if isempty(part)
    part = ones([N 1]);
end

% Running MDS
opt_mds.nb_dim = nb_dim;
opt_mds.flag_disp = flag_disp;
coord = niak_mds(dist_mat,opt_mds);

% Plot the MDS results
clf
if flag_disp
    
    list_c = unique(part);
    nb_c = length(list_c);
    cm = jet(nb_c);
    
    if nb_dim == 2
        hold on
        for num_c = 1:nb_c
            ind_c = find(part==list_c(num_c));
            plot(coord(1,ind_c),coord(2,ind_c),'o','MarkerFaceColor',cm(num_c,:),'MarkerSize',15);
        end
                
    elseif nb_dim == 3
        hold on
        for num_c = 1:nb_c
            ind_c = find(part==list_c(num_c));
            plot3(coord(1,ind_c),coord(2,ind_c),coord(3,ind_c),'o','MarkerFaceColor',cm(num_c,:),'MarkerSize',15);
        end        
        
    end
end

