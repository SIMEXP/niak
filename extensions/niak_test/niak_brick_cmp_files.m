function [in,out,opt] = niak_brick_cmp_files(in,out,opt)
% Quantitative comparison of files from different base folders.
%
% SYNTAX:
% [IN,OUT,OPT] = NIAK_BRICK_CMP_FILES(IN,OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% IN (structure) with the following fields:
%   SOURCE (cell of strings) a list of files.
%   TARGET (cell of strings) another list of files.
%
% OUT (string) the name of a .csv (report) file
% 
% OPT (structure) with the following fields:
%   BASE_SOURCE (string, mandatory) the base folder for SOURCE files.
%   BASE_TARGET (string, mandatory) the base folder for TARGET files.
%   BLACK_LIST_SOURCE (string) the black list to grab files from SOURCE,
%      if IN.SOURCE is omitted.
%   BLACK_LIST_TARGET (string) the black list to grab files from TARGET,
%      if IN.TARGET is omitted.
%   EPS (scalar, default 10^(-4)) the amount of "numeric noise" tolerated to 
%       declare two volumes to be equal
%   FLAG_SOURCE_ONLY (boolean, default false) when comparing two matlab structures,
%       the tests will only consider fields found in the source, i.e. if there are 
%       more fields in the target, those will be ignored. Only the variables found
%       in the source will be compared with those from the target as well.
%   FLAG_TEST (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update IN, OUT, OPT
%   FLAG_VERBOSE (boolean, default 1) if the flag is 1, then the function 
%       prints some infos during the processing.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% IN, OUT, OPT are similar to the inputs, but updated with default values.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_GRAB_FOLDER
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   The report has one line per file (ignoring the base folder for both source 
%   and target). The columns are the following:
%      'source' (boolean) the file exist in the source
%      'target' (boolean) the file exist in the target
%      'identical' (boolean or NaN) the files are identical (see NOTE 2 below)
%         NaN for unsupported file types, or files that exist only on source
%         or target
%      'same_labels' (boolean or NaN) the .csv files have the same labels.
%         NaN for any other file type.
%      'same_variables' (boolean or NaN) the .mat files have the same variables.
%         NaN for any other file type.
%      'same_header_info' (boolean or NaN) the .nii/.mnc files have the same info
%         in the header. NaN for any other file type.
%      'same_dim' (boolean or NaN) the volumes have the same dimensions (.nii/.mnc)
%         or the spreadsheets have the same dimension (.csv). NaN for any other file type.
%      'dice_mask_brain' (scalar in [0,1] or NaN) the dice coefficient between the brain mask 
%         of the two volumes (.nii/.mnc). NaN for any other file type.
%      'max_diff' (positive scalar or NaN) the max absolute difference between the two 
%         volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type.
%      'min_diff' (positive scalar or NaN) the min absolute difference between the two 
%         volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type.
%      'mean_diff' (positive scalar or NaN) the mean absolute difference between the two 
%         volumes (.nii/.mnc) or spreadsheets (.csv). NaN for any other file type.
%      'max_corr' (scalar in [0,1] or NaN) the max correlation between the time series 
%         of voxels inside the brain mask between two 4D volumes (.nii/.mnc). 
%         NaN for any other file type.
%      'min_corr' (scalar in [0,1] or NaN) the min correlation between the time series 
%         of voxels inside the brain mask between two 4D volumes (.nii/.mnc). 
%         NaN for any other file type.
%      'mean_corr' (scalar in [0,1] or NaN) the mean correlation between the time series 
%         of voxels inside the brain mask between two 4D volumes (.nii/.mnc). 
%         NaN for any other file type.
%
% NOTE 2
%   two files are identical if they exist in both source and target and
%      * for .nii/.mnc: the headers are identical and the max absolute difference is 
%        less than OPT.EPS
%      * for .csv files: the labels are identical and the max absolute difference is 
%        less than OPT.EPS
%      * for .mat files: the content is identical up to Matlab/Octave's precision
%
% NOTE 3
%   If IN.SOURCE or IN.TARGET is omitted, the brick will call NIAK_GRAB_FOLDER
%   to grab all files in SOURCE and TARGET.
%
% NOTE 4
%   Two files are considered equivalent (and are being compared), if they are located in 
%   identical folders with identical names, relative to the base folders
%      OPT.BASE_SOURCE
%      OPT.BASE_TARGET
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2012-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: files, comparison, test

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
if ~exist('in','var')||~exist('out','var')
    error('niak:brick','Bad syntax, type ''help %s'' for more info.',mfilename)
end

%% Options
list_fields   = { 'base_source' , 'base_target' , 'black_list_source' , 'black_list_target' , 'flag_source_only' , 'eps'   , 'flag_verbose' , 'flag_test' };
list_defaults = { NaN           , NaN           , {}                  , {}                  , false              , 10^(-4) , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if ~isempty(opt.base_source)
    opt.base_source = niak_full_path(opt.base_source);
end
if ~isempty(opt.base_target)
    opt.base_target = niak_full_path(opt.base_target);
end

opt_m.eps = opt.eps;
opt_m.flag_source_only = opt.flag_source_only;

%% Files in
in = psom_struct_defaults(in,{'source','target'},{{},{}});

if isempty(in.source)
    in.source = niak_grab_folder(opt.base_source,opt.black_list_source);
end

if isempty(in.target)
    in.target = niak_grab_folder(opt.base_target,opt.black_list_target);
end

if ~iscellstr(in.source)||~iscellstr(in.target)
    error('IN.SOURCE and IN.TARGET should be cells of string!')
end

%% Files out
if ~ischar(out)||isempty(out)
    error('OUT should be a non-empty string!')
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Get rid of base directory
source_b = regexprep(in.source,['^' opt.base_source],'');
target_b = regexprep(in.target,['^' opt.base_target],'');
files = union(source_b,target_b);

%% Loop over files
is_source = ismember(files,source_b);
is_target = ismember(files,target_b);
lx = files;
ly = { 'source' , 'target' , 'identical' , 'same_labels' , 'same_variables' , 'same_header_info' , 'same_dim' , 'dice_mask_brain', 'max_diff' , 'min_diff' , 'mean_diff' , 'max_corr' , 'min_corr' , 'mean_corr' };
tab = zeros(length(lx),length(ly));
if opt.flag_verbose
    fprintf('Found %i unique files to compare ...\n',length(files))
    fprintf('    Source: %s\n',opt.base_source)
    fprintf('    Target: %s\n',opt.base_target)
end
for num_f = 1:length(files)
    if opt.flag_verbose
        niak_progress(num_f,length(files));
    end
    [path_f,name_f,ext_f] = niak_fileparts(files{num_f});
    if ~is_source(num_f)||~is_target(num_f)
        % if the file does not exist in either source or target, move to the next file
        tab(num_f,:) = [is_source(num_f) is_target(num_f) repmat(NaN,[1 size(tab,2)-2])];
        continue
    end
    
    file_source = [opt.base_source files{num_f}];
    file_target = [opt.base_target files{num_f}];
    tab(num_f,1:2) = [1 1];
    switch ext_f
        
        case {'.nii','.nii.gz','.mnc','.mnc.gz'}
            %% A 3D or 3D+t image
            [hdr_s,vol_s] = niak_read_vol(file_source);
            [hdr_t,vol_t] = niak_read_vol(file_target);
            hdr_s.info = rmfield(hdr_s.info,{'file_parent','history'});
            hdr_t.info = rmfield(hdr_t.info,{'file_parent','history'});
            tab(num_f,4) = NaN; % 'same_labels' does not apply to a nifti/minc file           
            tab(num_f,5) = NaN; % 'same_variables' does not apply to a nifti/minc file           
            tab(num_f,6) = psom_cmp_var(hdr_s.info,hdr_t.info); % compare the "info" section of the headers
            if (ndims(vol_s) == ndims(vol_t)) && min(size(vol_s)==size(vol_t))
                tab(num_f,7) = 1; % the two volumes have the same dimensions
                mask_s = niak_mask_brain(vol_s);
                mask_t = niak_mask_brain(vol_t);
                avg_sz_mask = (sum(mask_s(:))+sum(mask_t(:)));
                if avg_sz_mask>0
                    tab(num_f,8) = 2*sum(mask_s(:)&mask_t(:))/avg_sz_mask;
                else
                    tab(num_f,8) = 1;
                end
                mask = mask_s & mask_t;
                if ~any(mask)
                    tab(num_f,9) = 0; % no brain voxel, so no difference
                    tab(num_f,10) = 0; % no brain voxel, so no difference
                    tab(num_f,11) = 0; % no brain voxel, so no difference
                    tab(num_f,12) = NaN; % no brain voxel, so can't compute correlations
                    tab(num_f,13) = NaN; % no brain voxel, so can't compute correlations
                    tab(num_f,14) = NaN; % no brain voxel, so can't compute correlations
                elseif ndims(vol_s)==4                    
                    y_s = niak_vol2tseries(vol_s,mask);
                    y_t = niak_vol2tseries(vol_t,mask);
                    tab(num_f,9) = max(abs(y_s(:)-y_t(:))); % Compute the max difference between the two volumes
                    tab(num_f,10) = min(abs(y_s(:)-y_t(:))); % Compute the min difference between the two volumes
                    tab(num_f,11) = mean(abs(y_s(:)-y_t(:))); % Compute the mean difference between the two volumes
                    y_s = niak_normalize_tseries(y_s,'mean');
                    y_t = niak_normalize_tseries(y_t,'mean');
                    r_st = sum(y_s.*y_t,1)./(sqrt(sum(y_s.^2,1).*sum(y_t.^2,1))); % Compute the correlation between the two time series
                    tab(num_f,12) = max(r_st); % Compute the max correlation between the two time series
                    tab(num_f,13) = min(r_st); % Compute the min correlation between the two time series
                    tab(num_f,14) = mean(r_st); % Compute the mean correlation between the two time series
                else
                    tab(num_f,9) = max(abs(vol_s(mask)-vol_t(mask))); % Compute the max difference between the two volumes
                    tab(num_f,10) = min(abs(vol_s(mask)-vol_t(mask))); % Compute the min difference between the two volumes
                    tab(num_f,11) = mean(abs(vol_s(mask)-vol_t(mask))); % Compute the mean difference between the two volumes
                    tab(num_f,12) = NaN;
                    tab(num_f,13) = NaN;
                    tab(num_f,14) = NaN;
                end
                tab(num_f,3) = tab(num_f,6) & (tab(num_f,11) <= opt.eps); % if the headers are similar and the differences are smaller than a tolerance level, consider that the two files are identical
            else
                tab(num_f,3)  = 0; % the two images are different
                tab(num_f,7)  = 0; % the two volumes do not have the same dimensions
                tab(num_f,8)  = NaN; % it's not possible to compute the DICE between brain masks
                tab(num_f,9)  = NaN; % it's not possible to compute max_diff
                tab(num_f,10) = NaN; % it's not possible to compute max_diff
                tab(num_f,11) = NaN; % it's not possible to compute max_diff
                tab(num_f,12) = NaN; % it's not possible to compute the max correlation
                tab(num_f,13) = NaN; % it's not possible to compute the min correlation
                tab(num_f,14) = NaN; % it's not possible to compute the mean correlation
            end
        
        case '.csv'
            %% A "comma-separated values" spreadsheet
            [tab_s,lx_s,ly_s] = niak_read_csv(file_source);
            [tab_t,lx_t,ly_t] = niak_read_csv(file_target);
            tab(num_f,5) = NaN; % 'same_variables' does not apply to a .csv
            tab(num_f,6) = NaN; % 'same_header_info' does not apply to a .csv
            tab(num_f,8) = NaN; % 'dice_mask_brain' does not apply to .csv
            tab(num_f,7) = min(size(tab_s)==size(tab_t)); % test if the two spreadsheets have the same dimensions
            if ~tab(num_f,7)
                tab(num_f,3)  = 0; % the two files are different
                tab(num_f,4)  = 0; % not the same labels 
                tab(num_f,9)  = NaN; % cannot compute the max difference                 
                tab(num_f,10) = NaN; % cannot compute the min difference
                tab(num_f,11) = NaN; % cannot compute the mean difference
            else
                tab(num_f,4)  = psom_cmp_var(lx_s,lx_t)&psom_cmp_var(ly_s,ly_t);
                mask_nan_s = isnan(tab_s(:));
                mask_nan_t = isnan(tab_t(:));
                flag_same_nan = ~any(mask_nan_s~=mask_nan_t);
                tab_s(mask_nan_s) = 0;
                tab_t(mask_nan_t) = 0;
                tab(num_f,9)  = max(abs(tab_s(:)-tab_t(:)));                
                tab(num_f,10) = min(abs(tab_s(:)-tab_t(:)));
                tab(num_f,11) = mean(abs(tab_s(:)-tab_t(:)));
                tab(num_f,3)  = tab(num_f,4) && flag_same_nan && (tab(num_f,9) <= opt.eps); % if the labels are identical and the differences are smaller than a tolerance level, consider that the two files are identical
            end            
            tab(num_f,12) = NaN; % it's not possible to compute the max correlation
            tab(num_f,13) = NaN; % it's not possible to compute the min correlation
            tab(num_f,14) = NaN; % it's not possible to compute the mean correlation
        
        case '.mat'
            %%  A matlab .mat file
            data_s = load(file_source);
            data_t = load(file_target);
            tab(num_f,3) = psom_cmp_var(data_s,data_t,opt_m);
            tab(num_f,4) = NaN; % 'same_labels' does not apply to a .mat
            if opt.flag_source_only
                tab(num_f,5) = min(ismember(fieldnames(data_s),fieldnames(data_t))); % test if the variables in source are present in target
            else
                tab(num_f,5) = min(ismember(fieldnames(data_s),fieldnames(data_t)))&min(ismember(fieldnames(data_t),fieldnames(data_s))); % test if the two .mat files contain the same list of variables
            end
            tab(num_f,6)  = NaN; % 'same_header_info' does not apply to a .mat
            tab(num_f,7)  = NaN; % 'same_dim' does not apply to a .mat file
            tab(num_f,8)  = NaN; % 'dice_mask_brain' does not apply to .mat
            tab(num_f,9)  = NaN; % 'max_diff' does not apply to a .mat file
            tab(num_f,10) = NaN; % 'min_diff' does not apply to a .mat file
            tab(num_f,11) = NaN; % 'mean_diff' does not apply to a .mat file
            tab(num_f,12) = NaN; % it's not possible to compute the max correlation
            tab(num_f,13) = NaN; % it's not possible to compute the min correlation
            tab(num_f,14) = NaN; % it's not possible to compute the mean correlation            
        otherwise
            %% Unsupported file types. Fill all test with NaN (non-applicable/undefined)
            tab(num_f,3:end) = repmat(NaN,[1 size(tab,2)-2]);
    end
end

%% Write the report
if opt.flag_verbose
    fprintf('Writing report ...\n')
end
opt_csv.labels_x = lx;
opt_csv.labels_y = ly;
niak_write_csv(out,tab,opt_csv);
