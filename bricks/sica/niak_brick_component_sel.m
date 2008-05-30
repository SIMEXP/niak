function [files_in,files_out,opt] = niak_brick_component_sel(files_in,files_out,opt)

% Select independent components based on spatial priors.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SEL(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%
% FILES_IN  (structure) with the following fields :
%
%       FMRI (string) the original fMRI 3D+t data
%
%       COMPONENT (string) a 2D text array with the temporal distribution of
%               sICA.
%
%       MASK (string) a path to a binary mask (the spatial a priori).
%
%       TRANSFORMATION (string, default identity) a transformation from the
%           functional space to the mask space.
%
% FILES_OUT (structure)  with the following fields.  Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%       FIGURE (string, , default <base COMPONENT>_<base MASK>_fig_compsel.dat)
%           an eps figure showing the spatial distribution of the
%           components on axial slices after robust correction to a normal
%           distribution, as well as the time, spectral and time frequency
%           representation of the time component.
%
%       COMP_SEL (string, default <base COMPONENT>_<base MASK>_compsel.dat)
%           A text file. First column gives the numbers of the selected
%           components in the order of selection, and the second column
%           gives the score of selection.
%
% OPT   (structure) with the following fields :
%
%       NB_CLUSTER (default floor(nbvox/10), where nbvox is the number of 
%           voxels in the region). The number of clusters used in stepwise
%           regression.
%
%       P (real number, 0<P<1, default 0.0001) the p-value of the stepwise
%           regression.
%
%       NB_KMEANS (default 10) the number of repetition for kmeans clustering.
%
%       TYPE_SCORE (string, default 'freq') Score function. 'freq' for the
%           frequency of selection of the regressor and 'inertia' for the
%           relative part of inertia explained by the clusters "selecting"
%           the regressor.
%
%       THRESHOLD (default 0.15) the threshold of the scores to select the
%           components. value between 0 and 1. =-1 for automatic threshold
%           by Otsu algorithm.
%
%       FOLDER_OUT (string, default: path of FILES_IN.SPACE) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_VERBOSE (boolean, default 1) gives progression infos
%
%       FLAG_TEST (boolean, default 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN, FILES_OUT and OPT.
%
% OUTPUTS
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% COMMENTS
% This brick is using multiple functions from the SICA toolbox, developped
% by Vincent Perlbarg, LIF Inserm U678, Faculte de medecine
% Pitie-Salpetriere, Universite Pierre et Marie Curie, France.
% E-mail: Vincent.Perlbarg@imed.jussieu.fr
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : pipeline, niak, preprocessing, fMRI

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

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SEL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_component_sel'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','component','mask','transformation'};
gb_list_defaults = {NaN,NaN,NaN,NaN,'gb_niak_omitted'};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'comp_sel','figure'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'nb_cluster','p','nb_kmeans','type_score','threshold','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {0,0.001,'freq',0.15,10,1,0,''};
niak_set_defaults

%% Parsing the input names
[path_s,name_s,ext_s] = fileparts(files_in.component(1,:));
if isempty(path_s)
    path_s = '.';
end

if strcmp(ext_s,'.gz')
    [tmp,name_s,ext_s] = fileparts(name_s);
end

[path_m,name_m,ext_m] = fileparts(files_in.mask(1,:));
if isempty(path_m)
    path_m = '.';
end

if strcmp(ext_m,'.gz')
    [tmp,name_m,ext_m] = fileparts(name_m);
end

%% Setting up default output
if isempty(opt.folder_out)
    opt.folder_out = path_s;
end

if isempty(files_out.comp_sel)
    files_out.comp_sel = cat(2,opt.folder_out,filesep,name_s,'_',name_m,'_compsel.dat');
end

if isempty(files_out.figure)
    files_out.figure = cat(2,opt.folder_out,filesep,name_s,'_',name_m,'_fig_compsel.eps');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%
%% Reading inputs %%
%%%%%%%%%%%%%%%%%%%%

%% Mask of interest
if flag_verbose
    fprintf('Reading (and eventually resampling) the mask of interest ...\n');
end
if strcmp(files_in.transformation,'gb_niak_omitted');
    [hdr_roi,mask_roi] = niak_read_vol(files_in.mask);
    mask_roi = mask_roi>0;
else
    file_mask_tmp = niak_file_tmp('_mask_roi.mnc');
    instr_res = sprintf('mincresample %s %s -like %s -tricubic -transform %s -invert_transformation',files_in.mask,file_mask_tmp,files_in.fmri,files_in.transformation);
    if flag_verbose
        system(instr_res)
    else
        [succ,msg] = system(instr_res);
        if succ~=0
            error(masg);
        end
    end
    [hdr_roi,mask_roi] = niak_read_vol(file_mask_tmp);
    mask_roi = mask_roi>0.9;
    delete(file_mask_tmp);
end

%% Extracting time series in the mask
if flag_verbose
    fprintf('Extracting time series in the mask ...\n');
end
[hdr_func,vol_func] = niak_read_vol(files_in.fmri);
tseries_roi = niak_build_tseries(vol_func,mask_roi);
clear vol_func

%% Temporal sica components
A = load(files_in.component);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Stepwise regression %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n*********\nPerforming stepwise regression\n*********\n\n');
end

%% Correcting time series for mean and variances.
sigs{1} = niak_correct_mean_var(tseries_roi,'mean_var');
tseries_ica = niak_correct_mean_var(A,'mean_var');
clear A

%% Selecting number of classe
nbvox = size(sigs{1},2);

if nb_cluster == 0
    nb_cluster = floor(nbvox/10); % default value for the number of clusters.
    opt.nb_cluster = nb_cluster;
end

[intersec,selecVector,selecInfo] = st_automatic_selection(sigs,tseries_ica,opt.p,opt.nb_kmeans,opt.nb_cluster,opt.type_score,0,'off');

[A,B] = sort(selecVector);
sortS = A(end:-1:1);
num_comp = B(end:-1:1);

if threshold == -1
    threshold = sub_otsu_corsica(selecVector);
end

I = find(sortS>threshold);

% Building output structure

compSelInfo.numcomp = num_comp(I);
compSelInfo.score = selecVector;
compSelInfo.thres = sugThres;
compSelInfo.add = [];
compSelInfo.rem = [];

opt_comp_sel.scoreType = 'S3';
opt_comp_sel.win=[];
opt_comp_sel.tc_file=[];
opt_comp_sel.mask_file=mask_file;
opt_comp_sel.thres_p=[];

compSelInfo.date = datestr(now);
compSelInfo.name = strcat(opt_comp_sel.scoreType,'_',sicaName,'_',compSelInfo.date);
compSelInfo.label = 'N/A';
compSelInfo.opt_comp_sel = opt_comp_sel;

function sugThres = sub_otsu_corsica(SelecVecor)

%%%%%%%%%% suggested threshold using Otsu algorithm %%%%%%%%%%%%
[H,X] = hist(selecVector,floor(length(selecVector)/5));
H = H/sum(H);
ngr = length(H);
somme = sum((1:(ngr)).*H);
eps = 10^(-10);
seuil = 0;
smax = 0;
p = 0;
a = 0;
for i = 1:(ngr-1)
    a = a+(i)*H(i);
    p = p+H(i);
    s = somme*p-a;
    d = p*(1-p);
    if (d>=eps)
        s = s*s/d;
        if (s >= smax)
            smax = s;
            amax = a;
            pmax = p;
            seuil = i;
        end
    end
end
seuil = seuil-1;

if seuil > 0
    sugThres = X(seuil);
else
    sugThres = mean(selecVector);
end
sugThres = round(1000*sugThres)/1000;

