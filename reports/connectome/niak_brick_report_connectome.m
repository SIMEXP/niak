function [in,out,opt] = niak_brick_report_connectome(in,out,opt)
% Generate an html report for the connectome pipeline
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_REPORT_CONNECTOME(IN,OUT,OPT)
%
% IN.INDIVIDUAL (string) a .mat file with the quantization data for the 
%     individual overlays.
% IN.AVERAGE    (string) a .mat file with the quantization data for the 
%     average overlays.
% IN.NETWORK    (string) a .mat file with the quantization data for the 
%     network overlay.
%
% OUT (string) the name of the rmap.html report. 
% 
% OPT.LABEL_NETWORK (cell of strings) string labels for each network.
% OPT.LABEL_SUBJECT (cell of strings) string labels for each network.
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
in = psom_struct_defaults ( in , { 'individual' , 'average' , 'network'} , { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' });
if ~ischar(out)
    error('FILES_OUT should be a string')
end

if nargin < 3
    opt = struct;
end    

opt = psom_struct_defaults ( opt , ...
    { 'label_network' , 'label_subject' , 'flag_test' }, ...
    { NaN             , NaN             , false         });

if opt.flag_test 
    return
end

%% Lists of subject/network
list_subject = opt.label_subject;
list_network = opt.label_network;

%% Read the quantization data
quant_ind = load(in.individual);
quant_avg = load(in.average);
quant_net = load(in.network);

%% The template
niak_gb_vars;
file_rmap = [GB_NIAK.path_niak 'reports' filesep 'connectome' filesep 'templates' filesep 'rmap.html'];

%% Read rmap
hf = fopen(file_rmap);
str_rmap = fread(hf,Inf,'uint8=>char')';
fclose(hf);

%% Update rmap 
str_rmap = strrep(str_rmap,'$ORIGINX',sprintf('%1.3f',quant_ind.origin(1)));
str_rmap = strrep(str_rmap,'$ORIGINY',sprintf('%1.3f',quant_ind.origin(2)));
str_rmap = strrep(str_rmap,'$ORIGINZ',sprintf('%1.3f',quant_ind.origin(3)));
str_rmap = strrep(str_rmap,'$VOXELSIZE',sprintf('%1.3f',quant_ind.voxel_size));
str_rmap = strrep(str_rmap,'$NUMELY',sprintf('%i',quant_ind.size_slice(1)));
str_rmap = strrep(str_rmap,'$NUMELZ',sprintf('%i',quant_ind.size_slice(2)));
str_rmap = strrep(str_rmap,'$AVGMIN',sprintf('%i',quant_avg.min_img));
str_rmap = strrep(str_rmap,'$AVGMAX',sprintf('%i',quant_avg.max_img));
str_rmap = strrep(str_rmap,'$INDMIN',sprintf('%i',quant_ind.min_img));
str_rmap = strrep(str_rmap,'$INDMAX',sprintf('%i',quant_ind.max_img));
str_rmap = strrep(str_rmap,'$NETMIN',sprintf('%i',quant_net.min_img));
str_rmap = strrep(str_rmap,'$NETMAX',sprintf('%i',quant_net.max_img));
str_rmap = strrep(str_rmap,'$NETWORK',list_network{1});
str_rmap = strrep(str_rmap,'$SUBJECT',list_subject{1});

%% Write report
[hf,msg] = fopen(out,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',str_rmap);
fclose(hf);