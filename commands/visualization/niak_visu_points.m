function [] = niak_visu_points(coord,val,opt)
% Plot points in 2D or 3D associated with a color-coded value
%
% SYNTAX:
% NIAK_VISU_POINTS(COORD,VAL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% COORD
%       (array NB_DIM*N) the coordinates of N points in a space with NB_DIM
%       dimensions. NB_DIM can be 2 or 3.
%
% VAL
%       (vector length N) VAL(I) is the value associated to the point
%       COORD(:,I).
%
% OPT
%       (structure, optional) has the following fields:
%
%       MARKER_SIZE
%           (real number, default 15) the size of the marker used in the
%           plot.
%
%       MARKER_TYPE
%           (string, default 'o') the marker type (see the help of PLOT for
%           possible options).
%
%       TYPE_COLORMAP
%           (string, default 'jet') the type of the color map. Any matlab
%           colormap name will work here, e.g. hsv,  gray, hot, cool, bone,
%           copper, flag, pink, prism.
%
%       LIMITS
%           (vector 1*2, default [min(val) max(val)]) the values
%           corresponding to the limits of the color map.
%
% _________________________________________________________________________
% EXAMPLE:
% coord = randn([2 100]);
% val = sqrt(sum(coord.^2,1));
% niak_visu_points(coord,val);  
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_VISU_MDS 
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

if nargin<2
    val = ones([size(coord,2) 1]);
end

% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'marker_size','marker_type','type_colormap','limits'};
gb_list_defaults = {15,'o','jet',[min(val) max(val)]};
niak_set_defaults

if size(coord,1)==2
    scatter(coord(1,:),coord(2,:),marker_size,val,marker_type);
elseif size(coord,1)==3
    scatter(coord(1,:),coord(2,:),coord(3,:),marker_size,val,marker_type);
else
    error('Scatter plots are not supported in dimension > 3');
end

eval(sprintf('cmap = %s(256);',type_colormap));
colormap(cmap);
caxis(limits);