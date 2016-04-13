function [files_in,files_out,opt] = niak_brick_subtype_similarity_matrix(files_in,files_out,opt)
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
if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPE_SIMILARITY_MATRIX(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtype_similarity_matrix'' for more info.')
end

% Input
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

% Output
if ~exist('files_out','var')||isempty(files_out)
    files_out = pwd;
end
if ~ischar(files_out)
    error('FILES_OUT should be a string');
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

%% Build correlation matrix
R = niak_build_correlation(data.data');

% Cluster subjects
hier = niak_hierarchical_clustering(R);

% Reorder subjects based on clustering
order = niak_hier2order(hier);

% Generate re-ordered matrix
simmat = R(order,order);

%% Save the similarity matrix

% Save as .mat file
mat_file = fullfile(files_out, 'similarity_matrix.mat');
save(mat_file,'simmat');

% Save as .png file
opt_png.limits = [-1 1];
opt_png.color_map = 'hot_cold';
niak_visu_matrix(simmat,opt_png);
namefig = fullfile(files_out, 'similarity_matrix.png');
print(namefig,'-dpng','-r300');

%% Generate and save dendrogram
figure
niak_visu_dendrogram(hier);
nameden = fullfile(files_out, 'dendrogram.png');
print(nameden,'-dpng','-r300');

%% Save hierarchical clustering and ordering of subjects
hier_file = fullfile(files_out, 'hier.mat');
save(hier_file,'hier');
order_file = fullfile(files_out, 'order.mat');
save(order_file,'order');

end

