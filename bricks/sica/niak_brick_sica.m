function [files_in,files_out,opt] = niak_brick_sica(files_in,files_out,opt)

% Compute a decomposition of an (individual) fMRI dataset into spatially 
% independent components.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN  (string) an fMRI dataset.
%
% FILES_OUT (structure) with the following fields.  Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted').
%
%       SPACE (string, default <BASE_NAME>_sica_space.mat)
%           a 3D+t dataset. Volume K is the spatial distribution of the Kth
%           source estimaed through ICA.
%
%       TIME (string, default <BASE_NAME>_sica_time.dat)
%           a text file. Column Kth is the temporal distribution of the Kth
%           ica source.
%
%       FIGURE (string, default <BASE_NAME>_sica_fig.pdf )
%           a pdf figure showing the spatial distribution of the
%           components on axial slices after robust correction to normal
%           distribution, as well as the time, spectral and time frequency
%           representation of the time component.
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
%       NB_COMP (optional, default min(60,foor(0.95*T)))
%           number of components to compute (for default : T is the number
%           of time samples.
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

niak_gb_vars; % Importing NIAK global variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_sica'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'norm','algo','nb_comp','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {'mean','Infomax',60,1,0,''};
niak_set_defaults

%% Output files
if ~isstruct(files_out)
    error('FILES_OUT should be a structure.');
end
gb_name_structure = 'files_out';
gb_list_fields = {'space','time','figure'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in(1,:));
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out.space)
    files_out.space = cat(2,opt.folder_out,filesep,name_f,'_sica_space',ext_f);
end

if isempty(files_out.time)
    files_out.time = cat(2,opt.folder_out,filesep,name_f,'_sica_time.dat');
end

if isempty(files_out.figure)
    files_out.figure = cat(2,opt.folder_out,filesep,name_f,'_sica_figure.pdf');
end

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
mask = mask & (mean_vol>0);

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
opt_sica.param_nb_comp = min(nb_comp,floor(0.95*nt));
opt_sica.type_nb_comp = 0;
opt_sica.verbose = 'off';
res_ica = st_do_sica(vol,opt_sica);

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
A = res_ica.poids;
res_ica = rmfield(res_ica,'poids');
if ~strcmp(files_out.time,'gb_niak_omitted')
    [hf,mesg] = fopen(files_out.time,'w');
    if hf == -1
        error(mesg);
    end
    for  num_l = 1:size(A,1)
        fprintf(hf,'%1.15f ',A(num_l,:));
        fprintf(hf,'\n');
    end
    fclose(hf)
end

if ~strcmp(files_out.figure,'gb_niak_omitted')

    %% Generating a temporary eps output
    file_fig_eps = niak_file_tmp('.eps');
    
    %% Options for the montage
    opt_visu.voxel_size = hdr.info.voxel_size;
    opt_visu.fwhm = max(hdr.info.voxel_size)*1.5;
    opt_visu.vol_limits = [0 3];
    opt_visu.type_slice = 'axial';
    opt_visu.type_color = 'jet';
    
    hf = figure;

    for num_c = 1:size(vol_space,4)

        vol_c = niak_correct_vol(vol_space(:,:,:,num_c),mask);
        niak_montage(abs(vol_c),opt_visu);
        title(sprintf('Spatial component %i, file %s',num_c,name_f));
        if num_c == 1
            print(hf,'-dpsc','-r300',file_fig_eps);
        else
            print(hf,'-dpsc','-r300','-append',file_fig_eps);
        end

        clf

        nt = size(A,1);

        %% temporal distribution
        subplot(3,1,1)
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                plot(hdr.info.tr*(1:nt),A(:,num_c));
            else
                plot(A(:,num_c));
            end
        else
            plot(A(:,num_c));
        end
                
        xlabel('time')
        ylabel('a.u.')
        title(sprintf('Time component %i, file %s',num_c,name_f));

        %% Frequency distribution
        subplot(3,1,2)
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                niak_visu_spectrum(A(:,num_c),hdr.info.tr);
            else
                niak_visu_spectrum(A(:,num_c),1);
            end
        else
            niak_visu_spectrum(A(:,num_c),1);
        end

        %% Time-frequency distribution
        subplot(3,1,3)
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                niak_visu_wft(A(:,num_c),hdr.info.tr);
            else
                niak_visu_wft(A(:,num_c),1);
            end
        else
            niak_visu_wft(A(:,num_c),1);
        end

        print(hf,'-dpsc','-r300','-append',file_fig_eps);

        clf

    end

    close(hf);
    
    instr_ps2pdf = cat(2,gb_niak_ps2pdf,' ',file_fig_eps,' ',files_out.figure);
    [succ,msg] = system(instr_ps2pdf);
    if succ~=0
        warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf : ',msg));
    end
    delete(file_fig_eps)
end