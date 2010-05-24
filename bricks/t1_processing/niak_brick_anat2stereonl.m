function [files_in,files_out,opt] = niak_brick_anat2stereonl(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_ANAT2STEREONL
%
% Non-linear coregistration of a T1 anatomical scan in native space to the 
% MNI stereotaxic space.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANAT2STEREONL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN        
%       (structure) with the following fields :
%
%       T1
%           (string) the file name of a T1 volume.
%
%       T1_MASK
%           (string, default 'gb_niak_omitted') the file name of a binary 
%           mask of a region of interest. If unspecified (or equal to 
%           'gb_niak_omitted'), no mask is used (either for the T1 or for 
%           the template).
%
%       TEMPLATE
%           (string, default '') the file name of the target template. If
%           left empty, the default will be used, i.e. the MNI-152
%           symmetrical non-linear average (see COMMENTS below). 
%
%       TEMPLATE_MASK
%           (string, default '') the file name of a binary mask of a region
%           of interest in the template space. If left empty, the default
%           will be used, i.e. a brain mask of the default template (see
%           COMMENTS below).
%
%   FILES_OUT
%       (structure) with the following fields.  Note that if a field is an 
%       empty string, a default value will be used to name the outputs. 
%       If a field is ommited, the output won't be saved at all (this is 
%       equivalent to setting up the output file names to 
%       'gb_niak_omitted'). 
%                       
%       TRANSFORMATION
%           (string, default <base FILES_IN.T1>_native2stereonl.xfm) The 
%           non-linear transformation to the stereotaxic space.
%
%       TRANSFORMATION_GRID
%           (string, default <base FILES_IN.T1>_native2stereonl_grid.<ext FILE_IN.T1>) 
%           The grid of the non-linear transformation to the stereotaxic 
%           space.
%
%       T1_STEREONL
%           (string, default <base FILES_IN.T1>_stereonl.<ext FILE_IN.T1>) 
%           The T1 image resampled in stereotaxic space.
%
%   OPT           
%       (structure) with the following fields:
%
%       ARG
%           (string, default '') any argument that will be passed to the
%           NIAK_BESTLINREG script (see comments below). 
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
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MASK_BRAIN_T1, NIAK_BRICK_NU_CORRECT,
% NIAK_BRICK_ANAT_PREPROCESS, NIAK_BRICK_ANAT2STEREOLIN
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   This is a simple wrapper of a perl script called BEST1STEPNLREG.PL, by
%   Claude Lepage and Andrew Janke. The script is bundled in NIAK and can
%   be found in <root niak>/extensions/CIVET-1.1.9/niak_best1stnlreg.pl
%   See the script code for license information (it is a BSD-like license
%   similar to what is used in most minc tools). Note that the script is
%   simply included in NIAK archive releases, but is not part of the
%   subversion repository hosted by google code. As a consequence, a simple
%   download of the latest NIAK code repository will not be enough to get
%   this brick to work.
%
% NOTE 2: 
%   The BEST1STEPNLREG script does hierachical non-linear fitting between 
%   two files. The script needs to be manually edited to change the 
%   parameters of the fit. Most of the work is actually done by the 
%   MNI-AUTOREG package by Louis Collins, Andrew Janke and Steve Robbins. 
%   This package needs to be installed independently of NIAK, as part of 
%   the MINC bundle. See :
%   http://www.bic.mni.mcgill.ca/ServicesSoftware/HomePage
%
% NOTE 3:
%   The default template is the so-called "mni-models_icbm152-nl-2009-1.0"
%   by Louis Collins, Vladimir Fonov and Andrew Janke. 
%   A small subset of this package is bundled in the NIAK archive releases
%   and can be found in :
%   <root niak>/extensions/mni-models_icbm152-nl-2009-1.0
%   See the AUTHORS, COPYING and README files in this folder for details
%   about authorship and license information (it is a BSD-like license
%   similar to what is used in most minc tools). Note that the templates
%   are simply included in NIAK archive releases, but are not part of the
%   subversion repository hosted by google code. As a consequence, a simple
%   download of the latest NIAK code repository will not be enough to get
%   this brick to work.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, T1, non-linear coregistration, template

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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_ANAT2STEREONL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_anat2stereonl'' for more info.')
end

%% Input files
gb_name_structure = 'files_in';
gb_list_fields = {'t1','t1_mask','template','template_mask'};
gb_list_defaults = {NaN,'gb_niak_omitted','',''};
niak_set_defaults

%% Output files
gb_name_structure = 'files_out';
gb_list_fields = {'transformation','transformation_grid','t1_stereonl'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'arg','flag_verbose','folder_out','flag_test'};
gb_list_defaults = {'',true,'',false};
niak_set_defaults

%% Building default input names for template
if isempty(files_in.template)
    flag_gb_niak_fast_gb = false;
    niak_gb_vars; % load important NIAK variables
    files_in.template = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a.mnc.gz'];
    files_in.template_mask = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0' filesep 'mni_icbm152_t1_tal_nlin_sym_09a_mask.mnc.gz'];
end

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in.t1);
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

if isempty(files_out.t1_stereonl)
    files_out.t1_stereonl = [opt.folder_out,filesep,name_f,'_stereonl',ext_f];
end

if isempty(files_out.transformation)
    files_out.transformation = [opt.folder_out,filesep,name_f,'_native2stereonl.xfm'];
end

if isempty(files_out.transformation_grid)
    files_out.transformation_grid = [opt.folder_out,filesep,name_f,'_native2stereonl_grid' ext_f];
end

if flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = 'Non-linear coregistration to stereotaxic space';
    stars = repmat('*',[1 length(msg)]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);    
end

%% Building the path to access the perl script
if ~exist('gb_niak_path_niak','var')
    flag_gb_niak_fast_gb = false;    
    niak_gb_vars; % load important NIAK variables
end

file_script = [gb_niak_path_niak 'commands' filesep 't1_processing' filesep 'niak_best1stepnlreg.pl'];
   
%% Setting up the system call to NIAK_BESTLINREG.PL
if strcmp(files_in.t1_mask,'gb_niak_omitted')
    arg_mask = '';
else
    arg_mask = ['-source_mask ' files_in.t1_mask ' -target_mask ' files_in.template_mask];
end

if strcmp(files_out.transformation,'gb_niak_omitted')
    arg_transf = niak_file_tmp(['_' name_f '_native2stereonl.xfm']);
else
    arg_transf = files_out.transformation;
end

if strcmp(files_out.t1_stereonl,'gb_niak_omitted')
    arg_out = '';
else
    [path_f,name_f,ext_f] = fileparts(files_out.t1_stereonl);
    
    if isempty(path_f)
        path_f = '.';
    end
    
    if strcmp(ext_f,gb_niak_zip_ext)
        [tmp,name_f,ext_f] = fileparts(name_f);        
        flag_zip = true;        
    else 
        flag_zip = false;
    end
    file_stereonl = [path_f,filesep,name_f,ext_f];
    
    arg_out = file_stereonl;
end

instr = [file_script ' -clobber ' arg ' ' arg_mask ' ' files_in.t1 ' ' files_in.template ' ' arg_transf ' ' arg_out];    

%% Running NIAK_BESTLINREG.PL
if flag_verbose
    fprintf('Running BEST1STEPNLREG with the following command:\n%s\n\n',instr)
end

if flag_verbose
    system(instr)
else
    [status,msg] = system(instr);
    if status~=0
        error('The BEST1STEPNLREG command failed with that error message :\n%s\n',msg);
    end
end

%% if necessary, zip the output non-linear volume
if flag_zip
    system([gb_niak_zip ' ' file_stereonl]);
end

%% Renaming the output grid file
[path_t,name_t,ext_t] = fileparts(files_out.transformation);
file_grid = [path_t,filesep,name_t,'_grid_0.mnc'];
[path_g,name_g,ext_g] = fileparts(files_out.transformation_grid);
if strcmp(ext_g,gb_niak_zip_ext)    
    instr_zip = [gb_niak_zip ' ' file_grid];
    [status,msg] = system(instr_zip);
    if status ~= 0
        error('There was a problem zipping the grid file, error message : %s',msg);
    end
    file_grid = [file_grid gb_niak_zip_ext];
end
instr_mv = ['mv ' file_grid ' ' files_out.transformation_grid];
[status,msg] = system(instr_mv);
if status ~= 0
    error('There was a problem moving the final grid file, error message : %s',msg);
end
sub_rename_grid(files_out.transformation_grid,files_out.transformation);

%% Cleaning temporary files
if strcmp(files_out.transformation,'gb_niak_omitted')
   system(['rm -f ' arg_transf])
end
if flag_verbose
    fprintf('Done !\n')
end

%% Rename the grid file in the xfm file
function [] = sub_rename_grid(file_grid,file_xfm)

hf = fopen(file_xfm,'r');
xfm_info = fread(hf,Inf,'uint8=>char')';
fclose(hf);

hf2 = fopen(file_xfm,'w');
cell_info = niak_string2lines(xfm_info);

for num_l = 1:length(cell_info)
    if num_l~=length(cell_info)
        fprintf(hf2,'%s\n',cell_info{num_l});
    else
        [tmp,tmp2,tmp3] = fileparts(file_grid);
        fprintf(hf2,'Displacement_Volume = %s;\n',cat(2,tmp2,tmp3));
    end
end
fclose(hf2);
