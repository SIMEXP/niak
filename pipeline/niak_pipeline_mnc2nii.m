function pipe = niak_pipeline_mnc2nii(files_in,opt)
% Mass convert the content of a folder from minc to nifti, and vice-versa.
% Non imaging files can be specified, they will simply be copied.
%
% PIPE = NIAK_PIPELINE_MNC2NII(FILES_IN,OPT)
%
% FILES_IN (cell of strings) a list of files. If a string is passed, it is 
%   assumed to be a folder, and all files inside are grabbed recursively. 
%
% OPT.FOLDER_OUT (string) where to save the converted files. 
% OPT.FOLDER_IN (string, default FILES_IN if FILES_IN is a string, mandatory
%   option otherwise) all input files are assumed to live under that folder. 
%   OPT.FOLDER_IN will be replaced by OPT.FOLDER_OUT for converted files.
% OPT.FLAG_MNC2NII (boolean, default true) if the flag is true, conversion is 
%   done from minc to nifti (as the name of the pipeline implies). If the 
%   flag is false, the conversion goes from nifti to minc. 
% OPT.BLACK_LIST (string or cell of string) a list of folder (or subfolders of 
%   OPT.FOLDER_IN) to be ignored by the grabber. Absolute names should be used
%   (i.e. '/home/user23/database/toto' rather than 'toto'). If not, the names
%   will be assumed to refer to the current directory.  
% OPT.ARG_MNC2NII (string, default '') an argument that will be added in
%   the system call to the MNC2NII function.
% OPT.FLAG_ZIP (boolean, default true for mnc2nii, false for nii2mnc) if 
%   FLAG_ZIP is true, the nii files are zipped. The tools used to zip files is 
%   'gzip -f'. This setting can be changed by editing the variable GB_NIAK_ZIP 
%   in the file NIAK_GB_VARS or NIAK_GB_VARS_LOCAL.
% OPT.FLAG_VERBOSE (boolean, default 1) if the flag is 1, then the function 
%   prints some infos during the processing.
% OPT.FLAG_TEST (boolean, default false) if OPT.FLAG_TEST is true, the pipeline
%   is generated but no tests are run 
% OPT.PSOM (structure, optional) options to send to PSOM_RUN_PIPELINE. 
%   See psom.simexp-lab.org
%
% PIPE (structure) a PSOM pipeline. See psom.simexp-lab.org
%
% Copyright (c) Pierre Bellec, 
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Quebec, Canada, 2016
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: MINC, NIFTI, conversion

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

if ~exist('files_in','var')
    error('syntax: PIPE = NIAK_PIPELINE_MNC2NII(FILES_IN,OPT)')
end

if ischar(files_in)
    opt.folder_in = files_in;
    files_in = niak_full_path(files_in);
end

%% Options
if nargin < 2
    opt = struct;
end
opt = psom_struct_defaults(opt, ...
   { 'flag_mnc2nii' , 'psom' , 'black_list' , 'folder_out' , 'folder_in' , 'flag_zip' , 'flag_verbose' , 'flag_test' , 'arg_mnc2nii' }, ...
   { true           , struct , {}           , NaN          , NaN         , true       , true           , false       , ''            });
opt.folder_in = niak_full_path(opt.folder_in);
opt.folder_out = niak_full_path(opt.folder_out);
opt.psom.path_logs = [opt.folder_out 'logs' filesep];
list_files = niak_grab_folder(opt.folder_in,opt.black_list);

%% Conversion options
if opt.flag_mnc2nii
    ext_source = { '.mnc' , '.mnc.gz' };
    ext_target = '.nii';
else
    ext_source = { '.nii' , '.nii.gz' };
    ext_target = '.mnc';
end

if opt.flag_zip
    ext_target = [ext_target '.gz'];
end
 
%% Build the pipeline
pipe = struct;
if opt.flag_verbose
    fprintf('Found %i files. Adding jobs ...\n',length(list_files));
end
for num_f = 1:length(list_files)
    if opt.flag_verbose
        niak_progress(num_f,length(list_files));
    end
        
    file_name = list_files{num_f};
    [path_f,name_f,ext_f] = niak_fileparts(file_name);
    path_f = [path_f filesep];
    name_job = ['job' niak_datahash(file_name)];
    if isfield(pipe,name_job)
        error('Distinct files results in identical hash. Please send a bug report.')
    end
    pipe.(name_job).files_in = file_name;
    ind = strfind(path_f,opt.folder_in);
    if isempty(ind)||(ind(1)~=1)
        error(sprintf('File %s does not live in folder OPT.FOLDER_IN %s',file_name,opt.folder_in))
    end
    if ismember(ext_f,ext_source)
        %% A neuroimaging file! Let's convert it    
        pipe.(name_job).files_out = [regexprep(path_f,['^' opt.folder_in],opt.folder_out) name_f ext_target];
        pipe.(name_job).command = '[hdr,vol] = niak_read_vol(files_in); hdr.file_name = files_out; niak_write_vol(hdr,vol);';
    else
        pipe.(name_job).files_in = {pipe.(name_job).files_in};
        pipe.(name_job).files_out = {[regexprep(path_f,['^' opt.folder_in],opt.folder_out) name_f ext_f]};
        pipe.(name_job).command = 'niak_brick_copy(files_in,files_out);';
    end
end

if ~opt.flag_test
    psom_run_pipeline(pipe,opt.psom);
end