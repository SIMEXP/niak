function [files_in,files_out,opt] = niak_brick_component_supp(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_COMPONENT_SUPP
%
% Suppress some ica components from an fMRI dataset.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SUPP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUT
%
%  * FILES_IN  
%       (structure) with the following fields :
%
%       FMRI 
%           (string) 
%           the original fMRI 3D+t data
%
%       SPACE 
%           (string)
%           a 3D+t dataset. Volume K is the spatial distribution of the Kth
%           source estimaed through ICA.
%
%       TIME 
%           (string)
%           a text file. Column Kth is the temporal distribution of the Kth
%           ica source.
%
%       COMPSEL 
%           (cell of strings)
%           Each entry of COMPSEL is a file of component selection 
%           (see NIAK_BRICK_COMPONENT_SEL). It is a text file where the
%           first column is the number of the component, and optionally the
%           second column is a score.
%
%  * FILES_OUT 
%           (string, default <BASE FMRI>_p.<EXT FMRI>) 
%           file name for the fMRI data after component suppression.
%
%  * OPT   
%       (structure) with the following fields (any omitted field will be
%       set to default value if possible, and will produce an error
%       otherwise) :
%
%       THRESHOLD 
%           (scalar, default 0.15) 
%           a threshold to apply on the score for suppression (scores 
%           above the thresholds are selected). If the threshold is -Inf, 
%           all components will be suppressed. If the threshold is Inf, an 
%           adaptative method based on the Otsu algorithm will be applied 
%           to select the threshold automatically.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN.SPACE) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) gives progression infos
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS :
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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Importing important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMPONENT_SUPP(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_component_supp'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','space','time','compsel'};
gb_list_defaults = {NaN,NaN,NaN,NaN};
niak_set_defaults

%% Output file
if ~ischar(files_out)
    error('FILES_OUT should be a string !');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'threshold','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {0.15,1,0,''};
niak_set_defaults

%% Parsing the input names
[path_s,name_s,ext_s] = fileparts(files_in.fmri(1,:));
if isempty(path_s)
    path_s = '.';
end

if strcmp(ext_s,gb_niak_zip_ext)
    [tmp,name_s,ext_s] = fileparts(name_s);
    ext_s = cat(2,ext_s,gb_niak_zip_ext);
end

%% Setting up default output
if isempty(opt.folder_out)
    opt.folder_out = path_s;
end

if isempty(files_out)
    files_out = cat(2,opt.folder_out,filesep,name_s,'_p',ext_s);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Suppressing the selected components from the fMRI data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n***************\nSuppressing sica components\n***************\n');
end

%% Reading the list of components that need to be suppressed
list_supp = [];

for num_s = 1:length(files_in.compsel)
    mat_sel = load(files_in.compsel{num_s});
    comps = round(mat_sel(:,1));
    if size(mat_sel,2)>1
        score = mat_sel(:,2);
        comps = comps(score>threshold);
    end
    list_supp = union(list_supp,comps);
end

if flag_verbose
    fprintf('Components to be suppressed : %s',num2str(list_supp'))
    fprintf('\n')
end

%% Reading functional data, and space & time components
if flag_verbose
    fprintf('Reading functional data and sica results...\n')
end
[hdr_func,vol_func] = niak_read_vol(files_in.fmri);
[hdr_sica,vol_space] = niak_read_vol(files_in.space);
vec_time = load(files_in.time);

%% Reshaping the functional data in a time*space array
mask_brain = niak_mask_brain(mean(abs(vol_func),4));
[nx,ny,nz,nt] = size(vol_func);
tseries_func = reshape(vol_func,[nx*ny*nz nt]);
clear vol_func
tseries_func = tseries_func(mask_brain>0,:)';

%% Building the time*space array associated with the sica components
vec_space = reshape(vol_space,[nx*ny*nz size(vol_space,4)]);
clear vol_space
tseries_sica = vec_time(:,list_supp)*vec_space(mask_brain>0,list_supp)';

%% Removing the effect of sica component on fMRI data
if flag_verbose
    fprintf('Removing the effect of components ...\n')
end
vol_supp = zeros([nx*ny*nz nt]);
vol_supp(mask_brain>0,:) = (tseries_func-tseries_sica)';
vol_supp = reshape(vol_supp,[nx ny nz nt]);

%% Writting results
if flag_verbose
    fprintf('Writting results ...\n')
end
opt_hist.command = 'niak_brick_component_supp';
opt_hist.files_in = files_in;
opt_hist.files_out = files_out;

hdr_func = niak_set_history(hdr_func,opt_hist);
hdr_func.file_name = files_out;
niak_write_vol(hdr_func,vol_supp);