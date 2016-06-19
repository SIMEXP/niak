function [in,out,opt] = niak_brick_preproc_ind_motion2report(in,out,opt)
% Generate javascript formatted measure of intra-subject inter-run registration
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_PREPROC_IND_MOTION2REPORT(IN,OUT,OPT)
%
% IN.(SUBJECT) (string) The name of a .csv file with individual confound measures 
%   for one run. 
% OUT (string) the name of a .js file with three variables:
%   tsl, rot and fd.  
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but 
%    update IN, OUT and OPT.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: preprocessing report

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
if ~ischar(in) 
    error('IN should be a string');
end

if ~ischar(out) 
    error('OUT should be a string');
end

if nargin < 3
    opt = struct;
end    
opt = psom_struct_defaults ( opt , ...
    { 'flag_test' }, ...
    { false         });

if opt.flag_test 
    return
end

%% Load confounds
tab = niak_read_csv_cell(in);
labels_tsl = {'motion_tx','motion_ty','motion_tz'};
text_js = sub_add_js('',tab(:,ismember(tab(1,:),labels_tsl)),'tsl');
labels_rot = {'motion_rx','motion_ry','motion_rz'};
text_js = sub_add_js(text_js,tab(:,ismember(tab(1,:),labels_rot)),'rot');
labels_fd = {'FD','scrub'};
text_js = sub_add_js(text_js,tab(:,ismember(tab(1,:),labels_fd)),'fd');

%% Write output
[hf,msg] = fopen(out,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_js);
fclose(hf);

function text_js = sub_add_js(text_js,tab,name)

%% Compose js text
text_js = [text_js sprintf('var %s = {\n  columns: [\n',name)];
for ii = 1:size(tab,2)
    text_js = [text_js sprintf('    [''%s'' ',tab{1,ii})];
    for ss = 2:size(tab,1)
	      text_js = [text_js, ', ' tab{ss,ii} ];
    end
    if ii == size(tab,2)
        text_js = [text_js sprintf(']\n')];
    else
        text_js = [text_js sprintf('],\n')];
    end
end
text_js = sprintf([text_js '  ],\n  selection: {\n' ...
          '    enabled: true\n' ...
          '  },\n' ...
          '  onclick: function (d) { selectTime(d.index);}\n' ...
          '};\n']);