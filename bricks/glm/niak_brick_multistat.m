function [files_in,files_out,opt] = niak_brick_multistat(files_in,files_out,opt)

% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MULTISTAT
%
% Fits a mixed effects linear model.
%
% Combines effects (E) and their standard errors (S) using a linear mixed 
% effects model:     E = X b + e_fixed + e_random,     where
%    b is a vector of unknown coefficients,
%    e_fixed  is normal with mean zero, standard deviation S,
%    e_random is normal with mean zero, standard deviation sigma (unknown).
% The model is fitted by REML using the EM algorithm with NITER iterations.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MULTISTAT(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  FILES_IN  
%       (structure) with the following fields:
%
%       EF 
%         (cell array) of string filenames for the fmri effect files, the 
%         dependent variables.
%
%       SD
%         (cell array) of string filenames for the standard deviations of 
%         the dependent variables. If FILES_IN.SD=[], then FILES_IN.SD is 
%         assumed to be zero for all voxels, OPT.DF.DATA is set to Inf, 
%         and OPT.FWHM.VARATIO now smoothes the voxel sd.
%
%
%  FILES_OUT
%        (structure) of filenames with the following fields:
%
%        DF
%          The name a matlab file containing the variable DF
%
%        FWHM
%          The name a matlab file containing the variable FWHM
%
%        T 
%          The name an image file containing the T statistic image =ef/sd.
%
%        EF      
%          The name an image file containing the effect image for magnitudes.
%
%        SD      
%          The name an image file containing standard deviation of the effect 
%          for magnitudes. 
%
%        RFX     
%          The name an image file containing the ratio of random to fixed 
%          effects standard deviation. Note that rfx^2 is the F statistic 
%          for testing for random effects.
%
%        CONJ
%          The name an image file containing the conjunction (minimum) of 
%          the T statistics for the data, i.e. min(INPUT_FILES_EF/sd) using 
%          a mixed effects sd. 
%
%        RESID   
%          The name an image file containing the residuals from the model.
%
%        WRESID  
%          The name an image file containing the whitened residuals from 
%          the model normalized by dividing by their root sum of squares.
%
%  OPT   
%     (structure) with the following fields.
%     Note that if a field is omitted, it will be set to a default
%     value if possible, or will issue an error otherwise.
%
%     MATRIX_X 
%           is the design matrix, whose rows are the files, and columns
%           are the explanatory (independent) variables of interest. 
%           Default is X=[1; 1; 1; ..1] which just averages the files. 
%           If the rank of X equals the number of files, e.g. if X is square, 
%           then the random effects cannot be estinmated, but the fixed effects
%           sd's can be used for the standard error. This is done very quickly.
%
%     CONTRAST 
%           is a matrix whose rows are contrasts for the statistic images.
%           Default is [1 0 ... 0], i.e. it picks out the first column of X.
%
%     FWHM
%         (structure) with the following fields.
%
%         DATA
%            fwhm in mm of FILES_IN.EF. It is only used to calculate 
%            the degrees of freedom. If empty (default), it is 
%            estimated from the least-squares residuals, or it is read 
%            from FILES_IN.FWHM if available.
%
%         VARATIO
%            fwhm in mm of the Gaussian filter used to smooth the ratio
%            of the random effects variance divided by the fixed effects variance.
%            -0 will do no smoothing, and give a purely random effects analysis;
%            -Inf will do complete smoothing to a global ratio of one, giving a 
%            purely fixed effects analysis. 
%            The higher the FWHM.VARATIO, the higher the ultimate degrees of
%            freedom DF of the tstat image, and the more sensitive the test. 
%            However too much smoothing will bias the results. 
%            Alternatively, if FWHM.VARATIO is negative, it is taken as 
%            the desired df, and the fwhm is chosen to get as close to 
%            this as possible (if fwhm>50, fwhm=Inf). Default is -100, 
%            i.e. the fwhm is chosen to achieve 100 df.
%
%     DF 
%           (structure) with the following fields.
%
%           DATA
%               is the row vector of degrees of freedom of the input files.
%               If empty (default), these are read from FILES_IN.DF.
%
%           LIMIT
%               controls which method is used for estimating FWHM. 
%               If DF.RESID > DF.LIMIT, then the FWHM is calculated assuming 
%               the Gaussian filter is arbitrary. However if DF is small, 
%               this gives inaccurate results, so if DF.RESID <= DF.LIMIT, 
%               the FWHM is calculated assuming that the axes of the Gaussian 
%               filter are aligned with the x, y and z axes of the data. 
%               Default is 4.
%
%     NB_ITER
%             is the number of iterations of the EM algorithm. Default is 10.
%
%     FOLDER_OUT 
%           (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%     FLAG_VERBOSE 
%           (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%     FLAG_TEST 
%           (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% This function is a NIAKIFIED port of a part of the MULTISTAT function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, 2009.
%               Pierre Bellec, McConnell Brain Imaging Center, 2009.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MULTISTAT(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_multistat'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'ef','sd','df','fwhm'};
gb_list_defaults = {NaN,[],NaN,[]};
niak_set_defaults

if ~iscell(files_in.ef)
    error('niak_brick_multistat: FILES_IN.EF should be a cell array');
end

if ~iscell(files_in.df)
    error('niak_brick_multistat: FILES_IN.DF should be a cell array');
end

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'matrix_x','contrast','fwhm','df','nb_iter','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[],[],[],[],10,0,'',1};
niak_set_defaults

%% FILES_OUT
[path_f,name_f,ext_f] = fileparts(files_in.ef{1});

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end

if ~isfield(files_out,'df')
    full_name = cat(2,folder_f,filesep,name_f,'_df.mat');
    files_out = setfield(files_out,'df',full_name);
end

if ~isfield(files_out,'fwhm')
    full_name = cat(2,folder_f,filesep,name_f,'_fwhm.mat');
    files_out = setfield(files_out,'fwhm',full_name);
end

list_outputs = {'_t','_ef','_sd','_rfx','_conj','_resid','_wresid'};
for num_l = 1:length(list_outputs)
    field_name = lower(list_outputs{num_l}(2:end));
    if isfield(files_out,field_name)
       if isempty(getfield(files_out,field_name))
          full_name = cat(2,folder_f,filesep,name_f,list_outputs{num_l},'.mnc');
          files_out = setfield(files_out,field_name,full_name);
       end
    end
end

if flag_test 
    return
end

%% STATS OUTPUT
which_stats = '';

for num_l = 1:length(list_outputs)
    field_name = lower(list_outputs{num_l}(2:end));
    if isfield(files_out,field_name)
       which_stats = cat(2,which_stats,' ',list_outputs{num_l});
    end
end
if ~isempty(which_stats)
    which_stats(1) = [];
end

%% Open files_ef:
disp('Loading Data...')
nfiles = length(files_in.ef);
for i=1:nfiles
    [hdr,vol_i] = niak_read_vol(files_in.ef{i});
    vol.ef(:,:,:,i) = vol_i;
end
Steps = abs(hdr.info.voxel_size);
[nx,ny,nz] = size(vol_i);
numpix = nx*ny;

%% Open files_sd:
if isempty(files_in.sd)
    vol.sd = [];
else
   for i=1:nfiles
    [hdr,vol_i] = niak_read_vol(files_in.sd{i});
    vol.sd(:,:,:,i) = vol_i;
   end 
end

%% Auxiliary defaults:
matrix_x = opt.matrix_x;
if isempty(matrix_x); 
    matrix_x = ones(nfiles,1); 
end
contrast = opt.contrast;
if isempty(contrast)
    contrast = [1 zeros(1,size(matrix_x,2)-1)]; 
end
fwhm = opt.fwhm;
if isempty(fwhm)
    fwhm.varatio = -100;
end
if ~isfield(fwhm,'data')
    fwhm.data = [];
end

df = opt.df;
if isempty(df)
    df.data = [];
    df.limit = 4;
end
df.resid = nfiles-rank(matrix_x);

%% Open files_df:
if isempty(files_in.sd)
   df.data = Inf;
else
   if isempty(df.data)
      for i=1:nfiles
         d = load(files_in.df{i});
         df.data(i) = d.df.t(1); %% check ind_contrast
      end
   end
end

if length(df.data)==1
   df.data = ones(1,nfiles)*df.data;
end
df.fixed = sum(df.data);


%% Open files_fwhm:
if ~isempty(files_in.fwhm)
    for i=1:nfiles
        d = load(files_in.fwhm{i});
        fwhm.data(i) = d.fwhm.data;
    end
end
if ~isempty(fwhm.data)
    tmp = fwhm.data;
    fwhm.data = mean(tmp(tmp>0));
end

%% Start Computations:
disp('Starting Computations...')
opt_which.which_stats = which_stats;
opt_which.contrast = contrast;
opt_which = niak_make_multi_which_stats(opt_which);
which_stats = opt_which.which_stats;

if isempty(which_stats)
   disp(df.data)
   return
end

if df.resid>0
   % Degrees of freedom is greater than zero, so do mixed effects analysis:
   varatio_vol = zeros(numpix, nz);
   
   if fwhm.varatio<0
      % find fwhm to achieve target df:
      df_target = -fwhm.varatio;
      if df_target<=df.resid
         fwhm.varatio = 0;
      elseif df_target>=df.fixed
         fwhm.varatio = Inf;
      end
   end
   
   disp('Computing Variance Ratio...')
   if fwhm.varatio<Inf
      
      opt_var.matrix_x = matrix_x;
      opt_var.voxel_size = Steps;
      opt_var.df = df;
      opt_var.nb_iter = opt.nb_iter;
      [varatio_vol,opt_var] = niak_variance_ratio(vol,opt_var);
      fwhm.data  = opt_var.fwhm;
      fwhm.data 
      
      
      disp('Updating fwhm...')
      if fwhm.varatio<0
          % find fwhm to achieve target df:
          opt_upd.fwhm = fwhm;
          opt_upd.df = df;
          opt_upd.nb_slices = nz;
          opt_upd.voxel_size = Steps;
          opt_upd = niak_update_fwhm_varatio(opt_upd);
          fwhm = opt_upd.fwhm;
          if isinf(fwhm.varatio)
              varatio_vol=zeros(nx,ny,nz);
          end
      end
      disp('Regularizing df...')
      opt_reg.df = df;
      opt_reg.fwhm.varatio = fwhm.varatio;
      opt_reg.voxel_size = Steps;
      opt_reg.fwhm.data = fwhm.data;
      opt_reg.nb_slices = nz;
      opt_reg = niak_regularized_df(opt_reg);
      df = opt_reg.df;
      ker_x = opt_reg.ker_x;
      ker_y = opt_reg.ker_y;
      K = opt_reg.ker_z;
      df.rfx=round(df.rfx);
      df.t=round(df.t);
      if (fwhm.varatio>0) && (fwhm.varatio<Inf)
         varatio_vol = reshape(varatio_vol,[numpix,nz]);
         % Smoothing varatio in slice is done using conv2 with a kernel ker_xy.
         for slice=1:nz
            varatio_slice = reshape(varatio_vol(:,slice),nx,ny);
            varatio_vol(:,slice) = reshape(conv2(ker_x,ker_y,varatio_slice,'same'),numpix,1);
         end
         % Smoothing betwen slices is done by straight matrix multiplication
         % by a toeplitz matrix K normalized so that the column sums are 1.
         varatio_vol=varatio_vol*K;
      end
   else
      df.rfx = Inf;
      df.t = df.fixed;
   end
   
   disp('Doing a random effect analysis...')
   % Second loop over slices to get statistics:
   opt_rand.matrix_x  = matrix_x ;
   opt_rand.contrast = contrast;
   opt_rand.which_stats = which_stats;
   opt_rand.df = df;
   opt_rand.fwhm = fwhm;
   stats_vol = niak_multi_rand_glm(vol,varatio_vol,opt_rand);
   
else
   disp('Doing a fixed effect analysis...')
   % If degrees of freedom is zero, estimate effects by least squares,
   % and use the standard errors to estimate the sdeffect.
   opt_fix.matrix_x  = matrix_x ;
   opt_fix.contrast = contrast;
   opt_fix.which_stats = which_stats;
   opt_fix.df = df;
   [stats_vol,opt_fix] = niak_multi_fix_glm(vol,opt_fix);
   df = opt_fix.df;
end

%% Writing output files
disp('Writing outputs...')
if ~strcmp(files_out.df,'gb_niak_omitted');
    save(files_out.df,'df');
end

if ~strcmp(files_out.fwhm,'gb_niak_omitted');
    save(files_out.fwhm,'fwhm');
end

hdr = hdr(1);

if any(which_stats(:,1))
    if flag_verbose
        fprintf('Writing the t stats data in %s ...\n',files_out.t);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.t;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.t;
    opt_hist.comment = sprintf('T stats data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.t);
end

if any(which_stats(:,2))
    if flag_verbose
        fprintf('Writing the effects in %s ...\n',files_out.ef);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.ef;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.ef;
    opt_hist.comment = sprintf('Magnitude of effects data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.ef);
end

if any(which_stats(:,3))
    if flag_verbose
        fprintf('Writing the standard deviations of effects in %s ...\n',files_out.sd);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.sd;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.sd;
    opt_hist.comment = sprintf('Standard deviations of effects data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.sd);
end

if which_stats(1,4) && isfield(stats_vol,'rfx')
    if flag_verbose
        fprintf('Writing the residuals in %s ...\n',files_out.rfx);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.rfx;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.rfx;
    opt_hist.comment = sprintf('Rfx data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.rfx);
end

if which_stats(1,5)
    if flag_verbose
        fprintf('Writing the conjuntions in %s ...\n',files_out.conj);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.conj;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.conj;
    opt_hist.comment = sprintf('Conjuntions data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.conj);
end


if which_stats(1,6) && isfield(stats_vol,'resid')
    if flag_verbose
        fprintf('Writing the residuals in %s ...\n',files_out.resid);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.resid;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.resid;
    opt_hist.comment = sprintf('Residuals data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.resid);
end

if which_stats(1,7) && isfield(stats_vol,'wresid')
    if flag_verbose
        fprintf('Writing the whitened residuals in %s ...\n',files_out.wresid);
    end
    hdr_out = hdr;
    hdr_out.file_name = files_out.wresid;
    opt_hist.command = 'niak_brick_multistat';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.wresid;
    opt_hist.comment = sprintf('Whitened residuals data');
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,stats_vol.wresid);
end

clear stats_vol

