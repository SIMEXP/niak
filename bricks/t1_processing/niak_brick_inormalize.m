function [files_in,files_out,opt] = niak_brick_inormalize(files_in,files_out,opt)
% Normalize the intensities of a brain volume.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_INORMALIZE(FILES_IN,FILES_OUT,OPT)
%
% FILES_IN.VOL (string) the file name of a brain volume.
% FILES_IN.MODEL (string) the file name a model volume.
% FILES_OUT (string, default <FILES_IN.T1>_IN.<EXT>) The brain volume 
%   after intensity normalization.
% OPT.ARG (string, default '') any argument that will be passed to the
%   NU_CORRECT command (see comments below). 
% OPT.FLAG_VERBOSE (boolean, default: 1) If FLAG_VERBOSE == 1, write
%   messages indicating progress.
% OPT.FLAG_TEST (boolean, default: 0) if FLAG_TEST equals 1, the brick does 
%   not do anything but update the default values in FILES_IN, FILES_OUT and OPT.
% OPT.FOLDER_OUT (string, default: path of FILES_IN) If present, all default 
%   outputs will be created in the folder FOLDER_OUT. The folder needs to be 
%   created beforehand.
%
% * The structures FILES_IN, FILES_OUT and OPT are updated with default
%   valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
% * This function is a simple NIAK-compliant wrapper around the minc tool
%   called INORMALIZE. Type "inormalize -help" in a terminal for more
%   infos.
% * The source and the model need to have the same sampling.
%
% Copyright (c) Pierre Bellec. See license in the code.
% SEE ALSO: NIAK_BRICK_MASK_BRAIN_T1, NIAK_PIPELINE_BRICK_PREPROCESS

% McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008-2010.
% Centre de recherche de l'institut de griatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2010-2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, intensity normalization
%
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


niak_gb_vars; % load important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_INORMALIZE(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_inormalize'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'vol','model'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

%% Output files
if ~exist('files_out','var')
    files_out = '';
end

if ~ischar(files_out)
    error('FILES_OUT should be a string.');
end
    
%% Options
gb_name_structure = 'opt';
gb_list_fields = {'arg','flag_verbose','folder_out','flag_test'};
gb_list_defaults = {'',true,'',false};
niak_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in.vol);
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,GB_NIAK.zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,GB_NIAK.zip_ext);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

if isempty(files_out)    
    files_out.t1_nu = [opt.folder_out,filesep,name_f,'_in',ext_f];
end

if flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'Intensity normalization on brain volume';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);    
end

%% Applying INORMALIZE
[path_v,name_v,ext_v] = niak_fileparts(files_in.vol);
[path_m,name_m,ext_m] = niak_fileparts(files_in.model);
[path_o,name_o,ext_o,flag_zip] = niak_fileparts(files_out);
path_tmp = niak_path_tmp(['_' name_f]);

if ~ismember(ext_v,{'.mnc','.mnc.gz'})
    in_vol = [path_tmp 'vol.mnc'];
    niak_brick_copy(files_in.vol,in_vol,struct('flag_fmri',true));
else
    in_vol = files_in.vol;
end

if ~ismember(ext_m,{'.mnc','.mnc.gz'})
    in_model = [path_tmp 'model.mnc'];
    niak_brick_copy(files_in.model,in_model,struct('flag_fmri',true));
else
    in_model = files_in.model;
end

if ~ismember(ext_o,{'.mnc'})
    tmp_out = [path_tmp 'out.mnc'];
    flag_conv = true;
else
    tmp_out = files_out;
    flag_conv = false;
end

instr = ['inormalize -clobber ' arg ' -model ' in_model ' ' in_vol ' ' tmp_out];

%% Running INORMALIZE
if flag_verbose
    fprintf('Running INORMALIZE with the following command:\n%s\n\n',instr)
end

if flag_verbose
    system(instr)
else
    [status,msg] = system(instr);
    if status~=0
        error('The inormalize command failed with that error message :\n%s\n',msg);
    end
end

%% Compressing outputs if needed
if flag_conv
    niak_brick_copy(tmp_out,files_out,struct('flag_fmri',true));
end

