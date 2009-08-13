function [files_in,files_out,opt] = niak_brick_mnc2nii3d(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MNC2NII3D
%
% Copy the content of a directory and convert all the minc files into the
% nifti 3D format, i.e. 4D files are converted into series of 3D nifti
% files.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MNC2NII3D(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN
%       (string) a full path.
%
%  * FILES_OUT
%       (string, default FILES_IN) a full path
%
%  * OPT
%       (structure) with the following fields :
%
%       FLAG_RECURSIVE
%           (boolean, default true) recursively copy subfolders.
%
%       ARG_MNC2NII
%           (string, default '') an argument that will be added in
%           the system call to the MNC2NII function.
%
%       FLAG_SKIP
%           (string, default true) if FLAG_SKIP is true, any existing
%           output will not be overwritten.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% This brick is just a wraper of MINC2NII system calls.
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

niak_gb_vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MNC2NII(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_MNC2NII'' for more info.')
end
if ~exist('files_out','var')||isempty(files_out)
    files_out = files_in;
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_skip','flag_recursive','flag_verbose','arg_mnc2nii'};
gb_list_defaults = {true,true,true,''};
niak_set_defaults

dir_files = dir(files_in);

mask_dir = [dir_files.isdir];
list_all = {dir_files.name};
mask_dot = ismember(list_all,{'.','..'});
dir_files = dir_files(~mask_dot);
mask_dir = mask_dir(~mask_dot);
list_all = list_all(~mask_dot);
list_files = list_all(~mask_dir);
list_dir = list_all(mask_dir);

niak_mkdir(files_out);
tmp_folder = niak_path_tmp('_convert');

opt_3d.folder_out = tmp_folder;
opt_3d.flag_test = false;

try
    for num_f = 1:length(list_files)
        
        file_name = list_files{num_f};
        if ~exist(file_name,'file')
            source_file = [files_in filesep file_name];
        else
            source_file = file_name;
        end
        
        [path_tmp,name_tmp,ext] = fileparts(file_name);
        if strcmp(ext,gb_niak_zip_ext)
            [path_tmp,name_tmp,ext] = fileparts(name_tmp);
        end
        
        if strcmp(ext,'.mnc')
            msg = sprintf('Converting %s ...\n',file_name);
            if flag_verbose
                fprintf('%s',msg)
            end
            
            if flag_skip
                opt_3d.flag_test = true;
                [var_tmp,files_out_3d] = niak_brick_4d_to_3d(source_file,'',opt_3d);
                
                flag_exist = true;
                for num_g = 1:length(files_out_3d)
                    [path_tmp,name_tmp,ext] = fileparts(files_out_3d{num_g});
                    if strcmp(ext,gb_niak_zip_ext)
                        [path_tmp,name_tmp,ext] = fileparts(name_tmp);
                    end
                    target_file = [files_out filesep name_tmp '.nii'];
                    flag_exist = flag_exist & exist(target_file,'file');
                end
            else
                flag_exist = false;
            end
            
            if ~flag_exist
                opt_3d.flag_test = false;
                [var_tmp,files_out_3d] = niak_brick_4d_to_3d(source_file,'',opt_3d);
                for num_g = 1:length(files_out_3d)
                    [path_tmp,name_tmp,ext] = fileparts(files_out_3d{num_g});
                    if strcmp(ext,gb_niak_zip_ext)
                        [path_tmp,name_tmp,ext] = fileparts(name_tmp);
                    end
                    target_file = [files_out filesep name_tmp '.nii'];
                    instr_cp = ['mnc2nii ',arg_mnc2nii,' ',files_out_3d{num_g},' ',target_file];
                    if ~strcmp(source_file,target_file)
                        
                        [flag_err,err_msg] = system(instr_cp);
                        if flag_err
                            error(err_msg)
                        end
                    end
                end
            else
                msg = sprintf('   The output already existed. I will skip this one (FLAG_SKIP is true) ...\n',file_name);
                if flag_verbose
                    fprintf('%s',msg)
                end
            end
            
        else
            target_file = [files_out filesep file_name];
            flag_exist = exist(target_file,'file')&flag_skip;
            if ~flag_exist
                instr_cp = ['cp -f ' source_file ' ' target_file];
                msg = sprintf('Copying %s to %s\n',source_file,target_file);
                if ~strcmp(source_file,target_file)
                    if flag_verbose
                        fprintf('%s',msg)
                    end
                    [flag_err,err_msg] = system(instr_cp);
                    if flag_err
                        error(err_msg)
                    end
                end
            else
                msg = sprintf('Copying %s to %s\n',source_file,target_file);
                msg2 = sprintf('   The output already existed. I will skip this one (FLAG_SKIP is true) ...\n',file_name);
                if flag_verbose
                    fprintf('%s%s',msg,msg2)
                end
            end
            
        end
    end
    
   system(['rm -rf ' tmp_folder]);
    
    if flag_recursive
        
        for num_d = 1:length(list_dir)
            
            niak_brick_mnc2nii3d([files_in filesep list_dir{num_d}],[files_out filesep list_dir{num_d}],opt);
            
        end
    end
    
catch
    errmsg = lasterror;
    system(['rm -rf ' tmp_folder]);
    fprintf('\n\n******************\nSomething went bad ... the pipeline has FAILED !\nThe last error message occured was :\n%s\n',errmsg.message);
end
