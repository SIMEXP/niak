function [files_in,files_out,opt] = niak_brick_vol2surf(files_in,files_out,opt)
% Interpolate volumetric data onto a surface.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_VOL2SURF(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%    (structure) with the following fields:
%
%    VOL        
%        (string) a file name of a 3D or 3D+t dataset.
%
%    SURF
%        (string or cell of strings, default gray/white/middle surfaces for the 
%        2009 non-linear symmetric ICBM template) case string: the surface 
%        used to interpolate. Case cell of string size n x k: multiple 
%        surfaces are provided (SURF(k,:) is one surface, all surfaces are 
%        concatenated in the second dimension). Interpolation is performed on all 
%        surfaces and the max value (in absolute value) is retained. 
%
% FILES_OUT       
%    (string, default <BASE FILES_IN.VOL>_surf.mat) a MAT file with one
%    variable DATA. DATA(t,v) is the interpolated value of VOL(:,:,:,t) at 
%    node v of the surface. See FILES_IN.SURF for further comments on the case 
%    of multiple surfaces.
%
% OPT           
%    (structure) with the following fields.  
%
%    INTERPOLATION
%        (string, default 'nearest_neighbour') The interpolation scheme. 
%        available options : 'linear' , 'cubic' , 'nearest_neighbour'
%
%    FLAG_VERBOSE 
%        (boolean, default 1) if the flag is 1, then the function 
%        prints some infos during the processing.
%
%    FLAG_TEST 
%        (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%        do anything but update the default values in FILES_IN, 
%        FILES_OUT and OPT.
%        
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%           
% _________________________________________________________________________
% COMMENTS;
%
% This is a simple wraper of VOLUME_OBJECT_EVALUATE, part of the MINC 
% bundle. It will eventually be replaced by a pure matlab implementation,
% but that may take a while. This brick requires the minc tools to work.
%  
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Departement d'informatique et de recherche operationnelle,
% Universite de Montreal, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : surface, volume, interpolation

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_VOL2SURF(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_vol2surf'' for more info.')
end

%% Input files 
files_in = psom_struct_defaults(files_in,{'vol','surf'},{NaN,''});

if isempty(files_in.surf)
    niak_gb_vars
    path_surf = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0_surface' filesep];
    file_white_l = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_white_left.obj'];
    file_white_r = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_white_right.obj'];
    file_gray_l  = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_gray_left.obj'];
    file_gray_r  = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_gray_right.obj'];
    file_mid_l   = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_mid_left.obj'];
    file_mid_r   = [path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_mid_right.obj'];
    files_in.surf{1,1} = file_white_l;
    files_in.surf{1,2} = file_white_r;
    files_in.surf{2,1} = file_gray_l;
    files_in.surf{2,2} = file_gray_r;
    files_in.surf{3,1} = file_mid_l;
    files_in.surf{3,2} = file_mid_r;
end

if ischar(files_in.surf)
    files_in.surf = {files_in.surf};
end

%% Options
list_fields   = {'interpolation'     , 'flag_verbose' , 'flag_test' , 'folder_out' };
list_defaults = {'nearest_neighbour' , true           , false       , ''           };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

%% Output files
[path_f,name_f,ext_f] = niak_fileparts(files_in.vol);

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

if (nargin<2)||isempty(files_out)
    files_out = [opt.folder_out,filesep,name_f,'_surf.mat'];
end

if opt.flag_test == 1
    return
end

%% The brick starts here

%% Read the volume
if opt.flag_verbose
    fprintf('Reading volume %s ...\n',files_in.vol);
end
[hdr,vol] = niak_read_vol(files_in.vol);

%% Loop over volumes
if opt.flag_verbose
    fprintf('Interpolating volumetric data on the surface(s) ...\n')
end
vol_tmp = niak_file_tmp(['_interp_surf.mnc']);
data_tmp = niak_file_tmp(['_interp_surf.dat']);
for num_t = 1:size(vol,4)
    hdr.file_name = vol_tmp;
    niak_write_vol(hdr,vol(:,:,:,num_t));
    for num_s = 1:size(files_in.surf,1)
        for num_k = 1:size(files_in.surf,2)
            instr_interp = ['volume_object_evaluate -' opt.interpolation ' ' vol_tmp ' ' files_in.surf{num_s,num_k} ' ' data_tmp];
            [failed,msg] = system(instr_interp);
            if failed~=0
                error('The system call to VOLUME_OBJECT_EVALUATE failed : %s',msg)
            end
            if num_k == 1
                tmp = load(data_tmp);
            else
                tmp = [tmp ; load(data_tmp)];
            end
        end
        if (num_s == 1)&&(num_t==1)
            data = zeros(length(tmp),size(vol,4));
            data(:,num_t) = tmp;
        else
            data(abs(data(:,num_t))<=abs(tmp),num_t) = tmp(abs(data(:,num_t))<=abs(tmp));
        end
    end
end

%% Write results
if opt.flag_verbose
    fprintf('Saving results in %s ...\n',files_out);
end
save(files_out,'data');
delete(vol_tmp);
delete(data_tmp);
