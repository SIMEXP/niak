function [files_in,files_out,opt]=niak_brick_regress_confounds(files_in,files_out,opt)
% Regress slow time drifst, global signals, motion parameters, etc
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
%   CUSTOM_PARAMS 
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
%   QC_SLOWDRIFT 
%      (string, default FOLDER_OUT/qc_<base FMRI>_ftest_slowdrift.<ext FMRI>) 
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
%   QC_CUSTOMPARAM
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
list_fields    = { 'fmri' , 'dc_low' , 'custom_params'   , 'motion_param' , 'mask_brain' , 'mask_vent' , 'mask_wm' };
list_defaults  = { NaN    , NaN      , 'gb_niak_omitted' , NaN            , NaN          , NaN         , NaN       };
%% FILES_OUT
list_fields    = { 'confounds'       , 'filtered_data'   , 'qc_slowdrift'    , 'qc_wm'           , 'qc_motion'       , 'qc_customparam'  , 'qc_gse'          };
list_defaults  = { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% OPTIONS
list_fields    = { 'flag_slow' , 'folder_out' , 'flag_verbose', 'flag_motion_params', 'flag_wm', 'flag_gsc', 'flag_pca_motion', 'flag_test', 'pct_var_explained'};
list_defaults  = { true        , ''           , true          , true                , true     , true      , true             , false      , 0.95               };
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

if isempty(files_out.qc_slowdrift)
    files_out.qc_slowdrift = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_slowdrift',ext_f);
end

if isempty(files_out.qc_wm)
    files_out.qc_wm = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_wm',ext_f);
end

if isempty(files_out.qc_motion)
    files_out.qc_motion = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_motion',ext_f);
end

if isempty(files_out.qc_customparam)
    files_out.qc_customparam = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_customparam',ext_f);
end

if isempty(files_out.qc_gse)
    files_out.qc_gse = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_gse',ext_f);
end

if opt.flag_test 
    return
end

%% Read spatial inputs
if opt.flag_verbose
    fprintf('Reading the fMRI dataset ...\n%s',files_in.fmri);
end
[hdr_vol,vol] = niak_read_vol(files_in.fmri); % fMRI dataset
y = reshape(vol,[size(vol,1)*size(vol,2)*size(vol,3) size(vol,4)])'; % organize the fMRI dataset as a time x space array

if opt.flag_verbose
    fprintf('Reading the brain mask ventricle ...\n%s',files_in.mask_vent);
end
[hdr_mask,mask_vent] = niak_read_vol(files_in.mask_vent); % mask of the ventricles

if opt.flag_verbose
    fprintf('Reading the brain mask ...\n%s',files_in.mask_brain);
end
[hdr_mask,mask_brain] = niak_read_vol(files_in.mask_brain); % mask of the brain
mask = (mask_brain & ~mask_vent)>0;

if opt.flag_verbose
    fprintf('Reading the white matter mask ...\n%s',files_in.mask_wm);
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
    labels = [labels repmat({'slowdrift'},[1 size(x,2)])];
end

%% Motion parameters
if opt.flag_verbose
    fprintf('Reading (and reducing) the motion parameters ...\n')
end
transf = load(files_in.motion_param);
[rot,tsl] = niak_transf2param(transf.transf);
rot = niak_normalize_tseries(rot')';
tsl = niak_normalize_tseries(tsl')';
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
model.y = niak_normalize_tseries(y);
model.x = niak_normalize_tseries([slow_drift motion_param wm_av]);
labels_all = [repmat({'slowdrift'},[1 size(x,2)]) repmat({'motion'},[1 size(motion_param,2)]) {'wm_av'}];
opt_qc.test ='ftest';

%% F-test slow drift
if ~strcmp(files_out.qc_slowdrift,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the slow time drifts ...\n')
    end
    opt_qc.c = ismember(labels_all,'slowdrift');
    if any(opt_qc.c)
        res = niak_glm(model,opt_qc);
        qc = reshape(res.ftest,size(mask_brain));
    else
        qc = zeros(size(mask_brain));
    end
    hdr_qc.file_name = files_out.qc_slowdrift;
    niak_write_vol(hdr_qc,qc);
end

%% F-test white matter
if ~strcmp(files_out.qc_wm,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the average signal in the white matter ...\n')
    end
    opt_qc.c = ismember(labels_all,'wm_av');
    res = niak_glm(model,opt_qc);
    hdr_qc.file_name = files_out.qc_wm;
    niak_write_vol(hdr_qc,reshape(res.ftest,size(mask_brain)));
end

%% F-test motion
if ~strcmp(files_out.qc_motion,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the motion parameters ...\n')
    end
    opt_qc.c = ismember(labels_all,'motion');
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
    y   = results1.e;
    vol = reshape(y',size(vol));
end

%% Add Global signal
if opt.flag_verbose
    fprintf('Generate a PCA-based estimation of the global signal ...\n')
end
pc_spatial_av = sub_pc_spatial_av(vol,mask);
model_pc.y = pc_spatial_av;
model_pc.x = x;
res = niak_glm(model_pc,opt_glm);
pc_spatial_av = res.e;

if opt.flag_gsc
    x2 = pc_spatial_av;
    labels2 = repmat({'pc_spatial_av'},[1 size(x2,2)]);
else
    x2 = [];
    labels2 = {};
end

%% Custom parameters to be regressed
custom_covar=[];
if ~strcmp(files_in.custom_params,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Regress custom parameters ...\n')
    end
    covar = load(files_in.custom_params);
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
model.x = [pc_spatial_av covar];
labels_all2 = [ repmat({'pc_spatial_av'},[1 size(pc_spatial_av,2)]) repmat({'custom'},[1 size(covar,2)]) ];

%% The custom covariates
if ~strcmp(files_out.qc_customparam,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the custom covariates ...\n')
    end
    opt_qc.c = ismember(labels_all2,'custom');
    if any(opt_qc.c)
        res = niak_glm(model,opt_qc);
        qc = reshape(res.ftest,size(mask_brain));
    else
        qc = zeros(size(mask_brain));
    end
    hdr_qc.file_name = files_out.qc_customparam;
    niak_write_vol(hdr_qc,qc);
end

%% The global signal
if ~strcmp(files_out.qc_gse,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Generate a F-test map for the global signal estimate ...\n')
    end
    opt_qc.c = ismember(labels_all2,'pc_spatial_av');
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
    opt_glm.flag_residuals = true;
    opt_glm.test = 'none';
    [results2,opt_glm] = niak_glm(model,opt_glm);
    y   = results2.e;
    vol_denoised = reshape(y',size(vol));
else
    % there is nothing to regress we put the input in the output
    vol_denoised = vol;
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