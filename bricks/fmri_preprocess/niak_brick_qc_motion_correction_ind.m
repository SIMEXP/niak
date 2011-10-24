function [files_in,files_out,opt] = niak_brick_qc_motion_correction_ind(files_in,files_out,opt)
% Derive individual measures of quality control for fMRI motion correction.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_MOTION_CORRECTION_IND(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields : 
%
%   VOL
%       (cell of string) multiple file names of 3D+t datasets in the same 
%       space.
%
%   MOTION_PARAMETERS
%       (cell of string) multiple file names of .mat files including one
%       variable TRANSF, such that TRANSF(:,:,I) is the 4*4 rigid-body
%       motion estimated for volume I of the corresponding FILES_IN.VOL
%
% FILES_OUT
%   (structure) with the following fields :
%
%   FIG_MOTION_PARAMETERS
%       (string, default <path of FILES_IN{1}>LABEL_motion_parameters.pdf)
%       A pdf figure with plots of the translation/rotation parameters
%       (from FILES_IN.MOTION_PARAMETERS).
%
%   MASK_AVERAGE
%       (string, default <path of FILES_IN{1}>LABEL_mask_average.<EXT>)
%       the average of binary mask of the brain for all files in
%       FILES_IN.MASK
%
%   MASK_GROUP
%       (string, default <path of FILES_IN{1}>LABEL_mask_group.<EXT>)
%       A binary version of MASK_AVERAGE after a threshold has been
%       applied.
%
%   MEAN_VOL
%       (string, default <path of FILES_IN{1}>LABEL_mean.<EXT>)
%       the average of the volumes for all files in FILES_IN.VOL
%
%   STD_VOL
%       (string, default <path of FILES_IN{1}>LABEL_std.<EXT>)
%       the average volumes of standard deviation for all files in
%       FILES_IN.VOL
%
%   FIG_COREGISTER
%       (string, default <path of FILES_IN{1}>LABEL_qc_coregister.pdf)
%       A histogram representation of TAB_COREGISTER.
%
%   TAB_COREGISTER
%       (string, default <path of FILES_IN{1}>LABEL_qc_coregister.csv)
%       A text table of comma separated values. First line is a label
%       and subsequent lines are for each entry of FILES_IN. See the
%       NOTES below for a list of quality control measures.
%
% OPT
%   (structure) with the following fields.
%
%   LABELS_VOL
%       (cell of strings, default FILES_IN) the labels used for each entry 
%       in the tables.
%
%   LABEL
%       (string, default name of FILES_IN{1}, without path or extension) 
%       used in the default names.
%
%   FWHM 
%       (real value, default 3) the FWHM of the blurring kernel used to 
%       extract of mask of the brain.
%       
%   FLAG_REMOVE_EYES 
%       (boolean, default 0) if FLAG_REMOVE_EYES == 1, an attempt is done 
%        to remove the eyes from the mask.
%
%   THRESH
%       (real number, default 0.95) the threshold used to define a group 
%       mask based on the average of all individual masks.
%
%   FOLDER_OUT
%       (string, default: path of FILES_IN)
%       If present, the output will be created in the folder FOLDER_OUT. 
%       The folder needs to be created beforehand.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_MOTION_CORRECTION, NIAK_BRICK_QC_COREGISTER
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   The individual masks are averaged, resutling in a volume with values 
%   between 0 and 1. 0 corresponds to voxels that were in no individual 
%   brain mask, while 1 corresponds to voxels that were in all invidual 
%   brain masks.
%   The group mask is this average brain mask after threshold (OPT.THRESH).
%
% NOTE 2:
%   The first column ('perc_overlap_mask') is the percentage of overlap of 
%   the group mask and each individual mask, relative to the size of the 
%   individual masks. This is to check the consistency of the field of 
%   views across masks.
%   The second column ('xcorr_vol') is a spatial cross-correlation of the 
%   individual volume with the average volume, restricted to the group 
%   brain mask.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Montreal, Canada, 2010.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, quality control, motion

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
gb_list_fields    = {'vol' , 'motion_parameters' };
gb_list_defaults  = {NaN   , NaN                 };
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields    = {'fig_motion_parameters' , 'mean_vol'        , 'std_vol'         , 'mask_average'    , 'mask_group'      , 'fig_coregister'  , 'tab_coregister'  };
gb_list_defaults  = {'gb_niak_omitted'       , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_remove_eyes' , 'fwhm' , 'label' , 'labels_vol' , 'thresh' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {false              , 3      , ''      , files_in.vol , 0.95     , true           , false       , ''           };
niak_set_defaults

[path_f,name_f,ext_f] = niak_fileparts(files_in.vol{1});

if isempty(label)
    label = name_f;
end

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.fig_motion_parameters)
    files_out.mask_group = [opt.folder_out label '_motion_parameters.pdf'];
end

if isempty(files_out.mask_group)
    files_out.mask_group = [opt.folder_out label '_mask_group',ext_f];
end

if isempty(files_out.mask_average)
    files_out.mask_average = [opt.folder_out label '_mask_average',ext_f];
end

if isempty(files_out.mean_vol)
    files_out.mean_vol = [opt.folder_out label '_mean',ext_f];
end

if isempty(files_out.std_vol)
    files_out.std_vol = [opt.folder_out label '_std',ext_f];
end

if isempty(files_out.fig_coregister)
    files_out.fig_coregister = [opt.folder_out label '_qc_coregister.pdf'];
end

if isempty(files_out.tab_coregister)
    files_out.tab_coregister = [opt.folder_out label '_qc_coregister.csv'];
end

nb_file = length(files_in.vol);
if length(files_in.motion_parameters)~=nb_file
    error('There should be the same number of entries in FILES_IN.VOL and FILES_IN.MASK')
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

folder_tmp = niak_path_tmp('_qc_motion');
%% Generate individual masks
if flag_verbose
    fprintf('Generating individual brain masks ...\n');
end
file_mask = cell([nb_file 1]);
for num_f = 1:nb_file
    if flag_verbose
        fprintf('     %s \n',files_in.vol{num_f});
    end

    clear files_in_tmp files_out_tmp opt_tmp
    file_mask{num_f}         = [folder_tmp 'mask_vol' num2str(num_f) '.mnc'];
    files_in_tmp             = files_in.vol{num_f};
    files_out_tmp            = file_mask{num_f};
    opt_tmp.fwhm             = opt.fwhm;
    opt_tmp.flag_remove_eyes = opt.flag_remove_eyes;
    opt_tmp.flag_verbose     = false;
    niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
end

%% Build a figure of motion parameters
if flag_verbose
    fprintf('Generating figures of motion parameters ...\n');
end
file_eps = cell([nb_file 1]);
hfa = figure;
for num_f = 1:nb_file
    motion_params = load(files_in.motion_parameters{num_f});
    rot = zeros([size(motion_params.transf,3) 3]);
    tsl = zeros([size(motion_params.transf,3) 3]);
    for num_t = 1:size(motion_params.transf,3)
        [rot(num_t,:),tsl(num_t,:)] = niak_transf2param(motion_params.transf(:,:,num_t));
    end    
    subplot(2,1,1)
    plot(rot)
    legend('rotation x','rotation y','rotation z')
    title(sprintf('Rotation parameters %s',labels_vol{num_f}));
    subplot(2,1,2)
    plot(tsl)
    legend('translation x','translation y','translation z')
    title(sprintf('Translation parameters %s',labels_vol{num_f}));
    file_eps{num_f} = [folder_tmp 'motion_parameters_' labels_vol{num_f} '.eps'];
    print(hfa,'-dpsc','-r300',file_eps{num_f});
end
close(hfa)
file_eps_final = [folder_tmp 'fig_final.eps'];
instr_concat = ['gs  -q -dNOPAUSE -dBATCH -dNOPLATFONTS -sOutputFile=' file_eps_final '  -sDEVICE=pswrite ' ];
for num_e = 1:nb_file
    instr_concat = [instr_concat file_eps{num_e} ' '];
end
instr_concat = [instr_concat 'quit.ps'];
system(instr_concat)
system(['ps2pdf ',file_eps_final,' ',files_out.fig_motion_parameters]);

%% Coregister
if flag_verbose
    fprintf('Generating measures of quality of coregistration between runs ...\n');
end
clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp.vol                = files_in.vol;
files_in_tmp.mask               = file_mask;
files_out_tmp.mask_average      = files_out.mask_average;
files_out_tmp.mask_group        = files_out.mask_group;
files_out_tmp.mean_vol          = files_out.mean_vol;
files_out_tmp.std_vol           = files_out.std_vol;
files_out_tmp.fig_coregister    = files_out.fig_coregister;
files_out_tmp.tab_coregister    = files_out.tab_coregister;
opt_tmp.labels_subject          = opt.labels_vol;
opt_tmp.thresh                  = opt.thresh;
opt_tmp.flag_test               = false;
opt_tmp.flag_verbose            = opt.flag_verbose;
niak_brick_qc_coregister(files_in_tmp,files_out_tmp,opt_tmp);

%% clean-up
if flag_verbose
    fprintf('Done !\n');
end
instr_clean = ['rm -rf ' folder_tmp];
[status,msg] = system(instr_clean);
if status~=0
    error(msg)
end