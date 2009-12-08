function [files_in,files_out,opt] = niak_brick_anonymize_mnc(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_ANONYMIZE_MNC
%
% Copy the content of a directory and anonymize all the MINC headers.
% Specifically, all infos beyond world coordinates informations are lost.
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANONYMIZE_MNC(FILES_IN,FILES_OUT,OPT)
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANONYMIZE_MNC(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_anonymize_mnc'' for more info.')
end
if ~exist('files_out','var')||isempty(files_out)
    files_out = files_in;
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_recursive','flag_verbose'};
gb_list_defaults = {true,true};
niak_set_defaults

dir_files = dir(files_in);

mask_dir = [dir_files.isdir];
list_all = {dir_files.name};
mask_dot = ismember(list_all,{'.','..'});
mask_dir = mask_dir(~mask_dot);
list_all = list_all(~mask_dot);
list_files = list_all(~mask_dir);
list_dir = list_all(mask_dir);

niak_mkdir(files_out);

for num_f = 1:length(list_files)
    
    file_name = list_files{num_f};
    source_file = [files_in filesep file_name];
    
    [path_tmp,name_tmp,ext] = fileparts(file_name);
    
    if strcmp(ext,gb_niak_zip_ext)
        [path_tmp,name_tmp,ext] = fileparts(name_tmp);
        ext = [ext gb_niak_zip_ext];
    end
    
    if strcmp(ext,'.mnc')||strcmp(ext,['.mnc' gb_niak_zip_ext])
        target_file = [files_out filesep name_tmp ext];
        [hdr,vol] = niak_read_vol(source_file);
        hdr.file_name = target_file;
        hdr = rmfield(hdr,'details');
        hdr.info.history = '';
        niak_write_vol(hdr,vol);        
        msg = sprintf('Convert %s to %s\n',source_file,target_file);
    else
        target_file = [files_out filesep file_name];
        instr_cp = ['cp -f ' source_file ' ' target_file];        
        msg = sprintf('Copy %s to %s\n',source_file,target_file);
        [flag_err,err_msg] = system(instr_cp);
        if flag_err
            error(err_msg)
        end
    end    
        
    if ~strcmp(source_file,target_file)
        if flag_verbose
            fprintf('%s',msg)
        end        
    end

end

if flag_recursive
    
    for num_d = 1:length(list_dir)
        
        niak_brick_anonymize_mnc([files_in filesep list_dir{num_d}],[files_out filesep list_dir{num_d}],opt);
        
    end
end
