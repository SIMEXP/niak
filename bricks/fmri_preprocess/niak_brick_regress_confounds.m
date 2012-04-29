function [files_in,files_out,opt]=niak_brick_regress_confounds(files_in,files_out,opt)
% Regress slow time drifst, global signals, motion parameters
% "scrubbing" of time frames with excessive motion is also available.
%
% SYNTAX :
% NIAK_BRICK_REGRESS_CONFOUNDS(FILES_IN,FILES_OUT,OPT)
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
%   FILTERED_DATA 
%      (string, default FOLDER_OUT/<base FMRI>_cor.<ext FMRI>) the name 
%      of a 3D+t file. Same as FMRI with the confounds regressed out.
%
%   CONFOUNDS 
%      (string, default FOLDER_OUT/<base FMRI>_cor.mat) a .mat file with 
%      the covariates that were regressed out (X, LABELS for stage 1, 
%      including slow time drifts, motion parameters and white matter
%      average, and X2, LABELS2 for stage 2, including custom covariates
%      and global signal).
%
%   SCRUBBING
%      (string, default FOLDER_OUT/<base FMRI>_scrub.mat) a .mat file with 
%      the following variables:
%          MASK_SCRUB (vector of boolean): if MASK_SCRUB(I) is true, the 
%             volume #I is scrubbed.
%          FD (vector) FD(I) is the framewise displacement at volume I.
%          DVARS (vector) DVARS(I) is the mean squares variance
%             of residuals.
%
%   QC_SLOW_DRIFT 
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_slow_drift.<ext FMRI>) 
%      the name of a volume file with the f-test of the slow time drifts
%
%   QC_WM 
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_wm.<ext FMRI>)  
%      the name of a volume file with the f-test of the average white matter 
%      signal
%
%   QC_MOTION 
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_motion.<ext FMRI>)  
%      the name of a volume file with the f-test of the motion parameters 
%      (after PCA reduction).
%
%   QC_GSE 
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_gse.<ext FMRI>)  
%      the name of a volume file with the f-test of the global signal PCA
%      estimate.
%
%   QC_CUSTOM_PARAM
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_customparam.<ext FMRI>)  
%      the name of a volume with the f-test of the custom params
%
% OPT 
%
%   FOLDER_OUT
%      (string, default folder of FMRI) the folder where the default outputs
%      are generated.
%
%   FLAG_SLOW
%       (boolean, default true) turn on/off the correction of slow time drifts
%
%   FLAG_GSC 
%       (boolean, default true) turn on/off global signal correction
%
%   FLAG_MOTION_PARAMS 
%       (boolean, default false) turn on/off the removal of the 6 motion 
%       parameters + the square of 6 motion parameters.
%
%   FLAG_WM 
%       (boolean, default true) turn on/off the removal of the average 
%       white matter signal
%
%   FLAG_SCRUBBING
%       (boolean, default true) turn on/off the "scrubbing" of volumes with 
%       excessive motion.
%
%   THRE_FD
%       (scalar, default 0.5) the maximal acceptable framewise displacement 
%       after scrubbing.
%
%   THRE_DVARS
%       (scalar, default default ) the maximal acceptable mean squares variance
%       of residuals after scrubbing (expressed in % of baseline BOLD signal.
%       
%   PCT_VAR_EXPLAINED 
%       (boolean, default 0.95) the % of variance explained by the selected 
%       PCA components when reducing the dimensionality of motion parameters.
%
%   FLAG_PCA_MOTION 
%       (boolean, default true) turn on/off the PCA reduction of motion 
%       parameters.
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
% F. Carbonell, P. Bellec, A. Shmuel. Validation of a superposition model 
% of global and system-specific resting state activity reveals anti-correlated 
% networks.  To appear in Brain Connectivity.
%
% For an overview of the regression steps as well as the "scrubbing" of 
% volumes with excessive motion, see:
%
% J. D. Power, K. A. Barnes, Abraham Z. Snyder, B. L. Schlaggar, S. E. Petersen
% Spurious but systematic correlations in functional connectivity MRI networks 
% arise from subject motion
% NeuroImage Volume 59, Issue 3, 1 February 2012, Pages 2142–2154
%
% Copyright (c) Christian L. Dansereau, Felix Carbonell, Pierre Bellec 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2012
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
list_fields    = { 'fmri' , 'dc_low' , 'custom_param'    , 'motion_param' , 'mask_brain' , 'mask_vent' , 'mask_wm' };
list_defaults  = { NaN    , NaN      , 'gb_niak_omitted' , NaN            , NaN          , NaN         , NaN       };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% FILES_OUT
list_fields    = { 'scrubbing'       , 'confounds'       , 'filtered_data'   , 'qc_slow_drift'   , 'qc_wm'           , 'qc_motion'       , 'qc_custom_param'  , 'qc_gse'          };
list_defaults  = { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% OPTIONS
list_fields    = { 'flag_scrubbing' , 'thre_fd' , 'thre_dvars' , 'flag_slow' , 'folder_out' , 'flag_verbose', 'flag_motion_params', 'flag_wm', 'flag_gsc', 'flag_pca_motion', 'flag_test', 'pct_var_explained'};
list_defaults  = { true             , 0.5       , 0.5          , true        , ''           , true          , true                , true     , true      , true             , false      , 0.95               };
opt = psom_struct_defaults(opt,list_fields,list_defaults);


[path_f,name_f,ext_f] = niak_fileparts(files_in.fmri);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.confounds)
    files_out.confounds = cat(2,opt.folder_out,filesep,name_f,'_cor.mat');
end

if isempty(files_out.filtered_data)
    files_out.filtered_data = cat(2,opt.folder_out,filesep,name_f,'_cor',ext_f);
end

if isempty(files_out.qc_slow_drift)
    files_out.qc_slow_drift = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_slow_drift',ext_f);
end

if isempty(files_out.qc_wm)
    files_out.qc_wm = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_wm',ext_f);
end

if isempty(files_out.qc_motion)
    files_out.qc_motion = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_motion',ext_f);
end

if isempty(files_out.qc_custom_param)
    files_out.qc_custom_param = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_customparam',ext_f);
end

if isempty(files_out.qc_gse)
    files_out.qc_gse = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_gse',ext_f);
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

%% Initialization 
x = [];
labels = {};
opt_glm.flag_residuals = true;
opt_glm.test = 'none';

%% Add Time filter dc high and low
if opt.flag_verbose
    fprintf('Reading slow time drifts ...\n')
end
slow_drift = load(files_in.dc_low);
slow_drift = slow_drift.tseries_dc_low;
mask_i = std(slow_drift,[],1)~=0;
slow_drift = slow_drift(:,mask_i); % get rid of the intercept in the slow time drifts
if opt.flag_slow
    x = [x slow_drift];
    labels = [labels repmat({'slow_drift'},[1 size(slow_drift,2)])];
end

%% Motion parameters
if opt.flag_verbose
    fprintf('Reading (and reducing) the motion parameters ...\n')
end
transf = load(files_in.motion_param);
[rot,tsl] = niak_transf2param(transf.transf);
rot = niak_normalize_tseries(rot');
tsl = niak_normalize_tseries(tsl');
motion_param = [rot,tsl,rot.^2,tsl.^2];
if opt.flag_pca_motion
    [eig_val,motion_param] = niak_pca(motion_param',opt.pct_var_explained);
end
if opt.flag_motion_params
    x = [x motion_param];
    labels = [labels repmat({'motion'},[1 size(motion_param,2)])];
end

%% Add white matter average
if opt.flag_verbose
    fprintf('White matter average ...\n')
end
wm_av = mean(y(:,mask_wm>0),2);
if opt.flag_wm   
    x = [x,wm_av];
    labels = [labels {'wm_av'}];
end

%% Generate F-TEST maps for all components of the model for quality control purposes
hdr_qc = hdr_mask;
model.y = y;
model.x = niak_normalize_tseries([slow_drift motion_param wm_av]);
labels_all = [repmat({'slow_drift'},[1 size(slow_drift,2)]) repmat({'motion'},[1 size(motion_param,2)]) {'wm_av'}];
opt_qc.test ='ftest';

%% F-test slow drift
if ~strcmp(files_out.qc_slow_drift,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the slow time drifts ...\n')
    end
    model.c = ismember(labels_all,'slow_drift');
    if any(model.c)
        res = niak_glm(model,opt_qc);
        qc = reshape(res.ftest,size(mask_brain));
    else
        qc = zeros(size(mask_brain));
    end
    hdr_qc.file_name = files_out.qc_slow_drift;
    niak_write_vol(hdr_qc,qc);
end

%% F-test white matter
if ~strcmp(files_out.qc_wm,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the average signal in the white matter ...\n')
    end
    model.c = ismember(labels_all,'wm_av');
    res = niak_glm(model,opt_qc);
    hdr_qc.file_name = files_out.qc_wm;
    niak_write_vol(hdr_qc,reshape(res.ftest,size(mask_brain)));
end

%% F-test motion
if ~strcmp(files_out.qc_motion,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the motion parameters ...\n')
    end
    model.c = ismember(labels_all,'motion');
    res = niak_glm(model,opt_qc);
    hdr_qc.file_name = files_out.qc_motion;
    niak_write_vol(hdr_qc,reshape(res.ftest,size(mask_brain)));
end

%% Regress confounds stage 1 (slow time drifts, average WM, motion parameters)  
if ~isempty(x)
    if opt.flag_verbose
        fprintf('Regress the confounds stage 1 (slow time drifts, average WM, motion parameters) ...\n')
    end
    model.x = niak_normalize_tseries(x);
    res = niak_glm(model,opt_glm);
    y   = res.e;
    vol = reshape(y',size(vol));
end

%% Add Global signal
if opt.flag_verbose
    fprintf('Generate a PCA-based estimation of the global signal ...\n')
end
pc_spatial_av = sub_pc_spatial_av(vol,mask);

if opt.flag_gsc
    x2 = pc_spatial_av;
    labels2 = {'pc_spatial_av'};
else
    x2 = [];
    labels2 = {};
end

%% Custom parameters to be regressed
covar=[];
if ~strcmp(files_in.custom_param,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Regress custom parameters ...\n')
    end
    covar = load(files_in.custom_param);
    covar = covar.covar;
    model_covar.y = covar;
    model_covar.x = x;
    res = niak_glm(model_covar,opt_glm);
    covar = res.e;

    if ~isempty(covar) && (size(covar,1)==size(y,1))
        covar = niak_normalize_tseries(covar);
        x2 = [x2 covar];
        labels2 = [ labels2 repmat({'custom'},[1 size(covar,2)]) ];
    else
        error('The dimensions of the user-specified covariates are inappropriate (%i samples, functional datasets has %i time points)',size(covar,1),size(y,1))
    end
else
    covar = [];
end

%% F-TEST stage 2 (global signal + custom covariates)
model.y = y;
model.x = [pc_spatial_av covar];
labels_all2 = [ repmat({'pc_spatial_av'},[1 size(pc_spatial_av,2)]) repmat({'custom'},[1 size(covar,2)]) ];

%% The custom covariates
if ~strcmp(files_out.qc_custom_param,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the custom covariates ...\n')
    end
    model.c = ismember(labels_all2,'custom');
    if any(model.c)
        res = niak_glm(model,opt_qc);
        qc = reshape(res.ftest,size(mask_brain));
    else
        qc = zeros(size(mask_brain));
    end
    hdr_qc.file_name = files_out.qc_custom_param;
    niak_write_vol(hdr_qc,qc);
end

%% The global signal
if ~strcmp(files_out.qc_gse,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the global signal estimate ...\n')
    end
    model.c = ismember(labels_all2,'pc_spatial_av');
    res = niak_glm(model,opt_qc);
    hdr_qc.file_name = files_out.qc_gse;
    niak_write_vol(hdr_qc,reshape(res.ftest,size(mask_brain)));
end

%% Regress confounds stage 2 
if ~isempty(x2)
    if opt.flag_verbose
        fprintf('Regress the confounds stage 2 (global signal + custom covariates)...\n')
    end
    model.x=x2;
    res = niak_glm(model,opt_glm);
    y = res.e;
    y = y + repmat(mean_y,[size(y,1) 1]); % put the mean back in the time series
    vol_denoised = reshape(y',size(vol));
else
    % there is nothing to regress we put the input in the output
    y = y + repmat(mean_y,[size(y,1) 1]); % put the mean back in the time series
    vol_denoised = vol;
end

%% Scrubbing
if opt.flag_verbose
    fprintf('Scrubbing frames exhibiting large motion ...\n')
end
mask_e = mask;
mask_e(1,:,:) = false; % remove edge slices
mask_e(end,:,:) = false;
mask_e(:,1,:) = false;
mask_e(:,end,:) = false;
mask_e(:,:,1) = false;
mask_e(:,:,end) = false;
dvars = 100*sqrt(mean(((y(2:end,mask_e) - y(1:(end-1),mask_e))/median(median(y(:,mask_e)))).^2,2));
transf = load(files_in.motion_param);
[rot,tsl] = niak_transf2param(transf.transf);
rot_d = 50*(rot/360)*pi*2; % adjust rotation parameters to express them as a displacement for a typical distance from the center of 50 mm
rot_d = rot_d(:,2:end) - rot_d(:,1:(end-1));
tsl_d = tsl(:,2:end) - tsl(:,1:(end-1));
fd = sum(abs(rot_d)+abs(tsl_d),1)';
mask_scrubbing = false(size(y,1),1);
if opt.flag_scrubbing
    mask_scrubbing(2:end) = (fd>opt.thre_fd)&(dvars>opt.thre_dvars);
    vol_denoised = vol_denoised(:,~mask_scrubbing);
end

%% Save the fMRI dataset after regressing out the confounds
if ~strcmp(files_out.filtered_data,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Saving results in %s ...\n',files_out.filtered_data);
    end  
    hdr_vol.file_name = files_out.filtered_data;
    niak_write_vol(hdr_vol,vol_denoised);
end

%% Save the confounds
if ~strcmp(files_out.confounds,'gb_niak_omitted')
    save(files_out.confounds, 'x' , 'x2' , 'labels' , 'labels2');
end

%% Save the scrubbing parameters
if ~strcmp(files_out.scrubbing,'gb_niak_omitted')
    save(files_out.scrubbing,'mask_scrubbing','fd','dvars');
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
