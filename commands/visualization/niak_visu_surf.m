function [ a, cb ] = niak_visu_surf( data, surf, opt);
% Basic viewer for surface data.
% 
% SYNTAX:
% [ A, CB ] = NIAK_VISU_SURF( DATA , SURFACE , [ OPT ] );
% 
% _________________________________________________________________________
% INPUTS :
%
% DATA
%   (vector, length V) vector of data, v=#vertices
%
% SURFACE
%   (structure) with the following fields:
%   
%   COORD
%      (matrix 3 x V) coordinates of nodes
%
%   TRI
%      (matrix T x 3) triangle indices, 1-based, T=#triangles.
%
% OPT
%   (structure, optional) with the following fields:
%
%   TITLE
%      (string, default: name of DATA) title to be included in the figure.
%
%   STYLE
%      (string, default: 'two_hemispheres_full') defines the organization 
%      of the montage. Available options:
%         'two_hemispheres_full': show left/right bottom/top back/front
%            for two hemispheres.
%         'one_hemisphere_full': show left/right bottom/top back/front
%            for one hemisphere.
%         'two_hemispheres_left_right': show left/right for two hemispheres.
%       
%   LIMIT
%      (vector 1 x 2, default [min(DATA) max(DATA)]) Min/Max for the scale 
%      associated with DATA.
% 
%   BACKGROUND
%      (string or vector 1 x 3, default 'white') background colour, 
%      any matlab ColorSpec, such as 'white' (default), 'black'=='k', 
%      'r'==[1 0 0], [1 0.4 0.6] (pink) etc.
%      Letter and line colours are inverted if background is dark (mean<0.5).
%
%   SHADING
%      (string, default 'flat') The type of shading for rendering.
%      Available options: 'faceted', 'flat', 'interp'
%      Type "help shading" for more info.
%
%   MATERIAL
%      (string, default 'shiny') The type of material for rendering.
%      Available options: 'shiny', 'dull', 'metal'
%      Type "help material" for more info. 
%
%   LIGHTING
%      (string, default 'phong') The type of light for rendering.
%      Available options: 'flat', 'gouraud', 'phong', 'none'
%      Type "help lighting" for more info.
%
%   COLORMAP
%      (string or matrix, default jet(256) with white associated with 
%      the minimum) any acceptable argument for colormap.
%
% _________________________________________________________________________
% OUTPUTS :
%
% A
%    (vector) handles to the axes, left to right, top to bottom. 
%
% CB
%    (scalar) handle to the colorbar.
%
% _________________________________________________________________________
% COMMENTS
%
% Copyright (c) Keith Worsley, McGill University, 2008.
% Updated by Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : surface, visualization
cm = jet(256);
cm(1,:) = 0.8;

clim=[min(data),max(data)];
if clim(1)==clim(2)
    clim=clim(1)+[-1 0];
end

list_fields   = { 'style'                , 'limit' , 'title'      , 'background' , 'lighting' , 'material' , 'shading' , 'colormap' };
list_defaults = { 'two_hemispheres_full' , clim    , inputname(1) , 'white'      , 'phong'    , 'dull'     , 'flat'    , cm         };

if nargin<3 
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

if isempty(data)
    data = ones(size(surf.coord,2),1);
end

% find cut between hemispheres, assuming they are concatenated
t=size(surf.tri,1);
v=size(surf.coord,2);
tmax=max(surf.tri,[],2);
tmin=min(surf.tri,[],2);
% to save time, check that the cut is half way
if min(tmin(t/2+1:t))-max(tmax(1:t/2))==1
    cut=t/2;
    cuv=v/2;
else % check all cuts
    for i=1:t-1
        tmax(i+1)=max(tmax(i+1),tmax(i));
        tmin(t-i)=min(tmin(t-i),tmin(t-i+1));
    end
    cut=min([find((tmin(2:t)-tmax(1:t-1))==1) t]);
    cuv=tmax(cut);
end
tl=1:cut;
tr=(cut+1):t;
vl=1:cuv;
vr=(cuv+1):v;
flag_cut = cut < t;
if flag_cut
    surf.tri(tr,:) = surf.tri(tr,:) - cuv;
end

%% Init window
clf;
colormap(opt.colormap);

h=0.39;
w=0.4;

r=max(surf.coord,[],2)-min(surf.coord,[],2);
w1=h/r(2)*r(1)*3/4;
h1=h/r(2)*r(1); % h/r(2)*r(3)

switch opt.style
    case 'two_hemispheres_full'
        list_positions = { [0.055         0.62 h*3/4 w ] , ...
                           [0.3           0.58 w     h ] , ...
                           [1-0.055-h*3/4 0.62 h*3/4 w ] , ...
                           [0.055         0.29 h*3/4 w ] , ...
                           [0.3           0.18 w     h ] , ...
                           [1-0.055-h*3/4 0.29 h*3/4 w ] , ...
                           [0.055         0.02 w1    h1] , ...
                           [1-0.055-w1    0.03 w1    h1] };
        list_tri = { tl  , ...
                     1:t , ...
                     tr  , ... 
                     tl  , ...
                     1:t , ...
                     tr  , ... 
                     1:t , ...
                     1:t };
        list_ver = { vl  , ...
                     1:v , ...
                     vr  , ...
                     vl  , ...
                     1:v , ...
                     vr  , ...
                     1:v , ...
                     1:v };
        list_view = { [ -90 0   ] , ...
                      [ 0   90  ] , ...
                      [ 90  0   ] , ...
                      [ 90  0   ] , ...
                      [ 0   -90 ] , ...
                      [ -90 0   ] , ...                      
                      [ 180 0   ] , ...                      
                      [ 0   0   ]};                     

    case 'one_hemisphere_full'
    case 'two_hemispheres_left_right'
    otherwise
        error('%s is an unknown style',opt.style);
end

for num_v = 1:length(list_view)   
    a(num_v)=axes('position',list_positions{num_v});
    trisurf(surf.tri(list_tri{num_v},:),surf.coord(1,list_ver{num_v}),surf.coord(2,list_ver{num_v}),surf.coord(3,list_ver{num_v}),...
        double(data(list_ver{num_v})),'EdgeColor','none');
    view(list_view{num_v}(1),list_view{num_v}(2));
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)
end
 
id0=[0 0 cuv 0 0 cuv 0 0];
for i=1:length(a)
    set(a(i),'CLim',opt.limit);
    set(a(i),'Tag',['SurfStatView ' num2str(i) ' ' num2str(id0(i))]);
end

cb=colorbar('location','South');
set(cb,'Position',[0.35 0.085 0.3 0.03]);
set(cb,'XAxisLocation','bottom');
h=get(cb,'Title');
set(h,'String',opt.title);

whitebg(gcf,opt.background);
set(gcf,'Color',opt.background,'InvertHardcopy','off');

dcm_obj=datacursormode(gcf);
set(dcm_obj,'UpdateFcn',@SurfStatDataCursor,'DisplayStyle','window');

set(gcf,'PaperPosition',[0.25 2.5 6 4.5]);

return
end
