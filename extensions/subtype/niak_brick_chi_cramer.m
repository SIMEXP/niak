function [files_in,files_out,opt] = niak_brick_chi_cramer(files_in,files_out,opt)
% Builds contingency table and calculates Chi-2 and Cramer's V statistics 
% for subtype pipeline
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CHI_CRAMER(FILES_IN,FILES_OUT,OPT)
% _________________________________________________________________________
%
% INPUTS:
%
% FILES_IN 
%   (structure) with the following fields:
%
%   MODEL
%       (string) a .csv files coding for the 
%       pheno data. Is expected to have a header and a first column 
%       specifying the case IDs/names corresponding to the data in 
%       FILES_IN.DATA
%
%   SUBTYPE.<NETWORK>
%       (string) path to the subtype maps for that network. The following
%       field is expected to be inside the structure inside the .mat file.
%
%       PART
%           (vector) PART(I) = J if the object I is in the class J.
%           See also: niak_threshold_hierarchy
%
% FILES_OUT
%   (structure) with the following fields:
%
%   STATS
%       (string, default 'group_stats.mat') path to the .mat file output
%       containing chi-squared and Cramer's V stats
%
%   CONTAB
%       (string, default 'chi2_contingency_table.csv') path to .csv file
%       output containing the contingency table
%
% OPT
%   (structure) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   GROUP_COL_ID
%       (string, default 'Group') the column name in the model csv that separates 
%       subjects into groups to compare chi-squared and Cramer's V stats
%
%   NB_SUBTYPE
%       (integer) the number of desired subtypes
% _________________________________________________________________________
% OUTPUTS:
%
%  GROUP_STATS.MAT
%       (.mat) contains the following variables:
%
%       MODEL
%           (structure) contains the fields: 
%               SUBJECT_ID: list of subject IDs
%               PARTITION: the subtypes in which subjects were clustered
%                   from files_in.subtype
%               GROUP: the grouping variable from files_in.model
%               SUBJECT_DROP: list of subjects that had to be dropped due
%                   to presence of NaN values
%       STATS
%           (structure) with the following fields:
%               CHI2 (structure): 
%                   EXPECTED: contains expected cell frequencies
%                   X2: computed CHI2 stat
%                   DF: degrees of freedom
%                   P: p-value
%                   H: significance of hypothesis testing (0 not
%                       significant, 1 significant)
%               CRAMERV: computed Cramer's V stat
%
%   CHI2_CONTINGENCY_TABLE.CSV
%       (.csv) containing the calculated contingency table
%
%   PIE_CHART_(n).PDF
%       pie charts illustrating the proportions of data in n groups in 
%       each subtype
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CHI_CRAMER(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_chi_cramer'' for more info.')
end

% Input
files_in = psom_struct_defaults(files_in,...
           { 'model', 'subtype' },...
           { NaN    , NaN       });

% Options
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'nb_subtype',  'group_col_id' ,  'flag_verbose' , 'flag_test' },...
      { ''           , NaN         ,  'Group'        ,  true           , false       });

% Output
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'stats'                      , 'contab'                                },...
                { [path_out 'group_stats.mat'] , [path_out 'chi2_contingency_table.csv'] });
else
    files_out = psom_struct_defaults(files_out,...
                { 'stats'           , 'contab'                     },...
                { 'group_stats.mat' , 'chi2_contingency_table.csv' });
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Load the model
[tab,sub_id,labels_y] = niak_read_csv(files_in.model);

%% Load the subtypes
subtype = load(files_in.subtype);
part = subtype.part;

%% Build the model from user's csv and input column
col_ind = find(strcmp(opt.group_col_id,labels_y));
if all(col_ind == 0)
    error('Group column %s has not been found in %s',opt.group_col_id,files_in.model)
end
col = tab(:,col_ind);
% Build a mask for NaN values in model and mask out subjects with NaNs
[x, y] = find(~isnan(col));
sub_id = unique(x);
[a, b] = find(isnan(col));  % the subjects that were dropped due to having NaNs
sub_drop = unique(a);
partition = part(sub_id,:);
% Save the model
model.subject_id = sub_id;
model.partition = partition;
model.group = col;
model.subject_drop = sub_drop;

%% Build the contingency table

name_clus = {};
name_grp = {};
list_gg = unique(col)'; % find unique values from input column to differentiate the groups
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

% Write the table into a csv
opt_ct.labels_x = name_grp;
opt_ct.labels_y = name_clus;
opt_ct.precision = 2;
niak_write_csv(files_out.contab, contab, opt_ct)

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

% Pie chart visualization
files_out.pie = make_paths(opt.folder_out, 'pie_chart_%d.pdf', 1:n_row);

for pp = 1:n_row
    fh = figure('Visible', 'off');
    pc_val = contab(pp,:);
    pc = pie(pc_val);
    textc = findobj(pc,'Type','text');
    percval = get(textc,'String');
    prune_clus = name_clus(pc_val ~= 0);
    prune_val = pc_val(pc_val ~= 0);
    if length(prune_clus) == 1
        labels = {sprintf('%s: %s',prune_clus{1},percval)};
    else
        labels = strcat(prune_clus, {': '},percval');
    end
    pc = pie(prune_val,labels);
    c_title = ['Group' num2str(list_gg(pp))];
    title(c_title);
    print(fh, files_out.pie{pp}, '-dpdf', '-r300');
end

%% Save the model and stats
save(files_out.stats,'model','stats')
    
end

function path_array = make_paths(out_path, template, scales)
    % Get the number of networks
    n_networks = length(scales);
    path_array = cell(n_networks, 1);
    for sc_id = 1:n_networks
        sc = scales(sc_id);
        path = fullfile(out_path, sprintf(template, sc));
        path_array{sc_id, 1} = path;
    end
return
end

