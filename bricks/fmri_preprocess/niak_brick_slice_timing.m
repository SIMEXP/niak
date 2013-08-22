function [files_in,files_out,opt] = niak_brick_slice_timing(files_in,files_out,opt)
% Correct for slice timing differences in 3D+t fMRI via temporal interpolation
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN        
%    (string) a file name of a 3D+t dataset .
%
% FILES_OUT       
%    (string, default <BASE_NAME>_a.<EXT>) File name for outputs. 
%    If FILES_OUT is an empty string, the name of the outputs will be 
%    the same as the inputs, with a '_a' suffix added at the end.
%
% OPT           
%    (structure) with the following fields.  
%
%    SUPPRESS_VOL 
%        (integer, default 0) the number of volumes that are suppressed 
%        at the begining of the time series. 
%
%    INTERPOLATION
%        (string, default 'spline') the method for temporal interpolation,
%        Available choices : 'linear', 'spline', 'cubic' or 'sinc'.
%
%    TYPE_ACQUISITION
%        (string, default 'manual') the type of acquisition used by the
%        scanner. If 'manual', SLICE_ORDER needs to be specified, 
%        otherwise it will be calculated. Possible choices are
%        'manual','sequential','sequential ascending','sequential descending',
%        'interleaved','interleaved ascending','interleaved descending'. For
%        interleaved modes, FIRST_NUMBER needs to be specified.
%    
%    TYPE_SCANNER
%        (string, default '') the type of MR scanner. The only value
%        that will change something to the processing here is 'Siemens',
%        which has different conventions for interleaved acquisitions.
%        This will change the default for OPT.FIRST_NUMBER. For every
%        MR scanner type, interleaved acquisition will start with odd
%        slices. On Siemens scanners, it will start with odd slices if
%        the number of slices is odd, and even slices if the number of
%        slices is even. 
%
%    FIRST_NUMBER
%        (string, default see description) the first number when using 
%        interleaved mode of TYPE_ACQUISITION. The default is 'odd' if
%        OPT.TYPE_SCANNER is different of 'Siemens'. For Siemens
%        scanner, the default will be 'odd' if the number of slices is
%        odd, and 'even' otherwise.
%    
%    STEP
%        (integer, default []) the interval between the slices. 
%        If [], use the info from the header of FILES_IN.
%    
%    NB_SLICES
%        (integer) the number of slices to use to calculate the
%        SLICE_ORDER. If not defined, uses the header number from
%        FILES_IN.
%    
%    TR
%        (integer) the time between slices in a volume. If not defined, 
%        uses the header number from FILES_IN.
%    
%    DELAY_IN_TR
%        (integer, default 0) the delay between the last slice of the
%        first volume and the first slice of the following volume.
%    
%    SLICE_ORDER 
%        (vector of integer) SLICE_ORDER(i) = k means that the kth slice 
%        was acquired in ith position. The order of the slices is 
%        assumed to be the same in all volumes.
%        ex : slice_order = [1 3 5 2 4 6] for 6 slices acquired in 
%        'interleaved' mode, starting by odd slices(slice 5 was acquired 
%        in 3rd position). Note that the slices are assumed to be axial,
%        i.e. slice z at time t is vol(:,:,z,t).
%
%    REF_SLICE	
%        (integer, default middle slice in acquisition time) slice for 
%        time 0
%
%    TIMING		
%        (vector 2*1) TIMING(1) time between two slices
%        TIMING(2) : time between last slice and next volume
%
%    FLAG_VARIANCE
%        (boolean, default 1) if FLAG_VARIANCE == 1, the mean and 
%        variance of the time series at each voxel is preserved.
%        This behaviour will not apply if FLAG_NU_CORRECT is on.
%
%    FLAG_CENTER
%        (boolean, default false) if the flag is true, the origin of space is 
%        placed in the center of the field of view.
%
%    FLAG_REGULAR
%        (boolean, default 1) if FLAG_REGULAR == 1, the spacing of all axis 
%        will be set to regular in MINC files. This is done to avoid bugs in 
%        latter stage of the analysis (MINCRESAMPLE cannot handle files with 
%        irregular spacing.
%
%    FLAG_EVEN_ODD
%        (boolean, default 0) if the flag is on, the mean of odd and even slices
%        will be set to a common values (the grand mean) for each volume. This is 
%        applied within a brain mask.
%
%    FLAG_HISTORY
%        (boolean, default 0) if FLAG_HISTORY == 1, the brick will preserve 
%        the history of MINC files. It is often a good idea to get rid of it, 
%        as the conversion from DICOM creates huge history that can even crash 
%        MINC tools and are in any case too long to be useful. On top of that
%        the NIAK tools do not set the history consistently, so in any case it 
%        does not matter to preserve it as it is not accurate. 
%
%    FLAG_NU_CORRECT
%        (boolean, default false) if FLAG_NU_CORRECT == 1, the NU_CORRECT
%        method is used to correct for non-uniformity of the B0 field.
%
%    ARG_NU_CORRECT
%        (string, default '-distance 200') the argument passed to NU_CORRECT.
%        See "nu_correct -help" in a terminal for more infos.
%
%    ITER_NU_CORRECT
%        (integer, default 3) iterate non-uniformity correction / brain masking
%        for ITER_NU_CORRECT times.
%
%    FLAG_SKIP
%        (boolean,  default 0) If FLAG_SKIP == 1, the brick is not performing the 
%        slice timing correction. All other steps (FLAG_HISTORY, SUPPRESS_VOL, etc)
%        are applied anyway if enabled. This flag is useful if you want to get rid 
%        of the slice timing correction in the pipeline. 
%
%    FOLDER_OUT 
%        (string, default: path of FILES_IN) If present, all default 
%        outputs will be created in the folder FOLDER_OUT. The folder 
%        needs to be created beforehand.
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
% SEE ALSO:
% NIAK_SLICE_TIMING, NIAK_DEMO_SLICE_TIMING
%
% _________________________________________________________________________
% COMMENTS
%
% Note 1:
% This process changes the timing of your data ! Those changes are
% twofold :
% 1. Some volumes are removed at the begining/end of the acquisition 
%    (see OPT.SUPPRESS_VOL).
% 2. The time of all slices in a volume is now the time of the slice of
%    reference.
% It is important that these effects are taken into account if stimulus 
% timing are considered in any further anaysis, typically in a general 
% linear model. The influence may be negligible for some design, e.g. long 
% blocks, and more important for other ones, e.g. event-related. Packages 
% like fMRIstat include the slice timing in the model, so slice timing 
% correction may not be necessary in the preprocessing. The time of frames
% is stored in a vector time frames, which is saved in a file
% <BASE FILES_OUT>_extra.mat. If some volumes are suppressed there will
% also be a variable MASK_SUPPRESS. This is a binary mask with as many entries
% as the original time series, with a 1 if the frame has been suppressed
% (scrubbed).
%
% NOTE 2:
% The linear/cubic/spline interpolations were coded by P Bellec, MNI 2008.
% They were all based on the INTERP1 matlab function, please refer to the
% associated documentation for more details regarding the interpolation
% schemes.
%
% NOTE 3:
% The sinc interpolation is a port from SPM5, under the GNU license.
% First code : Darren Gitelman at Northwestern U., 1998
% Based (in large part) on ACQCORRECT.PRO from Geoff Aguirre and
% Eric Zarahn at U. Penn.
% Subsequently modified by R Henson, C Buechel, J Ashburner and M Erb.
% Adapted to NIAK format and patched to avoid loops by P Bellec, MNI 2008.
%
% NOTE 4:
% The step in the last dimension (step) is essential to determine the correct 
% slice order. It tells us if the slices were taken going from neck to top of 
% head or inversely. Having a positive step in z means the slices were taken 
% from neck to top of head and that the slice order determined by this function 
% when given a type_acquisition option other than manual is in the correct order.
% 
% NOTE 5:
% The type_acquisition option (opt.type_acquisition) can have the following 
% values : 'manual','sequential','sequential ascending','sequential descending',
% 'interleaved','interleaved ascending' or 'interleaved descending'. Any other 
% value will return an error. 'sequential' mode is equivalent to 
% 'sequential ascending' mode and 'interleaved' mode is equivalent to 
% 'interleaved ascending' mode. If using 'interleaved' modes, first_number must be 
% specified in the form of 'odd' or 'even'. By default, it is set to 'manual' 
% mode in which case a slice_order needs to be input. If a mode other than 
% 'manual' is input as well as a slice_order, the latter will be used.
%
% NOTE 6:
% If the timing option is empty, a tr value and a delay_in_tr value may
% be input, otherwise the tr and delay_in_tr values are ignored. If no values
% are input for nb_slices and tr, they will be read from the file. 
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Sebastien Lavoie-Courchesne
% Montreal Neurological Institute, 2008-2010
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2010-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_slice_timing'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields      = { 'iter_nu_correct' , 'arg_nu_correct' , 'flag_nu_correct' , 'flag_center' , 'type_scanner','flag_history','flag_even_odd','flag_regular','flag_skip','flag_variance','suppress_vol','interpolation','slice_order','type_acquisition','first_number','step'   ,'ref_slice','timing','nb_slices','tr','delay_in_tr','flag_verbose','flag_test','folder_out' };
gb_list_defaults    = { 3                 , '-distance 200'  , false             , false         , ''            ,0             ,0              ,1             ,0          ,1              ,0             ,'spline'       ,[]           ,'manual'          ,'odd'         ,[]       ,[]         ,[]      ,[]         ,[]  ,0            ,1             ,0          ,''           };
niak_set_defaults;

%% Use specified values if defined. Use header values otherwise.

%% Output files
[path_f,name_f,ext_f] = fileparts(files_in(1,:));
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

%% Building default output names
if isempty(files_out)

    if size(files_in,1) == 1

        files_out = cat(2,opt.folder_out,filesep,name_f,'_a',ext_f);

    else

        name_filtered_data = cell([size(files_in,1) 1]);

        for num_f = 1:size(files_in,1)
            [path_f,name_f,ext_f] = fileparts(files_in(num_f,:));

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f] = fileparts(name_f);
            end
            
            name_filtered_data{num_f} = cat(2,opt.folder_out,filesep,name_f,'_a',ext_f);
        end
        files_out = char(name_filtered_data);

    end
end

if flag_test == 1
    return
end

%% Set up the defaults that necessitate to read the file
[hdr,vol] = niak_read_vol(files_in);
hdr = hdr(1);
[mat,step,start] = niak_hdr_mat2minc(hdr.info.mat);

% Z step
if isempty(opt.step)
    opt.step = step(3);
end

% First number
if isempty(opt.first_number)
    switch opt.type_scanner
        
        case 'Siemens'
            if floor(size(vol,3)/2) == size(vol,3)/2
                opt.first_number = 'even';
            else
                opt.first_number = 'odd';
            end
            
        otherwise
            opt.first_number = 'odd';
    end
end

% TR
if isempty(opt.tr)
    opt.tr = hdr.info.tr;
else 
    hdr.info.tr = opt.tr;
end

% Number of slices
if isempty(opt.nb_slices)
    opt.nb_slices = hdr.info.dimensions(3);
end

% timing
if isempty(opt.timing)
    opt.timing(1) = (opt.tr-opt.delay_in_tr)/opt.nb_slices;
    opt.timing(2) = opt.timing(1) + delay_in_tr;
end

% slice order
if isempty(opt.slice_order)
    
    switch opt.type_acquisition
        
        case 'manual'
            if ~exist(opt.slice_order,'var') && ~opt.flag_skip
                error('niak:brick', 'opt: slice_order must be specified when using type_acquisition manual.\n Type ''help niak_brick_slice_timing'' for more info.');
            end

        case {'sequential','sequential ascending'}
            if opt.step > 0
                opt.slice_order = 1:opt.nb_slices;
            else
                opt.slice_order = opt.nb_slices:-1:1;
            end
            
        case 'sequential descending'
            if opt.step > 0
                opt.slice_order = opt.nb_slices:-1:1;
            else
                opt.slice_order = 1:opt.nb_slices;
            end
            
        case {'interleaved','interleaved ascending'}
            if opt.step > 0
                if strcmp(opt.first_number,'odd')
                    opt.slice_order = [1:2:opt.nb_slices 2:2:opt.nb_slices];
                elseif strcmp(opt.first_number,'even')
                    opt.slice_order = [2:2:opt.nb_slices 1:2:opt.nb_slices];
                else
                    error('niak:brick','opt: first_number can only be ''odd'' or ''even''.\n Type ''help niak_brick_slice_timing'' for more info.');
                end
            else
                if strcmp(opt.first_number,'odd')
                    opt.slice_order = [opt.nb_slices:-2:1 opt.nb_slices-1:-2:1];
                elseif strcmp(opt.first_number,'even')
                    opt.slice_order = [opt.nb_slices-1:-2:1 opt.nb_slices:-2:1];
                else
                    error('niak:brick','opt: first_number can only be ''odd'' or ''even''.\n Type ''help niak_brick_slice_timing'' for more info.');
                end
            end
            
        case 'interleaved descending'
            if opt.step > 0
                if strcmp(opt.first_number,'odd')
                    opt.slice_order = [opt.nb_slices:-2:1 opt.nb_slices-1:-2:1];
                elseif strcmp(opt.first_number,'even')
                    opt.slice_order = [opt.nb_slices-1:-2:1 opt.nb_slices:-2:1];
                else
                    error('niak:brick','opt: first_number can only be ''odd'' or ''even''.\n Type ''help niak_brick_slice_timing'' for more info.');
                end
            else
                if strcmp(opt.first_number,'odd')
                    opt.slice_order = [1:2:opt.nb_slices 2:2:opt.nb_slices];
                elseif strcmp(opt.first_number,'even')
                    opt.slice_order = [2:2:opt.nb_slices 1:2:opt.nb_slices];
                else
                    error('niak:brick','opt: first_number can only be ''odd'' or ''even''.\n Type ''help niak_brick_slice_timing'' for more info.');
                end
            end
            
        otherwise
            
            error('niak:brick','opt: type_acquisition must be one of the specified values.\n Type ''help niak_brick_slice_timing'' for more info.');
            
    end
    
end

% Reference slice
if isempty(ref_slice)&&~opt.flag_skip 
    ref_slice = opt.slice_order(ceil(opt.nb_slices/2));
    opt.ref_slice = ref_slice;
elseif opt.flag_skip
    opt.ref_slice = 1;
    ref_slice = 1;
    opt.slice_order = 1:opt.nb_slices;
    slice_order = opt.slice_order;
end
time_ref = (find(opt.ref_slice == opt.slice_order)-1) * opt.timing(1); % the time associated with the slice of reference in the first volume

%% Reading data
if flag_verbose
    msg = sprintf('Performing slice timing correction on volume %s',files_in);
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

if flag_verbose
    msg = sprintf('Reading data...');
    fprintf('\n%s\n',msg);
end

if flag_variance
    std_vol = std(vol,0,4);
    moy_vol = mean(vol,4);
end

%% Verbose what's going on in terms of slice timing
if flag_verbose&&~flag_skip
    msg = sprintf('Applying slice timing correction...');
    fprintf('\n%s\n',msg);
    fprintf('Volume : %s\n',files_in);
    fprintf('Number of slices : %i\n',opt.nb_slices);
    fprintf('Slice of reference : %i\n',opt.ref_slice);
    fprintf('Interpolation method : %s\n',opt.interpolation);
    fprintf('Slice timing scheme : %s\n',opt.type_acquisition);
    fprintf('Slices are defined along the %s axis\n',hdr.info.dimension_order(3));
    fprintf('The step along this axis is : %1.2f\n',opt.step);
    fprintf('The scanner type is : %s\n',opt.type_scanner);
    fprintf('The resulting slice order is : ');
    opt.slice_order
    fprintf('The TR is : %1.2f\n',opt.tr);
    fprintf('The delay in TR is : %1.2f\n',opt.delay_in_tr);
elseif flag_verbose
    msg = sprintf('FLAG_SKIP is on, the brick will just copy the input on the output (yet it may apply some other corrections, see OPT.FLAG_XXX). NO SLICE TIMING CORRECTION WAS APPLIED !');
    fprintf('\n%s\n',msg);
end

%% Performing slice timing correction
opt_a.slice_order = opt.slice_order;
opt_a.timing = opt.timing;
opt_a.ref_slice = opt.ref_slice;
opt_a.interpolation = opt.interpolation;

if flag_skip
    vol_a = vol;
    hdr.extra.time_frames = opt.tr * (0:(size(vol_a,4)-1));
else
    [vol_a,opt_a] = niak_slice_timing(vol,opt_a);
    hdr.extra.time_frames = opt.tr * (0:(size(vol_a,4)-1)) + time_ref;
end

hdr.extra.mask_suppressed = false(size(vol_a,4),1);
if suppress_vol > 0;
    hdr.extra.mask_suppressed(1:suppress_vol) = true;
    hdr.extra.time_frames = hdr.extra.time_frames(~hdr.extra.mask_suppressed);
    vol_a = vol_a(:,:,:,~hdr.extra.mask_suppressed);
end

if flag_even_odd
    if flag_verbose
        msg = sprintf('Correcting the mean of odd and even slices to a common value ...');
        fprintf('\n%s\n',msg);
    end
    mask_brain = niak_mask_brain(vol_a);
    for num_t = 1:size(vol_a,4);
        v_o = vol_a(:,:,1:2:end,num_t);
        m_o = mean(v_o(mask_brain(:,:,1:2:end)));
        v_e = vol_a(:,:,2:2:end,num_t);
        m_e = mean(v_e(mask_brain(:,:,2:2:end)));
        v_g = vol_a(:,:,:,num_t);
        m_g = mean(v_g(mask_brain));
        v_o(mask_brain(:,:,1:2:end)) = v_o(mask_brain(:,:,1:2:end)) * (m_g/m_o);
        v_e(mask_brain(:,:,2:2:end)) = v_e(mask_brain(:,:,2:2:end)) * (m_g/m_e);
        v_g(:,:,1:2:end) = v_o ;
        v_g(:,:,2:2:end) = v_e;
        vol_a(:,:,:,num_t) = v_g;        
    end
end

if flag_variance&&~opt.flag_nu_correct
    if flag_verbose
        msg = sprintf('Preserving the mean and variance of the time series...');
        fprintf('\n%s\n',msg);
    end
    
    [nx,ny,nz,nt] = size(vol_a);
    vol_a = reshape(vol_a,[nx*ny*nz nt]);
    std_a = std(vol_a,0,2);
    moy_a = mean(vol_a,2);
    mask_a = std_a>0;
    
    for num_v = 1:nt
        vol_a(mask_a,num_v) = (((vol_a(mask_a,num_v)-moy_a(mask_a))./std_a(mask_a)).*std_vol(mask_a))+moy_vol(mask_a);
    end
    vol_a = reshape(vol_a,[nx ny nz nt]);
end
    
%% Updating the history and saving output
if flag_verbose
    msg = sprintf('Writting results...');
    fprintf('\n%s\n',msg);
end
hdr.file_name = files_out;
if flag_history
    opt_hist.command = 'niak_slice_timing';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out;
    hdr = niak_set_history(hdr,opt_hist);
else
    hdr.info.history = 'niak_slice_timing';
end
if flag_regular
    if ismember(hdr.type,{'minc1','minc2'})
        list_axis = {'xspace','yspace','zspace'};
        for num_a = 1:3
            ind = find(ismember(hdr.details.(list_axis{num_a}).varatts,'spacing'));
            if ~isempty(ind)
                hdr.details.(list_axis{num_a}).attvalue{ind} = 'regular__';
            end
        end
    end
end

%% Centering the field of view on the brain
if opt.flag_center
    if flag_verbose
       fprintf('\nCentering the field of view on the brain ...\n')
    end
    mask = niak_mask_brain(vol_a);
    ind = find(mask);
    [cx,cy,cz] = ind2sub (size(mask),ind);
    avg = mean([cx cy cz],1);
    hdr.info.mat(1:3,4) = -hdr.info.mat(1:3,1:3)*avg(:);
end

if opt.flag_nu_correct

    %% Correcting for non-uniformities
    if flag_verbose
       fprintf('\nCorrecting for non-uniformities ...\n    Iteration ')
    end
    
    vol_med = median(vol_a,4);    
    [path_f,name_f,ext_f,flag_z,ext_s] = niak_fileparts(files_out);
    nu.in.mask = psom_file_tmp(['_mask' ext_s]);
    nu.in.vol = psom_file_tmp(['_vol' ext_s]);
    nu.out.vol_nu = psom_file_tmp(['_vol_nu' ext_s]);
    nu.out.vol_imp = psom_file_tmp(['_vol.imp']);
    hdr_nu = hdr;
    hdr_nu.file_name = nu.in.vol;
    niak_write_vol(hdr_nu,vol_med);
    hdr_nu.file_name = nu.in.mask;
    
    for num_i = 1:opt.iter_nu_correct
        if opt.flag_verbose
            fprintf('%i - ',num_i)
        end
        
        % Generate a mask
        opt_m.fwhm = 2;
        mask = niak_mask_brain(vol_med,opt_m);
    
        % Run nu_correct on the median volume                
        niak_write_vol(hdr_nu,mask);
        opt_nu.arg = opt.arg_nu_correct;
        opt_nu.flag_verbose = false;
        niak_brick_nu_correct(nu.in,nu.out,opt_nu);
        [hdr_tmp,vol_med] = niak_read_vol(nu.out.vol_nu);
    end
    if opt.flag_verbose
        fprintf('\n')
    end
    
    % Apply the imp file on every volume
    instr_ev = ['nu_evaluate -clobber ' nu.in.vol ' ' nu.out.vol_nu ' -mapping ' nu.out.vol_imp ];
    hdr_nu.file_name = nu.in.vol;
    for num_v = 1:size(vol_a,4);   
        niak_progress(num_v,size(vol_a,4),5);
        niak_write_vol(hdr_nu,vol_a(:,:,:,num_v));
        [status,msg] = system(instr_ev);
        if status ~= 0
            error('The call to NU_CORRECT failed, the error message was: %s',msg)
        end
        [hdr_tmp,vol_a(:,:,:,num_v)] = niak_read_vol(nu.out.vol_nu);
    end    
    
    % Clean up
    psom_clean(nu)
end

%% Writing outputs
niak_write_vol(hdr,vol_a);
