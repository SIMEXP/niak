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
% This brick is based on the paper of f, Carbonel 2012 
%
% Copyright (c) Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
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
list_defaults  = { ''           , true          , true                , true     , true      , true             , false      , []       , true   , []         , []           , 0.95               };
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

%% Add Time filter dc high and low
[vol_dc_high] = load(files_in.dc_high);
if ~isempty(vol_dc_high.tseries_dc_high)
    
    if isempty(x)
        x = [vol_dc_high.tseries_dc_high];
    else
        x = [x,vol_dc_high.tseries_dc_high];
    end
    
end

[vol_dc_low]  = load(files_in.dc_low);
if ~isempty(vol_dc_low.tseries_dc_low)
    
    if isempty(x)
        x = [vol_dc_low.tseries_dc_low];
    else
        x = [x,vol_dc_low.tseries_dc_low];
    end
   
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
tmp_motion = [rot,tsl,rot.^2,tsl.^2];

if isempty(x)
    x = tmp_motion;
else
    x = [x,tmp_motion];
end   

corr_motion = corrcoef(tmp_motion);

[eig_val,eig_vec,weights] = niak_pca(tmp_motion');

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
    tmp_motion = eig_vec(:,pca_comp_selection);
end
    
if opt.flag_motion_params
    
    if isempty(x)
        x = tmp_motion;
    else
        x = [x,tmp_motion];
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
              
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regress confounds stage 1      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reshape y
y = reshape(vol,size(vol,4),size(vol,1)*size(vol,2)*size(vol,3));

%% Regress the confounds
if opt.flag_verbose
    fprintf('Regress the confounds stage 1 ...\n')
end

%% Normalized all x 

if ~isempty(x)
    
    x = (x - repmat(mean(x,1),size(x,1),1))./repmat(std(x,0,1),size(x,1),1);

    %% Add intercept
    x1 = [ones([size(x,1) 1])/sqrt(size(x,1)) x];

    [beta,e,std_e] = niak_lse(y,x1);

    y   = e;
    vol = reshape(e,size(vol));
    
end

% Init x
x = [];

%% Brain masking:

% Doing PCA
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
    x = [pc_spatial_av];
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regress confounds stage 2 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Regress the confounds
if opt.flag_verbose
    fprintf('Regress the confounds stage 2...\n')
end

%% Normalized all x
if ~isempty(x)
    x = (x - repmat(mean(x,1),size(x,1),1))./repmat(std(x,0,1),size(x,1),1);

    %% Add intercept
    x2 = [ones([size(x,1) 1])/sqrt(size(x,1)) x];

    [beta,e,std_e] = niak_lse(y,x2);

    vol_denoised = reshape(e,size(vol));
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

save(files_out.confounds,'eigenvariates','eigenvalues','pc_spatial_av','ind_pca','vol_dc_high.tseries_dc_high','vol_dc_low.tseries_dc_low', 'tmp_motion', 'custom_covar', 'pc_spatial_av', 'wm_av', 'corr_motion', 'opt', 'pca_comp_selection');


end