function pipeline = niak_report_brain_maps(in,opt)
% Generate a dashboard with brain maps
%
% SYNTAX: PIPE = NIAK_REPORT_FMRI_PREPROCESS(IN,OPT)
%
% IN.BACKGROUND (string or cell of strings) a brain volume to 
%   use as a background for each brain map.
% IN.OVERLAY (string or cell of string) a series of 3D or 4D brain volume
%
% OPT (structure) with the following fields:
%   FOLDER_OUT (string) the path where to store the results.
%   LABELS (cell of strings, default 'map1', 'map2', etc). 
%     Label number I will be used for IN.MAP{I} in the dashboard. 
%   IND (scalar or vector, default 1) if IN.MAP is a 4D volume, the IND-th
%     volume is extracted. If IND is a vector, IND(I) is used for IN.MAP{I}.
%   CLASS_VIEWER (string, default 'col-sm-6') the bootstrap class for the viewer. 
%   BACKGROUND.COLORMAP (string, default 'gray') The type of 
%     colormap. Anything supported by the instruction `colormap` will work.
%   BACKGROUND.NB_COLOR (default 256) the number of colors to use in 
%     quantization. 
%   BACKGROUND.QUALITY (default 90) for jpg images, set the quality of 
%     the background (from 0, bad, to 100, perfect).
%   BACKGROUND.LIMITS (vector 1x2) the limits for the colormap. By defaut it is using [min,max].
%     If a string is specified, the function will implement an adaptative strategy.
%   OVERLAY.COLORMAP (string, default 'hot_cold') The type of colormap. 
%     Anything supported by the instruction `colormap` will work, as well as 
%     'hot_cold' (see niak_hot_cold). This last color map always centers on zero.
%   OVERLAY.NB_COLOR (default 256) the number of colors to use in 
%     quantization. If Inf is specified, all values are included in the 
%     colormap. This is handy for integer values images (e.g. parcellation).
%   OVERLAY.THRESH (scalar, default []) if empty, does nothing. If a scalar, any value
%     below threshold becomes transparent.
%   OVERLAY.LIMITS (vector 1x2) the limits for the colormap. By defaut it is using [min,max].
%     If a string is specified, the function will implement an adaptative strategy.
%   PSOM (structure) options for PSOM. See PSOM_RUN_PIPELINE.
%   FLAG_VERBOSE (boolean, default true) if true, verbose on progress.
%   FLAG_TEST (boolean, default false) if the flag is true, the pipeline will
%     be generated but no processing will occur.
%
%   This pipeline needs the PSOM library to run.
%   http://psom.simexp-lab.org/
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : visualization, montage, 3D brain volumes

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

%% PSOM/NIAK variables
psom_gb_vars;
niak_gb_vars;

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'background' , 'overlay' }, ...
    { NaN          , NaN       });
if ischar(in.overlay)
    in.overlay = {in.overlay};
end

flag_template = ischar(in.background);
if flag_template
    in.background = {in.background};
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults ( opt , ...
    { 'folder_out' , 'labels' , 'ind' , 'class_viewer' , 'background' , 'overlay' , 'flag_test' , 'psom'   , 'flag_verbose' }, ...
    { NaN          , {}       , [1]   , 'col-sm-6'     , struct       , struct    , false       , struct() , true           });

opt.background = psom_struct_defaults( opt.background , ...
    { 'colormap' , 'nb_color' , 'quality' , 'limits'     }, ...
    { 'gray'     , 256        , 90        , 'adaptative' });

opt.overlay = psom_struct_defaults( opt.overlay , ...
    { 'colormap' , 'nb_color' , 'thresh' , 'limits'     }, ...
    { 'gray'     , 256        , []       , 'adaptative' });
  
if isempty(opt.labels)
    for oo = 1:length(in.overlay)
        opt.labels{oo} = sprintf('map%i',oo);
    end
end
if length(ind)==1
    ind = repmat(ind,[length(in.overlay) 1]);
end

opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];

%% Copy the report templates
pipeline = struct;
clear jin jout jopt
niak_gb_vars
path_template = [GB_NIAK.path_niak 'reports' filesep 'brain_map' filesep 'templates' filesep ];
jin = niak_grab_folder( path_template , {'.git','index.html','viewer.html'});
jout = strrep(jin,path_template,opt.folder_out);
jopt.folder_out = opt.folder_out;
pipeline = psom_add_job(pipeline,'cp_report_templates','niak_brick_copy',jin,jout,jopt);

% background images
list_background = cell(length(in.background,1));
for bb = 1:length(in.background)
    jname = ['background_' opt.labels{bb}];
    jin.source = in.background{bb};
    jin.target = in.background{bb};
    jout.montage = [opt.folder_out 'img' filesep jname '.jpg'];
    list_background{bb} = jout.montage;
    jout.quantization = [opt.folder_out 'img' filesep jname '.mat'];
    jopt.colormap = opt.background.colormap;
    jopt.limits = opt.background.limits;
    jopt.nb_color = opt.background.nb_color;
    jopt.quality = opt.background.quality;
    pipeline = psom_add_job(pipeline,jname,'niak_brick_montage',jin,jout,jopt);
end

% Overlay images
list_overlay = cell(length(in.overlay),1);
list_colormap = cell(length(in.overlay),1);
list_quantization = cell(length(in.overlay),1);
for oo = 1:length(in.overlay)
    jname = ['overlay_' opt.labels{bb}];
    jin.source = in.overlay{oo};
    jin.target = in.background{oo};
    jout.montage = [opt.folder_out 'img' filesep jname '.png'];
    list_overlay{oo} = jout.montage;
    jout.quantization = [opt.folder_out 'img' filesep jname '.mat'];
    list_quantization{oo} = jout.quantization;
    jout.colormap = [opt.folder_out 'img' filesep jname '_cm.png'];
    list_colormap{oo} = jout.colormap;
    
    jopt.colormap = opt.overlay.colormap;
    jopt.limits = opt.overlay.limits;
    jopt.thresh = opt.overlay.thresh;
    jopt.nb_color = opt.overlay.nb_color;
    pipeline = psom_add_job(pipeline,jname,'niak_brick_montage',jin,jout,jopt);
end

% Generate the motion report
for ll = 1:length(labels)
    clear jin jout jopt
    jin = list_quantization;
    jout.index = [opt.folder_out 'index.html'];
    jout.data = [opt.folder_out 'listMaps.js'];
    jopt.labels = opt.labels;
    jopt.class = opt.class;
    jopt.background = list_background;
    jopt.overlay = list_overlay;
    
    pipeline = psom_add_job(pipeline,'brain_map_report','niak_brick_report_brain_map',jin,jout,jopt);
end

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end
