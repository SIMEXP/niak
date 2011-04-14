function [] = niak_visu_part(part,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_VISU_PART
%
% Give a representation of a partition as a binary adjacency square matrix.
%
% SYNTAX :
% [] = NIAK_VISU_PART(PART,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PART
%       (vector) PART(i) is the number of the cluster of region i.
%
% OPT
%       (structure) with the following fields:
%
%       NB_CLUSTERS
%           (integer, default max(PART(:))) The number of clusters to use 
%
%       LABELS
%           (cell of strings) LABELS{J} is the label of cluster J.
%
%       TYPE_MAP
%           (string, default []) the colormap used to display the clusters 
%           (options: 'jet' or 'hotcold' or 'none').
%           If map is 'none', the current colormap is used.
%
%       FLAG_LABELS
%           (boolean, default false) If FLAG_LABELS is true, labels of the
%           clusters are displayed.
%
%       FLAG_COLORBAR
%           (boolean, default true) if FLAG_COLORBAR is true, a colorbar is
%           displayed with the number of regions.
%
% _________________________________________________________________________
% OUTPUTS:
%
% a figure with a matrix representation of the partition
%
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_THRESHOLD_HIERARCHY, NIAK_THRESHOLD_STABILITY
%
% _________________________________________________________________________
% COMMENTS 
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : visualization, partition, clustering

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

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'nb_clusters','labels','type_map','flag_labels','flag_colorbar'};
gb_list_defaults = {[],[],'none',false,true};
niak_set_defaults

if isempty(nb_clusters)
    nb_clusters = max(part);
end

list_clusters = unique(part(part~=0));
list_clusters = list_clusters(:)';

if isempty(labels)
    labels = cell([nb_clusters 1]);
end

for num_c = list_clusters
    if isempty(labels{num_c})
        labels{num_c} = cat(2,'C',num2str(num_c));
    end
end

if strcmp(type_map,'jet')
    coul_masks = jet(nb_clusters+1);
    coul_masks(1,:) = [1,1,1];    
    colormap(coul_masks);
elseif strcmp(type_map,'hotcold')
    c1 = hot(128);
    c2 = c1(:,[3 2 1]);
    coul_masks = [c2(length(c1):-1:1,:) ; c1];    
    colormap(coul_masks);
end

nb_rois = length(part);
part_m = zeros([nb_rois nb_rois]);

for num_c = list_clusters
    part_m(part==num_c,part==num_c) = num_c;
end

if strcmp(type_map,'hotcold')   
    imagesc(part_m,[-nb_clusters,nb_clusters]);
else
    imagesc(part_m,[0,nb_clusters]);
end

if flag_labels
    for num_c1 = list_clusters
        for num_c2 = list_clusters
            xt = mean(find(part==num_c1));
            yt = mean(find(part==num_c2));
            if num_c1 == num_c2
                h = text(xt,yt,labels{num_c1},'HorizontalAlignment','center','VerticalAlignment','middle');
%             else
%                 h = text(xt,yt,cat(2,labels{num_c1},',',labels{num_c2}),'HorizontalAlignment','center','VerticalAlignment','middle');
%                 if strcmp(type_map,'hotcold')
%                     set(h,'color',[1 1 1]);
%                 end
            end
            set(h,'fontSize',12);
        end
    end
end

axis('square');

if flag_colorbar
    colorbar
end