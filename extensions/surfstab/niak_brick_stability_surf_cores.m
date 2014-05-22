function [files_in,files_out,opt] = niak_brick_stability_surf_cores(files_in,files_out,opt)
% Multiscale selection of stable cores
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_CORES(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   STAB
%   (string) path to the .mat file containing the estimated stability based on 
%   the current dataset. The required fieldnames in the file can be specified by
%   OPT. It contains the following fields:
%
%       STAB 
%           (array; OPT.NAME_STAB) Array of dimension [S K] where STAB(:,K) is
%           the vectorized estimated stability matrix at scale SCALE(K).
%
%   PART
%
%       PART
%           (array; OPT.NAME_PART) Array of dimension [V K] where PART(:,K) is 
%           the partition of the V surface verteces into clusters based on
%           STAB(:, K).
%
%       SCALE
%           (vector; OPT.NAME_SCALE) Vector of length K that specifies the 
%           scales used in FILES_IN.STAB.
%
%   ROI
%   (string) path to the .mat file containing the outputs of the region
%   growing algorithm
%
%       PART_ROI
%           (OPT.NAME_PART_ROI) Vector of length V specifies the partition
%           of the V surface verteces into regions.
%
% FILES_OUT
%   (string) path to the .mat file that contains all field in the
%   FILES_IN.CONS file and two additional fields:
%
%   CORE_PART
%       (array) Array of dimension [V K]. CORE_PART(:,K) is the partition of
%       V surface verteces into core clusters of stability at scale
%       SCALE(K). The partition has integer values designating cluster
%       membership inside core clusters and zeros everywhere else.
%
%   CORE_STAB
%       (array) Array of dimension [S K]. CORE_STAB(:, K) is the vectorized
%       stability matrix at scale SCALE(K) that has been masked by non-zero
%       elements in CORE_PART(:, K). The resulting stability matrix has
%       stability values for stable cores and is zero outside of them.
%
% OPT
%   (structure) with the following fields.
%
%   NAME_STAB
%       (string, default: 'stab') variable in FILES_IN.STAB that contains
%       the array of vectorized stability matrices
%
%   NAME_SCALE
%       (string, default: 'scale') variable in FILES_IN.PART that contains
%       the scale vector corresponding to the scales of the stability
%       matrices in FILES_IN.STAB
%
%   NAME_PART
%       (string, default: 'part') variable in FILES_IN.PART that contains
%       the partition.
%
%   NAME_PART_ROI
%       (string, default: 'part_roi') variable in FILES_IN.PART that
%       contains the partition of the vertex level surface into atoms.
%
%   CORES
%       (structure, optional)with the following fields
%
%       TYPE
%           (string, default 'highpass') defines the method used to generate
%           stable clusters. 
%           Avalable options: 'highpass', 'kmeans'
%
%       OPT
%           (structure, optional) the options of the stable cluster method.
%           Depends on OPT.CORES.TYPE.
%           
%           highpass : THRE (scalar, default 0.5) THRE constitutes the 
%                           high-pass percentage cutoff for stability
%                           values (range 0 - 1)
%                      CONF (scalar, default 0.05) defines the confidence 
%                           interval with respect to the stability
%                           threshold in percent (range 0 - 1)
%                           
%           kmeans   : None
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function
%       prints some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%       do anything but update the default values in FILES_IN, FILES_OUT 
%       and OPT.
%
% _________________________________________________________________________
% OUTPUTS
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
% Keywords : BASC, clustering, stability contrast, 
%            multi-scale stepwise selection
%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_CORES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf_cores'' for more info.')
end

%% Files in
list_fields   = {'stab' , 'part' , 'roi' };
list_defaults = { NaN   , NaN    , NaN   };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Files out
if ~ischar(files_out)&&~iscellstr(files_out)
    error('FILES_OUT should be a cell of strings');    
end

%% Options
list_fields   = { 'name_stab' , 'name_scale' , 'name_part' , 'name_part_roi' , 'cores' , 'flag_verbose' , 'flag_test' };
list_defaults = { 'stab'      , 'scale'      , 'part'      , 'part_roi'      , struct  , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% Setup Cores Option Defaults
cores_opt.thre = 0.5;
cores_opt.conf = 0.05;

% Setup Cores Defaults
opt.cores = psom_struct_defaults(opt.cores,...
            { 'type'     , 'opt'     },...
            { 'highpass' , cores_opt });

if opt.flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Read Inputs
if opt.flag_verbose
        fprintf('Reading the input data...\n');
end

stab = load(files_in.stab, opt.name_stab);
part = load(files_in.part, opt.name_scale, opt.name_part);
roi  = load(files_in.roi, opt.name_part_roi);

% Grab the data
stab        = stab.(opt.name_stab);
scale       = part.(opt.name_scale);
part        = part.(opt.name_part);
part_roi    = roi.(opt.name_part_roi);

% Prepare the outputs
nb_scales   = length(scale);
core_part = zeros(size(part));
core_stab_mat = zeros(size(stab));

%% Find Stable Cores

for sc_id = 1:nb_scales
    % Capture the correct values
    tmp_stab = stab(:, sc_id);
    tmp_part = part(:, sc_id);

    % Make a matrix of the stability vector
    tmp_stab_mat = niak_vec2mat(tmp_stab);
    % Bring the partition into roi space
    vp_opt.match = 'mode';
    tmp_part_roi = niak_stability_vol2part(tmp_part, part_roi, vp_opt);
    clusters = unique(tmp_part_roi);
    nb_vertex = length(tmp_part_roi);
    nb_clusters = length(clusters);
    % Build an empty matrix to store the average stability of regions
    % inside each cluster with the rest of the brain
    core_stab = zeros(nb_clusters, nb_vertex);
    % Build an identical empty matrix for the mask of the stable cores so
    % we can identify overlapping stable cores
    core_mask = zeros(nb_clusters, nb_vertex);
    
    % Loop through the clusters
    for cl_id = 1:nb_clusters
        % Get the current clusters number
        cl_num = clusters(cl_id);
        % Find regions that are in the current cluster
        cl_ind = tmp_part_roi == cl_num;
        cl_part = tmp_part_roi(cl_ind);
        
        % Pull the cluster columns out of the stability matrix
        cl_stab = tmp_stab_mat(:, cl_ind);
        % Build the within cluster stability
        cl_stab_wi = cl_stab(cl_ind, :);
 
        % Switch based on the stable core technique we are using 
        switch opt.cores.type
            case 'highpass'
                % We will threshold the stable cores at the given
                % percentile

                % Average across the rows to get the average within cluster
                % stability for each region in the cluster
                avg_cl_stab_wi = mean(cl_stab_wi, 2);
                % Get the correct percentile of stability within the cluster
                thre = prctile(avg_cl_stab_wi, opt.cores.opt.thre * 100);
                % Take off confidence interval
                thre = thre - opt.cores.opt.conf * thre;

                % Mask the regions in the cluster by the stability threshold
                cl_mask = avg_cl_stab_wi > thre;
                % Apply the mask to the elements
                cl_part = cl_part .* cl_mask;

                % And write the result back into the partition array
                core_stab(cl_id, cl_ind) = cl_part;
                core_mask(cl_id, :) = cl_mask;

            case 'kmeans'
                % We will divide the cluster into three parts and keep the
                % one with the highest average stability
                
                % Average across the rows to get an average of the
                % stability with the cluster of every region on the surface 
                avg_cl_stab = mean(cl_stab, 2);
                k_ind = niak_kmeans_clustering(avg_cl_stab', struct('nb_classes', 3));
                % Find the cluster with the highest average stability
                k_mean = zeros(3,1);
                for i = 1:3
                    k_mean(i,1) = mean(cl_stab(k_ind == i));
                end
                [tmp, k_tar] = max(k_mean);
                % Mask the elements of the surface by the stability
                % threshold of the target cluster
                cl_mask = k_ind==k_tar;
                
                % Mask the stability vector and store it in the partition
                % array to later find the maximium of overlapping clusters
                mask_stab = avg_cl_stab .* cl_mask;
                core_stab(cl_id, :) = mask_stab;
                core_mask(cl_id, :) = cl_mask;
                
            otherwise
                error('Unknown thresholding method in opt.core.type\n');
     
        end
   
    end
    
    % Identify the vertices that belong to several clusters
    overlap = sum(core_mask, 1);
    overlap_vert = overlap > 1;
    % Make a mask of the vertices that belong to only one cluster
    single_vert = overlap == 1;
    % Make a mask of the vertices that belong to no cluster
    no_vert = overlap == 0;
    
    % Generate a temporary partition container
    tmp_part_roi = zeros(size(overlap));
    % Get the clusters for the non-overlapping vertices
    [single_val, tmp_part_roi(single_vert)] = max(core_mask(:, single_vert), [], 1);
    % Get the clusters for the overlapping vertices based on a winner takes
    % all stability ranking
    [overlap_val, tmp_part_roi(overlap_vert)] = max(core_stab(:, overlap_vert), [], 1);
    
    % As a sanity check, see if all values of vertices that belong to no
    % cluster are zero
    if ~all(tmp_part_roi(no_vert)==0)
        error('Something is wrong with the stable core partition.');
    end
    
    % Write the updated partition back
    core_part(:, sc_id) = niak_part2vol(tmp_part_roi, part_roi);
    % Update the stability matrix
    dropped_ind = tmp_part_roi == 0;
    tmp_stab_mat(dropped_ind, dropped_ind) = 0;
    % Write the updated partition back
    core_stab_mat(:, sc_id) = niak_mat2vec(tmp_stab_mat);
    
end

% Store the new outputs in the structure
data.scale  = scale;
data.stab   = core_stab_mat;
data.part   = core_part;

%% Save outputs
if opt.flag_verbose
    fprintf('Saving outputs in a mat file at %s\n',files_out);
end
save(files_out,'-struct','data');
