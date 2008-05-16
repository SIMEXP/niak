function [files_in,files_out,opt] = niak_brick_sica(files_in,files_out,opt)

% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN  (string) an fMRI dataset.
%
% FILES_OUT (string, default <BASE_NAME>_sica.mat) a MAT file with a
%       spatial ICA decomposition. 
%
% OPT   (structure) with the following fields : 
%       
%       NORM (optional, default 'mean') 
%           Correction of the time series, possible values :
%           'mean' (correction to zero mean), 'mean_var' (correction
%           to zero mean and unit variance), 'mean_var2' (same
%           as 'mean_var' but slower, yet does not use as much memory).
%
%       ALGO (optional, default 'Infomax') 
%           the type of algorithm to be used for the sica decomposition.
%           Possible values : 'Infomax', 'Fastica-Def' or 'Fastica-Sym'.
%
%       NB_COMP (optional, default 50) 
%           number of components to compute
%
%       FOLDER_OUT (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%           the function prints some infos during the processing.
%
%       FLAG_TEST (boolean, default 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default 
%           values in FILES_IN, FILES_OUT and OPT.
%               
%
% OUTPUTS
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% COMMENTS:
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_sica'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'norm','algo','nb_comp','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {'mean','Infomax',50,1,0,''};
niak_set_defaults

%% Output files

[path_f,name_f,ext_f] = fileparts(files_in(1,:));
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

files_out = cat(2,opt.folder_out,filesep,name_f,'_sica.mat');

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading and pre-processing data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reading data
if flag_verbose
    fprintf('Reading data %s ...\n',files_in);
end
[hdr,vol] = niak_read_vol(files_in);

%% Segmenting the brain
if flag_verbose
    fprintf('Brain segmentation ...\n');
end
mean_vol = mean(abs(vol),4);
mask = niak_mask_brain(mean_vol);

%% Reshaping data
[nx,ny,nz,nt]=size(vol);
vol = reshape(vol,nx*ny*nz,nt);
vol = vol(mask>0,:)';

%% Correcting the mean (and possibly variance) of the time series
if flag_verbose
    fprintf('Correction of mean (possibly variance) of time series ...\n');
end
vol = niak_correct_mean_var(vol,opt.norm);

%%%%%%%%%%%%%%%%%%%%%%
%% sica computation %%
%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Performing spatial independent component analysis with %i components, this might take a while ...\n',nb_comp);
end
opt_sica.algo = opt.algo;
opt_sica.param_nb_comp = nb_comp;
opt_sica.type_nb_comp = 0;
opt_sica.verbose = 'off';
res_ica = st_do_sica(vol,opt_sica);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reformatting outputs %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
sica.S = res_ica.composantes;
res_ica = rmfield(res_ica,'composantes');
sica.A = res_ica.poids;
res_ica = rmfield(res_ica,'poids');
sica.nbcomp = res_ica.nbcomp;
sica.contrib = res_ica.contrib;
if isfield(res_ica,'residus')
    sica.residus = res_ica.residus;
end
clear res_ica
sica.TR = hdr.info.tr;
sica.mask = mask;
sica.data_name = files_in;
hdr(1).fname = '.';
sica.header = hdr;
sica.algo = opt.algo;
sica.detrend = 0;
sica.filter.high = -Inf;
sica.filter.low = Inf;
sica.slice_correction = 0;
sica.suppress_vol = [];
sica.type_norm = 2;
sica.className(1).name = 'N/A';
sica.className(1).color = [0.7 0.7 0.7];
sica.className(2).name = 'FAR';
sica.className(2).color = [1 0 0];
sica.className(3).name = 'FAR(t)';
sica.className(3).color = [1 0 0];
sica.className(4).name = 'FAR(o)';
sica.className(4).color = [1 0 0];
sica.className(5).name = 'PNR';
sica.className(5).color = [0 1 0];
sica.className(6).name = 'PNR(c)';
sica.className(6).color = [0 1 0];
sica.className(7).name = 'PNR(r)';
sica.className(7).color = [0 1 0];
sica.className(8).name = 'PNR(m)';
sica.className(8).color = [0 1 0];
sica.className(9).name = 'SAR';
sica.className(9).color = [1 1 0];
sica.className(10).name = 'SAR(a)';
sica.className(10).color = [1 1 0];
sica.className(11).name = 'SAR(d)';
sica.className(11).color = [1 1 0];
sica.labels = ones(1,sica.nbcomp);

%%%%%%%%%%%%%%%%%%%%
%% Saving outputs %%
%%%%%%%%%%%%%%%%%%%%
save(files_out,'sica');