function [files_in,files_out,opt] = niak_brick_classify(files_in,files_out,opt)
% Brain tissue segmentation on T1 scan in stereotaxic space.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CLASSIFY(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%   FILES_IN        
%       (structure) with the following fields :
%
%       VOL
%           (string) the file name of an MR volume (typically T1 or T2).
%
%       MASK
%           (string, default 'gb_niak_omitted') the file name of a binary 
%           mask of a region of interest. If unspecified (or equal to 
%           'gb_niak_omitted'), no mask is used.
%
%       TRANSF
%           (string, default 'gb_niak_omitted') non-linear transformation 
%           to map the tags from stereotaxic space to subject 
%
%   FILES_OUT
%       (string, default <FILES_IN.VOL>_CLASSIFY.<EXT>) Integer labels
%       coding for cerebrospinal fluid / gray matter / white matter (in
%       this order).
%
%   OPT           
%       (structure) with the following fields:
%
%       ARG
%           (string, default '') any argument that will be 
%           passed to the CLASSIFY command (see comments below). 
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
% NIAK_PIPELINE_T1_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
%   This function is a simple NIAK-compliant wrapper around the minc tool
%   called CLASSIFY_CLEAN. Type "classify_clean -help" in a terminal for 
%   more infos.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, T1, tissue segmentation

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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CLASSIFY(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_classify'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'vol','mask','transf'};
gb_list_defaults = {NaN,'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Output files
if ~ischar(files_out)
    error('FILES_OUT should be a string');
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
    files_out = [opt.folder_out,filesep,name_f,'_classify',ext_f];
end

if flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'Tissue classification on an MR volume';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);    
end

%% Setting up the system call to NU_CORRECT
[path_f,name_f,ext_f] = fileparts(files_out);
flag_zip = strcmp(ext_f,gb_niak_zip_ext);

path_tmp = niak_path_tmp(['_' name_f]);
file_tmp_classify = [path_tmp 'vol_classify.mnc'];

if ~strcmp(files_in.mask,'gb_niak_omitted')
    arg = [arg ' -mask_source ' files_in.mask];
end

if ~strcmp(files_in.transf,'gb_niak_omitted')
    arg = [arg ' -tag_transform ' files_in.transf];
end

instr = ['classify_clean -tmpdir ' path_tmp ' ' arg ' ' files_in.vol ' ' file_tmp_classify];

%% Running NU_CORRECT
if flag_verbose
    fprintf('Running CLASSIFY with the following command:\n%s\n\n',instr)
end

if flag_verbose
    system(instr)
else
    [status,msg] = system(instr);
    if status~=0
        error('The classify_clean command failed with that error message :\n%s\n',msg);
    end
end

%% Writting outputs
if flag_zip
    system([gb_niak_zip ' ' file_tmp_classify]);
    system(['mv ' file_tmp_classify gb_niak_zip_ext ' ' files_out]);
else
    system(['mv ' file_tmp_classify ' ' files_out]);
end

system(['rm -rf ' path_tmp]);

