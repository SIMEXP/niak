function [files_in,files_out,opt] = niak_brick_subtyping(files_in,files_out,opt)
% Build subtypes
% 
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT)
% _________________________________________________________________________
% 
% INPUTS:
% 
% FILES_IN 
%       (structure) with the following fields:
%
%   DATA 
%       (string) path to a .mat file containing an array (#subjects x
%       #voxels OR vertices OR regions) generated from subtype_preprocessing
%
%   HIER
%       (string) path to a .mat file containing a variable HIER which is a
%       2D array defining a hierarchy on a similarity matrix
%
%   MASK
%       (3D volume, default all voxels) a binary mask of the voxels that 
%       are included in the time*space array
%
%   MODEL
%       (string, optional, default 'gb_niak_omitted') the name of a csv file
%       containing information and variables about subjects 
% 
% FILES_OUT 
%       (string) path for results
% 
% OPT 
%       (structure) with the following fields:
%
%   NB_SUBTYPE
%       (integer) the number of desired subtypes
%
%   SUB_MAP_TYPE 
%       (string, default 'mean') how the subtypes are represented in the
%       volumes
%       (options: 'mean' or 'median')
%
%   NB_COL_CSV
%       (integer, optional, default 'gb_niak_omitted') the column number
%       (excluding column A for subject IDs) in the model csv that separates 
%       subjects into groups to compare chi-squared and Cramer's V stats
%
%   FLAG_STATS
%       (boolean, optional, default 0) if the flag is 1 (true), the brick
%       will calculate Cramer's V and chi-squared statistics for groups
%       specified in files_in.model
%
%   FLAG_VERBOSE
%       (boolean, optional, default true) turn on/off the verbose.
%
%   FLAG_TEST
%       (boolean, optional, default false) if the flag is true, the brick does not do 
%       anything but updating the values of FILES_IN, FILES_OUT and OPT.
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.


%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtyping'' for more info.')
end

% Input
if ~isstruct(files_in)
    error('FILES_IN should be a structure with the required subfields DATA, HIER, and MASK');
end
if isfield(opt,'flag_stats') && opt.flag_stats == 1 && ~isfield(files_in,'model')
    error('When OPT.FLAG_STATS is true, FILES_IN.MODEL should be a string');
end
if isfield(files_in,'model') && ~ischar(files_in.model)
    error('FILES_IN.MODEL should be a string');
end
list_fields   = { 'data' , 'hier' , 'mask', 'model' };
list_defaults = { NaN    , NaN    , NaN   , 'gb_niak_omitted' }; 
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

% Output
if ~ischar(files_out)
    error('FILES_OUT should be a string');
end
if exist('files_out','var')
    psom_mkdir(files_out);
end

% Options
if ~exist('opt','var')||isempty(opt)
    error('OPT should be a structure where the subfield NB_SUBTYPE must be specified with an integer');
end
if ~isstruct(opt)
    error('OPT should be a structure where the subfield NB_SUBTYPE must be specified with an integer');
end
if isfield(opt,'flag_stats') && opt.flag_stats == 1 && ~isfield(opt,'nb_col_csv')
    error('When OPT.FLAG_STATS is true, OPT.NB_COL_CSV must be specified with an integer');
end
if isfield(opt,'nb_col_csv') && ~isnumeric(opt.nb_col_csv)
    error('OPT.NB_COL_CSV should be an integer');
end
list_fields   = { 'nb_subtype', 'sub_map_type', 'nb_col_csv'     , 'flag_stats', 'flag_verbose' , 'flag_test' }; 
list_defaults = { NaN         , 'mean'        , 'gb_niak_omitted', 0           , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Load the data
data = load(files_in.data);

% Load the hierarchy
hier = load(files_in.hier);
hier = hier.hier;

% Order the subjects
order = niak_hier2order(hier);

% Read the mask
[hdr,mask] = niak_read_vol(files_in.mask);

%% Build the clusters by thresholding the hiearchy by the number of subtypes
part = niak_threshold_hierarchy(hier,struct('thresh',opt.nb_subtype));

%% Build subtype maps

% Generating and writing the mean subtype maps in a single volume
if strcmp(opt.sub_map_type, 'mean')
    sub.mean = zeros(max(part),size(data.data,2));
    for ss = 1:max(part)
        sub.mean(ss,:) = mean(data.data(part==ss,:),1);
    end
    vol_mean_sub = niak_tseries2vol(sub.mean,mask);
    file_name = 'mean_subtype.nii.gz';
    hdr.file_name = fullfile(files_out, file_name);
    niak_write_vol(hdr,vol_mean_sub);
end
    
% Generating and writing the median subtype maps in a single volume
if strcmp(opt.sub_map_type, 'median')
    sub.median = zeros(max(part),size(data.data,2));
    for ss = 1:max(part)
        sub.median(ss,:) = median(data.data(part==ss,:),1);
    end
    vol_median_sub = niak_tseries2vol(sub.median,mask);
    file_name = 'median_subtype.nii.gz';
    hdr.file_name = fullfile(files_out, file_name);
    niak_write_vol(hdr,vol_median_sub);
end
    
% Generating and writing t-test maps of the difference between subtype average 
% and grand average in a single volume
for ss = 1:max(part)
    sub.ttest(ss,:) = niak_ttest(data.data(part==ss,:),data.data(part~=ss,:),true);
end
vol_ttest_sub = niak_tseries2vol(sub.ttest,mask);
file_name = 'ttest_subtype.nii.gz';
hdr.file_name = fullfile(files_out, file_name);
niak_write_vol(hdr,vol_ttest_sub);

% Generating and writing effect maps of the difference between subtype
% average and grand average in a single volume
for ss = 1:max(part)
    [~,~,sub.mean_eff(ss,:),~,~] = niak_ttest(data.data(part==ss,:),data.data(part~=ss,:),true);
end
vol_eff_sub = niak_tseries2vol(sub.mean_eff,mask);
file_name = 'eff_subtype.nii.gz';
hdr.file_name = fullfile(files_out, file_name);
niak_write_vol(hdr,vol_eff_sub);

%% Statistics

if opt.flag_stats == 1 && ~strcmp(files_in.model,'gb_niak_omitted') && ~strcmp(opt.nb_col_csv,'gb_niak_omitted')
    [tab,sub_id,labels_y] = niak_read_csv(files_in.model);
    
    %% Build the model from user's csv and input column
    col = tab(:,opt.nb_col_csv);
    % Build a mask for NaN values in model and mask out subjects with NaNs
    mask_nan = ~max(isnan(col),[],2);
    col = col(mask_nan,:);
    sub_id = sub_id(mask_nan,:);
    partition = part(mask_nan,:);
    % Save the model
    model.subject_id = sub_id;
    model.partition = partition;
    model.group = col;
        
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
    path_ct = fullfile(files_out,'chi2_contingency_table.csv');
    niak_write_csv(path_ct,contab,opt_ct)
    
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
    
    for pp = 1:length(contab(:,1))
        pc_val = contab(pp,:);
        pc = pie(pc_val);
        textc = findobj(pc,'Type','text');
        percval = get(textc,'String');
        labels = strcat(name_clus, {': '},percval');
        pc = pie(pc_val,labels);
        c_title = ['Group' num2str(list_gg(pp))];
        title(c_title);
        name_pc = ['piechart_group' num2str(list_gg(pp)) '.png'];
        pc_out = fullfile(files_out, name_pc);
        print(pc_out, '-dpng', '-r300');
    end
    
    file_stat = fullfile(files_out,'group_stats.mat');
    save(file_stat,'model','stats')
    
end

%% Saving subtyping results and statistics

file_sub = fullfile(files_out, 'subtypes.mat');
save(file_sub,'sub','hier','order','part','opt')

end








