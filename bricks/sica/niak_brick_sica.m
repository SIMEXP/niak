function [files_in,files_out,opt] = niak_brick_sica(files_in,files_out,opt)
% Spatial independent component analysis (sICA) of an fMRI dataset.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%       FMRI
%          (string) the file name of an fMRI dataset.
%
%       MASK
%           (string, default 'gb_niak_omitted') the file name of a binary
%           mask of the brain. If omitted, it is computed using
%           NIAK_MASK_BRAIN.
%
%  FILES_OUT
%       (structure) with the following fields.  Note that if a field is an
%       empty string, a default value will be used to name the outputs.
%       If a field is ommited, the output won't be saved at all (this is
%       equivalent to setting up the output file names to
%       'gb_niak_omitted').
%
%       SPACE
%           (string, default <BASE_NAME>_sica_space.<EXT>)
%           a 3D+t dataset. Volume K is the spatial distribution of the Kth
%           source estimaed through ICA.
%
%       TIME
%           (string, default <BASE_NAME>_sica_time.mat)
%           a mat file with a variable TSERIES (2D array). TSERIES(:,K) is 
%           the temporal distribution of the Kth ICA source. 
%
%  OPT
%       (structure) with the following fields :
%
%       ALGO
%           (string, default 'Infomax')
%           the type of algorithm to be used for the sica decomposition.
%           Possible values : 'Infomax', 'Fastica-Def' or 'Fastica-Sym'.
%
%       NB_COMP
%           (integer, default min(60,foor(0.95*T)))
%           number of components to compute (for default : T is the number
%           of time samples.
%
%       FOLDER_OUT
%           (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then
%           the function prints some infos during the processing.
%
%       FLAG_TEST
%           (boolean, default 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Core of this function is copied from the fMRlab toolbox developed at
% Stanford :
% http://www-stat.stanford.edu/wavelab/Wavelab_850/index_wavelab850.html
% The code was mainly contributed by Scott Makeig under a GNU
% license. See subfunctions of NIAK_SICA for details. 
%
% The FastICA methods require the installation of the fastICA toolbox.
%
% _________________________________________________________________________
% REFERENCES:
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
% SEE ALSO:
% NIAK_COMPONENT_SEL, NIAK_BRICK_COMPONENT_SUPP, NIAK_SICA, 
% NIAK_PIPELINE_CORSICA, NIAK_BRICK_QC_CORSICA
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRI, ICA

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
niak_gb_vars; % Importing NIAK global variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_sica'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields    = {'fmri' , 'mask'            };
gb_list_defaults  = {NaN     , 'gb_niak_omitted' };
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields    = {'space'           , 'time'            };
gb_list_defaults  = {'gb_niak_omitted' , 'gb_niak_omitted' };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'norm' , 'algo'    , 'nb_comp' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {'mean' , 'Infomax' , 60        , 1              , 0           , ''           };
niak_set_defaults

[path_f,name_f,ext_f] = niak_fileparts(files_in.fmri);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.space)
    files_out.space = cat(2,opt.folder_out,filesep,name_f,'_sica_space',ext_f);
end

if isempty(files_out.time)
    files_out.time = cat(2,opt.folder_out,filesep,name_f,'_sica_time.mat');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    msg = 'Spatial independent component analysis';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading and pre-processing data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reading data
if flag_verbose
    fprintf('Reading data %s ...\n',files_in.fmri);
end
[hdr,vol] = niak_read_vol(files_in.fmri);

%% Segmenting the brain
if ~strcmp(files_in.mask,'gb_niak_omitted')
    if flag_verbose
        fprintf('Reading brain mask %s ...\n',files_in.mask);
    end
    [hdr,mask] = niak_read_vol(files_in.mask);
    mask = mask>0;
else    
    if flag_verbose
        fprintf('Brain segmentation ...\n');
    end
    mean_vol = mean(abs(vol),4);
    mask = niak_mask_brain(mean_vol);
    mask = mask & (mean_vol>0);
end

%% Reshaping data
[nx,ny,nz,nt]=size(vol);
vol = niak_vol2tseries(vol,mask);

%% Correcting the mean of the time series
if flag_verbose
    fprintf('Correction of the mean of time series ...\n');
end
opt_norm.type = 'mean';
vol = niak_normalize_tseries(vol,opt_norm);

%%%%%%%%%%%%%%%%%%%%%%
%% sica computation %%
%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Performing spatial independent component analysis with %i components, this might take a while ...\n',nb_comp);
end
opt_sica.algo = opt.algo;
opt_sica.param_nb_comp = min(nb_comp,floor(0.95*nt));
opt_sica.type_nb_comp = 0;
opt_sica.verbose = 'off';
res_ica = niak_sica(vol,opt_sica);
opt_sica.param_nb_comp = res_ica.nbcomp;

%%%%%%%%%%%%%%%%%%%%%%%%
%% Generating outputs %%
%%%%%%%%%%%%%%%%%%%%%%%%

%% Spatial sources
S = res_ica.composantes;
res_ica = rmfield(res_ica,'composantes');
vol_space = zeros([nx*ny*nz opt_sica.param_nb_comp]);
vol_space(mask>0,:) = S;
clear S
vol_space = reshape(vol_space,[nx ny nz opt_sica.param_nb_comp]);
if ~strcmp(files_out.space,'gb_niak_omitted')
    hdr.file_name = files_out.space;
    niak_write_vol(hdr,vol_space)
end

%% Temporal sources
if ~strcmp(files_out.time,'gb_niak_omitted')
    tseries = res_ica.poids;
    save(files_out.time,'tseries');
end

if flag_verbose
    fprintf('Done!\n');
end