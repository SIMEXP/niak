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
% % % % % % % % % %   NB_GROUP
% % % % % % % % % %       (integer, optional, default 'gb_niak_omitted') the number of
% % % % % % % % % %       distinct groups from the column in NB_COL_CSV to compare
% % % % % % % % % %       chi-squared and Cramer's V stats
%
%   FLAG_STATS
%       (boolean, optional, default false) if the flag is true, the brick
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
%
% % % % % % % % .mat file
% % % % % % % % % % PART
% % % % % % % %       (array 1 x #subjects) the partition of subjects into subgroups
% % % % % % % % % % hier
% % % % % % % % % % stats (ex. cramer v, chi2)
%%%%%%%%%%%%%%%% DIFF MAP  (vol)
%%%%%%%%%%%%%%%% AVERAGE SUBTYPE MAP (vol)
%%%%%%%%%%%%%%%% CHI2 .png
%%%%%%%%%%%%%%%% 

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUBTYPING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_subtyping'' for more info.')
end

% Input
if ~isstruct(files_in)
    error('FILES_IN should be a structure with the required subfields DATA, HIER, and MASK');
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
list_fields   = { 'nb_subtype', 'sub_map_type', 'nb_col_csv'     , 'nb_group'       , 'flag_stats', 'flag_verbose' , 'flag_test' };  %%%%%%%%
list_defaults = { NaN         , 'mean'        , 'gb_niak_omitted', 'gb_niak_omitted', false       , true           , false       };
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

%% Calculate Cramer's V and Chi2

if opt.flag_stats == 1 && ~strcmp(files_in.model,'gb_niak_omitted') && ~strcmp(opt.nb_col_csv,'gb_niak_omitted') %%%% && ~strcmp(opt.nb_group,'gb_niak_omitted')
    [tab,sub_id,labels_y] = niak_read_csv(files_in.model);
    
    % build the model from user's csv and input column
    model = tab(:,opt.nb_col_csv);
    % build a mask for NaN values in model and mask out subjects with NaNs
    mask_nan = ~max(isnan(model),[],2);
    model = model(mask_nan,:);
    sub_id = sub_id(mask_nan,:);
    part = part(mask_nan,:);
        
    % build the contingency table 
    
    name_clus = {};
    name_grp = {};
    list_gg = unique(model)';
    for cc = 1:opt.nb_subtype
        for gg = 1:length(list_gg) % for each group
            mask_sub = find(part(:)==cc); % build a mask to select subjects within one cluster 
            sub_model = model(mask_sub); % subjects within one cluster
            nn = numel(find(sub_model(:)==list_gg(gg))); % number of subjects for a single group that is in the cluster
            contab(gg,cc) = nn;
            name_clus{cc} = ['subt' num2str(cc)];
            name_grp{gg} = ['grp' num2str(list_gg(gg))];
        end
    end
    
    % write the table into a csv
    opt_ct.labels_x = name_grp;
    opt_ct.labels_y = name_clus;
    opt_ct.precision = 2;
    path_ct = fullfile(files_out,'chi2_ct.csv');
    niak_write_csv(path_ct,contab,opt_ct)
 
        
 
%     [~,pchi,~] = chi2cont(ct);
%     statschi(n_net,1) = pchi;
%     
%     
%     stats=mestab(ct);
%     Vchi(n_net,1) = stats.cramerV;
    
    % calculate chi-squared and cramer's v
    
    % 
% function [es,esCi,chi2]=cramerv(table,nRow,nCol,confLevel,is2by2)
% % this function computes Cramer's V, including exact analytical CI
% % ** NOTE: in the case of 2 by 2 tables Cramer's V is identical to phi
% % except possibly for the sign), which will be taken care of in the last
% % lines

%     colSum=sum(table);
%     rowSum=sum(table,2);
%     n=sum(sum(table));
%     k=min(nRow,nCol);
%     df=(nRow-1)*(nCol-1);
%     % expected frequency of occurrence in each cell: product of row and
%     % column totals divided by total N
%     ef=(rowSum*colSum)/n;
%     % chi square stats
%     chi2=(table-ef).^2./ef;
%     chi2=sum(chi2(:));
%     % Cramer's V
%     es=sqrt(chi2/(n*(k-1)));


% save the stats into a structure variable 'stats' with subfields
 

end

%% Saving subtyping results and statistics

file_sub = fullfile(files_out, 'subtypes.mat');
save(file_sub,'sub','hier','order','part','opt')

end








