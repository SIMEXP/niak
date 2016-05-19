function [files_in,files_out,opt] = niak_brick_t1_preprocess_minc(files_in,files_out,opt)
% Coregistration of a T1 brain volume in the MNI stereotaxic space.
% Both linear and non-linear transformations are estimated along with 
% various preprocessing (non-uniformity correction, intensity 
% normalization, brain extraction) and tissue classification. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_T1_PREPROCESS(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%ls
% FILES_IN.ANAT (string) the file name of a T1 volume.
% FILES_IN.TEMPLATE (string or structure, optional, default 'mni_icbm152_nlin_sym_09a')
%   the template that will be used as a target for brain coregistration. 
%   Available choices: 
%       'mni_icbm152_nlin_asym_09a' : an adult symmetric template 
%          (18.5 - 43 y.o., 40 iterations of non-linear fit). 
%       'mni_icbm152_nlin_sym_09a' : an adult asymmetric template 
%          (18.5 - 43 y.o., 20 iterations of non-linear fit). 
%   It is also possible to manually specify the template files with the following fields:
%        T1 (string) the T1 template
%        MASK (string) a brain mask
%        MASK_DILATED (string) a dilated brain mask
%        MASK_ERODED (string) an eroded brain mask
%
% FILES_OUT  
%    (structure) with the following fields. Note that if a field is an 
%    empty string, a default value will be used to name the outputs. If 
%    a field is ommited, the output won't be saved at all (this is 
%    equivalent to setting up the output file names to 
%    'gb_niak_omitted').
%
%
%    TRANSFORMATION_LIN 
%        (string, default <BASE_ANAT>_native2stereolin.xfm)
%        Linear transformation from native to stereotaxic space (lsq9).
%
%    TRANSFORMATION_NL 
%        (string, default <BASE_ANAT>_stereolin2stereonl.xfm)
%        Non-linear transformation from linear stereotaxic space to
%        non-linear stereotaxic space.
%
%    TRANSFORMATION_NL_GRID 
%        (string, default <BASE_ANAT>_stereolin2stereonl_grid.mnc)
%        Deformation field for the non-linear transformation.
%
%    ANAT_NUC 
%        (string, default <BASE_ANAT>_nuc_native.<EXT>)
%        t1 image partially corrected for non-uniformities (without
%        mask), in native space. Intensities have not been normalized.
%    
%    ANAT_NUC_STEREOLIN 
%        (string, default <BASE_ANAT>_nuc_stereolin.<EXT>)
%        original t1 image transformed in stereotaxic space using the 
%        lsq9 transformation, fully corrected for non-uniformities (with mask)
%        and with intensities normalized to match the MNI template.
%
%    ANAT_NUC_STEREONL 
%        (string, default <BASE_ANAT>_nuc_stereonl.<EXT>)
%        original t1 image transformed in stereotaxic space using the 
%        non-linear transformation, fully corrected for non-uniformities (with
%        mask) and with intensities normalized to match the MNI template.
%    
%    MASK_STEREOLIN 
%        (string, default <BASE_ANAT>_mask_stereolin.<EXT>)
%        brain mask in stereotaxic (linear) space.
%
%    MASK_STEREONL
%        (string, default <BASE_ANAT>_mask_stereonl.<EXT>)
%        brain mask in stereotaxic (non-linear) space.
%
%    CLASSIFY 
%        (string, default <BASE_ANAT>_classify_stereolin.<EXT>)
%        final masked discrete tissue classification in stereotaxic
%        (linear) space.
%
% OPT        
%    (structure) with the following fields:
%
%    MASK_BRAIN_T1
%        (structure) See the OPT structure of NIAK_BRICK_MASK_BRAIN_T1
%        for an exact list of options.
%
%    MASK_HEAD_T1
%        (structure) See the OPT structure of NIAK_BRICK_MASK_HEAD_T1
%        for an exact list of options.
%
%    NU_CORRECT
%        (structure) See the OPT structure of NIAK_BRICK_NU_CORRECT
%        for an exact list of options. The most usefull option is the
%        following :
%
%        ARG
%         (string, default '-distance 200') any argument that will be 
%         passed to the NU_CORRECT command. The '-distance' option 
%         sets the N3 spline distance in mm (suggested values: 200 
%         for 1.5T scan; 50 for 3T scan). 
%
%    FLAG_ALL
%        (boolean, default false) if FLAG_ALL is true, by default 
%        the brick will generate all outputs with default output 
%        names.
%
%    FLAG_VERBOSE 
%        (boolean, default: 1) If FLAG_VERBOSE == 1, write
%        messages indicating progress.
%
%    FLAG_TEST 
%        (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%        do anything but update the default values in FILES_IN, 
%        FILES_OUT and OPT.
%
%    FOLDER_OUT 
%        (string, default: path of FILES_IN) If present, all default 
%        outputs will be created in the folder FOLDER_OUT. The folder 
%        needs to be created beforehand.
%         
% _________________________________________________________________________
% OUTPUT:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_MASK_BRAIN_T1, NIAK_BRICK_NU_CORRECT,
% NIAK_BRICK_ANAT2STEREOLIN, NIAK_BRICK_ANAT2STEREONL,
% NIAK_BRICK_NU_CORRECT, NIAK_BRICK_INORMALIZE, NIAK_BRICK_CLASSIFY
%
% _________________________________________________________________________
% COMMENTS:
%
% NOTE 1:
%   This is essentially a NIAKified version of a small subpart of the CIVET
%   pipeline developed in the lab of Alan C. Evans, see :
%   http://wiki.bic.mni.mcgill.ca/index.php/CIVET
%   Claude Lepage, Andrew Janke, Vladimir Fonov and Patrick Bermudez gave 
%   precious directions to NIAKify this part of the pipeline.
%   Many other people were and are still involved in the development of 
%   CIVET, including Yasser Ad-Dab'bagh, Jason Lerch and Oliver Lyttelton. 
%   See the CIVET webpage for a detailed list of contributions. 
%
% NOTE 2:
%   This brick is based on all the bricks listed in the "see also" section
%   above. Please see the help of these bricks for more details. Two PERL
%   scripts written by Claude Lepage and Andrew Janke are also used and 
%   distributed with NIAK (NIAK_BESTLINREG.PL and NIAK_BEST1STEPNL.PL). 
%   These scripts do not follow the MIT license typically found in NIAK. 
%   See the PERL scripts code for license information (it is a BSD-like 
%   license similar to what is used in most minc tools). 
%
% NOTE 3: 
%   Almost all of the work here (except for the brain extraction) is done
%   by a package called MINC tools that needs to be installed for NIAK to
%   work properly : 
%   http://en.wikibooks.org/wiki/MINC
%   Coregistration in particular is powered by MINCTRAC and the MNI-AUTOREG
%   package by L. Collins and coll :
%   http://en.wikibooks.org/wiki/MINC/Tools/mni_autoreg
%
% NOTE 4:
%   The flowchart of the brick is as follows :
%
%    1.  Non-uniformity correction in native space (without mask):
%        NIAK_BRICK_NU_CORRECT
%
%    2.  Brain extraction in native space:
%        NIAK_BRICK_MASK_BRAIN_T1
%
%    3.  Linear coregistration in stereotaxic space (with mask from 2).
%        NIAK_BRICK_ANAT2STEREOLIN
%
%    4.  Non-uniformity correction based on the template mask
%        NIAK_BRICK_NU_CORRECT
%
%    5.  Brain extraction, combined with the template mask
%        NIAK_BRICK_MASK_BRAIN_T1
%
%    6.  Intensity normalization
%        NIAK_BRICK_INORMALIZE
%
%    7.  Non-linear coregistration in template space (with mask from 5)
%        NIAK_BRICK_ANAT2STEREONL
%
%    8.  Generation of the brain mask in the non-linear stereotaxic
%        space by intersection of the template mask with a head mask.
%        NIAK_BRICK_MASK_HEAD_T1, NIAK_BRICK_MATH_VOL
%
%    9.  Generation of the mask in the stereotaxic linear space by 
%        application of the inverse non-linear transform from 7 and the 
%        brain mask from 8.
%        NIAK_BRICK_RESAMPLE_VOL
%
%    10. Tissue classification
%        NIAK_BRICK_CLASSIFY
%
% NOTE 5:
%   The adult template is the so-called "mni-models_icbm152-nl-2009-1.0"
%   by Louis Collins, Vladimir Fonov and Andrew Janke. 
%   A small subset of this package is bundled in NIAK.
%   See the AUTHORS, COPYING and README files in the 
%   ~niak/template/mni-models_icbm152-nl-2009-1.0 
%   folder for details about authorship and license information (it is a 
%   BSD-like license similar to what is used in most of the minc tools). 
%   More infos can be found on the web :
%   http://www.bic.mni.mcgill.ca/ServicesAtlases/HomePage
%
%   The pediatric template was generated by the same group of 
%   investigators using the NIHPD database. See the following website for 
%   more details on this package (as well as the full version) : 
%   http://www.bic.mni.mcgill.ca/ServicesAtlases/NIHPD-obj1
%
% _________________________________________________________________________
% REFERENCES:
%
%   Regarding linear and non-linear coregistration :
%
%   D. L. Collins, P. Neelin, T. M. Peters and A. C. Evans, 
%   ``Automatic 3D Inter-Subject Registration of MR Volumetric Data in 
%   Standardized Talairach Space, Journal of Computer Assisted Tomography, 
%   18(2) pp192-205, 1994.
%
%   Collins, D.L. Evans, A.C. (1997). "ANIMAL: Validation and Applications
%   of Non-Linear Registration-Based Segmentation". "International Journal 
%   of Pattern Recognition and Artificial Intelligence", vol. 11, 
%   pp. 1271-1294.
%
%   Regarding the ICBM MNI non-linear template :
%
%   VS Fonov, AC Evans, K Botteron, CR Almli, RC McKinstry, DL Collins and 
%   the brain development cooperative group. Unbiased average 
%   age-appropriate atlases for pediatric studies. NeuroImage, Volume 54, 
%   2011, pp. 313-327.
%
%   Regarding the pipeline flowchart :
%
%   Zijdenbos, A.P., Forghani, R., and Evans, A.C. (2002). "Automatic
%   Pipeline Analysis of 3-D MRI Data for Clinical Trials: Application to 
%   Multiple Sclerosis". IEEE TRANSACTIONS ON MEDICAL IMAGING 21, 
%   pp. 1280-1291.
%
%   Regarding non-uniformity correction :
%
%   Sled, J.G., Zijdenbos, A.P., and Evans, A.C. (1998). "A Nonparametric
%   Method for Automatic Correction of Intensity Nonuniformity in MRI 
%   Data". IEEE Transactions on Medical Imaging 17, pp. 87-97.
%
%   Regarding brain extraction :
%
%   J. G. Park & C. Lee (2009). `Skull stripping based on region growing 
%   for magnetic resonance brain images'. NeuroImage 47(4):1394-1407.
%
%   Regarding brain tissue classification :
%
%   Tohka, J., Zijdenbos, A., and Evans, A.C. (2004). "Fast and robust
%   parameter estimation for statistical partial volume models in brain 
%   MRI". NeuroImage, 23(1), pp. 84-97.
%
%   More relevant references can be found here :
%   http://wiki.bic.mni.mcgill.ca/index.php/CIVETReferences
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, 
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, T1, template, classification, coregistration,
% non-uniformities correction, brain extraction

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
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('SYNTAX: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_T1_PREPROCESS(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_civet'' for more info.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
 %% OPTIONS
opt_tmp.flag_test = false;
gb_name_structure = 'opt';
gb_list_fields    = {'flag_all' , 'template'                 , 'flag_test' , 'folder_out' , 'flag_verbose', 'scanner_strength' };
gb_list_defaults  = {false      , 'mni_icbm152_nlin_sym_09c' , 0           , ''           , 1             , '1.5T' };
niak_set_defaults
                                       


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[path_anat,name_anat,ext_anat] = fileparts(files_in.anat);

if isempty(opt.folder_out)
    folder_anat = [path_anat filesep];
else
    folder_anat = opt.folder_out;
end

scanner_strength = ''
if regexpi(opt.scanner_strength, "3.*t");
  scanner_strength = '--3t';
end

is_gz = false
if strcmp(ext_anat, '.gz');
    [bidon, name_anat, ext_anat] = fileparts(name_anat);
is_gz = true
else
    t1_path = files_in.anat;
end


%% FILES_OUT
gb_name_structure = 'files_out';
gb_list_fields        = {'transformation_lin' , 'transformation_nl' , 'transformation_nl_grid' , 'anat_clp'        , 'anat_stereolin'   , 'anat_stereonl'   , 'mask_stereolin'   , 'classify'       };
if flag_all 
    gb_list_defaults  = {'' , '' , '' , '' , '' , '' , '' , '' };
else
    gb_list_defaults  = {'gb_niak_omitted'    , 'gb_niak_omitted'   , 'gb_niak_omitted'        , 'gb_niak_omitted' , 'gb_niak_omitted'  , 'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
end
niak_set_defaults

if strcmp(files_out.transformation_lin,'')
    files_out.transformation_lin =  cat(2,folder_anat,name_anat,'_native2stereolin.xfm');   
end


if strcmp(files_out.transformation_nl_grid,'')
    files_out.transformation_nl_grid = cat(2,folder_anat,name_anat,'_stereolin2stereonl_grid', ext_anat);
end

if strcmp(files_out.anat_nuc,'')
    files_out.anat_nuc = cat(2,folder_anat,name_anat,'_clp',ext_anat);
end

if strcmp(files_out.anat_nuc_stereolin,'')
    files_out.anat_nuc_stereolin = cat(2,folder_anat,name_anat,'_stereolin',ext_anat);
end

if strcmp(files_out.anat_nuc_stereonl,'')
    files_out.anat_nuc_stereonl = cat(2,folder_anat,name_anat,'_stereonl',ext_anat);
end

if strcmp(files_out.mask_stereolin,'')
    files_out.mask_stereolin = cat(2,folder_anat,name_anat,'_mask_stereolin',ext_anat);
end

if strcmp(files_out.classify,'')
    files_out.classify = cat(2,folder_anat,name_anat,'_classify_stereolin',ext_anat);
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%


if flag_verbose
    fprintf('***********************************\nPreprocessing of a T1 brain volume with the BIC standard_pipeline\n***********************************\n');
    fprintf('Original brain volume : %s\n',files_in.anat);
end


%standard_pipeline_out_tmp  = niak_path_tmp()
standard_pipeline_out_tmp  = '/home/poquirion/test/standard/pipo';

if is_gz;
    copyfile(files_in.anat, standard_pipeline_out_tmp);
    system(['gunzip -f ', standard_pipeline_out_tmp, filesep, name_anat, ext_anat, '.gz']);
    t1_path = [standard_pipeline_out_tmp, filesep, name_anat, ext_anat];
end


cmd = ['standard_pipeline.pl ' scanner_strength ' --verbose --basedir ' standard_pipeline_out_tmp  ' 0 0 ' t1_path];

system( cmd );

if strcmp(files_out.transformation_lin,'gb_niak_omitted')
    files_out.transformation_lin =  cat(2,folder_anat,name_anat,'_native2stereolin.xfm');   
end


if strcmp(files_out.transformation_nl_grid,'gb_niak_omitted')
    files_out.transformation_nl_grid = cat(2,folder_anat,name_anat,'_stereolin2stereonl_grid', ext_anat);
end

if strcmp(files_out.anat_clp,'gb_niak_omitted')
    files_out.anat_nuc = cat(2,folder_anat,name_anat,'_clp',ext_anat);
end

if strcmp(files_out.anat_nuc_stereolin,'gb_niak_omitted')
    files_out.anat_nuc_stereolin = cat(2,folder_anat,name_anat,'_stereolin',ext_anat);
end

if strcmp(files_out.anat_nuc_stereonl,'gb_niak_omitted')
    files_out.anat_nuc_stereonl = cat(2,folder_anat,name_anat,'_stereonl',ext_anat);
end

if strcmp(files_out.mask_stereolin,'gb_niak_omitted')
    files_out.mask_stereolin = cat(2,folder_anat,name_anat,'_mask_stereolin',ext_anat);
end

if strcmp(files_out.classify,'gb_niak_omitted')
    files_out.classify = cat(2,folder_anat,name_anat,'_classify_stereolin',ext_anat);
end



%% Resample the template mask in non linear space by using the tal_mask and nl xmf 
%if flag_verbose
%    fprintf('\n\n\n**********\nResampling the brain mask in non linear space ...\n');
%end
%clear files_in_tmp files_out_tmp opt_tmp
%files_in_tmp.source         = files_out.mask_stereonl;
%files_in_tmp.target         = file_template;
%files_in_tmp.transformation = files_out.transformation_nl;
%files_out_tmp               = files_out.mask_stereolin;
%opt_tmp.interpolation       = 'nearest_neighbour';
%opt_tmp.flag_invert_transf  = true;
%opt_tmp.flag_verbose        = flag_verbose;
%niak_brick_resample_vol(files_in_tmp,files_out_tmp,opt_tmp);





    copy_and_zip('tal/tal_xfm_0_0_t1w.xfm', file_out.transformation_lin);
    copy_and_zip('nl/nl_xfm_1_0.xfm', file_out.transformation_nl);
    copy_and_zip('nl/nl_xfm_0_0_grid_0.mnc', files_out.transformation_nl_grid);
    copy_and_zip('clp/clamp_0_0_t1w.mnc', files_out.anat_clp);
    copy_and_zip('tal/tal_0_0_t1w.mnc', files_out.anat_stereolin);
    copy_and_zip('nl/nl_0_0_t1w.mnc', files_out.anat_stereonl);
    copy_and_zip('tal/tal_comp_msk_0_0.mnc', files_out.mask_stereolin);
    copy_and_zip('tal_cls/tal_clean_0_0.mnc', files_out.classify);

%[status,msg] = system(['rm -rf ' path_tmp]);
%if status~=0
%    error('There was a problem when trying to clean the temporary folder : %s',msg);
%end

end

function copy_and_zip(src,dest)
    [bidon, bidon, ext_src] = fileparts(src);
    [bidon, bidon, ext_dst] = fileparts(dest);
    if strcmp(dest,'.gz') && ~strcmp(src, '.gz')
        z_file = gzip(src);       
        copyfile(z_file.filenames,dest);
    else
        copyfile(src, dest);
    end
end
