function [in,out,opt] = niak_brick_preproc_motion2report(in,out,opt)
% Generate an html motion report
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_PREPROC_PARAMS2REPORT(IN,OUT,OPT)
%
% IN (string) not used. 
% OUT (string) the name of the .html report. 
% OPT.LABEL (string) subject_session_run label.
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
if ~ischar(out) 
    error('OUT should be a string');
end

if nargin < 3
    opt = struct;
end    
opt = psom_struct_defaults ( opt , ...
    { 'label' , 'flag_test' }, ...
    { NaN     , false         });

if opt.flag_test 
    return
end

%% The template
niak_gb_vars;
file_template = [gb_niak_path_niak 'reports' filesep 'fmri_preprocess' filesep 'templates' filesep 'motion' filesep 'motion_template.html'];

%% Read template
hf = fopen(file_template);
str_template = fread(hf,Inf,'uint8=>char')';
fclose(hf);

%% Update template

% Motion native
str_template = strrep(str_template,'$MOTION_NATIVE',['motion_native_' opt.label '.jpg']);
% Motion stereo
str_template = strrep(str_template,'$MOTION_STEREO',['motion_stereo_' opt.label '.jpg']);
% spacer
str_template = strrep(str_template,'$SPACER_NATIVE',['spacer.jpg']);
% spacer stereo (same as native ...)
str_template = strrep(str_template,'$SPACER_STEREO',['spacer.jpg']);

%% Write report
[hf,msg] = fopen(out,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',str_template);
fclose(hf);