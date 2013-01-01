function [files_in,files_out,opt] = niak_brick_pve(files_in,files_out,opt)
% Partial volume estimation in brain MRI with TMCD method
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_PVE(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%   (structure) with the following fields :
%
%   VOL
%      (string) the file name of an T1-weighted MR volume.
%
%   MASK
%      (string) the file name of a binary mask of the brain.
%
%   SEGMENTATION
%      (string, default 'gb_niak_omitted') the file name of a crisp 
%      classification of the brain into cerebro-spinal fluid, grey matter 
%      and white matter. If omitted, this will be then generated based on a 
%      modified k-means described in Manjon et al. MRM 2008. This is quite 
%      robust and very fast. 
%
% FILES_OUT
%   (structure) with the following fields. 
%                       
%   PVE_WM
%      (string, default <FILES_IN.VOL>_PVE_WM.<EXT>) tissue fraction 
%      estimate for white matter.
%
%   PVE_GM
%      (string, default <FILES_IN.VOL>_PVE_GM.<EXT>) tissue fraction 
%      estimate for grey matter.
%
%   PVE_CSF
%      (string, default <FILES_IN.VOL>_PVE_CSF.<EXT>) tissue fraction 
%      estimate for cerebro-spinal fluid
%
%   PVE_DISC
%      (string, default <FILES_IN.VOL>_PVE_DISC.<EXT>) crisp segmentation
%      with PVE labels.
%
% OPT           
%   (structure) with the following fields:
%   
%   RAND_SEED
%      (scalar, default []) The specified value is used to seed the random
%      number generator with PSOM_SET_RAND_SEED. If left empty, no action
%      is taken.
%
%   BETA
%      (scalar, default 0.1) the regularization parameter.
%
%   CLASS_PARAMS
%      (cell array, default []) A cell array of the tissue class parameters.
%      If left empty, the parameters will be estimated.
%         class_params{1}.mu is the mean intensity of CSF
%         class_params{1}.var is the intensity variance of CSF
%         class_params{2}.mu is the mean intensity of GM
%         class_params{2}.var is the intensity variance of GM
%         class_params{3}.mu is the mean intensity of WM
%         class_params{3}.var is the intensity variance of WM
%
%   FLAG_VERBOSE 
%      (boolean, default: 1) If FLAG_VERBOSE == 1, write
%      messages indicating progress.
%
%   FLAG_TEST 
%      (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%      do anything but update the default values in FILES_IN, 
%      FILES_OUT and OPT.
%               
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_T1_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% The method is described in 
%   J. Tohka, A. Zijdenbos, and A. Evans. 
%   Fast and robust parameter estimation for statistical partial volume 
%   models in brain MRI. 
%   NeuroImage, 23(1):84 - 97, 2004. 
%
% Please cite this paper if you use the code
% 
% The incremental kmeans algorithm used to initialize the method (if the 
% segmented image is not given) is described in
%   J.V. Manjón,  J. Tohka , G. García-Martí, J. Carbonell-Caballero, 
%   J.J. Lull, L. Martí-Bonmatí and M. Robles.
%   Robust MRI Brain Tissue Parameter Estimation by Multistage Outlier 
%   Rejection. 
%   Magnetic Resonance in Medicine, 59:866 - 873, 2008. 
% Please cite additionally this paper if you use the incremental k-means 
%
% In FILES_OUT.PVE_DISC, label 0 is background
%                        label 1 is csf   
%                        label 2 is gm
%                        label 3 is wm
%                        label 4 is background/csf
%                        label 5 is csf/gm
%                        label 6 is gm/wm 
%
% (C) 2010 Jussi Tohka 
% Department of Signal Processing,
% Tampere University of Technology, Finland
% Maintainer: jussi.tohka at tut.fi , pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, T1, partial volume effect

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_PVE(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_nu_correct'' for more info.')
end

%% Input files
list_fields   = {'vol' , 'mask' , 'segmentation'    };
list_defaults = {NaN   , NaN    , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Output files 
list_fields   = { 'pve_wm'          , 'pve_gm'          , 'pve_csf'         , 'pve_disc'        };
list_defaults = { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
list_fields   = { 'rand_seed' , 'beta' , 'class_params' , 'flag_verbose' , 'flag_test' };
list_defaults = { []          , 0.1    , []             , true           , false       };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

%% Building default output names
[path_f,name_f,ext_f] = niak_fileparts(files_in.vol);

if isempty(files_out.pve_wm)
    files_out.pve_wm = [path_f,filesep,name_f,'_pve_wm',ext_f];
end

if isempty(files_out.pve_gm)
    files_out.pve_gm = [path_f,filesep,name_f,'_pve_gm',ext_f];
end

if isempty(files_out.pve_csf)
    files_out.pve_csf = [path_f,filesep,name_f,'_pve_csf',ext_f];
end

if isempty(files_out.pve_disc)
    files_out.pve_disc = [path_f,filesep,name_f,'_pve_disc',ext_f];
end

if opt.flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Verbose
if opt.flag_verbose
    msg = 'Estimation of partial volume effects';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);    
end

%% Read the T1 volume and the brain mask
[hdr,img] = niak_read_vol(files_in.vol);
[hdr,brain_mask] = niak_read_vol(files_in.mask);
brain_mask = brain_mask>0;
if ~strcmp(files_in.segmentation,'gb_niak_omitted')
    [hdr,tissue_class] = niak_read_vol(files_in.segmentation);
else
    tissue_class = [];
end

%% Run the PVE estimation
[tfe,pve_disc] = sub_pvemri(img,brain_mask,tissue_class,opt.class_params,hdr.info.voxel_size,opt.beta,opt.flag_verbose);

%% Write results
if opt.flag_verbose
    fprintf('Writing results ...\n')
end

if ~strcmp(files_out.pve_wm,'gb_niak_omitted')
    hdr.file_name = files_out.pve_wm;
    niak_write_vol(hdr,tfe.wm);
end

if ~strcmp(files_out.pve_gm,'gb_niak_omitted')
    hdr.file_name = files_out.pve_gm;
    niak_write_vol(hdr,tfe.gm);
end

if ~strcmp(files_out.pve_csf,'gb_niak_omitted')
    hdr.file_name = files_out.pve_csf;
    niak_write_vol(hdr,tfe.csf);
end

if ~strcmp(files_out.pve_disc,'gb_niak_omitted')
    hdr.file_name = files_out.pve_disc;
    niak_write_vol(hdr,pve_disc);
end

  % MAIN FUNCTION

  % *******************************************

  % Iterative conditional modes based MRF

  % *******************************************
% Input arguments  
%         img        : A 3D MRI image to be segmented. This should be corrected for intensity nonuniformities.
%   brain_mask       : A mask defining brain/non-brain voxels. Voxels outside the brain should have value 0 and voxels inside the brain should have value 1 
%  tissue_class      : A segmentation of the image into csf, gm, and wm. 
%                       csf should have label 1
%                       gm should have label 2 
%                       wm should have label 3
%                      If you don't have this, give an empty matrix (i.e. []). 
%                      This will be then generated based on a modified k-means described in Manjon et al. MRM 2008. 
%                      This is quite robust and very fast. 
%                      IMPORTANT: the implementation assumes T1-weighted data!!!  It is, however, easy to modify the method for other weightings. 
%  class_params      : A cell array of the tissue class parameters (optional)
%                      you can give also an empty matrix and the parameters will 
%                      be estimated for you 
%                      class_params{1}.mu is the mean intensity of CSF
%                      class_params{1}.var is the intensity variance of CSF
%                      class_params{2}.mu is the mean intensity of GM
%                      class_params{2}.var is the intensity variance of GM
%                      class_params{3}.mu is the mean intensity of WM
%                      class_params{3}.var is the intensity variance of WM
%  voxel_size        : Voxel size of the image, a 3 component vector (optional, defaults to [1 1 1])
%        beta        : regularization parameter (optional, defaults to 0.1)
%      Output 
%                    : tfe = tissue fraction estimate images for csf, gm, and wm 
%                    : pve_disc: Crisp segmentation with PVE labels

function [tfe,pve_disc] = sub_pvemri(img,brain_mask,tissue_class,class_params,voxel_size,beta,flag_verbose)

  tic

  if nargin < 3

    error('Too few input arguments'); 

    return   

  elseif nargin == 3

    class_params = [];	  

    voxel_size = [1 1 1];

    beta = 0.1;

  elseif nargin == 4	  

    voxel_size = [1 1 1];

    beta = 0.1;  

  elseif nargin == 5

    voxel_size = abs(voxel_size);	  

    voxel_size = voxel_size/min(voxel_size);

    beta = 0.1;

  else

    voxel_size = abs(voxel_size);	  

    voxel_size = voxel_size/min(voxel_size);

  end

  sz = size(img);

  brain_mask = (brain_mask > 0.5);

  % cutting the size of the image based on the brain mask

  lim(1,1) = 1;

  for i = 1:sz(1)

    if sum(sum(brain_mask(i,:,:))) == 0

      lim(1,1) = i;

    else

      break;

    end

  end  

  lim(1,2) = sz(1);

  for i = sz(1):(-1):1

    if sum(sum(brain_mask(i,:,:))) == 0

      lim(1,2) = i;

    else

      break;

    end

  end

  lim(2,1) = 1;

  for i = 1:sz(2)

    if sum(sum(brain_mask(:,i,:))) == 0

      lim(2,1) = i;

    else

      break;

    end

  end  

  lim(2,2) = sz(2);

  for i = sz(2):(-1):1

    if sum(sum(brain_mask(:,i,:))) == 0

      lim(2,2) = i;

    else

      break;

    end

  end

  lim(3,1) = 1;

  for i = 1:sz(3)

    if sum(sum(brain_mask(:,:,i))) == 0

      lim(3,1) = i;

    else

      break;

    end

  end  

  lim(3,2) = sz(3);

  for i = sz(3):(-1):1

    if sum(sum(brain_mask(:,:,i))) == 0

      lim(3,2) = i;

    else

      break;

    end

  end

  

  if isempty(class_params)

    if isempty(tissue_class) 

      if flag_verbose
          disp('generating hard segmentation using incremental k-means');
      end
      tissue_class = kmeansinc(img,brain_mask);

    end

    tissue_class = round(tissue_class);
 
    if flag_verbose
        disp('Estimating tissue class parameters');
    end
    class_params = estimate_parameters(img,brain_mask,tissue_class); 

  end

  % add background class

  class_params{4}.mu = 0;

  class_params{4}.var = 0.1*class_params{1}.var;
  
  if flag_verbose
      disp('Computing partial volume classification')
  end
  pve_disc = icm_trans(img,brain_mask,lim,beta,voxel_size,class_params,flag_verbose);

  % maximum likelihood based tissue fraction estimation

  if flag_verbose
      disp('Estimating tissue fractions');
  end
  tfe.csf = zeros(sz);

  tfe.gm = zeros(sz);

  tfe.wm = zeros(sz);

  ind = find(pve_disc(:) == 1);

  tfe.csf(ind) = 1;

  ind = find(pve_disc(:) == 2);

  tfe.gm(ind) = 1;

  ind = find(pve_disc(:) == 3);

  tfe.wm(ind) = 1;

  t = 0:0.01:1;

  ind = find(pve_disc(:) == 4); % the tissue class is CSF/backrgound

  tmpmu = t*class_params{1}.mu + (1 - t)*class_params{4}.mu;

  tmpvar = t.^2*class_params{1}.var + (1 - t).^2*class_params{4}.var;

  reg_term = log(tmpvar);

  for i = 1:length(ind)

    score = (img(ind(i)) - tmpmu).^2./tmpvar + reg_term;  

    [tmpval,tfe.csf(ind(i))] = min(score); 

    tfe.csf(ind(i)) =  (tfe.csf(ind(i)) - 1)/100;

  end

  

  ind = find(pve_disc(:) == 5); % the tissue class is CSF/GM

  tmpmu = t*class_params{1}.mu + (1 - t)*class_params{2}.mu;

  tmpvar = t.^2*class_params{1}.var + (1 - t).^2*class_params{2}.var;

  reg_term = log(tmpvar);

  for i = 1:length(ind)

    score = (img(ind(i)) - tmpmu).^2./tmpvar + reg_term;  

    [tmpval,tfe.csf(ind(i))] = min(score); 

    tfe.csf(ind(i)) =  (tfe.csf(ind(i)) - 1)/100;

    tfe.gm(ind(i)) = 1 - tfe.csf(ind(i));	    

  end

  

  ind = find(pve_disc(:) == 6); % the tissue class is GM/WM

  tmpmu = t*class_params{2}.mu + (1 - t)*class_params{3}.mu;

  tmpvar = t.^2*class_params{2}.var + (1 - t).^2*class_params{3}.var;

  reg_term = log(tmpvar);

  for i = 1:length(ind)

    score = (img(ind(i)) - tmpmu).^2./tmpvar + reg_term;  

    [tmpval,tfe.gm(ind(i))] = min(score); 

    tfe.gm(ind(i)) =  (tfe.gm(ind(i)) - 1)/100;

    tfe.wm(ind(i)) = 1 - tfe.gm(ind(i));	    

  end

  toc

  

  % SUBFUNCTIONS

  % *******************************************

  % Iterative conditional modes based MRF

  % *******************************************



function seg = icm_trans(img,brain_mask,lim,beta,voxel_size,class_params,flag_verbose)



 

  inter = [2   (-1) (-1) (-1)  1  (-1) (-1) 

          (-1)   2  (-1) (-1)  1    1  (-1)

          (-1) (-1)   2  (-1) (-1)  1    1

          (-1) (-1) (-1)   2  (-1) (-1)  1

           1    1   (-1) (-1) 2   (-1) (-1)

	  (-1)  1     1  (-1) (-1)  2  (-1)

	  (-1) (-1)   1    1  (-1) (-1)  2];

	

  d(:,:,2) = [ sqrt(voxel_size(1)^2 + voxel_size(2)^2)  voxel_size(2)   sqrt(voxel_size(1)^2 + voxel_size(2)^2)

               voxel_size(1)                               0             voxel_size(1) 

	       sqrt(voxel_size(1)^2 + voxel_size(2)^2)  voxel_size(2)   sqrt(voxel_size(1)^2 + voxel_size(2)^2)]; 

  d(:,:,1) = sqrt(d(:,:,2).*d(:,:,2) + voxel_size(3)^2);

  d(:,:,3) = d(:,:,1);

  d(2,2,2) = 0.1;

  d = 1./d;

  d(2,2,2) = 0;

  

  pve(4,1) = 4;   % remember that we need to have BG label, BG label is numbered 4 in class_params (but 1 in inter!)

  pve(4,2) = 1;  

  pve(5,1) = 1;

  pve(5,2) = 2;

  pve(6,1) = 2;

  pve(6,2) = 3;

  

  sz = size(img);

  % check the limits 

  seg = zeros(sz + 2); % this to simplify the icm if/when there are non-background voxels in the image boundaries 

  for i = 1:6  

    cvalpdf(:,:,:,i) = zeros(lim(:,2)' -lim(:,1)' + 1); 

  end

  for i = 1:3  

    cvalpdf(:,:,:,i) = (1/(sqrt(2*pi*class_params{i}.var)))*exp(-(img(lim(1,1):lim(1,2),lim(2,1):lim(2,2),lim(3,1):lim(3,2)) - class_params{i}.mu).^2/(2*class_params{i}.var));

  end

  for i = 1:3 

    mutmp(1) = class_params{pve(3 + i,1)}.mu;

    mutmp(2) = class_params{pve(3 + i,2)}.mu;

    vartmp(1) = class_params{pve(3 + i,1)}.var;

    vartmp(2) = class_params{pve(3 + i,2)}.var; 

    % t = 0

    cvalpdf(:,:,:,3 + i) =  cvalpdf(:,:,:,3 + i) + ...
        (1/40)*(1/sqrt(2*pi*(vartmp(2))))* ...
        exp(-(img(lim(1,1):lim(1,2),lim(2,1):lim(2,2),lim(3,1):lim(3,2)) - ...
        mutmp(2)).^2/(2*(vartmp(2))));

    % t = 1

    cvalpdf(:,:,:,3 + i) =  cvalpdf(:,:,:,3 + i) + ...
	 (1/40)*(1/sqrt(2*pi*(vartmp(1))))* ...
	 exp(-(img(lim(1,1):lim(1,2),lim(2,1):lim(2,2),lim(3,1):lim(3,2)) - mutmp(1)).^2/(2*(vartmp(1))));

    for t = 0.05:0.05:0.95

      cvalpdf(:,:,:,3 + i) =  cvalpdf(:,:,:,3 + i) + ...
	 (1/20)*(1/sqrt(2*pi*(t^2*vartmp(1) + (1 - t^2)*vartmp(2))))* ...
	 exp(-(img(lim(1,1):lim(1,2),lim(2,1):lim(2,2),lim(3,1):lim(3,2)) - t*mutmp(1) - (1 - ...
	 t)*mutmp(2)).^2/(2*(t^2*vartmp(1) + (1 - t^2)*vartmp(2))));

    end

  end 

  seglim = lim + 1;

  [tmp,seg(seglim(1,1):seglim(1,2),seglim(2,1):seglim(2,2),seglim(3,1):seglim(3,2))] = max(cvalpdf,[],4);

   seg(seglim(1,1):seglim(1,2),seglim(2,1):seglim(2,2),seglim(3,1):seglim(3,2)) ...
   	   = seg(seglim(1,1):seglim(1,2),seglim(2,1):seglim(2,2),seglim(3,1):seglim(3,2)).*brain_mask(lim(1,1):lim(1,2),lim(2,1):lim(2,2),lim(3,1):lim(3,2));



  % seg_init = seg;

  cval = zeros(6,1);

  d2 = [d(:) d(:) d(:) d(:) d(:) d(:)]; 

  changed = 0;

  for t = 1:50

    if flag_verbose
        disp(['ICM iteration ' num2str(t) ' Changes ' num2str(changed)]);  
    end
 

    changed = 0;

    for x = seglim(1,1):seglim(1,2)

      for y = seglim(2,1):seglim(2,2)

	for z = seglim(3,1):seglim(3,2)

	  if brain_mask(x - 1,y - 1,z - 1) > 0

	    seg_tmp = seg((x - 1):(x + 1),(y - 1):(y + 1),(z - 1):(z + 1)) + 1; 

            cval = squeeze(cvalpdf((x - seglim(1,1) + 1),(y - seglim(2,1) + 1),(z - seglim(3,1) + 1),:))'.*exp(beta*(sum(d2.*inter(seg_tmp(:),2:7))));

            [tmp,maxc] = max(cval);

            changed = changed + (maxc ~= seg(x,y,z));

            seg(x,y,z) = maxc;	       

	  end

        end	

      end  

    end

    if changed < 1

      break;

    end  

   

  end

  clear cvalpdf

  seg = seg(2:(sz(1) + 1), 2:(sz(2) + 1),2:(sz(3) + 1));

 

 % ******************************************************************** 

 % PARAMETER ESTIMATION

 % step 1: outlier detection 

 % step 2: parameter estimation using least trimmed squares 

 %         see P.J. Rousseeuw and A.M. Leroy: Robust Regression and Outlier Detection

 %             John Wiley & Sons 1987 for the O(Nlog(N)) algorithm

 % ********************************************************************

function class_params = estimate_parameters(img,brain_mask,tissue_class); 

  B = zeros(3,3,3);

  B(:,2,2) = 1;

  B(2,:,2) = 1;

  B(2,2,:) = 1;

  Belements = 7;

  imgmax = max(img(:));

  imgmin = min(img(:));

  range = (imgmax - imgmin)/(2^16);

  

  for i = 1:3

    % step 1

    XeB = convn(tissue_class == i,B,'same');

    ind = find((XeB(:) == Belements).*brain_mask(:)); 

   

    % step 2 

    data = sort(img(ind) + 2*range*rand(length(ind),1) - range); % adding minute amount of noise

    n = length(data);

    h = n - floor(n/2);

    h2 = floor(n/2);

    old_sum = sum(data(1:h));

    old_power_sum = sum(data(1:h).*data(1:h));

    loc = old_sum/h;

    score = old_power_sum - old_sum*loc;

    best_score = score;

    best_loc = loc;

   

    for j = 1:h2

      old_sum = old_sum - data(j) + data(h + j);

      loc = old_sum/h;

      old_power_sum = old_power_sum - data(j)*data(j) + data(h + j)*data(h + j);

      score = old_power_sum - old_sum*loc;

      if score < best_score

        best_score = score;

        best_loc = loc;

      end

    end  

    class_params{i}.mu = best_loc;

    scaled_data = (data - best_loc).*((h - 1)/best_score).*(data - best_loc);  

    medd = median(scaled_data);

    class_params{i}.var = (best_score/(h - 1))*(medd/0.45493642311957);

  end

   

   % *************************************************

   % Incremental k-means algorithm

   % ************************************************'

 

function tissue_class = kmeansinc(img,brain_mask);

    % compute gradient

     cimg = convn(img,ones(3,3,3)/27,'same');

     sz = size(img);

     gr_img = zeros(sz);

     gr_img(2:(sz(1) - 1),2:(sz(2) - 1),2:(sz(3) - 1)) = ...
       (cimg(3:sz(1),2:(sz(2) - 1),2:(sz(3) - 1)) - cimg(1:(sz(1) - 2),2:(sz(2) - 1),2:(sz(3) - 1))).^2 + ...  
       (cimg(2:(sz(1) - 1),3:(sz(2)),2:(sz(3) - 1)) - cimg(2:(sz(1) - 1),1:(sz(2) - 2),2:(sz(3) - 1))).^2 + ...
       (cimg(2:(sz(1) - 1),2:(sz(2) - 1),3:(sz(3))) - cimg(2:(sz(1) - 1),2:(sz(2) - 1),1:(sz(3) - 2))).^2;

     gr_img = sqrt(gr_img); 

     ind = find(brain_mask(:) > 0);

     mgr = sum(gr_img(ind))/length(ind);

     sgr = sqrt(sum((gr_img(ind) -mgr).^2)/(length(ind) - 1));

     

     ind = find((brain_mask(:) > 0) & (gr_img(:) < 2*sgr));

     data = img(ind); 

     imgmax = max(data);

     imgmin = min(data);

     delta = (imgmax - imgmin)/256;

     init = [(mean(data) - delta) (mean(data) + delta)];

     [c1,costfunctionvalue1] = kmeans1d(data,2,init,50);

     init = [(c1(1) - delta) (c1(1) + delta) c1(2)];

     [c2,costfunctionvalue2] = kmeans1d(data,3,init,50);

     init = [c1(1) (c1(2) - delta) (c1(2) + delta)];

     [c3,costfunctionvalue3] = kmeans1d(data,3,init,50);

     if costfunctionvalue2 < costfunctionvalue3 

       c = c2;

     else

       c = c3;	       

     end

     % check the consistency of the means   

     c = sort(c);

     % classify voxels

     for i = 1:3

       dist(:,i) = (img(:) - c(i)).^2;

     end

     [tmp,tissue_class] = min(dist,[],2);

     tissue_class = reshape(tissue_class,sz).*brain_mask; 

     

     

     

 function [cen,costfunctionvalue] = kmeans1d(data,k,init,max_iter);  

    % Start the algorithm

   iter = 0;

   changes = 1;

   n = length(data);

   cen = init;

   datalabels = zeros(n,1);

   while (iter < max_iter) && changes

     iter = iter + 1;

     old_datalabels = datalabels;

     % Compute the distances between cluster centres and datapoints

     for i = 1:k

       dist(:,i) = (data - cen(i)).^2;

     end

     % Label data points based on the nearest cluster centre

     [tmp,datalabels] = min(dist,[],2);

     % compute the cost function value

     costfunctionvalue = sum(tmp);

     % calculate the new cluster centres 

     for i = 1:k

       cen(i) = mean(data(find(datalabels == i)));

     end

     % study whether the labels have changed

     changes = sum(old_datalabels ~= datalabels);

   end

   for i = 1:k

     dist(:,i) = (data - cen(i)).^2;

   end

   [tmp,datalabels] = min(dist,[],2);

   % compute the cost function value

   costfunctionvalue = sum(tmp);

  

  
