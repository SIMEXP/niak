function [files_in,files_out,opt] = niak_brick_slice_timing(files_in,files_out,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_SLICE_TIMING
%
% Correct for differences in slice timing in a 4D fMRI acquisition via
% temporal interpolation
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (string) a file name of a 3D+t dataset .
%
%  * FILES_OUT       
%       (string, default <BASE_NAME>_a.<EXT>) File name for outputs. 
%       If FILES_OUT is an empty string, the name of the outputs will be 
%       the same as the inputs, with a '_a' suffix added at the end.
%
%  * OPT           
%       (structure) with the following fields.  
%
%       SUPPRESS_VOL 
%           (integer, default 0) the number of volumes that are suppressed 
%           at the begining and the end of the time series. This can be 
%           usefull to limit the edges effects in the sinc interpolation.
%
%       INTERPOLATION
%           (string, default 'spline') the method for temporal interpolation,
%           Available choices : 'linear', 'spline', 'cubic' or 'sinc'.
%
%       SLICE_ORDER 
%           (vector of integer) SLICE_ORDER(i) = k means that the kth slice 
%           was acquired in ith position. The order of the slices is 
%           assumed to be the same in all volumes.
%           ex : slice_order = [1 3 5 2 4 6] for 6 slices acquired in 
%           'interleaved' mode, starting by odd slices(slice 5 was acquired 
%           in 3rd position). Note that the slices are assumed to be axial,
%           i.e. slice z at time t is vol(:,:,z,t).
%
%       REF_SLICE	
%           (integer, default middle slice in acquisition time) slice for 
%           time 0
%
%       TIMING		
%           (vector 2*1) TIMING(1) time between two slices
%           TIMING(2) : time between last slice and next volume
%
%       FLAG_VARIANCE
%           (boolean, default 1) if FLAG_VARIANCE == 1, the mean and 
%           variance of the time series at each voxel is preserved.
%
%       FLAG_SKIP
%           (boolean,  default 0) If FLAG_SKIP == 1, the brick is not doing
%           anything, just copying the input to the output. This flag is
%           useful if you want to get rid of the slice timing correction in
%           the pipeline. 
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, all default 
%           outputs will be created in the folder FOLDER_OUT. The folder 
%           needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
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
% correction may not be necessary in the preprocessing.
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
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
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

if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_slice_timing'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_skip','flag_variance','suppress_vol','interpolation','slice_order','ref_slice','timing','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {0,1,0,'spline',NaN,[],NaN,1,0,''};
niak_set_defaults

nb_slices = length(opt.slice_order);

if isempty(ref_slice)        
    ref_slice = slice_order(ceil(nb_slices/2));
    opt.ref_slice = ref_slice;
end

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

if flag_verbose
    msg = sprintf('Performing slice timing correction on volume %s',files_in);
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Reading data
if flag_skip
    if flag_verbose
        msg = sprintf('FLAG_SKIP is on, the brick will just copy the input on the output. NO SLICE TIMING CORRECTION WAS APPLIED !');
        fprintf('\n%s\n',msg);
    end

    instr_copy = ['cp ',files_in,' ',files_out];
    system(instr_copy);

else
    
    if flag_verbose
        msg = sprintf('Reading data...');
        fprintf('\n%s\n',msg);
    end

    [hdr,vol] = niak_read_vol(files_in);

    if flag_variance
        std_vol = std(vol,0,4);
        moy_vol = mean(vol,4);
    end
    
    %% Performing slice timing correction
    if flag_verbose
        msg = sprintf('Applying slice timing correction...');
        fprintf('\n%s\n',msg);
    end
    opt_a.slice_order = opt.slice_order;
    opt_a.timing = opt.timing;
    opt_a.ref_slice = opt.ref_slice;
    opt_a.interpolation = opt.interpolation;
    
    [vol_a,opt] = niak_slice_timing(vol,opt_a);

    if suppress_vol > 0;
        vol_a = vol_a(:,:,:,1+suppress_vol:end-suppress_vol);
    end

    if flag_variance
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
    hdr = hdr(1);
    hdr.file_name = files_out;
    opt_hist.command = 'niak_slice_timing';
    opt_hist.files_in = files_in;
    opt_hist.files_out = files_out;
    hdr = niak_set_history(hdr,opt_hist);
    niak_write_vol(hdr,vol_a);

end % if flag_skip