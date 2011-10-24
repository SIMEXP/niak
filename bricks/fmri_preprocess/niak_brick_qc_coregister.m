function [files_in,files_out,opt] = niak_brick_qc_coregister(files_in,files_out,opt)
% Derive measures of quality control for coregistration of brain volumes.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_COREGISTER(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%
%    VOL
%        (cell of string) multiple file names of 3D dataset in the same
%        space.
%
%    MASK
%        (string or cell of strings) one or multiple brain masks. If
%        only one mask is specified, this mask is used for computing all
%        indices. Otherwise, a "group" mask is defined by thresholding
%        the average of all masks. See OPT and COMMENTS below.
%
% FILES_OUT
%    (structure) with the following fields :
%
%    MASK_AVERAGE
%        (string, default <path of FILES_IN.VOL{1}>_mask_average.<EXT>)
%        the average of binary mask of the brain for all files in
%        FILES_IN.MASK
%
%    MASK_GROUP
%        (string, default <path of FILES_IN.VOL{1}>_mask_group.<EXT>)
%        A binary version of MASK_AVERAGE after a threshold has been
%        applied.
%
%    MEAN_VOL
%        (string, default <path of FILES_IN.VOL{1}>_mean.<EXT>)
%        the average of the volumes for all files in FILES_IN.VOL
%
%    STD_VOL
%        (string, default <path of FILES_IN.VOL{1}>_std.<EXT>)
%        the standard deviation of the volumes for all files in
%        FILES_IN.VOL
%
%    FIG_COREGISTER
%        (string, default <path of FILES_IN.VOL{1}>_qc_coregister.pdf)
%        A histogram representation of TAB_COREGISTER.
%
%    TAB_COREGISTER
%        (string, default <path of FILES_IN.VOL{1}>_qc_coregister.csv)
%        A text table of comma separated values. First line is a label
%        and subsequent lines are for each entry of FILES_IN. See the
%        NOTES below for a list of quality control measures.
%
% OPT
%    (structure) with the following fields.
%
%    LABELS_SUBJECT
%        (cell of strings, default FILES_IN.VOL) the labels used for
%        each volume in the tables.
%
%    THRESH
%        (real number, default 0.5) the threshold used to define a group
%        mask based on the average of all individual masks.
%
%    FOLDER_OUT
%        (string, default: path of FILES_IN)
%        If present, the output will be created in the folder
%        FOLDER_OUT. The folder needs to be created beforehand.
%
%    FLAG_VERBOSE
%        (boolean, default 1) if the flag is 1, then the function
%        prints some infos during the processing.
%
%    FLAG_TEST
%        (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%        do anything but update the default values in FILES_IN,
%        FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_T1_PREPROCESS, NIAK_BRICK_COREGISTER
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%    The individual masks are averaged, resutling in a volume with
%    values between 0 and 1. 0 corresponds to voxels that were in no
%    individual brain mask, while 1 corresponds to voxels that were in
%    all invidual brain masks.
%
%    The group mask is this average brain mask after threshold
%    (OPT.THRESH).
%
% NOTE 2:
%    The first column ('perc_overlap_mask') is the percentage of overlap
%    of the group mask and each individual mask, relative to the size of
%    the individual masks. This is to check the consistency of the field
%    of views across masks.
%
%    The second column ('xcorr_vol') is a spatial cross-correlation of
%    the individual volume with the average volume, restricted to the
%    group brain mask.
%
% NOTE 3:   
%    If the datasets are 3D+t, the brick will work on the average
%    volumes. The STD volume will then be the average of std volumes
%    generated within each 3D+t dataset.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, quality control, coregistration

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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_COREGISTER(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_qc_coregister'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields    = {'vol' , 'mask' };
gb_list_defaults  = {NaN   , NaN    };
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields    = {'mean_vol'        , 'std_vol'         , 'mask_average'    , 'mask_group'      , 'fig_coregister'  , 'tab_coregister'  };
gb_list_defaults  = {'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'labels_subject' , 'thresh' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {files_in.vol     , 0.5      , true           , false       , ''           };
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in.vol{1});
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.mask_group)
    files_out.mask_group = [opt.folder_out name_f,'_mask_group',ext_f];
end

if isempty(files_out.mask_average)
    files_out.mask_average = [opt.folder_out name_f,'_mask_average',ext_f];
end

if isempty(files_out.mean_vol)
    files_out.mean_vol = [opt.folder_out name_f,'_mean',ext_f];
end

if isempty(files_out.std_vol)
    files_out.std_vol = [opt.folder_out name_f,'_std',ext_f];
end

if isempty(files_out.fig_coregister)
    files_out.fig_coregister = [opt.folder_out name_f,'_qc_coregister.pdf'];
end

if isempty(files_out.tab_coregister)
    files_out.tab_coregister = [opt.folder_out name_f,'_qc_coregister.csv'];
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ischar(files_in.mask)
    files_in_tmp{1} = files_in.mask;
    files_in.mask  = files_in_tmp;
end

%% Averaging masks
if flag_verbose
    fprintf('Averaging masks. Percentage done :');
    curr_perc = -1;
end

for num_f = 1:length(files_in.mask)
    if flag_verbose
        new_perc = 5*floor(20*num_f/length(files_in.mask));
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
    [hdr,vol_mask] = niak_read_vol(files_in.mask{num_f});
    
    if num_f == 1
        mask_avg = double(vol_mask);
    else
        mask_avg = mask_avg + double(vol_mask);
    end
end
clear vol_mask
mask_avg = mask_avg/length(files_in.mask);
mask_all = mask_avg>=opt.thresh;
if flag_verbose
    fprintf('\n');
end

%% Averaging volumes
if flag_verbose
    fprintf('Averaging volumes. Percentage done :');
end

for num_f = 1:length(files_in.vol)
    if flag_verbose
        new_perc = 5*floor(20*num_f/length(files_in.vol));
        if curr_perc~=new_perc
            fprintf(' %1.0f',new_perc);
            curr_perc = new_perc;
        end
    end
    [hdr,vol] = niak_read_vol(files_in.vol{num_f});
        
    if num_f == 1
        flag_4d = size(vol,4)>1;
        if flag_4d
            mean_vol = mean(vol,4);
            std_vol = std(vol,[],4);
        else
            mean_vol = vol;
            std_vol = vol.^2;
        end
    else
        if flag_4d
            mean_vol = mean(vol,4) + mean_vol;
            std_vol = std(vol,[],4) + std_vol;
        else
            mean_vol = vol + mean_vol;
            std_vol = vol.^2 + std_vol;
        end
    end
end

mean_vol = mean_vol/length(files_in.vol);
if flag_4d
    std_vol  = std_vol/length(files_in.vol);
else
    std_vol  = sqrt((std_vol-length(files_in.vol)*(mean_vol.^2))/(length(files_in.vol)-1));
end

if flag_verbose
    fprintf('\n');
end

%% Compute score of fit
if flag_verbose
    fprintf('Deriving goodness of fit measures. Percentage done :');
end
if ~strcmp(files_out.tab_coregister,'gb_niak_omitted')
    
    tab_coregister = zeros([length(files_in.vol) 2]);
    mask_v = mask_all(:);
    mean_v = mean_vol(mask_all);
    
    for num_f = 1:length(files_in.vol)
        if flag_verbose
            new_perc = 5*floor(20*num_f/length(files_in.vol));
            if curr_perc~=new_perc
                fprintf(' %1.0f',new_perc);
                curr_perc = new_perc;
            end
        end
        
        % The mask
        if length(files_in.mask)==1
            tab_coregister(num_f,1) = 1;
        else
            [hdr,mask_f] = niak_read_vol(files_in.mask{num_f});
            tab_coregister(num_f,1) = sum(mask_v&mask_f(:))/sum(mask_f(:));
        end
        clear mask_f
        
        % The volume
        [hdr,mean_f] = niak_read_vol(files_in.vol{num_f});
        flag_4d = size(mean_f,4)>1;
        if flag_4d
            mean_f = mean(mean_f,4);
        end
        mean_f = mean_f(mask_all);
        rmean = niak_build_correlation([mean_v,mean_f]);
        tab_coregister(num_f,2) = rmean(1,2);
        clear mean_f
    end
    
    if flag_verbose
        fprintf('\n');
    end
end

%% Saving outputs
if ~strcmp(files_out.mask_group,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the group mask in the file %s ...\n',files_out.mask_group);
    end
    hdr.file_name = files_out.mask_group;
    niak_write_vol(hdr,mask_all);
end

if ~strcmp(files_out.mask_average,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average mask in the file %s ...\n',files_out.mask_average);
    end
    hdr.file_name = files_out.mask_average;
    niak_write_vol(hdr,mask_avg);
end

if ~strcmp(files_out.mean_vol,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average mean volume in the file %s ...\n',files_out.mean_vol);
    end
    hdr.file_name = files_out.mean_vol;
    niak_write_vol(hdr,mean_vol);
end

if ~strcmp(files_out.std_vol,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the average std volume in the file %s ...\n',files_out.std_vol);
    end
    hdr.file_name = files_out.std_vol;
    niak_write_vol(hdr,std_vol);
end

if ~strcmp(files_out.fig_coregister,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the scores of fit in a figure %s ...\n',files_out.fig_coregister);
    end    
    file_fig = niak_file_tmp('.eps');        
    hf = figure;
    ha = gca;
    barh(tab_coregister);
    axis([min(tab_coregister(:)) max(min(tab_coregister(:))+0.01,max(tab_coregister(:))) 0 max(length(labels_subject),2)+1]);
    set(ha,'ytick',1:length(labels_subject));
    set(ha,'yticklabel',labels_subject);
    legend({'perc_overlap_mask','xcorr_vol'});
    print(file_fig,'-depsc2');
    
    %% In octave, use ps2pdf to convert the result into PDF format
    instr_ps2pdf = cat(2,'ps2pdf -dEPSCrop ',file_fig,' ',files_out.fig_coregister);
    [succ,msg] = system(instr_ps2pdf);
    if succ~=0
        warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf : ',msg));
    end
    delete(file_fig)
    close(hf);
    
end

if ~strcmp(files_out.tab_coregister,'gb_niak_omitted')
    if flag_verbose
        fprintf('Saving the scores of fit in the file %s ...\n',files_out.tab_coregister);
    end    
    opt_tab.labels_x = labels_subject;
    opt_tab.labels_y = {'perc_overlap_mask','xcorr_vol'};
    niak_write_csv(files_out.tab_coregister,tab_coregister,opt_tab);
end