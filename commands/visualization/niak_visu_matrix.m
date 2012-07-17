function hf = niak_visu_matrix(matx,opt)
% Visualization of one or multiple matrices
%
% SYNTAX : 
% HF = NIAK_VISU_MATRIX(MATX,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% MATX      
%       (3D array or structure) matx is either a matrix, or a
%       structure with multiples entries such that matx.mat is a matrix.
%       Note that a vector can also be passed, in which case 
%       NIAK_VEC2MAT will be used to get back the matrix form.
%
% OPT       
%       (structure, optional) with the following fields:
%
%       COLOR_MAP   
%           (string, default 'jet' for positive matrices, 'hot_cold' 
%           otherwise) 'hot_cold' is a colormap designed for positive 
%           & negative matrices. Any regular type of matlab colormap 
%           can be used ('jet' is recommended for positive matrices). An
%           additional 'jet_rev' option is available, which is a revert
%           jet color map (red for low values, blue for high values).
%
%       LIMITS 
%           (vector, default [0 max(1,max(MATX))] for positive matrices, 
%           [min(-1,min(MATX)) max(1,max(MATX))] otherwise) 
%           the min and max value for displaying the matrix.
%
%       TYPE_VISU 
%           (string, default 'sub') if multiple matrices are specified 
%           (i.e. size(matx,3)>1), then if type_visu is 'fig', a new figure 
%           is created for each matrix. If type_visu is 'sub', subplots 
%           are used in the current figure.
%
%       LIST_FIELDS 
%           (cell of strings) if multiple matrices are specified in a 
%           structure, a attempt will be made to add the values of the 
%           field in LIST_FIELDS in the title of the figure.
%           
%       FLAG_SQUARE 
%           (boolean, default 1) if the flag is 1, apply an 'axis square' 
%           command.
%
%       FLAG_BAR 
%           (boolean, default 1) if the flag is 1, show a color bar.
%
% _________________________________________________________________________
% OUTPUTS :
%
% HF        
%       (vector) HF(I) is the handle of the Ith figure used.
%
% One or multiple figures (or subplots) are displayed which are
% color-coded representations of the matrices in matx.
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal 
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : matrix, visualization

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

%% Setting up default values for the 'info' part of the header
gb_name_structure = 'opt';
gb_list_fields    = { 'color_map' , 'limits' , 'type_visu' , 'labels' , 'flag_square', 'flag_bar','list_fields' };
gb_list_defaults  = { ''          , []       , 'sub'       , {}       , 1            , 1         , {}           };
niak_set_defaults

if (isstruct(matx))||(size(matx,3)>1)
    if isstruct(matx)
        nb_m = length(matx);
    else
        nb_m = size(matx,3);
    end
    if strcmp(type_visu,'fig')
        for num_m = 1:nb_m
            hf(num_m) = figure;
            if isstruct(matx)
                niak_visu_matrix(matx(num_m).mat,opt);
            else
                niak_visu_matrix(matx(:,:,num_m),opt);
            end
            if ~isempty(list_fields)
                str_title = [];
                for num_f = 1:length(list_fields)
                    if isfield(matx(num_m),list_fields{num_f})
                        val = getfield(matx(num_m),list_fields{num_f});
                        if ischar(val)
                            str_title = [str_title ' ' list_fields{num_f} ' = ' val ';'];
                        end
                        if isnumeric(val)
                            str_title = [str_title ' ' list_fields{num_f} ' = ' num2str(val) ';'];
                        end
                    end
                end
                title(str_title)
            else
                title(cat(2,'Entry :',num2str(num_m)));
            end
        end
        
    else

        N = ceil(sqrt(nb_m));
        M = ceil(nb_m/N);
        hf = gcf;
        for num_m = 1:nb_m
            subplot(M,N,num_m);
            if isstruct(matx)
                niak_visu_matrix(matx(num_m).mat,opt);
            else
                niak_visu_matrix(matx(:,:,num_m),opt);
            end
            
            if ~isempty(list_fields)
                str_title = [];
                for num_f = 1:length(list_fields)
                    if isfield(matx(num_m),list_fields{num_f})
                        val = getfield(matx(num_m),list_fields{num_f});
                        if ischar(val)
                            str_title = [str_title ' ' list_fields{num_f} ' = ' val ';'];
                        end
                        if isnumeric(val)
                            str_title = [str_title ' ' list_fields{num_f} ' = ' num2str(val) ';'];
                        end
                    end
                end
                title(str_title)
            else
                title(cat(2,'Entry ',num2str(num_m)));
            end
        end
        
    end
    return
end

hf = gcf;

if (size(matx,1) == 1)
    matx = niak_vec2mat(matx');
elseif (size(matx,2)==1)
    matx = niak_vec2mat(matx);
end

if isempty(color_map)
    if min(matx(:))>=0
        opt.color_map = 'jet';    
    else
        opt.color_map = 'hot_cold';
    end
end

if isempty(limits)
    if min(matx(:))>=0
        opt.limits = [0 max(1,max(matx(:)))];    
    else
        opt.limits = [min(-1,min(matx(:))) max(1,max(matx(:)))];
    end    
end

imagesc(matx,opt.limits);

[nx,ny] = size(matx);
axis([0.5 nx+0.5 0.5 ny+0.5]);

if strcmp(opt.color_map,'hot_cold')
    per_hot = max(matx(:))/(max(matx(:))-min(matx(:)));
    c1 = hot(128);
    c1 = c1(1:100,:);
    c2 = c1(:,[3 2 1]);
    c2(size(c2,1):-1:1,:);
    
    c= [c2(size(c2,1):-1:1,:) ; c1];
    colormap(c)   
elseif strcmp(opt.color_map,'jet_rev')
    c = jet(256);
    c = c(end:-1:1,:);
    colormap(c)
else
    colormap(opt.color_map)
end

if flag_bar
    colorbar
end

if flag_square
    axis('square')
end
