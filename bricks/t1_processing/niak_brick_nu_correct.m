function [files_in,files_out,opt] = niak_brick_nu_correct(files_in,files_out,opt)
% Non-uniformity correction on an MR scan. See comments for details on the
% algorithm. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NU_CORRECT(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN        
%   (structure) with the following fields :
%
%   VOL
%      (string) the file name of an MR volume (typically T1 or T2).
%
%   MASK
%      (string, default 'gb_niak_omitted') the file name of a binary 
%      mask of a region of interest. If unspecified (or equal to 
%     'gb_niak_omitted'), no mask is used.
%
% FILES_OUT
%   (structure) with the following fields.  Note that if a field is an 
%   empty string, a default value will be used to name the outputs. 
%   If a field is ommited, the output won't be saved at all (this is 
%   equivalent to setting up the output file names to 
%   'gb_niak_omitted'). 
%                       
%   VOL_NU
%      (string, default <FILES_IN.VOL>_NU.<EXT>) The non-uniformity
%      corrected T1 scan.
%
%   VOL_IMP
%      (string, default <FILES_IN.VOL>_NU.IMP) The estimated
%      intensity mapping.
%
% OPT           
%   (structure) with the following fields:
%
%   ARG
%     (string, default '-distance 200') any argument that will be 
%     passed to the NU_CORRECT command (see comments below). The 
%     '-distance' option sets the N3 spline distance in mm (suggested 
%     values: 200 for 1.5T scan; 50 for 3T scan). 
%
%   FLAG_VERBOSE 
%     (boolean, default: 1) If FLAG_VERBOSE == 1, write
%     messages indicating progress.
%
%   FLAG_TEST 
%     (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%     do anything but update the default values in FILES_IN, 
%     FILES_OUT and OPT.
%
%   FOLDER_OUT 
%     (string, default: path of FILES_IN) If present, all default 
%     outputs will be created in the folder FOLDER_OUT. The folder 
%     needs to be created beforehand.
%             
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MASK_BRAIN_T1, NIAK_PIPELINE_T1_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   This function is a simple NIAK-compliant wrapper around the minc tool
%   called NU_CORRECT. Type "nu_correct -help" in a terminal for more
%   infos.
%
% NOTE 2:
%   The correction method is N3 [1], and should work with any MR volume 
%   including raw (non-stereotaxic) data.  The performance of this method 
%   can be enhanced by supplying a mask for the region of interest.
%
%   [1] J.G. Sled, A.P. Zijdenbos and A.C. Evans, "A non-parametric method
%       for automatic correction of intensity non-uniformity in MRI data",
%       in "IEEE Transactions on Medical Imaging", vol. 17, n. 1,
%       pp. 87-97, 1998 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, T1, non-uniformity correction

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
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NU_CORRECT(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_nu_correct'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'vol','mask'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'vol_nu','vol_imp'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'arg','flag_verbose','folder_out','flag_test'};
gb_list_defaults = {'-distance 200',true,'',false};
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

if isempty(files_out.vol_nu)    
    files_out.vol_nu = [opt.folder_out,filesep,name_f,'_nu',ext_f];
end

if isempty(files_out.vol_imp)    
    files_out.vol_imp = [opt.folder_out,filesep,name_f,'_nu.imp'];
end

if flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'Non-uniformity correction on an MR volume';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);    
end

%% Setting up the system call to NU_CORRECT
[path_f,name_f,ext_f] = fileparts(files_out.vol_nu);
flag_zip_nu = strcmp(ext_f,gb_niak_zip_ext);
[path_f,name_f,ext_f] = fileparts(files_out.vol_imp);
flag_zip_imp = strcmp(ext_f,gb_niak_zip_ext);

path_tmp = niak_path_tmp(['_' name_f]);
file_tmp_nu = [path_tmp 'vol_nu.mnc'];
file_tmp_imp = [path_tmp 'vol_nu.imp'];

if strcmp(files_in.mask,'gb_niak_omitted')
    instr = ['nu_correct -clobber -tmpdir ' path_tmp ' ' arg ' ' files_in.vol ' ' file_tmp_nu];
else
    instr = ['nu_correct -clobber -tmpdir ' path_tmp ' ' arg ' -mask ' files_in.mask ' ' files_in.vol ' ' file_tmp_nu];
end

%% Running NU_CORRECT
if flag_verbose
    fprintf('Running NU_CORRECT with the following command:\n%s\n\n',instr)
end

if flag_verbose
    system(instr)
else
    [status,msg] = system(instr);
    if status~=0
        error('The nu_correct command failed with that error message :\n%s\n',msg);
    end
end

%% Writting outputs
if ~strcmp(files_out.vol_nu,'gb_niak_omitted')
    if flag_zip_nu
        system([gb_niak_zip ' ' file_tmp_nu]);        
        system(['mv ' file_tmp_nu gb_niak_zip_ext ' ' files_out.vol_nu]);
    else
        system(['mv ' file_tmp_nu ' ' files_out.vol_nu]);
    end
end

if ~strcmp(files_out.vol_imp,'gb_niak_omitted')
    if flag_zip_imp
        system([gb_niak_zip ' ' file_tmp_imp]);        
        system(['mv ' file_tmp_imp gb_niak_zip_ext ' ' files_out.vol_imp]);
    else
        system(['mv ' file_tmp_imp ' ' files_out.vol_imp]);
    end    
end

system(['rm -rf ' path_tmp]);

