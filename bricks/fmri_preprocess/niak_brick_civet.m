function [files_in,files_out,opt] = niak_brick_civet(files_in,files_out,opt)
% Run the CIVET pipeline on a T1 anatomical image. 
%
% Possible outputs include the estimated transformation to the MNI152 
% template (linear/lsq9 and non-linear), non-uniformity corrected volumes 
% in the native and template space, segmentation in white matter/grey 
% matter/CSF in native and template spaces, partial volume effect estimates 
% in native and template spaces, a mask of the brain in native and template 
% spaces. 
% 
% For more information on the CIVET pipeline, see :
% http://wiki.bic.mni.mcgill.ca/index.php/CIVET
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CIVET(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN 
%       (structure) with the following fields :
%
%       ANAT 
%           (string) a file with an individual T1 anatomical volume. If 
%           previous results of civet are used (see below), this should be 
%           an empty string.
%
%       CIVET 
%           (structure) If OPT.CIVET is specified to import results of a 
%           previously generated results using CIVET, this field will be 
%           updated to indicate all files of the original results that have 
%           been copied and renamed. This is usefull in pipeline mode for 
%           proper handling of inputs/outputs dependencies.
%
%  * FILES_OUT  
%       (structure) with the following fields. Note that if a field is an 
%       empty string, a default value will be used to name the outputs. If 
%       a field is ommited, the output won't be saved at all (this is 
%       equivalent to setting up the output file names to 
%       'gb_niak_omitted').
%
%
%       TRANSFORMATION_LIN 
%           (string, default transf_<BASE_ANAT>_native_to_stereolin.xfm)
%           Linear transformation from native to stereotaxic space (lsq9).
%
%       TRANSFORMATION_NL 
%           (string, default transf_<BASE_ANAT>_stereolin_to_stereonl.xfm)
%           Non-linear transformation from linear stereotaxic space to
%           stereotaxic space.
%
%       TRANSFORMATION_NL_GRID 
%           (string, default transf_<BASE_ANAT>_stereolin_to_stereonl_grid.mnc)
%           Deformation field for non-linear transformation.
%
%       ANAT_NUC 
%           (string, default <BASE_ANAT>_nuc_native.<EXT>)
%           t1 image partially corrected for non-uniformities (without
%           mask), in native space.
%       
%       ANAT_NUC_STEREO_LIN 
%           (string, default <BASE_ANAT>_nuc_stereolin.<EXT>)
%           original t1 image transformed in stereotaxic space using the 
%           lsq9 transformation, fully corrected for non-uniformities (with mask)
%
%       ANAT_NUC_STEREO_NL 
%           (string, default <BASE_ANAT>_nuc_stereonl.<EXT>)
%           original t1 image transformed in stereotaxic space using the 
%           non-linear transformation, fully corrected for non-uniformities (with
%           mask)
%       
%       MASK 
%           (string, default <BASE_ANAT>_mask_native.<EXT>)
%           brain mask in native space.
%
%       MASK_STEREO 
%           (string, default <BASE_ANAT>_mask_stereolin.<EXT>)
%           brain mask in stereotaxic (linear) space.
%
%       CLASSIFY 
%           (string, default <BASE_ANAT>_classify_stereolin.<EXT>)
%           final masked discrete tissue classification in stereotaxic
%           (linear) space after correction for partial volumes.
%
%       PVE_WM 
%           (string, default <BASE_ANAT>_wm_stereolin.<EXT>)
%           partial volume estimates for white matter in stereotaxic space.
%
%       PVE_GM 
%           (string, default <BASE_ANAT>_gm_stereolin.<EXT>)
%           partial volume estimates for grey matter in stereotaxic (linear)
%           space.
%
%       PVE_CSF 
%           (string, default <BASE_ANAT>_csf_stereolin.<EXT>)
%           partial volume estimates for cerebro-spinal fluids in 
%           stereotaxic (linear) space.
%
%       VERIFY 
%           (string, default <BASE_ANAT>_verify.png)
%           quality control image for registration and classification
%
%   
%  * OPT   
%       (structure) with the following fields:
%
%       N3_DISTANCE 
%           (real number, default 200 mm)  N3 spline distance in mm 
%           (suggested values: 200 for 1.5T scan; 25 for 3T scan). 
%
%       CIVET_COMMAND
%           (string, default
%           GB_NIAK_PATH_CIVET/CIVET_Processing_Pipeline)
%           The command used to invoke CIVET.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_KEEP_TMP
%           (boolean, default 0) if FLAG_KEEP_TMP is true, the temporary
%           folder will not be removed after completion of the job. This
%           might be useful to get access to the logs of CIVET.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%
%       FLAG_VERBOSE 
%           (boolean, default: 1) If FLAG_VERBOSE == 1, write
%           messages indicating progress.
%
%       CIVET (structure)
%           If this field is present, the CIVET pipeline WILL NOT be used
%           to process the data. Instead, a copy/renaming of previously
%           generated results will be used. All of the following fields need
%           to be specified :
%               
%               FOLDER 
%                   (string) The path of a folder with CIVET results. If 
%                   this field is specified, the brick is not going to run 
%                   CIVET but will rather copy and rename files from the 
%                   previously processed CIVET results.
%                   The field ANAT will be ignored in this case.
%
%               ID 
%                   (string) If results of a previous CIVET processing are 
%                   used, an ID has to be specified for the subject.
%
%               PREFIX 
%                   (string) If results of a previous CIVET processing are 
%                   used, a prefix has to be specified for the database.
%
% _________________________________________________________________________
% OUTPUTS
%
%   The structures FILES_IN, FILES_OUT and OPT are updated with default
%   values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO
% 
% NIAK_DEMO_CIVET, NIAK_PIPELINE_FMRI_PREPROCESS
%
% _________________________________________________________________________
% COMMENTS
%
% The outputs of the CIVET pipeline will never be zipped, even if the
% inputs were zipped. That's a bit tough, but zipping the minc outputs is 
% simply too much work. 
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, filtering, fMRI

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

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CIVET(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_civet'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'anat','civet'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'transformation_lin','transformation_nl','transformation_nl_grid','anat_nuc','anat_nuc_stereo_lin','anat_nuc_stereo_nl','mask','mask_stereo','classify','pve_wm','pve_gm','pve_csf','verify'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults

%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'flag_keep_tmp','civet_command','flag_test','folder_out','flag_verbose','n3_distance','civet'};
gb_list_defaults = {0,'',0,'',1,200,'gb_niak_omitted'};
niak_set_defaults
        
if isempty(civet_command)
    civet_command = cat(2,gb_niak_path_civet,filesep,'CIVET_Processing_Pipeline');
end

if isstruct(opt.civet)
    if ~isfield(opt.civet,'folder')|~isfield(opt.civet,'id')|~isfield(opt.civet,'prefix')
        error('Please specify fields FOLDER, ID and PREFIX in OPT.CIVET');
    end
    flag_civet = 1;
else
    flag_civet = 0;
end

%% Building default output names

if ~flag_civet
    
    %% A file FILES_IN.ANAT has been specified, parse its base name and
    %% folder
    [path_anat,name_anat,ext_anat] = fileparts(files_in.anat);

    if isempty(path_anat)
        path_anat = '.';
    end

    if strcmp(ext_anat,gb_niak_zip_ext)
        [tmp,name_anat,ext_anat] = fileparts(name_anat);        
        flag_zip = 1;
    else
        flag_zip = 0;
    end

    if isempty(opt.folder_out)
        folder_anat = path_anat;
    else
        folder_anat = opt.folder_out;
    end
    
    %% Generate temporary names to run the CIVET pipeline.   
    if ~flag_test
        civet_folder = niak_path_tmp('_civet');   
    else
        civet_folder = [filesep 'tmp' filesep];
    end
    civet_id = 'coco';
    civet_prefix = 'anat';        
    
else
    
    %% Previsouly generated CIVET results have been specified. Use the
    %% CIVET folder, prefix and id to name the outputs.
    
    name_anat = cat(2,opt.civet.prefix,'_',opt.civet.id);
    ext_anat = '.mnc';
    flag_zip = 0;
    
    if isempty(opt.folder_out)
        folder_anat = opt.civet.folder;        
    else
        folder_anat = opt.folder_out;
    end
    
    civet_folder = opt.civet.folder;
    civet_id = opt.civet.id;
    civet_prefix = opt.civet.prefix;
    
    files_in.anat = 'gb_niak_omitted';
    
end
       
%% Generating the default outputs of the NIAK brick and civet

if strcmp(files_out.transformation_lin,'')    
    files_out.transformation_lin = cat(2,folder_anat,'transf_',name_anat,'_native_to_stereolin.xfm');        
end
files_civet.transformation_lin = cat(2,civet_folder,civet_id,filesep,'transforms',filesep,'linear',filesep,civet_prefix,'_',civet_id,'_t1_tal.xfm');

if strcmp(files_out.transformation_nl,'')    
    files_out.transformation_nl = cat(2,folder_anat,'transf_',name_anat,'_stereolin_to_stereonl.xfm');    
end
files_civet.transformation_nl = cat(2,civet_folder,civet_id,filesep,'transforms',filesep,'nonlinear',filesep,civet_prefix,'_',civet_id,'_nlfit_It.xfm');

if strcmp(files_out.transformation_nl_grid,'')    
    files_out.transformation_nl_grid = cat(2,folder_anat,'transf_',name_anat,'_stereolin_to_stereonl_grid.mnc');    
end
files_civet.transformation_nl_grid = cat(2,civet_folder,civet_id,filesep,'transforms',filesep,'nonlinear',filesep,civet_prefix,'_',civet_id,'_nlfit_It_grid_0.mnc');

if strcmp(files_out.anat_nuc,'')    
    files_out.anat_nuc = cat(2,folder_anat,name_anat,'_nuc_native',ext_anat);    
end
files_civet.anat_nuc = cat(2,civet_folder,civet_id,filesep,'native',filesep,civet_prefix,'_',civet_id,'_t1_nuc.mnc');

if strcmp(files_out.anat_nuc_stereo_lin,'')    
    files_out.anat_nuc_stereo_lin = cat(2,folder_anat,name_anat,'_nuc_stereolin',ext_anat);    
end
files_civet.anat_nuc_stereo_lin = cat(2,civet_folder,civet_id,filesep,'final',filesep,civet_prefix,'_',civet_id,'_t1_final.mnc');

if strcmp(files_out.anat_nuc_stereo_nl,'')    
    files_out.anat_nuc_stereo_nl = cat(2,folder_anat,name_anat,'_nuc_stereonl',ext_anat);        
end
files_civet.anat_nuc_stereo_nl = cat(2,civet_folder,civet_id,filesep,'final',filesep,civet_prefix,'_',civet_id,'_t1_nl.mnc');

if strcmp(files_out.mask,'')    
    files_out.mask = cat(2,folder_anat,name_anat,'_mask_native',ext_anat);
end
files_civet.mask = cat(2,civet_folder,civet_id,filesep,'mask',filesep,civet_prefix,'_',civet_id,'_skull_mask_native.mnc');

if strcmp(files_out.mask_stereo,'')    
    files_out.mask_stereo = cat(2,folder_anat,name_anat,'_mask_stereolin',ext_anat);
end
files_civet.mask_stereo = cat(2,civet_folder,civet_id,filesep,'mask',filesep,civet_prefix,'_',civet_id,'_skull_mask.mnc');

if strcmp(files_out.classify,'')    
    files_out.classify = cat(2,folder_anat,name_anat,'_classify_stereolin',ext_anat);
end
files_civet.classify = cat(2,civet_folder,civet_id,filesep,'classify',filesep,civet_prefix,'_',civet_id,'_classify.mnc');

if strcmp(files_out.pve_wm,'')    
    files_out.pve_wm = cat(2,folder_anat,name_anat,'_wm_stereolin',ext_anat);
end
files_civet.pve_wm = cat(2,civet_folder,civet_id,filesep,'classify',filesep,civet_prefix,'_',civet_id,'_pve_wm.mnc');

if strcmp(files_out.pve_gm,'')    
    files_out.pve_gm = cat(2,folder_anat,name_anat,'_gm_stereolin',ext_anat);
end
files_civet.pve_gm = cat(2,civet_folder,civet_id,filesep,'classify',filesep,civet_prefix,'_',civet_id,'_pve_gm.mnc');

if strcmp(files_out.pve_csf,'')
    files_out.pve_csf = cat(2,folder_anat,name_anat,'_csf_stereolin',ext_anat);
end
files_civet.pve_csf = cat(2,civet_folder,civet_id,filesep,'classify',filesep,civet_prefix,'_',civet_id,'_pve_csf.mnc');

if strcmp(files_out.verify,'')
    files_out.verify = cat(2,folder_anat,name_anat,'_verify.png');
end
files_civet.verify = cat(2,civet_folder,civet_id,filesep,'verify',filesep,civet_prefix,'_',civet_id,'_verify.png');

if flag_civet
    files_in.civet = files_civet;
end

if flag_test == 1    
    return
end

%%%%%%%%%%%%%%%%
%% Run CIVET  %%
%%%%%%%%%%%%%%%%

%% If no pre-generated CIVET results have been specified, it is necessary
%% to run the CIVET pipeline on the anatomical volume

if ~flag_civet
       
    if flag_verbose
        fprintf('Running CIVET on volume %s. This is going to take a while ! (roughly one hour)\n',files_in.anat);
    end
    
    %% Copy the anatomical volume in a temporary folder, under a
    %% civet-compliant name.
    flag = niak_mkdir(civet_folder);
    if flag_zip
        [succ,msg] = system(cat(2,'cp ',files_in.anat,' ',civet_folder,filesep,civet_prefix,'_',civet_id,'_t1.mnc',gb_niak_zip_ext))
        if succ~=0
            error(msg);
        end
        [succ,msg] = system(cat(2,gb_niak_unzip,' ',civet_folder,filesep,civet_prefix,'_',civet_id,'_t1.mnc',gb_niak_zip_ext));        
    else
        [succ,msg] = system(cat(2,'cp ',files_in.anat,' ',civet_folder,filesep,civet_prefix,'_',civet_id,'_t1.mnc'));
    end
    if succ~=0
        error(msg);
    end
    
    %% Run CIVET in spawn mode
    niak_gb_vars
    instr_civet = cat(2,civet_command,' -sourcedir ',civet_folder,' -targetdir ',civet_folder,' -prefix ',civet_prefix,' -run ',civet_id,' -spawn -no-surfaces -N3-distance ',num2str(n3_distance));
    [flag,str] = system(instr_civet);
    if flag
        error(str)
    end
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copying and renaming the results of CIVET %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

list_results = {'transformation_lin','transformation_nl','transformation_nl_grid','anat_nuc','anat_nuc_stereo_lin','anat_nuc_stereo_nl','mask','mask_stereo','classify','pve_wm','pve_gm','pve_csf','verify'};

for num_r = 1:length(list_results)

    name_res = getfield(files_out,list_results{num_r});
    name_civet = getfield(files_civet,list_results{num_r});

    if ~strcmp(name_res,'gb_niak_omitted')

        if flag_verbose
            fprintf('Copying %s to %s\n',name_civet,name_res);
        end
        
        if ~strcmp(list_results{num_r},'transformation_nl')

            %% Just copy and rename the stuff
            [flag,str] = system(cat(2,'cp ',name_civet,' ',name_res));
            if flag~=0
                warning(str)
            end
        else

            %% For the non-linear transform, it is necessary to rename the
            %% grid file inside the xfm file.
            hf = fopen(name_civet,'r');
            hf2 = fopen(name_res,'w');
            xfm_info = fread(hf,Inf,'uint8=>char')';
            cell_info = niak_string2lines(xfm_info);
            
            for num_l = 1:length(cell_info)
                if num_l~=length(cell_info)
                    fprintf(hf2,'%s\n',cell_info{num_l});
                else
                    [tmp,tmp2,tmp3] = fileparts(files_out.transformation_nl_grid);
                    fprintf(hf2,'Displacement_Volume = %s;',cat(2,tmp2,tmp3));
                end
            end
            fclose(hf);
            fclose(hf2);
            
        end
                               
    end              
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cleaning temporary files %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~flag_civet

    if flag_verbose
        fprintf('Cleaning temporary files.\n')
    end
    
    if ~flag_keep_tmp
        try
            str = rmdir(civet_folder,'s');
        catch
            warning(str);
        end
    end
    
end

fprintf('Done !\n')