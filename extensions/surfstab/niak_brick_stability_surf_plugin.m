function [files_in,files_out,opt] = niak_brick_stability_surf_plugin(files_in,files_out,opt)
% Build stability_maps at the voxel level based on clustering replications
% and a target cluster
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_PLUGIN(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (string) a .mat file with two fields:
%       DATA_ROI
%
%       PART_ROI
%
% FILES_OUT
%   (string, optional) the name of a .mat file with the variables:
%       PART is a VxK matrix, where the k-th column is the partition associated 
%       with the number of cluster OPT.SCALE_TAR(k).
%
% OPT
%   (structure) with the following fields:
%
%   SCALE_TAR
%       (vector) of K integers. The target scales  (i.e. number of final 
%       clusters).
%
%   SCALE_REP
%       (vector, default same as OPT.SCALE_TAR) The desired scales to be used 
%       for generating the replication clusters at a later point.
%
%   NAME_DATA
%       (string, default 'data') the name of the variable that contains
%       the data.
%
%   NAME_PART
%       (string, default 'part') the name of the fieldname in FILE_IN.PART that
%       contains the partition.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
%
%   FLAG_VERBOSE
%       (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, default false) if the flag is true, the brick does not do anything
%       but updating the values of FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, surface analysis, cortical thickness, stability
% analysis, bootstrap, jacknife.

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

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_PLUGIN(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf_plugin'' for more info.')
end

% FILES_IN
if ~ischar(files_in)
    error('FILES_IN should be a string!');
end

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string!');
end

% Options
if nargin < 3
    opt = struct;
end
list_fields   = { 'scale_tar' , 'scale_rep' , 'name_data' , 'name_part' ,  'rand_seed' , 'flag_verbose' , 'flag_test' };
list_defaults = { NaN         , []          , 'data_roi'  , 'part_roi'  , []           , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if isempty(opt.scale_rep)
    opt.scale_rep = opt.scale_tar;
end

if opt.flag_test
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read in data
data = load(files_in);

if ~isfield(data,opt.name_data)
    error('I could not find the variable called %s in the file %s',opt.name_data, files_in)
elseif ~isfield(data,opt.name_part)
    error('I could not find the variable called %s in the file %s',opt.name_part, files_in)
else
    data_roi = data.(opt.name_data);
    part_roi = data.(opt.name_part);
end
    
%% Build the plugin clustering

if opt.flag_verbose
    fprintf('Building the plug-in estimate of the clusters ...\n');
    fprintf('    Clustering, ');
end

R = niak_build_correlation(data_roi);
hier = niak_hierarchical_clustering(R);
opt_t.thresh = opt.opt.scale_tar;
part_tmp = niak_threshold_hierarchy(hier,opt_t);
V = length(part_roi);
num_scale = length(opt.scale_tar);
part = zeros(V,num_scale);
% TODO: replace this with only one line when the new
% niak_part2vol becomes available
for part_index = 1:num_scale
    part(:,part_index) = niak_part2vol(part_tmp(:, part_index),part_roi);
end

%% Save Outputs
if opt.flag_verbose
    fprintf('Saving outputs to %s\n', files_out);
end
scale_tar = opt.scale_tar;
scale_rep = opt.scale_rep;
save(files_out, 'part', 'scale_tar', 'scale_rep', 'hier');
