function [files_in,files_out,opt] = niak_brick_stability_surf_contrast(files_in,files_out,opt)
% Build an estimate of the (vertex-based) stability contrast at multiple scales
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_CONTRAST(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN.STAB
%   (string) full path to a .mat file with the following fields:
%
%   STAB
%      (structure) with fields corresponding to stability matrices for
%      different scales. Each field consists of an array S with
%      cluster by vertex vertex-stability scores such that S(c,v)
%      corresponds to the stability of the vertex v in cluster c.
%
%   SCALE_TAR
%       (array) list of the target scales used to generate the stability
%       maps
%
%   SCALE_NAMES
%
%       (cell) the names of the field names in FILES_IN.STAB. SCALE_NAMES{i}
%       corresponds to the FILES_IN.STAB field name with scale SCALES(i).
%
% FILES_IN.PART
%   (string) full path to a .mat file containing the field
%
%   PART
%      (array) the target clustering as a vector v. Entry v(i,1) corresponds
%      to the cluster assignment of vertex i.
%
% FILES_OUT
%   (string) a mat file with two variables SCALES (identical to OPT.SCALES) 
%   and SIL (the stability contrast). 
%
% OPT
%   (structure) with the following fields:
%
%   FLAG_TEST
%      (boolean, default false) if the flag is true, the brick does not do anything
%      but updating the values of FILES_IN, FILES_OUT and OPT.
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
% Keywords : 

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

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SURF_CONTRAST(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_surf_contrast'' for more info.')
end

%% FILES_IN
list_fields   = { 'stab' , 'part' };
list_defaults = { NaN    , NaN    };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

%% Options
list_fields   = { 'flag_test' , 'flag_verbose' };
list_defaults = { false       , 'false'        };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the file container
part_file = load(files_in.part);
stab_file = load(files_in.stab);

nb_scales = length(stab_file.scale_tar);
sil = zeros(nb_scales,1);

% Prepare the output
out.scale_tar = zeros(numel(stab_file.scale_tar),1);
out.scale_names = stab_file.scale_names;

if opt.flag_verbose
    start_glob = tic;
end

% Sanity check for the scales
for sc_ind = 1:nb_scales
    scale = stab_file.scale_tar(sc_ind);
    scale_name = stab_file.scale_names{sc_ind};
    [stab_scale, N] = size(stab_file.stab.(scale_name));
    part_scale = max(part_file.part(:, sc_ind));
    if scale ~= stab_scale
        error(['stab.scale(%d) = %d but stab.stab.%s has scale %d and '...
               'part.part(:, %d) has scale %d\n'],...
               sc_ind, scale, scale_name, stab_scale, part_scale);
    end
end
% Sanity check for the order of the scales
[scale_ord, scale_ind] = sort(out.scale_tar);
if scale_ord ~= out.scale_tar
    warning('The input ordering of the scales does not seem to be sorted\n');
end
out.scale_tar = stab_file.scale_tar;
fprintf('All scales and scale_names and partitions make sense. Carry on.\n');

for num_sc = 1:nb_scales
    % Get the stability field name
    scale_name = stab_file.scale_names{num_sc};
    part = part_file.part(:, num_sc);
    stab = stab_file.stab.(scale_name);
    [scale, N] = size(stab);
    
    if opt.flag_verbose
        fprintf('Computing stability contrast for scale %d (%s)\n',...
                scale,scale_name);
        start_loc = tic;
    end
    
    % Prepare temporary storage
    intra_surf = zeros(length(part),1);
    inter_surf = zeros(length(part),1);
    sil_surf = zeros(length(part),1);
    mask = part > 0;
    
    %% Loop over clusters
    for num_c = 1:scale
        % get the stability of each vertex with the cluster
        intra = stab(num_c,:);       
        % get the maximum stability for each vertex with all the other
        % clusters
        inter = max(stab((1:scale)~=num_c,:),[],1);
        intra_surf(part==num_c) = intra(part==num_c);
        fprintf('    surf: %d, inter: %d, part_numc: %d, num_c: %d\n',...
                size(inter_surf),size(inter),size(part==num_c),num_c);
        inter_surf(part==num_c) = inter(part==num_c);        
    end
    % Get silhouette
    sil_surf = intra_surf - inter_surf;
    sil(num_sc) = mean(sil_surf(mask));
    % Store the results
    out.stab_surf.(scale_name).inter = inter_surf;
    out.stab_surf.(scale_name).intra = intra_surf;    
    out.sil_surf.(scale_name) = sil_surf;
    if opt.flag_verbose
        elapsed_loc = toc(start_loc);
        fprintf('Done computing stability contrast for scale %d (%s)\n    This took %d seconds\n',scale, scale_name, elapsed_loc);
    end
end

% Store the silhouette for the scales
out.sil = sil;
if opt.flag_verbose
    fprintf('Done with stability contrast computation.\n');
end

% Save the silhouette
save(files_out,'-struct','out');

if opt.flag_verbose
    elapsed_glob = toc(start_glob);
    fprintf('In total this took %d seconds. Find the results at:\n    %s',elapsed_glob,files_out);
end
