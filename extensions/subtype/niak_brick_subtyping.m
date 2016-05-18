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
%   (structure) with the following fields:
%
%   DATA 
%       (string) path to a .mat file containing a variable STACK, which is 
%       an array (#subjects x #voxels OR vertices OR regions), see also
%       niak_brick_network_stack
%
%   MATRIX
%       (string) path to a .mat file containing a variable SIM_MATRIX,
%       which is an array (#subjects x #subjects). Note this matrix must be
%       unordered/unclustered.
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
%   (structure) with the following fields:
%
%   SUBTYPE
%       (string, default 'subtype.mat') path to subject by subtype by voxel
%       array .mat file
%
%   SUBTYPE_MAP
%       (string, default '<OPT.SUB_MAP_TYPE>_subtype.nii.gz') path to ...
%
%   GRAND_MEAN_MAP
%       (string, default 'grand_mean.nii.gz') path to ...
%
%   GRAND_STD_MAP
%       (string, default 'grand_std.nii.gz') path to ...
%
%   TTEST_MAP
%       (string, default 'ttest_subtype.nii.gz') path to ...
% 
%   EFF_MAP
%       (string, default 'eff_subtype.nii.gz') path to ...
%
%   STATS
%       (string, default 'group_stats.mat') path to ...
%
%   CONTAB
%       (string, default 'chi2_contingency_table.csv') path to ...
% 
% OPT 
%   (structure) with the following fields:
%
%   FOLDER_OUT
%       (string, default '') if not empty, this specifies the path where
%       outputs are generated
%
%   NB_SUBTYPE
%       (integer) the number of desired subtypes
%
%   SUB_MAP_TYPE
%       (string, default 'mean') how the subtypes are represented in the
%       volumes (options: 'mean' or 'median')
%
%   GROUP_COL_ID
%       (integer, default 0) the column number
%       (excluding column A for subject IDs) in the model csv that separates 
%       subjects into groups to compare chi-squared and Cramer's V stats
%
%   FLAG_STATS
%       (boolean, default 0) if the flag is 1 (true), the brick
%       will calculate Cramer's V and chi-squared statistics for groups
%       specified in files_in.model
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
% FILES_OUT
%       Directory containing the following: 
%
%   SUBTYPES.MAT
%       (structure) with the following fields:
%
%       HIER
%           (2D array) a copy of the variable from FILES_IN.HIER 
%       OPT
%           (structure) a copy of the options specified in OPT
%       PART
%           (vector) PART(I) = J if the object I is in the class J.
%           See also: niak_threshold_hierarchy
%       SUB
%           (structure) contains subfield for different maps (e.g.
%           mean/median, ttest, effect) for each subtype
%
%   4D VOLUMES (.nii.gz)
%       Different maps for subtypes as saved in the variable SUB in
%       SUBTYPES.MAT
%
%   GROUP_STATS.MAT
%       (structure) If OPT.FLAG_STATS was true, this .mat file will be 
%       generated, which contains Chi-squared and Cramer's V statistics
%
%   CHI2_CONTINGENCY_TABLE.CSV
%       (.csv) If OPT.FLAG_STATS was true, a Chi2 contingency table will be
%       saved
%
%   PIECHART_GROUP(n).PNG
%       (figure, .png) If OPT.FLAG_STATS was true, pie chart figures will
%       be generated to illustrate the proportions of data in n groups in 
%       each subtype
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.


%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtyping'' for more info.')
end

% Input
files_in = psom_struct_defaults(files_in,...
           { 'data' , 'mask' , 'matrix' , 'model'           },...
           { NaN    , NaN    , NaN      , 'gb_niak_omitted' });

% Options
opt = psom_struct_defaults(opt,...
      { 'folder_out' , 'nb_subtype', 'sub_map_type', 'group_col_id' , 'flag_stats' , 'flag_verbose' , 'flag_test' },...
      { ''           , NaN         , 'mean'        , 0              , false        , true           , false       });

% Output
if ~isempty(opt.folder_out)
    path_out = niak_full_path(opt.folder_out);
    files_out = psom_struct_defaults(files_out,...
                { 'subtype'                , 'subtype_map'                                              , 'grand_mean_map'               , 'grand_std_map'               , 'ttest_map'                       , 'eff_map'                       , 'stats'                      , 'contab'                                },...
                { [path_out 'subtype.mat'] , [path_out sprintf('%s_subtype.nii.gz' , opt.sub_map_type)] , [path_out 'grand_mean.nii.gz'] , [path_out 'grand_std.nii.gz'] , [path_out 'ttest_subtype.nii.gz'] , [path_out 'eff_subtype.nii.gz'] , [path_out 'group_stats.mat'] , [path_out 'chi2_contingency_table.csv'] });
else
    files_out = psom_struct_defaults(files_out,...
                { 'subtype'         , 'subtype_map'     , 'grand_mean_map'  , 'grand_std_map'   ,'ttest_map'        , 'eff_map'         , 'stats'           , 'contab'          , 'pie'             },...
                { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' });
end
  
% If the user wants stats, the group column must be specified
if opt.flag_stats && opt.group_col_id == 0
    error('OPT.FLAG_STATS is set to true but the group variable is undefined');
end
  
% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Load the data
data = load(files_in.data);
provenance = data.provenance; % loading provenance from the data file
data = data.stack; % get the stack data

%% Compute the hierarchy
% Load the similarity matrix
R = load(files_in.matrix);
R = R.sim_matrix;
% Cluster subjects
hier = niak_hierarchical_clustering(R);

% Read the mask
[hdr,mask] = niak_read_vol(files_in.mask);
mask = logical(mask);
% Get the number of voxels
n_vox = sum(mask(:));

%% Build the clusters by thresholding the hiearchy by the number of subtypes
part = niak_threshold_hierarchy(hier,struct('thresh',opt.nb_subtype));

%% Build subtype maps

% Generating and writing the mean or the median subtype maps in a single volume
sub.map = zeros(opt.nb_subtype, n_vox);
for ss = 1:opt.nb_subtype
    if strcmp(opt.sub_map_type, 'mean')
        % Construct the subtype map as the mean map of the subgroup
        sub.map(ss,:) = mean(data(part==ss,:),1);
    elseif strcmp(opt.sub_map_type, 'median')
        % Construct the subtype map as the median map of the subgroup
        sub.map(ss,:) = median(data(part==ss,:),1);
    end
end

% Bring the subtype map back to volumetric space
% Check if to be saved - improvable
if ~strcmp(files_out.subtype_map, 'gb_niak_omitted')
    vol_map_sub = niak_tseries2vol(sub.map, mask);
    hdr.file_name = files_out.subtype_map;
    niak_write_vol(hdr, vol_map_sub);
end

%% Generating and writing t-test and effect maps of the difference between subtype
% average and grand average in volumes

for ss = 1:opt.nb_subtype
    [sub.ttest(ss,:), ~, sub.mean_eff(ss,:), ~, ~] = niak_ttest(data(part==ss,:), data(part~=ss,:),true);
end
% Check if to be saved - improvable
if ~strcmp(files_out.ttest_map, 'gb_niak_omitted')
    vol_ttest_sub = niak_tseries2vol(sub.ttest, mask);
    hdr.file_name = files_out.ttest_map;
    niak_write_vol(hdr,vol_ttest_sub);
end
% Check if to be saved - improvable
if ~strcmp(files_out.eff_map, 'gb_niak_omitted')
    vol_eff_sub = niak_tseries2vol(sub.mean_eff, mask);
    hdr.file_name = files_out.eff_map;
    niak_write_vol(hdr,vol_eff_sub);
end

%% Generate and write grand mean map
hdr.file_name = files_out.grand_mean_map;
sub.gd_mean = mean(data,1);
vol_gd_mean = niak_tseries2vol(sub.gd_mean, mask);
niak_write_vol(hdr,vol_gd_mean);

% Generate and write the grand std map
% Check if to be saved - improvable
if ~strcmp(files_out.grand_std_map, 'gb_niak_omitted')
    hdr.file_name = files_out.grand_std_map;
    sub.gd_std = std(data,1);
    vol_std_mean = niak_tseries2vol(sub.gd_std, mask);
    niak_write_vol(hdr,vol_std_mean);
end

%% Statistics

if opt.flag_stats == 1 
    [tab,sub_id,labels_y] = niak_read_csv(files_in.model);
    
    %% Build the model from user's csv and input column
    col = tab(:,opt.group_col_id);
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
    % Check if to be saved - improvable
    if ~strcmp(files_out.contab, 'gb_niak_omitted')
        niak_write_csv(files_out.contab, contab, opt_ct)
    end
    
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
    
    files_out.pie = make_paths(opt.folder_out, 'pie_chart_%d.png', 1:n_row);
    
    % Pie chart visualization
    for pp = 1:n_row
        fh = figure('Visible', 'off');
        pc_val = contab(pp,:);
        pc = pie(pc_val);
        textc = findobj(pc,'Type','text');
        percval = get(textc,'String');
        labels = strcat(name_clus, {': '},percval');
        pc = pie(pc_val,labels);
        c_title = ['Group' num2str(list_gg(pp))];
        title(c_title);
        print(fh, files_out.pie{pp}, '-dpng', '-r300');
    end
    % Check if to be saved - improvable
    if ~strcmp(files_out.stats, 'gb_niak_omitted')
        save(files_out.stats,'model','stats')
    end
    
end

%% Saving subtyping results and statistics
if ~strcmp(files_out.subtype, 'gb_niak_omitted')
    save(files_out.subtype,'provenance','sub','hier','part','opt')
end
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







