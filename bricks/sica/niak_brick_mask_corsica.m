function [files_in,files_out,opt] = niak_brick_mask_corsica(files_in,files_out,opt)
% Generate masks for automated identification of noise components in ICA
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_CORSICA(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN        
%   (structure) with the following fields :
%
%   MASK_VENT_STEREO
%       (string) the file 
%       name of a binary mask of ventricles in stereotaxic space.
%
%   MASK_STEM_STEREO
%       (string) the file 
%       name of a binary mask of brain stem in stereotaxic space.
%
%   FUNCTIONAL_SPACE
%       (string) the file name of a 3D volume which defines the native
%       functional space coordinates, resolution & bounding box.
%
%   TRANSFORMATION_LIN
%       (string) the file name of a linear xfm transformation file from
%       the individual functional space to the stereotaxic space.
%
%   TRANSFORMATION_NL
%       (string) the file name of a non-linear xfm transformation file from
%       the individual functional space to the stereotaxic space.
%
%   SEGMENTATION
%       (string) the file name of a segmentation into three tissu types
%       (cerebrospinal fluid / gray matter / white matter, in this order)
%       of the anatomical volume in linear stereotaxic space.
%
% FILES_OUT   
%   (structure) with the following fields : 
%   
%   MASK_VENT_IND
%       (string) the file name of a binary mask of ventricles in native 
%       functional space.
%
%   MASK_STEM_IND
%       (string) the file name of a binary mask of brain stem in native 
%       functional space.
%       
% OPT           
% 	(structure) with the following fields.  
%
%   FOLDER_OUT 
%       (string, default: path of FILES_IN.MASK_SEGMENTATION) 
%       If present, the output will be created in the folder FOLDER_OUT. 
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST 
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%       do anything but update the default values in FILES_IN, FILES_OUT 
%       and OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_T1_PREPROCESS, NIAK_PIPELINE_CORSICA
%
% _________________________________________________________________________
% COMMENTS
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Departement d'informatique et recherche 
% operationnelle, Universite de Montreal, 2010.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : CORSICA, fMRI, physiological noise

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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MASK_GROUP(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_mask_group'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields    = {'mask_vent_stereo' , 'mask_stem_stereo' , 'functional_space' , 'transformation_lin' , 'transformation_nl' , 'segmentation' };
gb_list_defaults  = {NaN                , NaN                , NaN                , NaN                  , NaN                 , NaN            };
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields    = {'mask_vent_ind' , 'mask_stem_ind' };
gb_list_defaults  = {NaN             , NaN             };
niak_set_defaults

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {true           , false       , ''           };
niak_set_defaults

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
folder_tmp = niak_path_tmp('_mask_corsica');
[path_f,name_f,ext_f] = niak_fileparts(files_in.mask_vent_stereo);

%% Resampling the segmentation into individual functional space.
if flag_verbose
    tic;
    fprintf('Resampling the segmentation of brain tissues in individual functional space - ')
end
clear files_in_res files_out_res opt_res
files_in_res.source         = files_in.segmentation;
files_in_res.target         = files_in.functional_space;
files_in_res.transformation = files_in.transformation_lin;
files_out_res               = [folder_tmp 'brain_segmentation_ind.mnc'];
opt_res.flag_invert_transf  = true;
opt_res.interpolation       = 'nearest_neighbour';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
if flag_verbose    
    fprintf('%1.2f sec.\n',toc)
end

%% Resampling the mask of the ventricle in native space
if flag_verbose
    tic;
    fprintf('Resampling the mask of the ventricle in native space - ')
end
clear files_in_res files_out_res opt_res
files_in_res.source         = files_in.mask_vent_stereo;
files_in_res.target         = files_in.functional_space;
files_in_res.transformation = files_in.transformation_nl;
files_out_res               = [folder_tmp 'mask_vent_ind.mnc'];
opt_res.flag_invert_transf  = true;
opt_res.interpolation       = 'nearest_neighbour';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
if flag_verbose    
    fprintf('%1.2f sec.\n',toc)
end

%% Resampling the mask of the brain stem in native space
if flag_verbose
    tic;
    fprintf('Resampling the mask of the brain stem in native space - ')
end
clear files_in_res files_out_res opt_res
files_in_res.source         = files_in.mask_stem_stereo;
files_in_res.target         = files_in.functional_space;
files_in_res.transformation = files_in.transformation_nl;
files_out_res               = [folder_tmp 'mask_stem_ind.mnc'];
opt_res.flag_invert_transf  = true;
opt_res.interpolation       = 'nearest_neighbour';
niak_brick_resample_vol(files_in_res,files_out_res,opt_res);
if flag_verbose    
    fprintf('%1.2f sec.\n',toc)
end

%% Combining ventricle and CSF masks
if flag_verbose
    tic;
    fprintf('Combining ventricle and CSF masks - ')
end
clear files_in_math files_out_math opt_math
files_in_math{1}    = [folder_tmp 'brain_segmentation_ind.mnc'];
files_in_math{2}    = [folder_tmp 'mask_vent_ind.mnc'];
files_out_math      = files_out.mask_vent_ind;
opt_math.operation  = 'vol = (vol_in{2} > 0) & (round(vol_in{1}) == 1);';
niak_brick_math_vol(files_in_math,files_out_math,opt_math);
if flag_verbose    
    fprintf('%1.2f sec.\n',toc)
end

%% Combining brain and gray matter masks
if flag_verbose
    tic;
    fprintf('Combining brain stem and gray matter masks - ')
end
clear files_in_math files_out_math opt_math
files_in_math{1}    = [folder_tmp 'brain_segmentation_ind.mnc'];
files_in_math{2}    = [folder_tmp 'mask_stem_ind.mnc'];
files_out_math      = files_out.mask_stem_ind;
opt_math.operation  = 'vol = (vol_in{2} > 0) & (round(vol_in{1}) ~= 2);';
niak_brick_math_vol(files_in_math,files_out_math,opt_math);
if flag_verbose    
    fprintf('%1.2f sec.\n',toc)
end
    
%% Clean up temporary files
[status,msg] = system(['rm -rf ' folder_tmp]);
if status ~= 0
    error(sprintf('There was a problem cleaning up the temporary folder.\nThe command was : %s\n The feedback was: %s\n'),['rm -rf ' folder_tmp],msg);
end