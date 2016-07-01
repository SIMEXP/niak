function [model, stats, opt] = niak_cramer(model_mat, opt)
% SYNTAX:
% [MODEL, STATS, OPT] = NIAK_CRAMER(MODEL, OPT).
% ______________________________________________________________________________
% INPUTS:
%
%   MODEL_MAT
%       (array) model matrix
%
%   OPT
%       (structure) with the following fields
%
%       PART
%           (array, integer) partition of subjects in MODEL_MAT into groups
%
%       GROUP_COL_ID
%           (integer) the ID of thecolumn in MODEL_MAT that designates the group
%           membership of subjects
% 
%_______________________________________________________________________________
% OUTPUTS:
%
%
%_______________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_SUBTYPE
%
% ______________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%               Centre de recherche de l'institut de Geriatrie de Montreal
%               Departement d'informatique et de recherche operationnelle
%               Universite de Montreal, 2012-2016
%               Montreal Neurological Institute, 2016
% Maintainer : sebastian.urchs@mail.mcgill.ca
% See licensing information in the code.
% Keywords : general linear model
%% Check inputs
if ~exist('model_mat','var')||~exist('opt','var')
    error('niak:brick','syntax: [MODEL, STATS, OPT] = NIAK_CRAMER(MODEL, OPT).\n Type ''help niak_cramer'' for more info.')
end

%% Check the options
opt = psom_struct_defaults(opt,...
           { 'part' , 'group_col_id' },...
           { NaN    , NaN            });

%% Build the model from user's csv and input column
col = model_mat(:,opt.group_col_id);
% Build a mask for NaN values in model and mask out subjects with NaNs
[x, y] = find(~isnan(col));
sub_id = unique(x);
[a, b] = find(isnan(col));  % the subjects that were dropped due to having NaNs
sub_drop = unique(a);
partition = opt.part(sub_id,:); 
% Save the model
model.subject_id = sub_id;
model.partition = partition;
model.group = col;
model.subject_drop = sub_drop;

%% Build the contingency table 
list_gg = unique(col)'; % find unique values from input column to differentiate the groups
name_clus = cell(length(list_gg), 1);
name_grp = cell(length(list_gg),1);
contab = cell(length(list_gg), opt.nb_subtype);

for cc = 1:opt.nb_subtype % for each cluster
    for gg = 1:length(list_gg) % for each group
        mask_sub = partition(:)==cc; % build a mask to select subjects within one cluster 
        sub_col = col(mask_sub); % subjects within one cluster
        nn = numel(find(sub_col(:)==list_gg(gg))); % number of subjects for a single group that is in the cluster
        contab(gg,cc) = nn;
        name_clus{cc} = ['sub' num2str(cc)];
        name_grp{gg} = ['group' num2str(list_gg(gg))];
    end
end
stats = struct;
stats.contab.table = contab;
stats.contab.labels_x = name_grp;
stats.contab.labels_y = name_clus;

%% Chi-square test of the contigency table
stats.chi2.expected = sum(contab,2)*sum(contab)/sum(contab(:)); % compute expected frequencies
stats.chi2.X2 = (contab-stats.chi2.expected).^2./stats.chi2.expected; % compute chi-square statistic
stats.chi2.X2 = sum(stats.chi2.X2(:)); 
stats.chi2.df = prod(size(contab)-[1 1]);
stats.chi2.p = 1-chi2cdf(stats.chi2.X2,stats.chi2.df); % determine p value
stats.chi2.h = double(stats.chi2.p<=0.05);

%% Cramer's V

[n_row n_col] = size(contab); % figure out size of contigency table
col_sum = sum(contab); % sum of columns
row_sum = sum(contab,2); % sum of rows
n_sum = sum(sum(contab)); % sum of everything
kk = min(n_row,n_col); 
stats.cramerv = sqrt(stats.chi2.X2/(n_sum*(kk-1))); % calculate cramer's v