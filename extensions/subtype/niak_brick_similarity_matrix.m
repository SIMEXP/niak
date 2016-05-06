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
%   (string) path to a .mat file containing an array (#subjects x 
%   #vertices OR voxels OR regions) generated from subtype_preprocessing  
% 
% FILES_OUT
%   (structure) with the following fields:
%
%   MATRIX
%       (string, default 'similarity_matrix.mat) path to the .mat 
%       output file
%
%   SIM_FIG
%       (string, default 'similarity_matrix.png') path to the .png
%       visualization of the similarity matrix. 
%
%   DEN_FIG
%       (string, default 'dendrogram.png') path to the .png
%       visualization of the dendrogram
% 
% OPT 
%   (structure, optional) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
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

% Options
if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'flag_verbose' , 'flag_test' },...
      { ''           , true           , false       });

% Output
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'matrix'                           , 'sim_fig'                          , 'den_fig'                   },...
                { [path_out 'similarity_matrix.mat'] , [path_out 'similarity_matrix.png'] , [path_out 'dendrogram.png'] });
else
    files_out = psom_struct_defaults(files_out,...
                { 'matrix'          , 'sim_fig'         , 'den_fig'         },...
                { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' });
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the data
data = load(files_in);
provenance = data.provenance; % load provenance
data = data.stack; % load stack data

%% Build correlation matrix
sim_matrix = niak_build_correlation(data');

% Cluster subjects
hier = niak_hierarchical_clustering(sim_matrix);

% Reorder subjects based on clustering
subj_order = niak_hier2order(hier);

% Generate re-ordered matrix
rm = sim_matrix(subj_order,subj_order);

if ~strcmp(files_out.sim_fig, 'gb_niak_omitted')
    %% Save the similarity matrix as png
    opt_png.limits = [-1 1];
    opt_png.color_map = 'hot_cold';
    fh1 = figure('Visible', 'off');
    niak_visu_matrix(rm,opt_png);
    print(fh1, files_out.sim_fig,'-dpng','-r300');
end

if ~strcmp(files_out.den_fig, 'gb_niak_omitted')
    %% Generate and save dendrogram as png
    fh2 = figure('Visible', 'off');
    niak_visu_dendrogram(hier);
    print(fh2, files_out.den_fig,'-dpng','-r300');
end

if ~strcmp(files_out.matrix, 'gb_niak_omitted')
%% Save hierarchical clustering and ordering of subjects and similarity matrix as mat
    save(files_out.matrix,'provenance','hier','subj_order','sim_matrix');
end

