function [files_in,files_out,opt]=niak_brick_build_confounds(files_in,files_out,opt)
% Generate "noise" confounds for fMRI time series. 
%
% SYNTAX :
% NIAK_BRICK_BUILD_CONFOUNDS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% FILES_IN
%   (structure) with the following fields:
%
%   FMRI 
%      (string) the fmri time-series
%
%   DC_LOW 
%      (string) cosine basis of slow time drifts to be removed
%
%   DC_HIGH
%      (string) cosine basis of high frequencies to be removed
%
%   CUSTOM_PARAM
%      (string, optional) a .mat file with one variable 'covar'(TxK)
%
%   MOTION_PARAM 
%      (string) a .mat file with motion parameters (see
%      NIAK_PIPELINE_MOTION_CORRECTION)
%
%   MASK_WM 
%      (string) the name of a 3D volume file with a binary mask of 
%      the white matter
%
%   MASK_VENT 
%      (string) the name of a 3D volume file with a binary mask of 
%      the ventricle
%
%   MASK_BRAIN 
%      (string) the name of a 3D volume file with a binary mask of the 
%      brain
%
% FILES_OUT 
%    (structure) with the following fields (outputs associated with
%    absent fields are not generated, a default name is generated for
%    empty fields):
%
%   CONFOUNDS 
%      (string, default FOLDER_OUT/<base FMRI>_confounds.tsv.gz) the name 
%      of a file with (compressed) tab-separated values. Each column 
%      corresponds to a "confound" effect. The confounds include: 
%      slow time drifts, motion parameters, ventricular and white matter
%      average, COMPCOR, global signal, FD, custom regressors.
%
%   COMPCOR_MASK
%      (string, default FOLDER_OUT/<base FMRI>_mask_compcor.<ext FMRI>) the 
%      name of a 3D file, with a binary volume of the voxels used for compcor
%      regression. 
%
% OPT 
%
%   FOLDER_OUT
%      (string, default folder of FMRI) the folder where the default outputs
%      are generated.
%
%   COMPCOR
%      (structure) the options of the COMPCOR method. See the OPT argument
%      of NIAK_COMPCOR.
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
% COMMENTS: 
%
% The estimator of the global average using PCA is described in the 
% following publication:
%
%   F. Carbonell, P. Bellec, A. Shmuel. Validation of a superposition model 
%   of global and system-specific resting state activity reveals anti-correlated 
%   networks. Brain Connectivity 2011 1(6): 496-510. doi:10.1089/brain.2011.0065
%
% For an overview of the regression steps as well as the "scrubbing" of 
% volumes with excessive motion, see:
%
%   J. D. Power, K. A. Barnes, Abraham Z. Snyder, B. L. Schlaggar, S. E. Petersen
%   Spurious but systematic correlations in functional connectivity MRI networks 
%   arise from subject motion
%   NeuroImage Volume 59, Issue 3, 1 February 2012, Pages 21422154
%
% For a description of the COMPCOR method:
%
%   Behzadi, Y., Restom, K., Liau, J., Liu, T. T., Aug. 2007. A component based 
%   noise correction method (CompCor) for BOLD and perfusion based fMRI. 
%   NeuroImage 37 (1), 90-101. http://dx.doi.org/10.1016/j.neuroimage.2007.04.042
% 
%   This other paper describes more accurately the COMPCOR implemented in NIAK:
%   Chai, X. J., Castan, A. N. N., Ongr, D., Whitfield-Gabrieli, S., Jan. 2012. 
%   Anticorrelations in resting state networks without global signal regression. 
%   NeuroImage 59 (2), 1420-1428. http://dx.doi.org/10.1016/j.neuroimage.2011.08.048

% Note that a maximum number of (# degrees of freedom)/2 are removed through compcor.
%
% Copyright (c) Christian L. Dansereau, Felix Carbonell, Pierre Bellec 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2012-2015
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pca, glm, confounds, motion parameters

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

%% FILES_IN
list_fields    = { 'fmri' , 'dc_low' , 'dc_high' , 'custom_param'    , 'motion_param' , 'mask_brain' , 'mask_vent' , 'mask_wm' };
list_defaults  = { NaN    , NaN      , NaN       , 'gb_niak_omitted' , NaN            , NaN          , NaN         , NaN       };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% FILES_OUT
list_fields    = { 'compcor_mask'    , 'confounds'       };
list_defaults  = { 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% OPTIONS
list_fields    = { 'compcor' , 'folder_out' , 'flag_verbose', 'flag_test' };
list_defaults  = { struct()  , ''           , true          , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

[path_f,name_f,ext_f] = niak_fileparts(files_in.fmri);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.confounds)
    files_out.confounds = cat(2,opt.folder_out,filesep,name_f,'_confounds.tsv.gz');
end

if isempty(files_out.compcor_mask)
    files_out.compcor_mask = cat(2,opt.folder_out,filesep,name_f,'_compcor_mask',ext_f);
end

if opt.flag_test 
    return
end

%% Read spatial inputs
if opt.flag_verbose
    fprintf('Reading the fMRI dataset ...\n%s\n',files_in.fmri);
end
[hdr_vol,vol] = niak_read_vol(files_in.fmri); % fMRI dataset
y = reshape(vol,[size(vol,1)*size(vol,2)*size(vol,3) size(vol,4)])'; % organize the fMRI dataset as a time x space array
mean_y = mean(y,1);
y = niak_normalize_tseries(y,'mean');

if opt.flag_verbose
    fprintf('Reading the brain mask ventricle ...\n%s\n',files_in.mask_vent);
end
[hdr_mask,mask_vent] = niak_read_vol(files_in.mask_vent); % mask of the ventricles

if opt.flag_verbose
    fprintf('Reading the brain mask ...\n%s\n',files_in.mask_brain);
end
[hdr_mask,mask_brain] = niak_read_vol(files_in.mask_brain); % mask of the brain
mask = mask_brain>0;

if opt.flag_verbose
    fprintf('Reading the white matter mask ...\n%s\n',files_in.mask_wm);
end
[hdr_mask,mask_wm] = niak_read_vol(files_in.mask_wm); % mask of the white matter

%% Motion parameters
if opt.flag_verbose
    fprintf('Adding motion parameters...\n')
end
labels = { 'motion_tx' 'motion_ty' 'motion_tz' 'motion_rx' 'motion_ry' 'motion_rz' };
transf = load(files_in.motion_param);
[rot,tsl] = niak_transf2param(transf.transf);
x = [tsl rot];

%% Scrubbing
if opt.flag_verbose
    fprintf('Adding frame displacement...\n')
end
rot_d = 50*(rot/360)*pi*2; % adjust rotation parameters to express them as a displacement for a typical distance from the center of 50 mm
rot_d = rot_d(:,2:end) - rot_d(:,1:(end-1));
tsl_d = tsl(:,2:end) - tsl(:,1:(end-1));
fd = sum(abs(rot_d)+abs(tsl_d),1)';
fd = [0;fd];
labels = [labels {'FD'}];
x = [x fd];

%% Add Time filter dc low
if opt.flag_verbose
    fprintf('Adding slow time drifts ...\n')
end
slow_drift = load(files_in.dc_low);
slow_drift = slow_drift.tseries_dc_low;
mask_i = std(slow_drift,[],1)~=0;
slow_drift = slow_drift(:,mask_i); % get rid of the intercept in the slow time drifts
x = [x slow_drift];
labels = [labels repmat({'slow_drift'},[1 size(slow_drift,2)])];

%% Add Time filter dc high
if opt.flag_verbose
    fprintf('Adding high frequencies ...\n')
end
high_freq = load(files_in.dc_high);
if ~isempty(high_freq.tseries_dc_high)
    high_freq = high_freq.tseries_dc_high;
else
    high_freq = zeros([size(x,1) 0]);
end
x = [x high_freq];
labels = [labels repmat({'high_freq'},[1 size(high_freq,2)])];

%% Add white matter average
if opt.flag_verbose
    fprintf('Adding white matter average ...\n')
end
wm_av = mean(y(:,mask_wm>0),2);
x = [x,wm_av];
labels = [labels {'wm_avg'}];

%% Add ventricular average
if opt.flag_verbose
    fprintf('Adding ventricular average ...\n')
end
vent_av = mean(y(:,mask_vent>0),2);
x = [x,vent_av];
labels = [labels {'vent_avg'}];

%% Add Global signal
if opt.flag_verbose
    fprintf('Generate a PCA-based estimation of the global signal ...\n')
end
pc_spatial_av = sub_pc_spatial_av(vol,mask);
x = [x pc_spatial_av];
labels = [labels {'global_signal_pca'}];

%% Add Compcor
if opt.flag_verbose
    fprintf('Adding COMPCOR...\n')
end
[x_comp,mask_comp] = niak_compcor(vol,opt.compcor,mask_wm|mask_vent);
nb_comp_max = floor((size(y,1)-size(x,2))/2);
x_comp = x_comp(:,1:min(size(x_comp,2),nb_comp_max));
x = [x x_comp];
labels = [ labels repmat({'compcor'},[1 size(x_comp,2)]) ];

%% Custom parameters 
if ~strcmp(files_in.custom_param,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Adding custom parameters ...\n')
    end
    covar = load(files_in.custom_param);
    if isfield(hdr,'extra')
        covar = covar.covar(~hdr.extra.mask_suppressed,:);
    else
        covar = covar.covar;
    end
    if ~isempty(covar) && (size(covar,1)==size(y,1))
        covar = niak_normalize_tseries(covar);
        x2 = [x2 covar];
        labels2 = [ labels2 repmat({'custom'},[1 size(covar,2)]) ];
    else
        error('The dimensions of the user-specified covariates are inappropriate (%i samples, functional datasets has %i time points)',size(covar,1),size(y,1))
    end
end

%% Save the COMPCOR mask
if ~strcmp(files_out.compcor_mask,'gb_niak_omitted')
    hdr_vol.file_name = files_out.compcor_mask;
    if isfield(hdr_vol,'extra')
        hdr_vol = rmfield(hdr_vol,'extra');
    end
    niak_write_vol(hdr_vol,mask_comp);
end

%% Save the confounds
if ~strcmp(files_out.confounds,'gb_niak_omitted')
    niak_write_csv_cell(files_out.confounds,[labels ; num2cell(x)]); 
end

%%%%%%%%%%%%%%%%%%
%% SUBFUNCTIONS %%
%%%%%%%%%%%%%%%%%%

function pc_spatial_av = sub_pc_spatial_av(vol,mask)
%% global signal estimation using a combination of the global average (target) and PCA (explanatory variables)
% Coded after:
% F. Carbonell, P. Bellec, A. Shmuel. Validation of a superposition model 
% of global and system-specific resting state activity reveals anti-correlated 
% networks.  To appear in Brain Connectivity.

% PCA
tseries = niak_vol2tseries(vol,mask);
[eigenvalues,eigenvariates,weights] = niak_pca(tseries');

% Spatial Average
spatial_av = niak_normalize_tseries(mean(tseries,2));
eigenvariates = niak_normalize_tseries(eigenvariates);

% Determine PC to be removed
r = (1/(length(spatial_av)-1))*(spatial_av'*eigenvariates);
[coeff_av,ind_pca] = max(abs(r));
pc_spatial_av  = eigenvariates(:,ind_pca);
pc_spatial_av = pc_spatial_av*sign((pc_spatial_av'*spatial_av));
