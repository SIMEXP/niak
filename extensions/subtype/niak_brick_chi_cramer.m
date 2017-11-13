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
%   SUBTYPE
%       (string, default 'gb_niak_omitted) path to the subtype maps for 
%       a given network. The following field is expected to be inside the 
%       structure inside the .mat file.
%       PART
%           (vector) PART(I) = J if the object I is in the class J.
%           See also: niak_threshold_hierarchy
%       Note: Must be supplied when files_in.weights is omitted
%
%   WEIGHTS
%       (string, default 'gb_niak_omitted) path to the subtype_weights.mat 
%       file containing subtype weights for each subject, generated from 
%       NIAK_BRICK_SUBTYPE_WEIGHT
%       Note: Must be supplied when files_in.subtype is omitted and when
%       OPT.FLAG_WEIGHTS is true
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
%   PIE
%       (string, default 'gb_niak_omitted') path to folder containing pie
%       charts output
%
% OPT
%   (structure) with the following fields:
%
%   FLAG_WEIGHTS
%       (boolean, default false) if the flag is true, the brick will
%       calculate statistics based on the weights from FILES_IN.WEIGHTS
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   GROUP_COL_ID
%       (string, default 'Group') the column name in the model csv that 
%       separates subjects into groups to compare chi-squared and 
%       Cramer's V stats
%
%   NETWORK 
%       (integer, default 'gb_niak_omitted') the number of the desired
%       network; must be supplied when OPT.FLAG_WEIGHTS is true
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
           { 'model', 'subtype'        , 'weights'         },...
           { NaN    , 'gb_niak_omitted', 'gb_niak_omitted' });
if strcmp(files_in.subtype, 'gb_niak_omitted') && strcmp(files_in.weights, 'gb_niak_omitted')
    error('Either FILES_IN.SUBTYPE or FILES_IN.WEIGHTS must be supplied')
end

% Options
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'group_col_id' , 'network'        , 'flag_weights', 'flag_verbose' , 'flag_test' },...
      { ''           , 'Group'        , 'gb_niak_omitted', false         , true           , false       });
if strcmp(files_in.weights, 'gb_niak_omitted') && opt.flag_weights 
    error('When OPT.FLAG_WEIGHTS is true, FILES_IN.WEIGHTS must be specified')
end
if strcmp(opt.network, 'gb_niak_omitted') && opt.flag_weights
    error('When OPT.FLAG_WEIGHTS is true, OPT.NETWORK must be specified')
end

% Output
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'stats'                      , 'contab'                                },...
                { [path_out 'group_stats.mat'] , [path_out 'chi2_contingency_table.csv'] });
else
    files_out = psom_struct_defaults(files_out,...
                { 'stats'           , 'contab'         , 'pie'             },...
                { 'gb_niak_omitted' , 'gb_niak_omitted', 'gb_niak_omitted' });
end

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Load the model
[tab,sub_id,labels_y] = niak_read_csv(files_in.model);

%% Load the subtypes or the weights (depending on opt.flag_weights) & get the partition
if opt.flag_weights
    tmp_weights = load(files_in.weights);
    weights = tmp_weights.weight_mat;
    list_subject = tmp_weights.list_subject;
    nn = opt.network;
    [~, maxind] = max(weights(:,:,nn)'); % determine highest subtype weight for each subject
    part = maxind'; % generate partition based on weights
else
    subtype = load(files_in.subtype);
    part = subtype.part; % load partition
    list_subject = subtype.list_subject; % Load list of subjects
end

%% Build the model from user's csv and input column
col_ind = find(strcmp(opt.group_col_id,labels_y));
if all(col_ind == 0)
    error('Group column %s has not been found in %s',opt.group_col_id,files_in.model)
end
col = tab(:,col_ind);

% Re-order data and filter out subjects with no imaging data
col_norm = zeros(length(list_subject),size(col,2));
for ss = 1:length(list_subject)
    ind = find(strcmp(sub_id,list_subject{ss}));
    if isempty(ind)
        error(sprintf('I could not find subject %s in the model',list_subject{ss}));
    end
    col_norm(ss,:) = col(ind,:);
end
col = col_norm;

% Build a mask for NaN values in model and mask out subjects with NaNs
[x, y] = find(~isnan(col)); % find subjects that have non-NaN values
sub_ret = unique(x);
[a, b] = find(isnan(col));  % the subjects that were dropped due to having NaNs
sub_drop = unique(a);
partition = part(sub_ret,:); % mask partition on only subjects with non-NaN values

% Save the model
model.subject_retained = list_subject(sub_ret,:);
model.partition = partition;
model.group_name = opt.group_col_id;
model.group = col;
model.subject_dropped = list_subject(sub_drop,:);

%% Build the contingency table

name_clus = {};
name_grp = {};

col_val = unique(col)'; % find unique values from input column to differentiate the groups
[i, j] = find(~isnan(col_val)); % find the non-NaN values
list_mask = unique(j); % find unique values from non-NaN values
% Retain only non-NaN in data and differentiating variables
list_gg = col_val(list_mask); 
ret_col = col(sub_ret);

nb_subtype = max(part); % get number of subtypes from partition
for cc = 1:nb_subtype % for each cluster
    for gg = 1:length(list_gg) % for each group
        mask_sub = partition(:)==cc; % build a mask to select subjects within one cluster
        sub_col = ret_col(mask_sub); % subjects within one cluster
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

%% Work around the incompatibilities between Matlab and Octave 
is_octave = logical(exist('OCTAVE_VERSION', 'builtin') ~= 0);

% Pie chart visualization
for pp = 1:n_row
    fh = figure('Visible', 'off');
    pc_val = contab(pp,:);
    pc = pie(pc_val);
    textc = findobj(pc,'Type','text');
    percval = get(textc,'String');
    prune_clus = name_clus(pc_val ~= 0);
    prune_val = pc_val(pc_val ~= 0);
    if length(prune_clus) == 1 % in the case that one subtype makes up 100% of one group
        if is_octave
            percval{1} = '100%';
            labels = {sprintf('%s: %s',prune_clus{1},percval{1})};
        else
            labels = {sprintf('%s: %s',prune_clus{1},percval)};
        end
    else
        labels = strcat(prune_clus, {': '},percval');
    end
    pc = pie(prune_val,labels);
    c_title = ['Group' num2str(list_gg(pp))];
    title(c_title);
    if isempty(opt.folder_out);
        pie_name = sprintf('pie_chart_%d.pdf', pp);
        pc_out = [files_out.pie filesep pie_name];
        print(fh, pc_out, '-dpdf', '-r300');
    else
        files_out.pie = make_paths(opt.folder_out, 'pie_chart_%d.pdf', 1:n_row);
        print(fh, files_out.pie{pp}, '-dpdf', '-r300');
    end
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

