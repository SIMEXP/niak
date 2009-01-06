function pipeline = niak_pipeline_mask_brain(files_in,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MASK_BRAIN
%
% Derive brain masks in multiple fMRI datasets, and combine them into a
% group mask.
%
% SYNTAX:
% PIPELINE = NIAK_PIPELINE_MASK_BRAIN(FILES_IN,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (cell of strings) each entry is a file name of a 3D+t dataset. All
%       datasets need to be in the same space (either one individual, or
%       stereotaxic space).
%
%  * OPT           
%       (structure) with the following fields.  
%
%       MASK_BRAIN 
%           (structure) see the description of OPT in NIAK_MASK_BRAIN. Note
%           that the default value of OPT.VOXEL_SIZE is the one in the
%           header of the fmri volume.
%           
%       THRESH_MEAN
%           (scalar, default 1) the threshold that is applied on the
%           average mask to define the group mask.
%
%       FOLDER_OUT 
%           (string) 
%           where to save the outputs
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the function is
%           just generating the pipeline structure. If FLAG_TEST is false,
%           the data is actually processed.
%           
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_MASK_BRAIN, NIAK_BRICK_MASK_BRAIN
%
% _________________________________________________________________________
% COMMENTS
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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')|~exist('opt','var')
    error('niak:pipeline','syntax: PIPELINE = NIAK_PIPELINE_MASK_BRAIN(FILES_IN,OPT).\n Type ''help niak_pipeline_mask_brain'' for more info.')
end

%% Options
default_mask.folder_out = '';
default_psom.path_logs = '';
gb_name_structure = 'opt';
gb_list_fields = {'thresh_mean','psom','mask_brain','flag_test','folder_out'};
gb_list_defaults = {1,default_psom,default_mask,false,NaN};
niak_set_defaults
opt.psom(1).path_logs = [opt.folder_out 'logs' filesep];

if ~iscellstr(files_in)
    error('FILES_IN should be a cell of string');
end

%%%%%%%%%%%%%%%%%%%%%%
%% Individual masks %%
%%%%%%%%%%%%%%%%%%%%%%

name_brick = 'mask_brain';
nb_files = length(files_in);
files_mask = cell(size(files_in));

for num_f = 1:nb_files
    name_job = sprintf('%s_file%i',name_brick,num_f);
    clear files_in_tmp files_out_tmp opt_tmp
    
    files_in_tmp = files_in{num_f};
    files_out_tmp = '';
    opt_tmp = opt.mask_brain;
    opt_tmp.folder_out = opt.folder_out;
    opt_tmp.flag_test = true;

    [files_in_tmp,files_out_tmp,opt_tmp] = niak_brick_mask_brain(files_in_tmp,files_out_tmp,opt_tmp);
    opt_tmp.flag_test = false;
    files_mask{num_f} = files_out_tmp;
    
    pipeline.(name_job).command = 'niak_brick_mask_brain(files_in,files_out,opt);';
    pipeline.(name_job).files_in = files_in_tmp;
    pipeline.(name_job).files_out = files_out_tmp;
    pipeline.(name_job).opt = opt_tmp;
end

%%%%%%%%%%%%%%%%%%
%% average mask %%
%%%%%%%%%%%%%%%%%%

name_job = 'average_mask';

clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp = files_mask;
[path_f,name_f,ext_f] = fileparts(files_in{1});
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,gb_niak_zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
end

files_out_tmp = [opt.folder_out filesep 'mask_average' ext_f];

opt_tmp.operation = 'vol = zeros(size(vol_in{1})); for num_f = 1:length(vol_in); vol = vol + vol_in{num_f}; end; vol = vol/length(vol_in);';

pipeline.(name_job).command = 'niak_brick_math_vol(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%
%% group mask %%
%%%%%%%%%%%%%%%%

name_job = 'group_mask';

clear files_in_tmp files_out_tmp opt_tmp
files_in_tmp{1} = pipeline.average_mask.files_out;
files_out_tmp = [opt.folder_out filesep 'mask_group' ext_f];
opt_tmp.operation = 'vol = vol_in{1} >= opt_operation;';
opt_tmp.opt_operation = opt.thresh_mean;

pipeline.(name_job).command = 'niak_brick_math_vol(files_in,files_out,opt);';
pipeline.(name_job).files_in = files_in_tmp;
pipeline.(name_job).files_out = files_out_tmp;
pipeline.(name_job).opt = opt_tmp;

%%%%%%%%%%%%%%%%%%%%%%
%% Run the pipeline %%
%%%%%%%%%%%%%%%%%%%%%%

if ~opt.flag_test
    psom_run_pipeline(pipeline,opt.psom);
end