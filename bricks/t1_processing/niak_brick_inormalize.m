function [files_in,files_out,opt] = niak_brick_inormalize(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_INORMALIZE
%
% Normalize the intensities of a brain volume.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_INORMALIZE(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (structure) with the following fields :
%
%       VOL
%           (string) the file name of a brain volume.
%
%       MODEL
%           (string) the file name a model volume.
%
%  * FILES_OUT
%       (string, default <FILES_IN.T1>_IN.<EXT>) The brain volume after
%       intensity normalization.
%
%  * OPT           
%       (structure) with the following fields:
%
%       ARG
%           (string, default '') any argument that will be passed to the
%           NU_CORRECT command (see comments below). 
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%               
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MASK_BRAIN_T1, NIAK_PIPELINE_BRICK_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   This function is a simple NIAK-compliant wrapper around the minc tool
%   called INORMALIZE. Type "inormalize -help" in a terminal for more
%   infos.
%
% NOTE 2:
%   The source and the model need to have the same sampling.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, intensity normalization

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
niak_gb_vars; % load important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')|~exist('files_out','var')
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

if strcmp(ext_f,gb_niak_zip_ext)    
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,gb_niak_zip_ext);
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
[path_f,name_f,ext_f] = fileparts(files_out);
flag_zip = strcmp(ext_f,gb_niak_zip_ext);
if ~flag_zip
    instr = ['inormalize -clobber ' arg ' -model ' files_in.model ' ' files_in.vol ' ' files_out];
else
    instr = ['inormalize -clobber ' arg ' -model ' files_in.model ' ' files_in.vol ' ' path_f filesep name_f];
end

%% Running NU_CORRECT
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
if flag_zip
    system([gb_niak_zip ' ' path_f filesep name_f]);    
end

