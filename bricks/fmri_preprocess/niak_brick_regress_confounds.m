function [files_in,files_out,opt]=niak_brick_regress_confounds(files_in,files_out,opt)
% The function correct for various artefact global signal,motion and/or
% specific covariats specified by the user.
%
% SYNTAX :
% NIAK_BRICK_REGRESS_CONFOUNDS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% FILES_IN
%
%   FMRI (structure) the fmri time-series
%
%   DC_HIGH times series of the cosine bases to be removed
%
%   DC_LOW times series of the cosine bases to be removed
%
%
%   CUSTOM_PARAM (optional) take a .mat file with the variable 'covar'(TxK)
%
%   MOTION_PARAM (optional) voltera series
%
%   MASK_WM binary mask of the white matter
%
%   MASK_VENT binary mask of the ventricle
%
%   MASK_BRAIN binary mask of the brain
%
%   
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_OUT 
%    (structure, optional) 
%
%   FILTERED_DATA output data with the confounds regressed
%
%   CONFOUNDS .mat files with the counfouds regressed
%
%   QC_SLOWDRIFT output the f-test of the slow drift
%
%   QC_WM output the f-test of the average white matter signal
%
%   QC_MOTION output the f-test of the motion PCA components
%
%   QC_GSE output the f-test of the global signal
%
%   QC_CUSTOMPARAM output the f-test of the custom params
%
%
% _________________________________________________________________________
% OPT : 
%   FLAG_GSC (default, true) global signal correction
%
%   FLAG_MOTION_PARAMS (default, false) remove the 6 motion parameters +
%   the square of 6 motion parameters.
%
%   FLAG_WM (default, true) remove average white matter
%
%   FLAG_MOTIONPARAM (default, false) remove the 6 motion parameters
%
%   PCT_VAR_EXPLAINED (default, 0.95) the % of variance explained by the
%   selected pca components.
%
%   FLAG_PCA_MOTION (default, true) take the nb_motion_comp from the pca of
%   the motion parameters as the confounds
%
% _________________________________________________________________________
% COMMENTS : 
% This brick is based on the paper of Felix, Carbonel 2012 
%
% Copyright (c) Christian L. Dansereau, 2012.
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pca, glm, confounds, motion param

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

%% OPTIONS
list_fields    = { 'folder_out' , 'flag_verbose', 'flag_motion_params', 'flag_wm', 'flag_gsc', 'flag_pca_motion', 'flag_test', 'exclude', 'iscov', 'X_remove' , 'X_interest' , 'pct_var_explained'};
list_defaults  = { ''           , true          , false                , true     , true      , true             , false      , []       , true   , []         , []           , 0.95               };
opt = psom_struct_defaults(opt,list_fields,list_defaults);


%% FILES_OUT
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

if ~isfield(files_out,'qc_slowdrift') || isempty(files_out.qc_slowdrift)
    files_out.qc_slowdrift = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_slowdrift',ext_f);
end

if ~isfield(files_out,'qc_wm') || isempty(files_out.qc_wm)
    files_out.qc_wm = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_wm',ext_f);
end

if ~isfield(files_out,'qc_motion') || isempty(files_out.qc_motion)
    files_out.qc_motion = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_motion',ext_f);
end

if ~isfield(files_out,'qc_customparam') || isempty(files_out.qc_customparam)
    files_out.qc_customparam = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_customparam',ext_f);
end

if ~isfield(files_out,'qc_gse') || isempty(files_out.qc_gse)
    files_out.qc_gse = cat(2,opt.folder_out,filesep,'qc_',name_f,'_ftest_gse',ext_f);
end

if opt.flag_test 
    return
end


%% Open file_input:
[hdr_vol,vol] = niak_read_vol(files_in.fmri);

numframes = size(vol,4);
allpts = 1:numframes;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( allpts > 0);

if opt.flag_verbose
    fprintf('Reading the brain mask ventricle ...\n%s',files_in.mask_vent);
end
[hdr_mask,mask_vent] = niak_read_vol(files_in.mask_vent); 

if opt.flag_verbose
    fprintf('Reading the brain mask ...\n%s',files_in.mask_brain);
end
[hdr_mask,mask_brain] = niak_read_vol(files_in.mask_brain); 

mask = (mask_brain & ~mask_vent)>0;

[hdr_mask,mask_wm] = niak_read_vol(files_in.mask_wm); 



% Init x
x = [];

% reshape y
y = reshape(vol,size(vol,4),size(vol,1)*size(vol,2)*size(vol,3));

%% Add Time filter dc high and low
slow_drift = [];
[vol_dc_high] = load(files_in.dc_high);
if ~isempty(vol_dc_high.tseries_dc_high)
    
    if isempty(slow_drift)
        slow_drift = [vol_dc_high.tseries_dc_high];
    else
        slow_drift = [slow_drift,vol_dc_high.tseries_dc_high];
    end
    
end

[vol_dc_low]  = load(files_in.dc_low);
if ~isempty(vol_dc_low.tseries_dc_low)
    
    if isempty(slow_drift)
        slow_drift = [vol_dc_low.tseries_dc_low];
    else
        slow_drift = [slow_drift,vol_dc_low.tseries_dc_low];
    end
   
end

if isempty(x)
    x = slow_drift;
else
    x = [x,slow_drift];
end  


%% Motion parameters

if opt.flag_verbose
    fprintf('Regress motion parameters ...\n')
end

transf = load(files_in.motion_param);
[rot,tsl] = niak_transf2param(transf.transf);
% normalization
rot = (rot' -  repmat(mean(rot',1),size(rot',1),1))./repmat(std(rot',0,1),size(rot',1),1);
tsl = (tsl' -  repmat(mean(tsl',1),size(tsl',1),1))./repmat(std(tsl',0,1),size(tsl',1),1);
motion_param = [rot,tsl,rot.^2,tsl.^2];

corr_motion = corrcoef(motion_param);

[eig_val,eig_vec,weights] = niak_pca(motion_param');

% take pct_var_explained
thresh_var = opt.pct_var_explained*sum(eig_val);
tmp_selection=[];
for n_val=1:size(eig_val,1)
    if sum(eig_val(1:n_val)) >= thresh_var
        pca_comp_selection = 1:n_val;
        break;
    end   
end

% original_data = weights*eig_vec';
if opt.flag_pca_motion
    motion_pca = eig_vec(:,pca_comp_selection);
end
    
if opt.flag_motion_params
    if opt.flag_pca_motion
        conf_tmp = motion_pca;
    else
        conf_tmp = motion_param;
    end
    if isempty(x)
        x = conf_tmp;
    else
        x = [x,conf_tmp];
    end
end



%% Add  white matter average

for i=1:size(vol,4)
    temp = vol(:,:,:,i).*mask_wm;
    wm_av(i) = sum(temp(:));
end

wm_av = wm_av/sum(mask(:));
wm_av = wm_av(:);
wm_av = (wm_av - mean(wm_av))./std(wm_av);

if opt.flag_wm   
    if isempty(x)
        x = [wm_av];
    else
        x = [x,wm_av];
    end
end

%% QC F-TEST
% f-test slow drift
hdr_qc = hdr_mask;
opt_qc.test ='ftest';
model.y = y;

f_test_x = [wm_av,motion_pca,slow_drift];
n_p0 = size(slow_drift,2);

intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
model.x = [intercept, f_test_x];
model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
[results_sd,opt_qc]=niak_glm(model,opt_qc);

hdr_qc.file_name = files_out.qc_slowdrift;
niak_write_vol(hdr_qc,reshape(results_sd.ftest,size(mask_brain)));

% f-test white matter
f_test_x = [motion_pca,slow_drift,wm_av];
n_p0 = size(wm_av,2);

intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
model.x = [intercept, f_test_x];
model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
[results_wm,opt_qc]=niak_glm(model,opt_qc);

hdr_qc.file_name = files_out.qc_wm;
niak_write_vol(hdr_qc,reshape(results_wm.ftest,size(mask_brain)));

% f-test motion
f_test_x = [slow_drift,wm_av,motion_pca];
n_p0 = size(wm_av,2);

intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
model.x = [intercept, f_test_x];
model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
[results_motion,opt_qc]=niak_glm(model,opt_qc);

hdr_qc.file_name = files_out.qc_motion;
niak_write_vol(hdr_qc,reshape(results_motion.ftest,size(mask_brain)));

%% End F-TEST

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Regress confounds stage 1   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Regress the confounds
if opt.flag_verbose
    fprintf('Regress the confounds stage 1 ...\n')
end

%% Normalized all x 

if ~isempty(x)
    

    %% Add intercept
    x1 = [ones([size(x,1) 1])/sqrt(size(x,1)) x];
    clear model opt_glm;
%     [beta,e,std_e] = niak_lse(y,x1);
    model.y=y;
    model.x=x1;
    opt_glm.flag_residuals = true;
    [results1,opt_glm] = niak_glm(model,opt_glm);

    y   = results1.e;
    vol = reshape(y,size(vol));
    
end

% Init x
x = [];

%% Brain masking:

% Doing PCA

%% version of FELIX for the PCA
opt_pca.iscov = opt.iscov;

if isempty(opt.X_remove)
   opt_pca.X_remove = ones(numframes,1);
else
   opt_pca.X_remove = opt.X_remove;
end
if isempty(opt.X_interest)
   opt_pca.X_interest = eye(numframes);
else
   opt_pca.X_interest = opt.X_interest;
end
opt_pca.exclude = opt.exclude;

if opt.flag_verbose
    fprintf('Doing Principal Components Analysis ...\n');
end  
[eigenvariates,eigenvalues] = niak_pca_fmristat(vol,mask,opt_pca);

%% this is my proposition 
space = size(vol,1)*size(vol,2)*size(vol,3);
t_size = size(vol,4);
vol_matrix = reshape(vol,t_size,space);
mask_vec = reshape(mask,1,space);
[eig_val,eig_vec,weights] = niak_pca((vol_matrix.*repmat(mask_vec,t_size,1))');
%% end proposition

% Computing Spatial Average
tot = sum(mask(:));

for i=1:size(vol,4)
    temp = vol(:,:,:,i).*mask;
    spatial_av(i) = sum(temp(:));
end

spatial_av = spatial_av/tot;
spatial_av = spatial_av(:);

% Determining PC to be removed
Z = opt_pca.X_remove;
spatial_av_remove = spatial_av - Z*(pinv(Z)*spatial_av);
spatial_av_remove = spatial_av_remove(keep);
spatial_av_remove = spatial_av_remove/norm(spatial_av_remove);
% tmp = spatial_av_remove'*V;
tmp = spatial_av_remove'*eigenvariates;
r = tmp/(norm(spatial_av_remove));
[coeff_av,ind_pca] = max(abs(r));
pc_spatial_av  = eigenvariates(:,ind_pca);
pc_spatial_av = pc_spatial_av*sign((pc_spatial_av'*spatial_av_remove));



%% Add Global signal
if opt.flag_gsc
    if isempty(x)
        x = [pc_spatial_av];
    else
        x = [x,pc_spatial_av];
    end
end

%% Custom parameters to be regressed
custom_covar=[];
if isfield(files_in,'custom_params') && ~isempty(files_in.custom_params)
    if opt.flag_verbose
        fprintf('Regress custom parameters ...\n')
    end
    
    tmp = load(files_in.custom_params);
    covar = tmp.covar;
    
    if ~isempty(covar) && (size(covar,1)==size(x,1))
        custom_covar = (covar -  repmat(mean(covar,1),size(covar,1),1))./repmat(std(covar,0,1),size(covar,1),1);
        
        if isempty(x)
            x = [custom_covar];
        else
            x = [x,custom_covar];
        end
    else
        custom_covar = [];
              
    end
    
end

%% F-TEST
hdr_qc = hdr_mask;
opt_qc.test ='ftest';
model.y = y;

if isempty(custom_covar)
    % f-test global signal
    f_test_x = [pc_spatial_av];
    n_p0 = size(pc_spatial_av,2);

    intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
    model.x = [intercept, f_test_x];
    model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
    [results_gse,opt_qc]=niak_glm(model,opt_qc);

    hdr_qc.file_name = files_out.qc_gse;
    niak_write_vol(hdr_qc,reshape(results_gse.ftest,size(mask_brain)));
    
else

    % f-test global signal
    f_test_x = [custom_covar,pc_spatial_av];
    n_p0 = size(pc_spatial_av,2);

    intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
    model.x = [intercept, f_test_x];
    model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
    [results_gse,opt_qc]=niak_glm(model,opt_qc);

    hdr_qc.file_name = files_out.qc_gse;
    niak_write_vol(hdr_qc,reshape(results_gse.ftest,size(mask_brain)));
    
    % f-test custom params
    f_test_x = [pc_spatial_av,custom_covar];
    n_p0 = size(custom_covar,2);

    intercept = ones([size(f_test_x,1) 1])/sqrt(size(f_test_x,1));
    model.x = [intercept, f_test_x];
    model.c = [zeros(n_p0,size(model.x,2)-n_p0),eye(n_p0)];
    [results_customparam,opt_qc]=niak_glm(model,opt_qc);

    hdr_qc.file_name = files_out.qc_customparam;
    niak_write_vol(hdr_qc,reshape(results_customparam.ftest,size(mask_brain)));
end



%% End F-TEST

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regress confounds stage 2 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Regress the confounds
if opt.flag_verbose
    fprintf('Regress the confounds stage 2...\n')
end

if ~isempty(x)
  
    %% Add intercept
    x2 = [ones([size(x,1) 1])/sqrt(size(x,1)) x];
    clear model opt_glm;
    model.y=y;
    model.x=x2;
    opt_glm.flag_residuals = true;
    [results2,opt_glm] = niak_glm(model,opt_glm);

    y   = results2.e;
    vol_denoised = reshape(y,size(vol));
    
else
    % there is nothing to regress we put the input in the output
    vol_denoised = vol;
end

%% Save the result
if opt.flag_verbose
    fprintf('Saving results in %s ...\n',files_out.filtered_data);
end  
hdr_vol.file_name = files_out.filtered_data;
niak_write_vol(hdr_vol,vol_denoised);

save(files_out.confounds,'slow_drift', 'motion_param', 'motion_pca', 'wm_av', 'custom_covar', 'pc_spatial_av', 'corr_motion', 'pca_comp_selection', 'opt');


end