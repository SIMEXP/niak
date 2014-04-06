function [files_in,files_out,opt] = niak_brick_stability_surf_msteps_part(files_in, files_out, opt)
% Generate Partitions based on mstep scale selections
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_MSTEPS_PART(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   ROI
%       (string) path to the file that contains the data partitioned into
%       atoms. Contains a variable with name OPT.NAME_PART_ROI that
%       contains the partition vector assigning the atoms.
%
%   MSTEPS
%       (string) path to the file that contains the results of the msteps
%       process. Must contain two variables with names OPT.SCALES_FINAL and
%       OPT.NAME_SCALES_MAX.
%
%   CONS
%       (string) path to the file that contains the results of the
%       consensus clustering step. Must contain a variable with name
%       OPT.NAME_HIER.
%
% FILES_OUT
%   (string) path to structure with the following fields :
%
% OPT
%   (structure) with the following fields.
%
%   NAME_PART_ROI
%       (string, default: 'part_roi') the name of the variable in
%       FILES_IN.ROI that contains the partition into rois.
%
%   NAME_SCALES_FINAL
%       (string, default: 'scales_final') name of variable in
%       FILES_IN.MSTEPS that contains an array of dimension 2 by K where K
%       is the number of optimal scales selected by the msteps step. The
%       first column contains the optimal target cluster scales and
%       the second column contains the corresponding optimal stochastic
%       cluster scales for replication
%
%   NAME_SCALES_MAX
%       (string, default: 'scales_max') name of variable in FILES_IN.MSTEPS
%       that contains an array of dimension 2 by N where N is the number of
%       all scales that were investigated by msteps. The variable
%       OPT.NAME_SCALES_FINAL is a subset of this array. This array is used
%       to index the correct hierarchy.
%
%   NAME_HIER
%       (string, default: 'hier')
%
%   NAME_STAB
%       (string, default: 'stab')
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
%'part', 'scale', 'scales_clust','part_roi', 'hier', 'stab'
% OUTPUT VARIABLES:
%   PART
%       (array) the target partitions for the desired scales in
%       FILES_IN.MSTEPS OPT.NAME_SCALES_FINAL. The output array will have
%       dimensions V by K where V is the number of verteces on the surface
%       and K is the number of scales.
%
%   SCALE
%       (vector) the vector with the stochastic scales K used for
%       replication of the target clusters in SCALE_TARGET
%
%   SCALE_TARGET
%       (vector) the vector with the scales of the target clusters.
%
%   PART_ROI
%       (array)
%
%   HIER
%       (cell array) containing the hierarchy corresponding
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MSTEPS
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
% Keywords : BASC, clustering, stability contrast, multi-scale stepwise selection
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

%% Seting up default arguments
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_MSTEPS_PART(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf_msteps_part'' for more info.')
end

%% Files in
list_fields   = {'msteps' , 'roi' , 'cons' };
list_defaults = {NaN      , NaN   , NaN    };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Files out
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

%% Options
list_fields   = { 'name_part_roi' , 'name_scales_final' , 'name_scales_max' , 'name_hier' , 'name_stab' , 'flag_verbose' , 'flag_test' };
list_defaults = { 'part_roi'      , 'scales_final'      , 'scales_max'      , 'hier'      , 'stab'      , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if opt.flag_test
    return
end

%% Reading all inputs
% TODO:
% - add opt.name_scales_max to the checks!
%
% Checking the contents of the files, one input per file!
missing = false(3,1);
fields = {opt.name_hier, opt.name_part_roi, opt.name_scales_final};
inputs = {files_in.cons, files_in.roi, files_in.msteps};

cont_cons = whos('-file',files_in.cons);
if ~ismember(opt.name_hier, {cont_cons.name})
    missing(1) = true;
end

roi_cons = whos('-file',files_in.roi);
if ~ismember(opt.name_part_roi, {roi_cons.name})
    missing(2) = true;
end

mstep_cons = whos('-file',files_in.msteps);
if ~ismember(opt.name_scales_final, {mstep_cons.name})
    missing(3) = false;
end

if any(missing)
    error('I couln''t find %s in %s.\n', fields(missing), inputs(missing));
else
    % Loading inputs
    cons = load(files_in.cons, opt.name_hier);
    hier = cons.(opt.name_hier);
    
    roi = load(files_in.roi, opt.name_part_roi);
    part_roi = roi.(opt.name_part_roi);
    
    msteps = load(files_in.msteps, opt.name_scales_final,...
                  opt.name_scales_max, opt.name_stab);
    scales_final = msteps.(opt.name_scales_final);
    scales_max = msteps.(opt.name_scales_max);
end

%% Generating the mstep based partition
num_scales = size(scales_final, 1);
% Get the optimal scales for the final clusters
scales_target = scales_final(:, 2);
% Get the corresponding optimal scales of the stochastic clusters that were
% used to generate the stability matrices
scales_stoc = scales_final(:, 1);
% Get the index of the stochastic scales so we know which hierarchy to pick up
k_ind = arrayfun(@(x) find(scales_max(:, 1) == x,1,'first'), scales_stoc);

V = size(part_roi, 1);
part = zeros(V, num_scales);

for sc_id = 1:num_scales
    stoc_ind = k_ind(sc_id);
    sc_clust = scales_target(sc_id);
    sc_hier = hier{stoc_ind};

    opt_t.thresh = sc_clust;

    tmp_part = niak_threshold_hierarchy(sc_hier,opt_t);
    % Bring partition into vertex space
    part(:, sc_id) = niak_part2vol(tmp_part, part_roi);
end

% Truncate the stability matrix to the selected stochastic scales
stab = stab(:, k_ind);
hier = hier(k_ind);

%% Save outputs
if opt.flag_verbose
    fprintf('Saving outputs in a mat file at %s\n',files_out);
end
scale = scales_stoc;
save(files_out, 'part', 'scale', 'scales_target', 'part_roi', 'hier', 'stab');    