function part = niak_threshold_hierarchy(hier,opt)
% Threshold a hierarchy in order to obtain a partition.
%
% SYNTAX:
% PART = NIAK_THRESHOLD_HIERARCHY(HIER,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% HIER
%   (matrix) describes the hierarchy (see NIAK_HIERARCHICAL_CLUSTERING)
%
% OPT
%   (structure) with the following fields - absent fields will be assigned 
%   a default value if possible.
%
%	TYPE
%       (string, default 'nb_classes') the method to threshold the 
%       hierarchy. Possible values : 'dist', 'nb_classes', 'size'. 
%       See OPT.THRESH below.
%
%   THRESH
%       (scalar) threshold for converting the hierarchy into a partition. 
%       The exact meaning of THRESH depends on the method selected to 
%       "cut the tree" :
%           if OPT.TYPE = 'dist', it is a threshold on the maximal
%               distance between two clusters.
%           if OPT.TYPE = 'nb_classes', it is the number of classes
%           if OPT.TYPE = 'size', it is the maximal size of a class
%
%   FLAG_OTHER
%       (boolean, default false) if FLAG_OTHER is true, the distance in
%       HIER(:,5) is used instead of HIER(:,1) to threshold the hierarchy.
%
% _________________________________________________________________________
% OUTPUTS:
%
% PART
%   (vector) PART(I) = J if the object I is in the class J. If OPT.TYPE is
%   'nb_classes' and multiple number of classes are specified, then PART is
%   an array and PART(:,s) is the partition associated with OPT.THRESH(s)
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_HIERARCHICAL_CLUSTERING
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
% Centre de recherche de l'institut de Gériatrie de Montréal
% Département d'informatique et de recherche opérationnelle
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : hierarchical clustering

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
gb_list_fields    = {'flag_other' , 'thresh' , 'type'       };
gb_list_defaults  = {false        , NaN      , 'nb_classes' };
niak_set_defaults

if size(hier,2) == 3
    n = size(hier,1);
    hier = [hier(:,3) hier(:,1) hier(:,2) ((n+2):(2*n+1))'];
end

%% Other distance
if flag_other
    hier(:,1) = hier(:,5);
end

%% Initialization
N = hier(1,4)-1;
part = 1:N;
taille = ones(size(part));
niveau = zeros(size(part));
thresh = sort(thresh);
flag_m = length(thresh)>1;
if flag_m
    part_final = zeros([N length(thresh)]);
end

%% Thresholding the partition
switch opt.type

    case 'dist'

        %% Merge clusters until a certain number of clusters is reached
        num_m = 1;
        
        while (num_m<=N-1)&&(hier(num_m,1)<=thresh)

            x_object = hier(num_m,2);
            y_object = hier(num_m,3);
            new_object = hier(num_m,4);
            mask_x = part == x_object;
            mask_y = part == y_object;
            ind_x = find(mask_x,1);
            ind_y = find(mask_y,1);
            part(mask_x) = new_object;
            part(mask_y) = new_object;
            taille(mask_x|mask_y) = taille(ind_x) + taille(ind_y);
            niveau(mask_x|mask_y) = hier(num_m,1);
            num_m = num_m+1;
            
        end
        
    case 'nb_classes'
        
        %% Merge clusters until a certain number of clusters is reached
        num_m = 1;
        
        while (N-num_m +1)>min(thresh)

            x_object = hier(num_m,2);
            y_object = hier(num_m,3);
            new_object = hier(num_m,4);
            mask_x = part == x_object;
            mask_y = part == y_object;
            ind_x = find(mask_x,1);
            ind_y = find(mask_y,1);
            part(mask_x) = new_object;
            part(mask_y) = new_object;
            taille(mask_x|mask_y) = taille(ind_x) + taille(ind_y);
            niveau(mask_x|mask_y) = hier(num_m,1);
            num_m = num_m+1;
            if flag_m 
                if ismember(N-num_m+1,thresh)
                    part_final(:,thresh==N-num_m+1) = part;
                end            
            end
        end
        
    case 'size'
        
        %% Merge clusters until a certain cluster size is reached
        while ((~isempty(hier))&(max(taille)<thresh))
            x = find(objets == hier(1,2));
            y = find(objets == hier(1,3));
            part(:,x) = part(:,x) | part(:,y);
            objets(x) = max(objets)+1;
            objets = objets(1:size(part,2) ~= y);
            taille(x) = taille(x)+taille(y);
            taille = taille(1:size(part,2) ~= y);
            part = part(:,1:size(part,2) ~= y)>0;
            hier = hier(2:size(hier,1),:);
        end
        
    otherwise
        
        error('%s is an unkown method for OPT.TYPE',opt.type);
end

if flag_m
    part = zeros(size(part_final));
    for num_s = 1:length(thresh)
       if thresh(num_s)>=size(part_final,1)
           part(:,num_s) = 1:size(part,1);
       else
           [tmp1,tmp2,part(:,num_s)] = unique(part_final(:,num_s));
       end
    end
else
    [tmp1,tmp2,part] = unique(part);
end