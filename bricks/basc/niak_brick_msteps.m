function [files_in,files_out,opt] = niak_brick_msteps(files_in,files_out,opt)
% Multiscale stepwise selection of clustering parameters
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MSTEPS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (string or cell of strings) FILES_IN or FILES_IN{N} is a .mat file
%   with two variables SIL and NB_CLASSES. SIL is a matrix S*K, of stability
%   contrast measure. Measures in column K of SIL have been derived with
%   NB_CLASSES(K) clusters. If FILES_IN is a cell of string, there should
%   also be a variable NB_CLASSES_IND indicating the number of individual
%   clusters used for the group analysis. The row S of SIL is the stability
%   contrast with S final clusters.
%
% FILES_OUT
%   (structure) with the following fields :
%
%   MSTEPS
%       (string) The name of a .mat file with the following variables :
%
%       SCALES
%           (array) SCALES(R,:) is the Rth "optimal" scale selected (SCALES_R 
%           is one of the elements in LIST_SCALES).
%
%       SCORE
%           (scalar) SCORE is the percentage of weighted sum-of-squares 
%           explained by the selected scales.
%
%       SCALES_FINAL
%           (array) SCALES_FINAL(R,:) is the list of selected scale parameters
%           in the following order : individual, group (if applicable), final
%
%   TABLE
%       (string) The name of a .csv file with the list of selected scale
%       parameters (individual, group - if applicable, final).
%
% OPT
%   (structure) with the following fields.
%
%   PARAM
%       (scalar, default 0.05) if PARAM is comprised between 0 and 1, it is
%       the percentage of residual squares unexplained by the model.
%       If PARAM is larger than 1, it is assumed to be an integer, which is 
%       used directly to set the number of components of the model.
%
%   NEIGH
%       (vector, default [0.7 1.3]) defines the local neighbourhood of
%       a number of clusters. If NEIGH has more than two elements, the
%       first and last element will be used to define the neighbourhood.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
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
% SEE ALSO:
% NIAK_MSTEPS
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010-2011
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MSTEPS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_msteps'' for more info.')
end

%% Files in
if ~ischar(files_in)&&~iscellstr(files_in)
    error('FILES_IN should be a cell of strings');    
end

%% Files out
list_fields   = {'msteps' , 'table' };
list_defaults = {NaN      , NaN     };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
list_fields   = {'rand_seed' , 'param' , 'neigh'   , 'flag_verbose' , 'flag_test' };
list_defaults = {[]          , 0.05    , [0.7,1.3] , true           ,false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if opt.flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Reading all summary measures
if ischar(files_in)

    % There's a single mat file. This is an individual analysis.
    if opt.flag_verbose
        fprintf('Reading the stability measure...\n');
    end
    data = load(files_in);
    if any(abs(data.sil(:)))
        [sil_max,scales_max] = niak_build_max_sil(data.sil,data.nb_classes(:),opt.neigh,2);
        opt_msteps.weights = sil_max;
        opt_msteps.param = opt.param;
        opt_msteps.scales_max = scales_max;
        [scales,score,scales_final] = niak_msteps(data.stab,data.nb_classes(:),opt_msteps);
    else
        scales_final = [NaN NaN];
        scales = NaN;
        scales_max = [NaN NaN];
        score = NaN;
        warning('All silhouette measures are equal to zero. I am assuming that the data for this subject was not usable')
    end

else

    % There are multiple mat files. This is a group analysis.
    if opt.flag_verbose
        fprintf('Reading the stability contrast measure...\n');
    end
    nb_classes = [];               % The array of scales parameters will be generated by concatenation across FILES_IN{N}
    sil_all    = [];               % The array of stability contrast will be generated by concatenation across FILES_IN{N}
    N          = length(files_in); % The number of input files    
    group      = cell([N 1]);      % The group-level scales    
    for num_n = 1:N
        if opt.flag_verbose
            fprintf('    %s\n',files_in{num_n});
        end
        data = load(files_in{num_n},'sil','nb_classes','nb_classes_ind');
        ind = data.nb_classes_ind;
        group{num_n} = data.nb_classes;
        sil_all = [sil_all data.sil];
        nb_classes = [nb_classes ; [repmat(ind,[length(group{num_n}) 1]) group{num_n}(:)]];
    end
    nb_classes(nb_classes>=size(sil_all,1)) = size(sil_all,1);
    [nb_classes,red] = unique(nb_classes,'rows');
    sil_all = sil_all(:,red);
    [sil_max,scales_max] = niak_build_max_sil(sil_all,nb_classes,opt.neigh,2);
    [tmp,list_rows] = ismember(scales_max(:,1:end-1),nb_classes,'rows');
    [list_rows,order] = sort(list_rows);
    if opt.flag_verbose
        fprintf('Reading the stability matrices...\n');
    end
    ind_pos = 0;
    num_pos = 1;
    for num_n = 1:N
        if opt.flag_verbose
            fprintf('    %s\n',files_in{num_n});
        end
        while (num_pos<=length(list_rows))&&(list_rows(num_pos)-ind_pos<=length(group{num_n}))
            data = load(files_in{num_n},'stab');
            if num_pos == 1
                stab_all = zeros([size(data.stab,1) length(list_rows)]);
            end
            stab_all(:,order(num_pos)) = data.stab(:,list_rows(num_pos)-ind_pos);
            num_pos = num_pos+1;
        end
        ind_pos = ind_pos+length(group{num_n});
    end
    
    opt_msteps.weights = sil_max;
    opt_msteps.param = opt.param;
    [scales,score] = niak_msteps(stab_all,scales_max(:,end-1)',opt_msteps);
    scales = sort(scales);
    [tmp,list_scales] = ismember(scales,scales_max(:,end-1));
    scales_final = scales_max(list_scales,:);

end

%% Save outputs
if opt.flag_verbose
    fprintf('Saving outputs in a mat file\n');
end
save(files_out.msteps,'scales','scales_max','score','scales_final');

if opt.flag_verbose
    fprintf('Saving a table of selected scale parameters\n');
end

lab_x = {};
if ischar(files_in)
    lab_y = {'K','S'};
else
    lab_y = {'K','L','S'};
end
opt_tab.labels_x = lab_x;
opt_tab.labels_y = lab_y;
niak_write_csv(files_out.table,scales_final,opt_tab);
