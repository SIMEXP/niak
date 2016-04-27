function [files_in,files_out,opt] = niak_brick_similarity_matrix(files_in,files_out,opt)
% Build similarity matrix for subtype pipeline
% 
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPE_SIMILARITY_MATRIX(FILES_IN,FILES_OUT,OPT)
% _________________________________________________________________________
% 
% INPUTS:
% 
% FILES_IN 
%       (string) path to a .mat file containing an array (#subjects x 
%       #vertices OR voxels OR regions) generated from subtype_preprocessing  
% 
% FILES_OUT 
%       (string) path for results (default pwd)
% 
% OPT 
%       (structure, optional) with the following fields:
% 
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do 
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var') || ~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPE_SIMILARITY_MATRIX(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtype_similarity_matrix'' for more info.')
end

% Input
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

% Output
if ~ischar(files_out)
    error('FILES_OUT should be a string');
elseif isempty(files_out)
    files_out = pwd;
end
if exist('files_out','var')
    psom_mkdir(files_out);
end

% Options
if nargin < 3
    opt = struct;
end

list_fields   = { 'flag_verbose' , 'flag_test' };
list_defaults = { true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the data
data = load(files_in);
data = data.stack;

%% Build correlation matrix
sim_matrix = niak_build_correlation(data');

% Cluster subjects
hier = niak_hierarchical_clustering(sim_matrix);

% Reorder subjects based on clustering
subj_order = niak_hier2order(hier);

% Generate re-ordered matrix
rm = sim_matrix(subj_order,subj_order);

%% Save the similarity matrix as png
opt_png.limits = [-1 1];
opt_png.color_map = 'hot_cold';
fh1 = figure('Visible', 'off');
niak_visu_matrix(rm,opt_png);
namefig = [files_out filesep 'similarity_matrix.png'];
print(fh1, namefig,'-dpng','-r300');

%% Generate and save dendrogram as png
fh2 = figure('Visible', 'off');
niak_visu_dendrogram(hier);
nameden = [files_out filesep 'dendrogram.png'];
print(fh2, nameden,'-dpng','-r300');

%% Save hierarchical clustering and ordering of subjects and similarity matrix as mat
mat_file = [files_out filesep 'similarity_matrix.mat'];
save(mat_file,'hier','subj_order','sim_matrix');
end

