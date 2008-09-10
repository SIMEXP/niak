function [files_in,files_out,opt] = niak_brick_roc(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_ROC
%
% Build a Receiver-Operating Curve (ROC) from a ground truth binary map and
% a statistical map.
%
% SYNTAX :
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SPCA(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
%  * FILES_IN        
%       (structure) with the following fields :
%
%       GROUND_TRUTH 
%           (string) a 3D volume with a binary map of all true positives. 
%
%       SPM 
%           (string) a 3D statistical map. Bigger (absolute) values are
%           assumed to correspond to more significant results.
%
%  * FILES_OUT 
%       (string, default <BASE_SPM>_roc.dat)
%       The ROC stored in a text file 2D array (number of bins times 3).
%       See COMMENTS for the details.
%       
%
%  * OPT           
%       (structure) with the following fields.  
%       BINS 
%           (vector, default ) 
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
% NOTE 1:
% The first column of FILES_OUT is the lower bound of the bins (in terms of 
% sensitivity), the second column is the upper bound of the bins (again in 
% terms of sensitivity), and the third column is the specificity.
%
% NOTE 2:
% The specificity is defined as the proportion of false positives
% among all possible "negative" results, and the sensitivity is defined as
% the proportion of true positives among all possible "positive" result.
% This analysis is thus relevant only if there are a lot of positive and
% negative results to find in the ground truth map.
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ROC(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_roc'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'bins','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {[0 0.001 0.01 0.05:0.025:1'],0,'',1};
niak_set_defaults

%% Output files
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

%% Input files
if ~isstruct(files_in)
    error('FILES_IN should be a structure');
end
gb_name_structure = 'files_in';
gb_list_fields = {'spm','ground_truth'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in.spm);
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
    files_out = cat(2,opt.folder_out,filesep,name_f,'_roc.dat');
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Performing ROC analysis %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('\n_______________________________________\n\nROC analysis of SPM %s based on the ground truth map %s\n_______________________________________\n',files_in.spm,files_in.ground_truth);
end

%% Reading inputs
if flag_verbose
    fprintf('\nReading inputs ...\n');
end
[hdr_gt,vol_gt] = niak_read_vol(files_in.ground_truth);
[hdr_spm,vol_spm] = niak_read_vol(files_in.spm);

%% Deriving specificity and sensitivity for every possible threshold
if flag_verbose
    fprintf('\nDeriving specificity and sensitivity for every possible threshold ...\n');
end
mask_true = vol_gt(:)>0;
val_p = vol_spm(:);
[val_ord,ind] = sort(abs(val_p),1,'descend');
sens = cumsum(mask_true(ind))/sum(mask_true);
spec = cumsum(mask_true(ind)==0)/sum(mask_true==0);

%% Computing the ROC curve
if flag_verbose
    fprintf('\nComputing the ROC curve ...\n');
end
roc_curve = zeros([length(bins)-1 1]);
for num_b = 1:length(bins)-1
    roc_curve(num_b) = mean(sens((spec>=bins(num_b))&(spec<bins(num_b+1))));
end

%% Saving the ROC 
if flag_verbose
    fprintf('\nSaving the ROC ...\n')
end

niak_write_tab(files_out,[(bins(1:end-1)'+bins(2:end)')/2 roc_curve(:)],[],{'1-spec','sens'});