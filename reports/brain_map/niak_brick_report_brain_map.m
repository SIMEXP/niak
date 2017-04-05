function [in,out,opt] = niak_brick_report_brain_map(in,out,opt)
% Generate an html report with multiple brain map viewers
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_REPORT_BRAIN_MAP(IN,OUT,OPT)
%
% IN (cell of strings) each entry is a .mat file with the 
%    quantization data for one overlay. 
% OUT.INDEX (string) the name of the .html report. 
% OUT.DATA (string) the name of the javascript data. 
% OPT.LABELS (cell of strings) string labels for each volume.
% OPT.COLOR_BACKGROUND (string, default #000000) the color of the background. 
% OPT.COLOR_FONT (string, default #FFFFFF) the color of the fonts in the viewer. 
% OPT.OVERLAY (cell of strings) each entry is the png image of an overlay. 
% OPT.COLORMAP (cell of strings) each entry is the png image of the colormap 
%    associated with corresponding overlay. If only one entry is provided, 
%    the same colormap is used for all overlays. 
% OPT.BACKGROUND (cell of strings) each entry is the png image of a background.
%    If only one entry is provided, the same background is used for all overlays.  
% OPT.CLASS_VIEWER (string, default 'col-sm-6') the bootstrap class for the viewer. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but 
%    update IN, OUT and OPT.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: brain map, viewer, report

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

%% Defaults
if ~iscellstr(in)
    error('IN should be a cell of strings')
end

out = psom_struct_defaults ( out , { 'index' , 'data' } , { NaN , NaN });

if nargin < 3
    opt = struct;
end    

opt = psom_struct_defaults ( opt , ...
    { 'color_background' , 'color_font' , 'class_viewer' , 'overlay' , 'class' , 'background' , 'colormap' , 'labels' , 'flag_test' }, ...
    { '#000000'          , '#FFFFFF'    , 'col-sm-6'     , NaN       , NaN     , NaN          , NaN        , NaN      , false         });

if opt.flag_test 
    return
end

%% The template
niak_gb_vars;
file_template = [GB_NIAK.path_niak 'reports' filesep 'brain_map' filesep 'templates' filesep 'index.html'];
file_viewer   = [GB_NIAK.path_niak 'reports' filesep 'brain_map' filesep 'templates' filesep 'viewer.html'];

%% Read template
hf = fopen(file_template);
str_template = fread(hf,Inf,'uint8=>char')';
fclose(hf);

%% Read viewer
hf = fopen(file_viewer);
str_viewer_raw = fread(hf,Inf,'uint8=>char')';
fclose(hf);

%% Update viewer
str_viewer = '';
for oo = 1:length(opt.overlay)
    if (oo==1) || (length(opt.background)>1)
        [~,name,ext] = niak_fileparts(opt.background{oo});
        map = sprintf('<img id="background%i" class="hidden" src="img/%s%s">\n',oo-1,name,ext);
    else
        map = '';
    end
    [~,name,ext] = niak_fileparts(opt.overlay{oo});
    map = sprintf('%s        <img id="overlay%i" class="hidden" src="img/%s%s">\n',map,oo-1,name,ext);
    [~,name,ext] = niak_fileparts(opt.colormap{oo});
    map = sprintf('%s        <img id="colormap%i" class="hidden" src="img/%s%s">\n',map,oo-1,name,ext);
    
    tmp_viewer = str_viewer_raw;
    tmp_viewer = strrep(tmp_viewer,'$CANVAS',sprintf('canvas%i',oo-1));
    tmp_viewer = strrep(tmp_viewer,'$CLASS',['"' opt.class_viewer '"']);
    tmp_viewer = strrep(tmp_viewer,'$LABEL',opt.labels{oo});
    tmp_viewer = strrep(tmp_viewer,'$MAP',map);
    
    str_viewer = [str_viewer tmp_viewer];
end

%% Update template
str_template = strrep(str_template,'$DIV',str_viewer);
str_template = strrep(str_template,'$COLORBACKGROUND',opt.color_background);
str_template = strrep(str_template,'$COLORFONT',opt.color_font);
if length(opt.background)==1
    str_template = strrep(str_template,'"background"+mm','"background0"');
end

%% Write report
[hf,msg] = fopen(out.index,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',str_template);
fclose(hf);

%% Now save data for quantization
[hf,msg] = fopen(out.data,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'var listMaps = [ ')
for ll = 1:length(opt.labels)
    if ll < length(opt.labels)
        fprintf(hf,'"%s" ,',opt.labels{ll});
    else
        fprintf(hf,'"%s" ];\n',opt.labels{ll});
    end
end

fprintf(hf,'var params = {};\n');
for ii = 1:length(in)
    data = load(in{ii});
    fprintf(hf,'params[%i] = { origin: {X: %f, Y: %f, Z:%f}, voxelSize: %f, nbSlice: {Y: %i, Z: %i}, min: %f, max: %f};\n', ii-1, data.origin(1),data.origin(2), data.origin(3), data.voxel_size, data.size_slice(1),data.size_slice(2),data.min_img,data.max_img);
end
fclose(hf);
