function [files_in,files_out,opt] = niak_brick_time_filter(files_in,files_out,opt)

% Perform time high-pass and low-pass filtering using linear fitting of
% a discrete cosine basis. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN        (string OR array of strings) a file name of a 3D+t dataset OR
%                       an array of strings where each line is a file name
%                       of 3D data, all in the same space.
%
% FILES_OUT       (structure) with the following fields.  Note that if
%     a field is an empty string, a default value will be used to
%     name the outputs. If a field is ommited, the output won't be
%     saved at all (this is equivalent to setting up the output file
%     names to 'gb_niak_omitted'). 
%                       
%                 FILTERED_DATA (string or array of strings, default <FILES_IN>_F) File names for outputs. NOTE that
%                       if FILTERED_DATA does not exist, or if it is an empty string, the name 
%                       of the outputs will be the same as the inputs, 
%                       with a '_f' suffix added at the end.
%
%                 BETA_HIGH (string or array of strings, default <FILES_IN>_BETA_HIGH) File name 
%                       for the volumes of the regression coeffients in high
%                       frequency. If this field is ommited, the
%                       volumes will not be saved. If it is empty, the
%                       default name will be applied.
%                       Tip : In ANLYZE 7.5 format, a file name needs to be specified for each
%                       DC. You can use the function NIAK_BUILD_DC to
%                       determine how many high-frequency DC there will be,
%                       OR you can specify one string ending by '_'. File
%                       names with suffix '000<i>.ext' will be automatically
%                       generated.
%
%                 BETA_LOW (string or array of strings, default <FILES_IN>_BETA_LOW) File name 
%                       for the volumes of the regression coeffients in low
%                       frequency. If this field is ommited, the
%                       volumes will not be saved. If it is empty, the
%                       default name will be applied.
%                       Tip : In ANLYZE 7.5 format, a file name needs to be specified for each
%                       DC. You can use the function NIAK_BUILD_DC to
%                       determine how many low-frequency DC there will be,
%                       OR you can specify one string ending by '_'. File
%                       names with suffix '000<i>.ext' will be automatically
%                       generated.
%
%                 DC_HIGH (string, default <FILES_IN>_DC_HIGH.DAT) File name 
%                       for the matrix of high frequency discrete cosine.
%                       The matrix is saved in text format with 5 decimals.
%                       The first line defines the frequency associated
%                       with each cosine. If this field is ommited, the
%                       volumes will not be saved. If it is empty, the
%                       default name will be applied.
%
%                 DC_LOW (string, default <FILES_IN>_DC_LOW.DAT) File name 
%                       for the matrix of low frequency discrete cosine.
%                       The matrix is saved in text format with 5 decimals.
%                       The first line defines the frequency associated
%                       with each cosine. If this field is ommited, the
%                       volumes will not be saved. If it is empty, the
%                       default name will be applied.
%                 
%                 VAR_HIGH (string, default <FILES_IN>_VAR_HIGH) File name for the volume of percentage of variance in
%                       high frequencies. If this field is ommited, the
%                       volume will not be saved. If it is empty, the
%                       default name will be applied.
%
%                 VAR_LOW (string, default <FILES_IN>_VAR_LOW) File name for the volume of percentage of variance in
%                       low frequencies. If this field is ommited, the
%                       volume will not be saved. If it is empty, the
%                       default name will be applied.
%
% OPT           (structure) with the following fields:
%
%                FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the
%                    brick does not do anything but update the default 
%                    values in FILES_IN and FILES_OUT.
%
%                HP (real, default: 0.01) the cut-off frequency for high pass
%                    filtering. opt.hp = -Inf means no high-pass filtering.
%
%                LP (real, default: Inf) the cut-off frequency for low pass
%                    filtering. opt.lp = Inf means no low-pass filtering.
%
%                FLAG_ZIP   (boolean, default: 0) if FLAG_ZIP equals 1, an
%                   attempt will be made to zip the outputs.
%
%                FOLDER_OUT (string, default: path of FILES_IN) If present,
%                    all default outputs will be created in the folder FOLDER_OUT.
%                    The folder needs to be created beforehand.
%
%                TR (real, default : use image information) the repetition 
%                    time of the time series (s) which is the inverse of the 
%                    sampling frequency (Hz). Specify a value here only if
%                    you want to override the information in the image, or
%                    if you are using an image format where this
%                    information is absent, i.e. analyze.
%               
% OUTPUTS:
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% SEE ALSO:
% NIAK_FILTER_TSERIES, NIAK_DEMO_FILTER
%
% COMMENTS
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, filtering, fMRI

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

%% Input files
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_time_filter'' for more info.')
end

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'filtered_data','var_high','var_low','beta_high','beta_low','dc_high','dc_low'};
gb_list_defaults = {'','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'tr','hp','lp','folder_out','flag_test','flag_zip'};
gb_list_defaults = {-Inf,0.01,Inf,'',0,0};
niak_set_defaults

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

%% Building default output names
if isempty(files_out.filtered_data)

    if size(files_in,1) == 1

        files_out.filtered_data = cat(2,opt.folder_out,filesep,name_f,'_f',ext_f);

    else

        name_filtered_data = cell([size(files_in,1) 1]);

        for num_f = 1:size(files_in,1)
            [path_f,name_f,ext_f] = fileparts(files_in(1,:));

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f] = fileparts(name_f);
            end
            name_filtered_data{num_f} = cat(2,opt.folder_out,filesep,name_f,'_f',ext_f);
        end
        files_out.filtered_data = char(name_filtered_data);

    end
end

if isempty(files_out.var_high)
    files_out.var_high = cat(2,opt.folder_out,filesep,name_f,'_var_high',ext_f);
end

if isempty(files_out.var_low)
    files_out.var_low = cat(2,opt.folder_out,filesep,name_f,'_var_low',ext_f);
end

if isempty(files_out.beta_high)
    if size(files_in,1) == 1
        files_out.beta_high = cat(2,opt.folder_out,filesep,name_f,'_beta_high',ext_f);
    else
        files_out.beta_high = cat(2,opt.folder_out,filesep,name_f,'_beta_high_');
    end
end

if isempty(files_out.beta_low)
    if size(files_in,1) == 1
        files_out.beta_low = cat(2,opt.folder_out,filesep,name_f,'_beta_low',ext_f);
    else
        files_out.beta_low = cat(2,opt.folder_out,filesep,name_f,'_beta_low_');
    end
end

if isempty(files_out.dc_high)
    files_out.dc_high = cat(2,opt.folder_out,filesep,name_f,'_dc_high.dat');
end

if isempty(files_out.dc_low)
    files_out.dc_low = cat(2,opt.folder_out,filesep,name_f,'_dc_low.dat');
end


if flag_test == 1    
    return
end

%% Performing temporal filtering
[hdr,vol] = niak_read_vol(files_in);

if (opt.tr == -Inf)
    
    if isfield(hdr.info,'tr')
        opt.tr = hdr.info.tr;
    else
        error('please specify the TR of the fMRI data in opt.tr')
    end
    
else
    opt_f.tr = opt.tr;
end
opt_f.lp = opt.lp;
opt_f.hp = opt.hp;

%% We restrict the filtering in a mask of the brain to save time
%% The data are converted into a array of time series
mask = mean(abs(vol),4);
mask = niak_mask_brain(mask);

if ndims(vol)==3
    [nx,ny,nz] = size(vol); nt = 1;
else
    [nx,ny,nz,nt] = size(vol);
end

vol = reshape(vol,[nx*ny*nz nt])';
vol = vol(:,mask>0);

%% Filtering the data
opt_f.tr = opt.tr;
opt_f.hp = opt.hp;
opt_f.lp = opt.lp;
[tseries_f,extras] = niak_filter_tseries(vol,opt_f);

%% If relative variance maps have been requested, compute total variance of
%% the time series
if ~strcmp(files_out.var_high,'gb_niak_omitted')|~strcmp(files_out.var_low,'gb_niak_omitted')
    var_vol = var(vol);
end

%% Reshaping the filtered time series into a 3D+t volume
%clear vol
vol_f = zeros([nx*ny*nz nt]);
vol_f(mask>0,:) = tseries_f';
clear tseries_f
vol_f = reshape(vol_f,[nx ny nz nt]);

%% Writting the filtered data
hdr = hdr(1);
hdr.flag_zip = flag_zip;

hdr_out = hdr;
hdr_out.file_name = files_out.filtered_data;
opt_hist.command = 'niak_brick_time_filter';
opt_hist.files_in = files_in;
opt_hist.files_out = files_out.filtered_data;
opt_hist.comment = sprintf('Filtered data, high-pass filter cut-off= %1.2f Hz, low pass filter cut-off=%1.2f Hz, TR=%1.2f',opt.hp,opt.lp,opt.tr);
hdr_out = niak_set_history(hdr_out,opt_hist);
niak_write_vol(hdr_out,vol_f);
clear vol_f

%% Writting the regression coefficients for high frequencies
if ~strcmp(files_out.beta_high,'gb_niak_omitted')
    hdr_out = hdr;
    hdr_out.file_name = files_out.beta_high;
    vol_beta_high = zeros([nx*ny*nz size(extras.beta_dc_high,1)]);
    vol_beta_high(mask>0,:) = extras.beta_dc_high';
    vol_beta_high = reshape(vol_beta_high,[nx,ny,nz,size(extras.beta_dc_high,1)]);
    opt_hist.command = 'niak_brick_time_filter';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.beta_high;
    opt_hist.comment = sprintf('Regression coefficients for high-frequency discrete cosines, cut-off %1.2f Hz',opt.lp);
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,vol_beta_high);
    clear vol_beta_high
end

%% Writting the regression coefficients for low frequencies
if ~strcmp(files_out.beta_low,'gb_niak_omitted')
    hdr_out = hdr;
    hdr_out.file_name = files_out.beta_low;
    vol_beta_low = zeros([nx*ny*nz size(extras.beta_dc_low,1)]);
    vol_beta_low(mask>0,:) = extras.beta_dc_low';
    vol_beta_low = reshape(vol_beta_low,[nx,ny,nz,size(extras.beta_dc_low,1)]);
    opt_hist.command = 'niak_brick_time_filter';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.beta_low;
    opt_hist.comment = sprintf('Regression coefficients for low-frequency discrete cosines, cut-off %1.2f Hz',opt.hp);
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,vol_beta_low);
    clear vol_beta_low
end

%% Writting the discrete cosine basis for low frequencies
if ~strcmp(files_out.dc_low,'gb_niak_omitted')
    fid = fopen(files_out.dc_low,'w');    
    fprintf(fid,'Component %i (frequency %1.5f); ',[1:length(extras.freq_dc_low) ; extras.freq_dc_low']);
    fprintf(fid,'\n');
    
    for num_l = 1:size(extras.tseries_dc_low,1)
        fprintf(fid,'%1.5f ',extras.tseries_dc_low(num_l,:));
        fprintf(fid,'\n');
    end
end

%% Writting the discrete cosine basis for high frequencies
if ~strcmp(files_out.dc_high,'gb_niak_omitted')
    fid = fopen(files_out.dc_high,'w');    
    fprintf(fid,'Component %i (frequency %1.5f); ',[1:length(extras.freq_dc_high)'; extras.freq_dc_high']);
    fprintf(fid,'\n');
    
    for num_l = 1:size(extras.tseries_dc_high,1)
        fprintf(fid,'%1.5f ',extras.tseries_dc_high(num_l,:));
        fprintf(fid,'\n');
    end
end

%% Writting the relative variance for low frequencies
if ~strcmp(files_out.var_low,'gb_niak_omitted')
    hdr_out = hdr;
    hdr_out.file_name = files_out.var_low;
    vol_var_low = zeros([nx ny nz]);
    var_low = var(extras.tseries_dc_low*extras.beta_dc_low);
    vol_var_low(mask>0) = var_low./var_vol;    
    opt_hist.command = 'niak_brick_time_filter';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.beta_low;
    opt_hist.comment = sprintf('Relative variance of low-frequency discrete cosines, cut-off %1.2f Hz',opt.hp);
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,vol_var_low);
    clear vol_val_low
end

%% Writting the relative variance for high frequencies
if ~strcmp(files_out.var_high,'gb_niak_omitted')
    hdr_out = hdr;
    hdr_out.file_name = files_out.var_high;
    vol_var_high = zeros([nx ny nz]);
    if ~isempty(extras.tseries_dc_high)
        var_high = var(extras.tseries_dc_high*extras.beta_dc_high);    
        vol_var_high(mask>0) = var_high./var_vol;    
    end
    opt_hist.command = 'niak_brick_time_filter';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out.beta_high;
    opt_hist.comment = sprintf('Relative variance of high-frequency discrete cosines, cut-off %1.2f Hz',opt.hp);
    hdr_out = niak_set_history(hdr_out,opt_hist);
    niak_write_vol(hdr_out,vol_var_high);
    clear vol_val_high
end