function [files_in,files_out,opt] = niak_brick_glm_fir(files_in,files_out,opt)
% Estimate the significance of a GLM test on FIR
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_FIR(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
% 
%   FIR.(SUBJECT)
%      (string) the name of a .mat file, which contains one variable FIR_ALL. 
%      FIR_ALL{N}(:,I,J) is the FIR of network I at trial J for subject <SUBJECT>
%      and the networks MASK{N}.
%
%   MASK.(NETWORK)
%      (string) the file name of a mask of brain networks -- 
%      network I is filled with Is, 0 is for the background. 
%
%   MODEL
%      (string) the name of a CSV file describing the covariates at the level of group. 
%      Example :
%                , SEX , HANDENESS
%      <SUBJECT> , 0   , 0
%      This type of file can be generated with Excel (save under CSV).
%      Each column defines a covariate that can be used in a linear model.
%      The labels <SUBJECT> have to be consistent with MODEL.SUBJECT and NETWORKS.TSERIES/FMRI
%      If omitted, the group model will only include the intercept.
%
% FILES_OUT.(NETWORK)
%   (structure) results based on FILES_IN.MASK.(NETWORK). Structure with
%   the following fields:
%
%   RESULTS
%      (string, default 'gb_niak_omitted') 
%      The name of a .mat file with the following matlab variables:
%
%      X
%          (matrix NxK) each column is a covariate of the model
%
%      Y
%         (matrix NxW) each row is a vectorized version of the FIR estimates
%         in all brain networks for one subject 
%
%      C
%         (vector Kx1) C(K) is the weight of MODEL(:,K)
%         in the contrast.
%
%      LABELS_SUBJECT
%         (cell of strings) LABELS_SUBJECT{N} is the label of
%         the subject associated with X(N,:)
%
%      LABELS_COVARIATE
%         (cell of strings) LABELS_COVARIATE{K} is the label of
%         the covariate associated with X(:,K)
%
%      BETA
%         (matrix KxW) BETA(K,:) is the vector of effects at each 
%         time sample/region for all covariates.
%
%      EFF
%         (matrix 1xW) estimate of the effect associated with the 
%         specified contrast at each time sample/region
%
%      STD_NOISE
%         (matrix 1xW) estimate of the standard deviation of noise
%         at each time sample/region.
%
%      TTEST
%         (matrix 1xW) A t-test for the significance of the contrast
%         at each time sample/region.
%
%      PCE 
%         (matrix 1*W) the per-comparison error associated with each t-test
%         against a bilateral hypothesis of BETA(w)=0.
%
%      FDR
%         (matrix T*R) FDR(t,r) is the false-discovery rate associated with 
%         PCE(t,r), where t is the time sample and r is a region. 
%         See OPT.TYPE_FDR for more info.
%
%      TEST_Q
%         (matrix T*R) TEST_Q(r,r) equals to 1 if the associated t-test is deemed 
%         significant as part of the family (map) r. TEST_Q(t,r) equals 0 otherwise.
%
%      PERC_DISCOVERY
%          (vector 1*R) PERC_DISCOVERY(r) is the percentage of discoveries in the FIR
%          associated with region r.
%
%   TTEST
%      (string, default 'gb_niak_omitted') the file name of a 4D dataset. 
%      TTEST(:,:,:,n) is the t-stat map associated with the n-th network.
%
%   EFFECT
%      (string, default 'gb_niak_omitted') the file name of a 4D dataset. 
%      EFFECT(:,:,:,n) is the effect map corresponding the TTEST(:,:,:,n).
%
%   STD_EFFECT
%      (string, default 'gb_niak_omitted') the file name of a 4D dataset. 
%      STD_EFFECT(:,:,:,n) is the map of standard deviation of the effect 
%      corresponding to TTEST(:,:,:,n).
%
%   FDR
%      (string, default 'gb_niak_omitted') the file name of a 4D dataset. 
%      FDR(:,:,:,n) is the t-stat map corresponding to TTEST. All the 
%      t-values associated with a global false-discovery rate below 
%      OPT.FDR are put to zero.
%
%   PERC_DISCOVERY
%      (string, default 'gb_niak_omitted') the file name of a 3D volume. 
%      PERC_DISCOVERY(:,:,:) is the map of the number of discovery 
%      associated with each network, expressed as a percentage of the 
%      number of networks - 1 (i.e. the max possible number of discoveries 
%      associated with a network).
%
% OPT           
%   (structure) with the following fields:
%
%   FDR
%      (scalar, default 0.05) the level of acceptable false-discovery rate 
%      for the t-maps.
%
%   TYPE_FDR
%      (string, default 'LSL') how the FDR is controled. 
%      Available options:
%         'BH': a BH procedure on the full set of FIR.
%         'LSL': a GBH procedure controlling the FDR on the full set of FIR
%             but using the grouping of tests per FIR, with a least-slope 
%             estimation of the number of discoveries. See NIAK_FDR.
%
%   TEST.<LABEL>
%      (stucture) with one entry and and one field and the following subfields:
%
%      CONTRAST
%         (structure, with arbitray fields <NAME>, which needs to correspond to the 
%         label of one column in the file FILES_IN.MODEL.GROUP) The fields found in 
%         CONTRAST will determine which covariates enter the model:
%
%         <NAME>
%            (scalar) the weight of the covariate NAME in the contrast.
% 
%      INTERACTION
%         (structure, optional) with multiple entries and the following fields :
%       
%         LABEL
%            (string) a label for the interaction covariate.
%
%         FACTOR
%            (cell of string) covariates that are being multiplied together to build the
%            interaction covariate. 
%
%         FLAG_NORMALIZE_INTER
%            (boolean,default true) if FLAG_NORMALIZE_INTER is true, the factor of interaction 
%            will be normalized to a zero mean and unit variance before the interaction is 
%            derived (independently of OPT.<LABEL>.GROUP.NORMALIZE below.
%
%      PROJECTION
%         (structure, optional) with multiple entries and the following fields :
%
%         SPACE
%            (cell of strings) a list of the covariates that define the space to project 
%            out from (i.e. the covariates in ORTHO, see below, will be projected 
%            in the space orthogonal to SPACE).
%
%         ORTHO
%            (cell of strings, default all the covariates except those in space) a list of 
%            the covariates to project in the space orthogonal to SPACE (see above).
%
%         FLAG_INTERCEPT
%            (boolean, default true) if the flag is true, add an intercept in SPACE (even 
%            when the model does not have an intercept).
%
%      NORMALIZE_X
%         (structure or boolean, default false) If a boolean and true, all covariates of the 
%         model are normalized to a zero mean and unit variance. If a structure, the 
%         fields <NAME> need to correspond to the label of a column in the 
%         file FILES_IN.MODEL.GROUP):
%
%         <NAME>
%            (arbitrary value) if <NAME> is present, then the covariate is normalized
%            to a zero mean and a unit variance. 
%
%      NORMALIZE_Y
%         (boolean, default true) If true, the data is corrected to a zero mean and unit variance,
%         in this case across subjects.
%
%      FLAG_INTERCEPT
%         (boolean, default true) if FLAG_INTERCEPT is true, a constant covariate will be
%         added to the model.
%
%      SELECT
%         (structure, optional) with multiple entries and the following fields:           
%
%         LABEL
%            (string) the covariate used to select entries *before normalization*
%
%         VALUES
%            (vector, default []) a list of values to select (if empty, all entries are retained).
%
%         MIN
%            (scalar, default []) only values higher (strictly) than MIN
%            are retained.
%
%         MAX
%            (scalar, default []) only values lower (strictly) than MAX are retained. 
%
%         OPERATION
%            (string, default 'or') the operation that is applied to select the frames.
%            Available options:
%            'or' : merge the current selection SELECT(E) with the result of the previous one.
%            'and' : intersect the current selection SELECT(E) with the result of the previous one.
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function 
%       prints some infos during the processing.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_FIR, NIAK_BRICK_FIR_TSERIES, NIAK_PIPELINE_GLM_FIR,
% NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : FIR, GLM

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
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FDR_FIR(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_fdr_fir'' for more info.')
end
   
%% Files in
list_fields   = {'fir' , 'mask' , 'model' };
list_defaults = {NaN   , NaN    , NaN     };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

if ~isstruct(files_in.fir)
    error('FILES_IN.FIR should be a structure');
end

if ~isstruct(files_in.mask)
    error('MASK should be a structure')
end
list_network = fieldnames(files_in.mask);

if ~ischar(files_in.model)
    error('FILES_IN.MODEL should be a string')
end

%% Files out
if ~isstruct(files_out)
    error('FILES_OUT should be a structure')
end
mask1 = ismember(list_network,fieldnames(files_out));
mask2 = ismember(fieldnames(files_out),list_network);
if any(~mask1) || any(~mask2)
    error('FILES_IN.MASK and FILES_OUT should have the same fields');
end

for nn = 1:length(list_network)
    network = list_network{nn};
    list_fields   = { 'results'         , 'ttest'           , 'effect'          , 'std_effect'      , 'fdr'             , 'perc_discovery'  };
    list_defaults = { 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
    files_out.(network) = psom_struct_defaults(files_out.(network),list_fields,list_defaults);
end

%% Options
list_fields   = { 'type_fdr'   , 'fdr' , 'test' , 'flag_verbose' , 'flag_test' };
list_defaults = { 'LSL'        , 0.05  , NaN    , true           ,   false     };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Test 
label = fieldnames(opt.test);
label = label{1};
def_contrast.intercept = 1;
list_fields   = { 'select' , 'contrast'   , 'projection' , 'flag_intercept' , 'interaction' , 'normalize_x' , 'normalize_y' };
list_defaults = { struct() , def_contrast , struct()     , true             , {}            , false         , false         };
opt.test.(label) = psom_struct_defaults(opt.test.(label),list_fields,list_defaults);

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Build the group model
if opt.flag_verbose
    fprintf('Reading the group model ...\n');
end
list_subject = fieldnames(files_in.fir);
[model_group.x,model_group.labels_x,model_group.labels_y] = niak_read_csv(files_in.model);
opt.test.(label).labels_x = list_subject;
model_group = niak_normalize_model(model_group, opt.test.(label));
list_subject = model_group.labels_x;
if isempty(list_subject)
    error('There was no usable subject with the specified parameters');
end
for nn = 1:length(list_network)
network = list_network{nn};

%% Read the FIR estimates
if opt.flag_verbose
    fprintf('Read the FIR estimates ...\n');
end
mask_ok = false(length(list_subject),1);
for num_e = 1:length(list_subject)    
    subject = list_subject{num_e};
    if ~isfield(files_in.fir,subject)
        warning('I could not find a FIR file associated with subject %s. I am skipping it.',subject)
        continue
    end    
    if opt.flag_verbose
        fprintf('    %s\n',files_in.fir.(subject))
    end
    data = load(files_in.fir.(subject),network);
    mask_ok(num_e) = any(abs(data.(network).fir_mean(:)));
    if ~mask_ok(num_e)
        warning('The FIR did not have the minimum number of trials required in OPT.NB_MIN_FIR. I am going to use the data from this subject.')
        continue
    end        
    if num_e == 1        
        fir_net = zeros([size(data.(network).fir_mean) length(list_subject)]);
    end
    fir_net(:,:,num_e) = data.(network).fir_mean;
end    
if any(mask_ok)
    fir_net = fir_net(:,:,mask_ok);
else
    fir_net = zeros(0,0,0);
end
[nt,nn,ne] = size(fir_net);
model_group.labels_x = model_group.labels_x(mask_ok);
model_group.x = model_group.x(mask_ok,:);
model_group.y = reshape(fir_net,[nt*nn ne])';
list_subject  = list_subject(mask_ok);

%% Read the partition
if opt.flag_verbose
    fprintf('Read the partition volume ...\n')
end
[hdr,vol_part] = niak_read_vol(files_in.mask.(network));

%% Estimate the group-level model
if opt.flag_verbose
   fprintf('Estimate model...\n')
end
opt_glm_gr.test  = 'ttest' ;
opt_glm_gr.flag_beta = true ; 
opt_glm_gr.flag_residuals = true ;
y_x_c.x = model_group.x;
y_x_c.y = model_group.y;
y_x_c.c = model_group.c; 
[results, opt_glm_gr] = niak_glm(y_x_c , opt_glm_gr);

%% Reformat the results of the group-level model
beta    =  results.beta; 
e       = results.e ;
std_e   = results.std_e ;
ttest   = results.ttest ;
pce     = results.pce ; 
eff     =  results.eff ;
std_eff =  results.std_eff ; 
ttest(isnan(pce)) = 0;
pce(isnan(pce)) = 1;
ttest = reshape (ttest,[nt nn]);
eff = reshape (eff,[nt nn]);
std_eff   = reshape (std_eff,[nt nn]);

%% Run the FDR estimation
q = opt.fdr;
[fdr,test_q] = sub_fdr(pce,opt.type_fdr,q,nt,nn);
nb_discovery = sum(test_q,1);
perc_discovery = nb_discovery/size(fdr,1);
if any(test_q(:))
    vol_discovery = sum(ttest(test_q(:)).^2);
else
    vol_discovery = max(ttest(:).^2);
end

%% Build volumes
if ~strcmp(files_out.(network).perc_discovery,'gb_niak_omitted')||~strcmp(files_out.(network).fdr,'gb_niak_omitted')||~strcmp(files_out.(network).effect,'gb_niak_omitted')||~strcmp(files_out.(network).std_effect,'gb_niak_omitted')
    if opt.flag_verbose
       fprintf('Generating volumes ...\n')
    end    
    nb_net = size(ttest,1);
    vol_part(vol_part>nb_net) = 0;
    t_maps   = zeros([size(vol_part) nt]);
    fdr_maps = zeros([size(vol_part) nt]);
    eff_maps = zeros([size(vol_part) nt]);
    std_maps = zeros([size(vol_part) nt]);
    for num_t = 1:nt
        t_maps(:,:,:,num_t)   = niak_part2vol(ttest(num_t,:)',vol_part);    
        eff_maps(:,:,:,num_t) = niak_part2vol(eff(num_t,:)',vol_part);
        std_maps(:,:,:,num_t) = niak_part2vol(std_eff(num_t,:)',vol_part);
        ttest_thre = ttest(num_t,:)';
        ttest_thre( ~test_q(num_t,:)' ) = 0;
        fdr_maps(:,:,:,num_t) = niak_part2vol(ttest_thre,vol_part);
    end
    discovery_maps = niak_part2vol(perc_discovery,vol_part);
end

% t-test maps
if ~strcmp(files_out.(network).ttest,'gb_niak_omitted')
    hdr.file_name = files_out.(network).ttest;
    niak_write_vol(hdr,t_maps);
end

% perc_discovery
if ~strcmp(files_out.(network).perc_discovery,'gb_niak_omitted')
    hdr.file_name = files_out.(network).perc_discovery;
    niak_write_vol(hdr,discovery_maps);
end

% FDR-thresholded t-test maps
if ~strcmp(files_out.(network).fdr,'gb_niak_omitted')
    hdr.file_name = files_out.(network).fdr;
    niak_write_vol(hdr,fdr_maps);
end

% effect maps
if ~strcmp(files_out.(network).effect,'gb_niak_omitted')
    hdr.file_name = files_out.(network).effect;
    niak_write_vol(hdr,eff_maps);
end

% std maps
if ~strcmp(files_out.(network).std_effect,'gb_niak_omitted')
    hdr.file_name = files_out.(network).std_effect;
    niak_write_vol(hdr,std_maps);
end

%% Save results in mat form
if ~strcmp(files_out.(network).results,'gb_niak_omitted')
    save(files_out.(network).results,'model_group','beta','eff','std_eff','ttest','pce','fdr','test_q','q','perc_discovery','nb_discovery','vol_discovery')
end
end

%%%%%%%
%% SUBFUNCTION
%%%%%%%
function [fdr,test_q] = sub_fdr(pce,type_fdr,q,nt,nn)

pce_m = reshape(pce,[nt nn]);

switch type_fdr
    case 'global'
        [fdr,test_q] = niak_fdr(pce(:),'BH',q);
        fdr = niak_lvec2mat(fdr');
        test_q = niak_lvec2mat(test_q',0);    
    case 'LSL'
        [fdr,test_q] = niak_fdr(pce_m,'LSL',q);    
    otherwise
        error('%s is an unknown procedure to control the FDR',type_fdr)
end
