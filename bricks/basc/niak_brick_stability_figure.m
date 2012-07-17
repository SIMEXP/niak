function [files_in,files_out,opt] = niak_brick_stability_figure(files_in,files_out,opt)
% Generate a figure representing stability matrices and partitions.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_FIGURE(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%   STABILITY
%       (string) a .mat file containing two variables STAB and NB_CLASSES. 
%       STAB(:,S) is a vectorized version of a stability matrix with 
%       NB_CLASSES(S) random clusters.
%
%   HIERARCHY
%       (string or cell of strings, default FILES_IN.STABILITY) a .mat file
%       containing two variables HIER and NB_CLASSES. HIER{K} is the 
%       hierarchy associated with the consensus clustering for 
%       NB_CLASSES(K) random clusters. If FILES_IN.HIERARCHY has multiple
%       entires, HIERARCHY{L} is used to generate FILES_OUT{L}.
%
% FILES_OUT
%   (string or cell of strings)
%   A pdf representation of the stability matrices and associated clusters.
%   Each entry of FILES_OUT is associated with one row of OPT.SCALES_MAPS.
%
% OPT
%       (structure) with the following fields.
%
%   NAME_STAB
%       (string, default 'stab') The name of the variable defining the
%       stability matrix.
%
%   LABELS
%       (cell of string) LABEL{I} will be used to label the figures in
%       FILES_OUT{I}.
%
%   SCALES_MAPS
%       (array, default []) SCALES_MAPS(K,:) is the list of scales that will
%       be used to generate stability maps:
%           SCALES_MAPS(K,1) is the number of clusters used to select the 
%               stability matrix.
%           SCALES_MAPS(K,2) is the number of clusters used to select the 
%               consensus hierarchy.
%           SCALES_MAPS(K,3) is the (final) number of consensus clusters
%               used to define the order and represent the partition.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%       do anything but update the default values in FILES_IN,
%       FILES_OUT and OPT.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function
%       prints some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : stability, clustering, figure

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_MAPS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_maps'' for more info.')
end

%% Files in
list_fields    = {'stability' , 'hierarchy' };
list_defaults  = {NaN         , NaN         };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

if ~ischar(files_in.stability)
    error('FILES_IN.STABILITY should be a string')
end

if ischar(files_in.hierarchy)
    files_in.hierarchy = {files_in.hierarchy};
end
if ~iscellstr(files_in.hierarchy)
    error('FILES_IN.HIERARCHY should be a string or a cell of strings')
end

%% Files out
if ischar(files_out)
    files_out = {files_out};
end

if ~iscellstr(files_out)
    error('FILES_OUT should be a string or a cell of strings');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'name_stab' , 'scales_maps' , 'labels' , 'flag_verbose' , 'flag_test' };
gb_list_defaults  = {'stab'      , NaN           , NaN      , true           , false       };
niak_set_defaults

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = sprintf('Generating a figure representing the stability matrix and associated partition');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n Generating file ...\n',stars,msg,stars);
end


for num_f = 1:length(files_out)
    if flag_verbose
        fprintf('    %s\n',files_out{num_f});
    end
    
    %% Read the hierarchy    
    hier = load(files_in.hierarchy{min(length(files_in.hierarchy),num_f)},'hier','nb_classes');
    nb_classes_hier = hier.nb_classes;
    hier = hier.hier;    
    mask_hier = (nb_classes_hier==opt.scales_maps(num_f,end-1));    
        
    %% Read the stability matrix
    stab = load(files_in.stability,name_stab,'nb_classes');
    nb_classes = stab.nb_classes;
    mask = nb_classes==opt.scales_maps(num_f,1);
    stab = stab.(name_stab);
    mat = niak_vec2mat(stab(:,mask));
    
    %% Derive the partition & associated order
    opt_t.thresh = opt.scales_maps(num_f,end);        
    part = niak_threshold_hierarchy(hier{mask_hier},opt_t);
    order = niak_part2order(part,mat);
    
    %% generate a pdf of the stability matrix
    file_tmp = [psom_path_tmp 'fig.pdf'];
    hfa = figure;
    subplot(1,2,1)
    niak_visu_matrix(mat(order,order));
    title(sprintf('stability matrix %s',opt.labels{num_f}))
    
    subplot(1,2,2)
    niak_visu_part(part(order));
    colorbar
    title(sprintf('partition into stable clusters %s',opt.labels{num_f}))
    print(gcf,'-dpdf',file_tmp)
    system(['mv ' file_tmp ' ' files_out{num_f}]);
    close(hfa)
end

if flag_verbose
    fprintf('\nDone !\n');
end
