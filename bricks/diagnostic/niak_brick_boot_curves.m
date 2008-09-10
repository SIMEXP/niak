function [files_in,files_out,opt] = niak_brick_boot_curves(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_BOOT_CURVES
%
% Build the mean/std of multiple curves, as well as a bootstrap
% estimate of the standard deviation of the mean, and a simple bootstrap
% confidence intervel.
%
% SYNTAX :
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_BOOT_CURVES(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
%  * FILES_IN
%       (cell of strings) Each entry is curve in text format : first column
%       is the absciss, assumed to be similar for every curves, and second
%       column is the curve itself. The first line is assumed to be string
%       labels. 
%
%  * FILES_OUT 
%       (string) a table in text format. 
%       First line : the absciss. Second line : the mean of the curves. 
%       Third line : the std of the curves. Fourth line : a bootstrap
%       estimate of the std of the mean of the curves. Following lines : the
%       percentiles of simple bootstrap confidence interval on
%       the mean (see OPT.PERCENTILES).
%
%  * OPT           
%       (structure) with the following fields.  
%
%       PERCENTILES
%           (vector, default [0.0005 0.025 0.975 0.9995])
%           the (unilateral) confidence level of the bootstrap confidence
%           intervals.
%
%       NB_SAMPS
%           (integer, default 10000) the number of bootstrap samples used to
%           compute the standard-deviation-of-the-mean and the
%           bootstrap confidence interval on the mean.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some info during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS :
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO :
%
% _________________________________________________________________________
% COMMENTS :
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_BOOT_CURVES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_boot_curves'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'percentiles','nb_samps','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[0.0005 0.025 0.975 0.9995],10000,0,'',1};
niak_set_defaults

%% Output files
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

%% Input files
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings');
end

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in{1});
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

if isempty(files_out)
    files_out = cat(2,opt.folder_out,filesep,name_f,'_boot_perc',ext_f);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Computing mean/std volumes %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n_______________________________________\n\nComputing mean/std, std of the mean and confidence intervals of the following curves %s\n_______________________________________\n',char(files_in{:})');
end

%% Reading all curves
if flag_verbose
    fprintf('\nReading all curves ...\n');
end

nb_files = length(files_in);

for num_f = 1:nb_files
    [tab,labx,laby] = niak_read_tab(files_in{num_f});

    if num_f == 1
        absc = tab(:,1);
        all_curves = zeros([length(absc),nb_files]);
        all_curves(:,1) = tab(:,2);
    else
        if length(absc)~= size(tab,1)
            error('All tables should have the same number of columns')
        end
        
        if min(absc==tab(:,1))==0
            error('All curves should have the same sample grid (first column)')
        end
        
        all_curves(:,num_f) = tab(:,2);
    end
end

%% Computing mean/std curves
if flag_verbose
    fprintf('\nComputing mean/std curves ...\n');
end
mean_curve = mean(all_curves,2)';
std_curve = std(all_curves,0,2)';

%% Deriving bootstrap ci & std of the mean
if flag_verbose
    fprintf('\nDeriving bootstrap ci & std of the mean ...\n');
end

samps = zeros([nb_samps size(all_curves,1)]);

for num_s = 1:nb_samps
    samps(num_s,:) = mean(all_curves(:,ceil(nb_files*rand([nb_files 1]))),2)';
end

stdmean_curve = std(samps,0,1);
samps = sort(samps,1);
perc_curve = zeros([length(opt.percentiles) size(samps,2)]);

for num_e = 1:length(opt.percentiles);
    perc_curve(num_e,:) = samps(min(size(samps,1),ceil(opt.percentiles(num_e)*size(samps,1))),:);
end

%% Saving results
if flag_verbose
    fprintf('\nSaving results ...\n');
end

laby = cell([1 length(absc)]);
for num_y = 1:length(absc)
    laby{num_y} = num2str(absc(num_y),2);
end

labx = {'mean','std','std_mean'};
for num_e = 1:length(opt.percentiles);
    labx{3+num_e} = num2str(opt.percentiles(num_e),12);
end

tab_final = [mean_curve ; std_curve ; stdmean_curve ; perc_curve];

niak_write_tab(files_out,tab_final,labx,laby);