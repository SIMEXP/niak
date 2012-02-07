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

list_fields   = { 'title'      , 'background' , 'lighting' , 'material' , 'shading' , 'colormap' };
list_defaults = { inputname(1) , 'white'      , 'phong'    , 'dull'     , 'flat'    , cm         };

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

clim=[min(data),max(data)];
if clim(1)==clim(2)
    clim=clim(1)+[-1 0];
end

clf;
colormap(opt.colormap);

h=0.39;
w=0.4;

r=max(surf.coord,[],2)-min(surf.coord,[],2);
w1=h/r(2)*r(1)*3/4;
h1=h/r(2)*r(1); % h/r(2)*r(3)

a(1)=axes('position',[0.055 0.62 h*3/4 w]);
trisurf(surf.tri(tl,:),surf.coord(1,vl),surf.coord(2,vl),surf.coord(3,vl),...
    double(data(vl)),'EdgeColor','none');
view(-90,0); 
daspect([1 1 1]); axis tight; camlight; axis vis3d off;
lighting(opt.lighting)
material(opt.material)
shading(opt.shading) 

a(2)=axes('position',[0.3 0.58 w h]);
trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
    double(data),'EdgeColor','none');
view(0,90); 
daspect([1 1 1]); axis tight; camlight; axis vis3d off;
lighting(opt.lighting)
material(opt.material)       
shading(opt.shading)

if cut<t
    a(3)=axes('position',[1-0.055-h*3/4 0.62 h*3/4 w]);
    trisurf(surf.tri(tr,:)-cuv,surf.coord(1,vr),surf.coord(2,vr),surf.coord(3,vr),...
        double(data(vr)),'EdgeColor','none');
    view(90,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)
else
    a(3)=axes('position',[1-0.055-h*3/4 0.62 h/r(2)*r(1)*3/4 w]);
    trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
        double(data),'EdgeColor','none');
    view(180,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)
end

a(4)=axes('position',[0.055 0.29 h*3/4 w]);
trisurf(surf.tri(tl,:),surf.coord(1,vl),surf.coord(2,vl),surf.coord(3,vl),...
    double(data(vl)),'EdgeColor','none');
view(90,0); 
daspect([1 1 1]); axis tight; camlight; axis vis3d off;
lighting(opt.lighting)
material(opt.material)       
shading(opt.shading)

a(5)=axes('position',[0.3 0.18 w h]);
trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
    double(data),'EdgeColor','none');
view(0,-90); 
daspect([1 1 1]); axis tight; camlight; axis vis3d off;
lighting(opt.lighting)
material(opt.material)       
shading(opt.shading)

if cut<t
    a(6)=axes('position',[1-0.055-h*3/4 0.29 h*3/4 w]);
    trisurf(surf.tri(tr,:)-cuv,surf.coord(1,vr),surf.coord(2,vr),surf.coord(3,vr),...
        double(data(vr)),'EdgeColor','none');
    view(-90,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)

    a(7)=axes('position',[0.055 0.02 w1 h1]);
    trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
        double(data),'EdgeColor','none');
    view(180,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)

    a(8)=axes('position',[1-0.055-w1 0.03 w1 h1]);
    trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
        double(data),'EdgeColor','none');
    view(0,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)

else
    a(6)=axes('position',[1-0.055-h*3/4 0.29 h/r(2)*r(1)*3/4 w]);
    trisurf(surf.tri,surf.coord(1,:),surf.coord(2,:),surf.coord(3,:),...
        double(data),'EdgeColor','none');
    view(0,0);
    daspect([1 1 1]); axis tight; camlight; axis vis3d off;
    lighting(opt.lighting)
    material(opt.material)       
    shading(opt.shading)
end    
    
id0=[0 0 cuv 0 0 cuv 0 0];
for i=1:length(a)
    set(a(i),'CLim',clim);
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
