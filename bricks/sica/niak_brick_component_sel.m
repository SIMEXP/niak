function [files_in,files_out,opt] = niak_brick_component_sel(files_in,files_out,opt)
% Select independent components based on spatial priors.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SEL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN  
%    (structure) with the following fields :
%
%    FMRI 
%        (string) the original fMRI 3D+t data
%
%    COMPONENT 
%        (string) a 2D text array with the temporal distribution of sICA.
%
%    MASK 
%        (string) a path to a binary mask (the spatial a priori).
%
%    TRANSFORMATION 
%        (string, default 'gb_niak_omitted') a transformation file from 
%        the functional space to the mask space. If it is omitted, the
%        original mask will be used. If 'identity' is used, the mask
%        will be resampled at the resolution of the functional space,
%        but no actual transformation of the space will be applied.
%
%    COMPONENT_TO_KEEP
%        (string, default none) a text file, whose first line is a
%        a set of string labels, and each column is otherwise a temporal
%        component of interest. The ICA component with higher
%        correlation with each signal of interest will be automatically
%        attributed a selection score of 0.
%
% FILES_OUT 
%    (string, default <base COMPONENT>_<base MASK>_compsel.mat) The name
%    of a mat file with two variables SCORE and ORDER. SCORE(I) is the
%    selection score of component ORDER(I). Components are ranked by 
%    descending selection scores.
%
% OPT   
%    (structure) with the following fields :
%
%    NB_CLUSTER 
%        (default 0). The number of spatial clusters used in stepwise 
%        regression. If NB_CLUSTER == 0, the number of clusters is set 
%        to (nb_vox/10), where nb_vox is the number of voxels in the 
%        region.
%
%    P 
%        (real number, 0<P<1, default 0.0001) the p-value of the stepwise
%        regression.
%
%    NB_SAMPS 
%        (default 50) the number of kmeans repetition.
%
%    TYPE_SCORE 
%        (string, default 'freq') Score function. 'freq' for the
%        frequency of selection of the regressor and 'inertia' for the
%        relative part of inertia explained by the clusters "selecting"
%        the regressor.
%
%    FOLDER_OUT 
%        (string, default: path of FILES_IN.SPACE) If present,
%        all default outputs will be created in the folder FOLDER_OUT.
%        The folder needs to be created beforehand.
%
%    FLAG_VERBOSE 
%        (boolean, default 1) gives progression infos
%
%    FLAG_TEST 
%        (boolean, default 0) if FLAG_TEST equals 1, the
%        brick does not do anything but update the default
%        values in FILES_IN, FILES_OUT and OPT.
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
% This brick is using multiple functions from the SICA toolbox, developped
% by Vincent Perlbarg, LIF Inserm U678, Faculte de medecine
% Pitie-Salpetriere, Universite Pierre et Marie Curie, France.
% E-mail: Vincent.Perlbarg@imed.jussieu.fr
%
% _________________________________________________________________________
% REFERENCES
%
% Perlbarg, V., Bellec, P., Anton, J.-L., Pelegrini-Issac, P., Doyon, J. and 
% Benali, H.; CORSICA: correction of structured noise in fMRI by automatic
% identification of ICA components. Magnetic Resonance Imaging, Vol. 25,
% No. 1. (January 2007), pp. 35-46.
%
% MJ Mckeown, S Makeig, GG Brown, TP Jung, SS Kindermann, AJ Bell, TJ
% Sejnowski; Analysis of fMRI data by blind separation into independent
% spatial components. Hum Brain Mapp, Vol. 6, No. 3. (1998), pp. 160-188.
%
% _________________________________________________________________________
% SEE ALSO : 
% 
% NIAK_BRICK_SICA, NIAK_COMPONENT_SEL, NIAK_BRICK_COMPONENT_SUPP, NIAK_SICA
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : NIAK, ICA, CORSICA

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
niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SEL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_component_sel'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'component_to_keep','fmri','component','mask','transformation'};
gb_list_defaults = {'gb_niak_omitted',NaN,NaN,NaN,'gb_niak_omitted'};
niak_set_defaults

%% Output file
if ~ischar(files_out)
    error('FILES_OUT should be a string !');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'ww','nb_cluster','p','nb_samps','type_score','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {0,0,0.0001,50,'freq',1,0,''};
niak_set_defaults

%% Parsing the input names
[path_s,name_s,ext_s] = fileparts(files_in.component(1,:));
if isempty(path_s)
    path_s = '.';
end

if strcmp(ext_s,gb_niak_zip_ext)
    [tmp,name_s,ext_s] = fileparts(name_s);
    ext_s = cat(2,ext_s,gb_niak_zip_ext);
end

[path_m,name_m,ext_m] = fileparts(files_in.mask(1,:));
if isempty(path_m)
    path_m = '.';
end

if strcmp(ext_m,gb_niak_zip_ext)
    [tmp,name_m,ext_m] = fileparts(name_m);
    ext_m = cat(2,ext_m,gb_niak_zip_ext);
end

%% Setting up default output
if isempty(opt.folder_out)
    opt.folder_out = path_s;
end

if isempty(files_out)
    files_out = cat(2,opt.folder_out,filesep,name_s,'_',name_m,'_compsel.mat');
end

if ~strcmp(opt.type_score,'freq')&&~strcmp(opt.type_score,'inertia')
    error(sprintf('%s is an unknown score function type',opt.type_score));
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'Selection of ICA components using spatial priors';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n\n',stars,msg,stars);
end

%%%%%%%%%%%%%%%%%%%%
%% Reading inputs %%
%%%%%%%%%%%%%%%%%%%%

%% Read a table of components that need to be preserved
if ~strcmp(files_in.component_to_keep,'gb_niak_omitted')
    [XOI,labx,laby] = niak_read_tab(files_in.component_to_keep);
end

%% Mask of interest
if flag_verbose
    fprintf('Reading (and eventually resampling) the mask of interest ...\n');
end

[path_f,name_f,ext_f,flag_zip] = niak_fileparts(files_in.mask);
if flag_zip
    niak_gb_vars
    file_mask_tmp = niak_file_tmp(['_mask_roi.mnc' gb_niak_zip_ext]);
else
    file_mask_tmp = niak_file_tmp('_mask_roi.mnc');
end
switch files_in.transformation
    case 'identity'
        instr_res = sprintf('mincresample %s %s -clobber -like %s -nearest_neighbour',files_in.mask,file_mask_tmp,files_in.fmri);
    case 'gb_niak_omitted'
        instr_res = ['cp ' files_in.mask ' ' file_mask_tmp];
    otherwise
        instr_res = sprintf('mincresample %s %s -clobber -like %s -nearest_neighbour -transform %s -invert_transformation',files_in.mask,file_mask_tmp,files_in.fmri,files_in.transformation);
end

[succ,msg] = system(instr_res);
if succ~=0
    error(masg);
end
if flag_verbose
    fprintf('%s\n',msg)
else
    
end
[hdr_roi,mask_roi] = niak_read_vol(file_mask_tmp);
mask_roi = mask_roi>0.9;
delete(file_mask_tmp);


%% Extracting time series in the mask
if flag_verbose
    fprintf('Extracting time series in the mask ...\n');
end
[hdr_func,vol_func] = niak_read_vol(files_in.fmri);
mask_roi = mask_roi & niak_mask_brain(mean(abs(vol_func),4));
opt_tseries.flag_all = true;
tseries_roi = niak_build_tseries(vol_func,mask_roi,opt_tseries);
[nt,nb_vox] = size(tseries_roi);
clear vol_func
sigs{1} = niak_correct_mean_var(tseries_roi,'mean_var');

%% Temporal sica components
tmp = load(files_in.component);
A = tmp.tseries;
clear tmp
nb_comp = size(A,2);
tseries_ica = niak_correct_mean_var(A,'mean_var');

%% Identify the components of interest
if ~strcmp(files_in.component_to_keep,'gb_niak_omitted')
    if size(XOI,1)~=size(A,1)
        error('The components of interest should have as many time frames as the fMRI data (%i vs %i)!',size(XOI,1),size(A,1))
    end
    num_xoi = zeros([size(XOI,2) 1]);
    val_xoi = zeros([size(XOI,2) 1]);
    XOI = niak_correct_mean_var(XOI,'mean_var');
    coroi = (1/(size(A,1)-1))*XOI'*tseries_ica;
    
    for num_c = 1:size(XOI,2)
       [val_tmp,ind_tmp] = max(coroi(num_c,:));
       val_xoi(num_c) = val_tmp;
       num_xoi(num_c) = ind_tmp;
    end
else
    val_xoi = [];
    num_xoi = [];
end
       
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Stepwise regression %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Performing stepwise regression ...\n');
end

if nb_vox <= 20
    
    if flag_verbose
        fprintf('There is hardly any data falling in the mask of interest (%i voxels). No component is selected.\n',nb_vox);
    end
    %% There is no functional data in the mask, no component is selected...
    num_comp = 1:nb_comp;
    score = zeros(size(num_comp));
    order = 1:length(score);
    score = score(:);
    order = order(:);

else

    %% Selecting number of spatial classes
    if nb_cluster == 0
        nb_cluster = floor(nb_vox/10); % default value for the number of clusters.
        opt.nb_cluster = nb_cluster;
    end

    %% Computing score and score significance            
    [intersec,selecVector,selecInfo] = niak_component_sel(sigs,tseries_ica,opt.p,opt.nb_samps,opt.nb_cluster,opt.type_score,0,'on');

    %% Reordering scores
    for num_c = 1:length(val_xoi)
        if flag_verbose            
            fprintf('temporal ICA component %i has the highest correlation with the component of interest number %i (%1.3f). His initial selection score %1.3f is now set to 0.\n',num_xoi(num_c),num_c,val_xoi(num_c),selecVector(num_xoi(num_c)));
        end
        selecVector(num_xoi(num_c)) = 0;
    end
    [score,order] = sort(selecVector',1,'descend');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writting the results of component selection %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save(files_out,'score','order');