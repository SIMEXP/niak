function [files_in,files_out,opt] = niak_brick_glm_table(files_in,files_out,opt)

% Build a summary table of a statistical parametric map.
% Includes different tresholding flavor (uncorrected p, FWE, FDR) as well
% as peak and cluster statistics, and labels from the AAL template.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_TABLE(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
%
% FILES_IN  (structure) with the following fields :
%
%     SPM (string) an 3D statstical parametrical map.
%
%     MASK (string) a binary mask of the search region.
%
%     DF (string) a MAT file containing the degrees of freedom information
%           from the GLM analysis (either level 1 or 2).
%
% FILES_OUT (string) default (<BASE NAME SPM>_table.txt)
%       A table with summary statistics of the statistical parametric map
%       peaks and clusters, along with aal labels if the space of analysis
%       is MNI152.
%
% OPT   (structure) with the following fields.
%       Note that if a field is omitted, it will be set to a default
%       value if possible, or will issue an error otherwise.
%
%
%       FOLDER_OUT (string, default: path of FILES_IN) 
%           If present, all default outputs will be created in the folder 
%           FOLDER_OUT. The folder needs to be created beforehand.
%
%       FLAG_VERBOSE (boolean, default 1) 
%           if the flag is 1, then the function prints some infos during 
%           the processing.
%
%       FLAG_TEST (boolean, default 0) 
%           if FLAG_TEST equals 1, the brick does not do anything but 
%           update the default values in FILES_IN, FILES_OUT and OPT.
%
%
% OUTPUTS
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% COMMENTS:
% This brick is a "NIAKized" overlay of the STAT_SUMMARY function from the
% fMRIstat toolbox by Keith Worsley :
% http://www.math.mcgill.ca/keith/fmristat/
% 
% The labels come from the aal template:
% Tzourio-Mazoyer N et al. Automated anatomical labelling of activations in spm using a macroscopic anatomical parcellation of the MNI MRI single subject brain. Neuroimage 2002; 15: 273-289. 
% Please see NIAK_LABEL_PEAK for more info
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYNTAX
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_GLM_LEVEL1(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_glm_level1'' for more info.')
end

%% FILES_IN
gb_name_structure = 'files_in';
gb_list_fields = {'fmri','design'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

if ~ischar(files_in.fmri)
    error('niak_brick_glm_level1: FILES_IN.FMRI should be a string');
end

if ~ischar(files_in.design)
    error('niak_brick_glm_level1: FILES_IN.DESIGN should be a string');
end

if ~exist(files_in.fmri,'file')
    error(cat(2,'niak_brick_glm_level1: FILES_IN.FMRI does not exist (',files_in.fmri,')'));
end

if ~exist(files_in.design,'file')
    error(cat(2,'niak_brick_glm_level1: FILES_IN.DESIGN does not exist (',files_in.design,')'));
end
    
%% OPTIONS
gb_name_structure = 'opt';
gb_list_fields = {'contrast','confounds','fwhm_cor','exclude','nb_trends_spatial','nb_trends_temporal','numlags','pcnt','num_hrf_bases','basis_type','df_limit','flag_test','folder_out','flag_verbose'};
gb_list_defaults = {NaN,[],-100,[],0,0,1,1,[],'spectral',4,0,'',1};
niak_set_defaults

if isempty(num_hrf_bases)    
    
    design = load(files_in.design);
    if  ~isfield(design,'X_cache')
        error('The file FMRI.DESIGN should be a matrix containing a matlab variable called X_cache')
    end
    nb_response = size(design.X_cache.X,2);
    opt.num_hrf_bases = ones([nb_response 1]);
    
end

%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields = {'df','spatial_av','mag_t','del_t','mag_ef','del_ef','mag_sd','del_sd','mag_f','cor','resid','wresid','ar','fwhm'};
gb_list_defaults = {'gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted','gb_niak_omitted'};
niak_set_defaults        

%% Parsing base names
[path_f,name_f,ext_f] = fileparts(files_in.fmri);

if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if isempty(opt.folder_out)
    folder_f = path_f;
else
    folder_f = opt.folder_out;
end
       
%% Generating the default outputs of the FMRILM function and the NIAK brick
list_contrast = fieldnames(opt.contrast);
folder_fmri = niak_path_tmp('_fmristat');
nb_cont = length(list_contrast);

if strcmp(files_out.df,'') % df
    files_out.df = cat(2,folder_f,name_f,'_df.mat');
end

if strcmp(files_out.spatial_av,'')  % spatial_av
    files_out.spatial_av = cat(2,folder_f,name_f,'_spatial_av.mat');
end

%% contrast-dependent outputs
list_outputs = {'_mag_t','_del_t','_mag_ef','_del_ef','_mag_sd','_del_sd','_mag_F','_cor','_fwhm','_resid','_wresid','_AR'};
files_fmri.tmp = '';
which_stats = '';

for num_l = 1:length(list_outputs)

    str_tmp = cell([nb_cont 1]);
    str_tmp2 = cell([nb_cont 1]);
    for num_c = 1:nb_cont
        str_tmp{num_c} = cat(2,folder_f,name_f,'_',list_contrast{num_c},list_outputs{num_l},ext_f);
        str_tmp2{num_c} = cat(2,folder_fmri,name_f,'_',list_contrast{num_c},list_outputs{num_l},ext_f);
    end

    field_name = lower(list_outputs{num_l}(2:end));
    if strcmp(getfield(files_out,field_name),'')
        files_out = setfield(files_out,field_name,str_tmp);
        which_stats = cat(2,which_stats,' ',list_outputs{num_l});
    end
    files_fmri = setfield(files_fmri,field_name,str_tmp2);

end
files_fmri = rmfield(files_fmri,'tmp');

% %% Other outputs (do not depend on the contrast)
% list_outputs = {'_resid','_wresid','_ar'};
% for num_l = 1:length(list_outputs)
%     field_name = lower(list_outputs{num_l}(2:end));
%     if strcmp(getfield(files_out,field_name),'')
%         files_out = setfield(files_out,field_name,cat(2,folder_f,name_f,'_resid',ext_f));
%         which_stats = cat(2,which_stats,' ',list_outputs{num_l});
%     end
%     files_fmri = setfield(files_fmri,field_name,cat(2,folder_fmri,name_f,list_outputs{num_l},ext_f));
% end

if flag_test == 1
    rmdir(folder_fmri);
    return
end

%%%%%%%%%%%%
%% fmrilm %%
%%%%%%%%%%%%

flag_exist = exist('fmrilm');
if ~(flag_exist==2)
    error('I could not find the FMRILM function of the fMRIstat package. Instructions for installation can be found at http://www.math.mcgill.ca/keith/fmristat/')
end

%% output base name
output_file_base = [];
for num_c = 1:nb_cont
    if size(output_file_base,1)>0
        output_file_base = char(output_file_base,cat(2,folder_fmri,name_f,'_',list_contrast{num_c}));
    else
        output_file_base = cat(2,folder_fmri,name_f,'_',list_contrast{num_c});
    end
end

%% Design
design = load(files_in.design);
if  ~isfield(design,'X_cache')
    error('The file FMRI.DESIGN should be a matrix containing a matlab variable called X_cache')
end

%% contrast
nb_reg = 0;
for num_c = 1:nb_cont
    cont = getfield(opt.contrast,list_contrast{num_c});
    nb_reg = max(nb_reg,length(cont));
end

mat_contrast = zeros([nb_cont nb_reg]);
for num_c = 1:nb_cont
    cont = getfield(opt.contrast,list_contrast{num_c});
    mat_contrast(1:length(cont),:) = cont(:)';
end

%% Actual call to fmrilm   
[df,spatial_av] = fmrilm(files_in.fmri,output_file_base,design.X_cache,mat_contrast,exclude,which_stats,fwhm_cor,[nb_trends_temporal nb_trends_spatial pcnt],confounds,[],num_hrf_bases,basis_type,numlags,df_limit);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Moving outputs to the right folder %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~strcmp(files_out.df,'gb_niak_omitted');
    save(files_out.df,'df');
end

if ~strcmp(files_out.spatial_av,'gb_niak_omitted');
    save(files_out.spatial_av,'spatial_av');
end

list_fields = fieldnames(files_out);
mask_totej = niak_cmp_str_cell(list_fields,{'df','spatial_av'});
list_fields = list_fields(~mask_totej);

for num_l = 1:length(list_fields)
    
    field_name = list_fields{num_l};
    
    val_field_out = getfield(files_out,field_name);
    val_field_fmri = getfield(files_fmri,field_name);
    
    if ~ischar(val_field_out)
        
        %% Multiple outputs in a cell of strings
        nb_entries = length(val_field_out);
        for num_e = 1:nb_entries
            instr_mv = cat(2,'mv ',val_field_fmri{num_e},' ',val_field_out{num_e});
            [err,msg] = system(instr_mv);
            if err~=0
                warning(msg)
            end
        end
        
    else
        
        %% A single output, maybe an 'omitted' tag
        if ~strcmp(val_field_out,'gb_niak_omitted')
            instr_mv = cat(2,'mv ',val_field_fmri,' ',val_field_out);
            [err,msg] = system(instr_mv);
            if err~=0
                warning(msg)
            end
        end
        
    end
    
end
    
%% Deleting temporary files
system(cat(2,'rm -rf ',folder_fmri));