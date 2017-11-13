function [in,out,opt] = niak_brick_connectome_params2report(in,out,opt)
% Generate javascript formatted description of connectome parameters
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_CONNECTOME_PARAMS2REPORT(IN,OUT,OPT)
%
% IN (string) The name of a .mat file with two variables FILES_IN (the input files) and 
%   OPT (the options), describing the parameters of the pipeline. 
% OUT.LIST_SUBJECT (string) the name of a .js file with a description of the list 
%   of subjects, in a variable listSubject.
% OUT.LIST_RUN (string) the name of a .js file with a description of the list of 
%   runs, in a variable listRun.
% OUT.FILES_IN (string) the name of a .js file with a json description of the 
%   pipeline options, in a variable opt, as well as a function buildFilesIn that 
%   generates a .json description of the input file for a particular subject. 
% OUT.SUMMARY (string) the name of a .js file with a string summarizing the 
%   pipeline options. 
% OPT.LIST_SUBJECT (cell of strings, default use data found in IN) a list of 
%    subject IDs. 
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

out = psom_struct_defaults ( out , ...
    { 'list_subject' , 'list_run' , 'files_in' , 'summary' }, ...
    { NaN            , NaN        , NaN        , NaN       });

if nargin < 3
    opt = struct;
end    
opt = psom_struct_defaults ( opt , ...
    { 'list_subject' , 'flag_test' }, ...
    { {}             , false         });

if opt.flag_test 
    return
end

%% Load parameters
data = load(in);
if ~isfield(data,'files_in')
    error('I could not find the variable FILES_IN in the input file');
end
if ~isfield(data,'opt')
    error('I could not find the variable OPT in the input file');
end
[list_fmri,labels] = niak_fmri2cell(data.files_in.fmri);
if isempty(opt.list_subject)
    list_subject = fieldnames(data.files_in.fmri);
else
    list_subject = opt.list_subject;
end

%% List of subjects
text_subject = sprintf('var listSubject = [\n');
for ss = 1:(length(list_subject)-1)
    text_subject = [text_subject sprintf('{id: %i, text: ''%s'' },\n',ss,list_subject{ss})];
end
text_subject = sprintf('%s{id: %i, text: ''%s'' }\n];\n',text_subject,length(list_subject),list_subject{end});

[hf,msg] = fopen(out.list_subject,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_subject);
fclose(hf);

%% List of runs
text_run = sprintf(['  // Data structure describing all available runs\n' ...   
                    '  var dataRun = [\n']);
for ll = 1:(length(labels)-1)
    text_run = [ text_run sprintf('    { id: %i, text: ''%s'' },\n',ll,labels(ll).name)];
end 
text_run = [ text_run sprintf('    { id: %i, text: ''%s'' }\n  ];\n',length(labels),labels(end).name)];

[hf,msg] = fopen(out.list_run,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_run);
fclose(hf);

%% List of input filesep
text_files = sprintf(['function buildFilesIn (evt) {\n' ...
                      '  switch(evt.params.data.id) {\n']);
for ss = 1:length(list_subject)
    json_files = savejson('',data.files_in.fmri.(list_subject{ss}));
    text_files = [text_files sprintf('    case "%i":\n      var filesIn = %s\n break\n',ss,json_files)];
end
text_files = [text_files sprintf(['};\n' ...
              'return filesIn \n}\n'])];

%% Options
tmp.opt = data.opt;
tmp.network = data.files_in.network;
tmp.seeds = data.files_in.seeds;
text_files = [text_files sprintf('\nvar opt = %s\n',savejson('',tmp))];

[hf,msg] = fopen(out.files_in,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_files);
fclose(hf);

%% Pipeline summary
niak_gb_vars;
psom_gb_vars;
[status,ver_minc] = system('echo $MINC_TOOLKIT_VERSION');
ver_minc = ver_minc(1:(end-1));
%String.fromCharCode(13)
text_js = sprintf(['var pipeSummary = ''<p>This report on connectome analysis for %i subjects' ...
          ' was prepared by user "%s" using the system "%s", ' ...
          'on %s. The version of the software was as follows:</p>' ...
          '<p>%s version "%s" </p>' ... 
          '<p>Minc-toolkit version "%s" </p>' ...
          '<p>PSOM version "%s", located in %s </p>' ...
          '<p>NIAK version "%s", located in %s</p>'';'],length(list_subject),GB_NIAK.user, ...
          gb_psom_localhost,datestr(clock),GB_NIAK.language,GB_NIAK.language_version, ...
          ver_minc,gb_psom_version,gb_psom_path_psom,GB_NIAK.version,GB_NIAK.path_niak);
[hf,msg] = fopen(out.summary,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_js);
fclose(hf);

