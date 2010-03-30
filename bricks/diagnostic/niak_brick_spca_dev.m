function [files_in,files_out,opt] = niak_brick_spca(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_SPCA
%
% Performs a spatial principal component analysis on a 3D+t dataset
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SPCA(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (structure) with the following fields :
%       
%       FMRI
%           (string) file name of a 3D+t dataset. See NIAK_READ_VOL for
%           supported formats
%
%       MASK
%           (string) file name of a binary mask of the voxels of interest.
%           If not specified, NIAK_MASK_BRAIN will be used to extract one.
%
%  * FILES_OUT 
%       (structure) with the following fields. Note that if a field
%       is left empty, the default name will be used. If a field is absent, 
%       the specified output will not be generated.
%
%       SPACE 
%           (string, default <BASE NAME>_pca_spat.<EXT>)
%           Output name for the spatial components (eigenvector)
%
%       TIME
%           (string, default <BASE NAME>_pca_temp.dat)
%           Output name for the temporal components (temporal weights of the
%           eigenvectors);
%
%       VARIANCE 
%           (string, default <BASE NAME>_pca_var.dat)
%           The relative distribution of the energy in the PCA basis
%
%       FIGURE 
%           (string, default <BASE_NAME>_pca_fig.pdf )
%           a pdf figure showing the spatial distribution of the
%           components on axial slices after robust correction to normal
%           distribution, as well as the time, spectral and time frequency
%           representation of the time component.
%
%  * OPT           
%       (structure) with the following fields.  
%       NB_COMP 
%           (real number, default rank of TSERIES) 
%           If NB_COMP is comprised between 0 and 1, NB_COMP is assumed to 
%           be the percentage of the total variance that needs to be kept.
%           If NB_COMP is an integer, greater than 1, NB_COMP is the number 
%           of components that will be generated (the procedure always 
%           consider the principal components ranked according to the energy 
%           they explain in the data. 
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_AUTOCORRELATION, NIAK_PCA
%
% _________________________________________________________________________
% COMMENTS:
%
% The PCA is applied on the spatial euclidian product matrix in a mask of the
% brain after correction of the fMRI time series to a zero temporal mean 
% and unit variance.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_DIFF_VARIANCE(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_diff_variance'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'nb_comp','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[],0,'',1};
niak_set_defaults

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','mask'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'space','time','variance','figure'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

[path_f,name_f,ext_f] = fileparts(files_in);
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

%% Building default output names
if isempty(files_out.space)
    files_out.space = cat(2,opt.folder_out,filesep,name_f,'_pca_spat',ext_f);
end

if isempty(files_out.time)
    files_out.time = cat(2,opt.folder_out,filesep,name_f,'_pca_temp.dat');
end

if isempty(files_out.variance)
    files_out.variance = cat(2,opt.folder_out,filesep,name_f,'_pca_var.dat');
end

if isempty(files_out.figure)
    files_out.figure = cat(2,opt.folder_out,filesep,name_f,'_pca_fig.pdf');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Starting the PCA brick %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('_______________________________________\n\nSpatial principal component analysis of file %s\n_______________________________________\n',files_in);
end

%% Reading data
if flag_verbose
    fprintf('\n Reading fMRI data ...\n')
end
[hdr,vol] = niak_read_vol(files_in);

%% Brain mask
if ~strcmp(files_in.mask,'gb_niak_omitted')
    if flag_verbose
        fprintf('\n Extracting brain mask ...\n')
    end
    mask = niak_mask_brain(mean(abs(vol),4));
else
    [hdr_mask,mask] = niak_read_vol(files_in.mask);
    mask = round(mask)>0;
end

%% Correcting time series for mean and variance
if flag_verbose
    fprintf('\n Correction of the time series to zero mean and unit variance ...\n')
end
[nx,ny,nz,nt] = size(vol);
vol = reshape(vol,[nx*ny*nz nt]);
tseries = vol(mask,:)';
tseries = niak_correct_mean_var(tseries,'mean_var');

%% PCA !
if flag_verbose
    fprintf('\n Computing the principal components ...\n')
end

if isempty(nb_comp)
    [eig_val,eig_vec,weights] = niak_pca(tseries');
else
    [eig_val,eig_vec,weights] = niak_pca(tseries',nb_comp);
end

%% Saving the spatial components
if ~strcmp(files_out.space,'gb_niak_omitted')
    if flag_verbose
        fprintf('\n Saving the spatial components ...\n')
    end
    vol_space = zeros([nx*ny*nz length(eig_val)]);
    vol_space(mask,:) = weights;
    vol_space = reshape(vol_space,[nx ny nz length(eig_val)]);
    hdr.file_name = files_out.space;
    niak_write_vol(hdr,vol_space);
end

if ~strcmp(files_out.time,'gb_niak_omitted')
    if flag_verbose
        fprintf('\n Saving the temporal components ...\n')
    end

    [hf,mesg] = fopen(files_out.time,'w');
    if hf == -1
        error(mesg);
    end
    for  num_c = 1:size(eig_vec,2)
        fprintf(hf,'%1.15f ',eig_vec(:,num_c)');
        fprintf(hf,'\n');
    end
    fclose(hf);
end

if ~strcmp(files_out.variance,'gb_niak_omitted')
    if flag_verbose
        fprintf('\n Saving the relative variance explained by components ...\n')
    end

    var_pca = eig_val/sum(eig_val);
    laby = {'num_comp','perc_variance'};
    niak_write_tab(files_out.variance,[(1:length(var_pca))' var_pca],'',laby);
end

if ~strcmp(files_out.figure,'gb_niak_omitted')

    if flag_verbose
        fprintf('\n Saving a pdf summary of the analysis ...\n')
    end

    %% Generating a temporary eps output
    file_fig_eps = niak_file_tmp('.eps');
    
    %% Options for the montage
    opt_visu.voxel_size = hdr.info.voxel_size;
    opt_visu.fwhm = max(hdr.info.voxel_size)*1.5;
    opt_visu.vol_limits = [0 3];
    opt_visu.type_slice = 'axial';
    opt_visu.type_color = 'jet';    

    for num_c = 1:size(vol_space,4)
        
        hf = figure;
        
        vol_c = niak_correct_vol(vol_space(:,:,:,num_c),mask);
        niak_montage(abs(vol_c),opt_visu);
        title(sprintf('Spatial component %i, file %s',num_c,name_f));
        if num_c == 1
            print(hf,'-dpsc','-r300',file_fig_eps);
        else
            print(hf,'-dpsc','-r300','-append',file_fig_eps);
        end

        close(hf);
        
        hf = figure;
        
        nt = size(eig_vec,1);

        %% temporal distribution
        subplot(3,1,1)
        
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                plot(hdr.info.tr*(1:nt),eig_vec(:,num_c));
            else
                plot(eig_vec(:,num_c));
            end
        else
            plot(eig_vec(:,num_c));
        end
                
        xlabel('time')
        ylabel('a.u.')
        title(sprintf('Time component %i, file %s',num_c,name_f));

        %% Frequency distribution
        subplot(3,1,2)
        
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                niak_visu_spectrum(eig_vec(:,num_c),hdr.info.tr);
            else
                niak_visu_spectrum(eig_vec(:,num_c),1);
            end
        else
            niak_visu_spectrum(eig_vec(:,num_c),1);
        end

        %% Time-frequency distribution
        subplot(3,1,3)
        
        if isfield(hdr.info,'tr')
            if hdr.info.tr~=0
                niak_visu_wft(eig_vec(:,num_c),hdr.info.tr);
            else
                niak_visu_wft(eig_vec(:,num_c),1);
            end
        else
            niak_visu_wft(eig_vec(:,num_c),1);
        end

        print(hf,'-dpsc','-r300','-append',file_fig_eps);

        close(hf)

    end
    
    instr_ps2pdf = cat(2,gb_niak_ps2pdf,' ',file_fig_eps,' ',files_out.figure);
    [succ,msg] = system(instr_ps2pdf);
    if succ~=0
        warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf : ',msg));
    end
    delete(file_fig_eps)
end