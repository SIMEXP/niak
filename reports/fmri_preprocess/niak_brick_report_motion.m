function [in,out,opt] = niak_brick_qc_fmri_preprocess(in,out,opt)
% Generate anatomical and functional figures to QC coregistration
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_QC_FMRI_PREPROCESS(IN,OUT,OPT)
%
% IN.ANAT            (string) the file name of an individual T1 volume (in stereotaxic space)
% IN.TEMPLATE   (string) the file name of the template used for registration in stereotaxic space.
% IN.FUNC            (string) the file name of an individual functional volume (in stereotaxic space)
% OUT.STEREO     (string) the file name for the figure checking T1/template coregistration. 
% OUT.ANAT          (string) the file name for the figure of the T1 scan.
% OUT.TEMPLATE (string) the file name for the figure of the template.
% OUT.FUNC         (string) the file name for the figure of the functional volume.
% OUT.REPORT     (string) the file name of the html report. 
% OPT.FOLDER_OUT (string) where to generate the outputs. 
% OPT.ID                (string) the subject ID used to name the figures. 
% OPT.COORD       (array N x 3) Coordinates for the figure. The default is:
%                               [-30 , -65 , -15 ; 
%                                  -8 , -25 ,  10 ;  
%                                 30 ,  45 ,  60];    
% OPT.TEMPLATE (string) if specified, this file name will be used in the report
%   instead of OUT.TEMPLATE.
% OPT.FLAG_VERBOSE (boolean, default true) if true, verbose on progress. 
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but 
%    update IN, OUT and OPT.
%
% NOTE:
%   By default, the brick will generate all outputs. To skip an output, use 'gb_niak_omitted' 
%   as an output name. 
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2016.
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

%% Defaults

% Inputs
in = psom_struct_defaults( in , ...
    { 'anat' , 'template' , 'func' }, ...
    { NaN   , NaN          , NaN   });

% Outputs
if (nargin < 2) || isempty(out)
    out = struct;
end 
out = psom_struct_defaults( out , ...
    { 'anat' , 'template' , 'func' , 'report' }, ...
    { ''        , ''               , ''        , ''           });

% Options 
if nargin < 3
    opt = struct;
end
coord_def =[-30 , -65 , -15 ; 
                      -8 , -25 ,  10 ;  
                     30 ,  45 ,  60];
opt = psom_struct_defaults ( opt , ...
    { 'folder_out' , 'coord'      , 'flag_test' , 'id'                 , 'template' , 'flag_verbose' }, ...
    { pwd            , coord_def , false         , 'anonymous' , ''               , true                 });

opt.folder_out = niak_full_path(opt.folder_out);

% Output file names
if isempty(out.anat)
    out.anat = [opt.folder_out 't1_slices.jpg'];
end

if isempty(out.template)
    out.template = [opt.folder_out 'template_slices.jpg'];
end

if isempty(out.func)
    out.func = [opt.folder_out 'func_slices.jpg'];
end

if isempty(out.report)
    out.report = [opt.folder_out 'report_qc_coregister.html'];
end

% End of the initialization
if opt.flag_test
    return
end

%% Generate the image for the structural scan
if ~strcmp(out.anat,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generating slices of the anatomical scan...\n');
    end
    in_v.source = in.anat;
    in_v.target = in.template;
    out_v = out.anat;
    opt_v.coord = opt.coord;
    opt_v.colorbar = false;
    opt_v.colormap = 'gray';
    opt_v.limits = 'adaptative';
    opt_v.title = sprintf('structural scan, %s',opt.id);
    niak_brick_vol2img(in_v,out_v,opt_v);
end

%% Generate the image for the template
if ~strcmp(out.template,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generating slices of the template...\n');
    end
    in_v.source = in.template;
    in_v.target = in.template;
    out_v = out.template;
    opt_v.coord = opt.coord;
    opt_v.colorbar = false;
    opt_v.colormap = 'gray';
    opt_v.limits = 'adaptative';
    opt_v.title = sprintf('       template, %s',opt.id);
    niak_brick_vol2img(in_v,out_v,opt_v);
end

%% Generate the image for the functional scan
if ~strcmp(out.func,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generating slices of the functional scan...\n');
    end
    in_v.source = in.func;
    in_v.target = in.template;
    out_v = out.func;
    opt_v.coord = opt.coord;
    opt_v.colorbar = false;
    opt_v.colormap = 'jet';
    opt_v.limits = 'adaptative';
    opt_v.title = sprintf('functional scan, %s',opt.id);
    niak_brick_vol2img(in_v,out_v,opt_v);
end

%% Generate the html report
if ~strcmp(out.report,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generating the QC html report...\n');
    end
    
    %% Read html template
    file_self = which('niak_pipeline_qc_fmri_preprocess');
    path_self = fileparts(file_self);
    file_html = [path_self filesep 'niak_template_qc_fmri_preprocess.html'];
    hf = fopen(file_html,'r');
    str_html = fread(hf,Inf,'uint8=>char')';
    fclose(hf);

    %% Modify template and save output
    hf = fopen(out.report,'w+');
    [path_a,name_a,ext_a] = fileparts(out.anat);
    if ~isempty(opt.template)
       [path_t,name_t,ext_t] = fileparts(opt.template);
    else
       [path_t,name_t,ext_t] = fileparts(out.template);
    end
    [path_f,name_f,ext_f] = fileparts(out.func);
    text_write = strrep(str_html,'$TEMPLATE',[name_t ext_t]);
    text_write = strrep(text_write,'$ANAT',[name_a ext_a]);
    text_write = strrep(text_write,'$FUNC',[name_f ext_f]);
    fprintf(hf,'%s',text_write);
    fclose(hf);
end