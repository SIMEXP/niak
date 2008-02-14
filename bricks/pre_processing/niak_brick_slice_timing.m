function [files_in,files_out,opt] = niak_brick_slice_timing(files_in,files_out,opt)

% Correct for differences in slice timing in a 4D fMRI acquisition via
% temporal interpolation
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SLICE_TIMING(FILES_IN,FILES_OUT,OPT)
%
% INPUTS:
% FILES_IN        (string OR cell of string) a file name of a 3D+t dataset OR
%                       a cell of strings where each entry is a file name
%                       of 3D data, all in the same space.
%
% FILES_OUT       (string or cell of strings) identical to FILES_IN. NOTE that
%                       if FILES_OUT is an empty string or cell, the name 
%                       of the outputs will be the same as the inputs, 
%                       with a '_a' suffix added at the end.
%
% OPT           (structure) with the following fields :
%
%               OPT.INTERPOLATON METHOD (string, default 'linear') the method for
%                       temporal interpolation, choices 'linear' or 'sync'.
%                       Linear interpolation is not exact,
%                       yet it is much more stable than sync interpolation
%                       regarding noise and discontinuities and therefore recommended.
%
%               SLICE_ORDER (vector of integer) SLICE_ORDER(i) = k means
%                      that the kth slice was acquired in ith position. The
%                      order of the slices is assumed to be the same in all
%                      volumes.
%                      ex : slice_order = [1 3 5 2 4 6]
%                      for 6 slices acquired in 'interleaved' mode,
%                      starting by odd slices(slice 5 was acquired in 3rd 
%                      position). Note that the slices are assumed to be 
%                      axial, i.e. slice z at time t is
%                      vols(:,:,z,t).
%
%               REF_SLICE	(integer, default midle slice in acquisition time)
%                       slice for time 0
%
%               TIMING		(vector 2*1) TIMING(1) : time between two slices
%                           TIMING(2) : time between last slice and next volume
%
%               FLAG_VERBOSE (boolean, default 1) if the flag is 1, then
%                       the function prints some infos during the
%                       processing.
%               FLAG_TEST (boolean, default 0) if FLAG_TEST equals 1, the
%                       brick does not do anything but update the default 
%                       values in FILES_IN and FILES_OUT.
%               
% OUTPUTS:
% The slice timing corrected data for the input files are saved into the 
% output files.
%              
% SEE ALSO:
% NIAK_SLICE_TIMING, NIAK_DEMO_SLICE_TIMING
%
% COMMENTS
%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input files
if nargin == 0
    error('niak:brick','Please specify input files')
end

%% Output files
if nargout < 2
    files_out = '';
end

if isempty(files_out)
    if ischar(files_in)
        
        [path_f,name_f,ext_f] = fileparts(files_in);
        
        if strcmp(ext_f,'.gz')
            [tmp,name_f,ext_f2] = fileparts(name_f);
            ext_f = [ext_f2,ext_f];
        end
        
        files_out = cat(2,path_f,name_f,'_a',ext_f);
        
    elseif iscellstr(files_in)
        
        files_out = cell([length(files_in) 1]);
        
        for num_f = 1:length(files_in);
        
            [path_f,name_f,ext_f] = fileparts(files_in{num_f});

            if strcmp(ext_f,'.gz')
                [tmp,name_f,ext_f2] = fileparts(name_f);
                ext_f = [ext_f2,ext_f];
            end

            files_out{num_f} = cat(2,path_f,filesep,name_f,'_a',ext_f);
            
        end
        
    else
        
        error('niak:brick','the input files FILES_IN should be a string or a cell of strings !')
        
    end
end

%% Options
try 
    flag_test = opt.flag_test;
catch
    opt.flag_test = 0;
    flag_test = 0;
end

if flag_test == 1
    opt = rmfield(opt,'flag_test');
    gb_name_structure = 'opt';
    gb_list_fields = {'interpolation_method','slice_order','ref_slice','timing','flag_verbose'};
    gb_list_defaults = {'linear',NaN,[],NaN,1};
    niak_set_defaults
    opt.flag_test = 1;
    return
end

%% Performing slice timing correction and saving data
[hdr,vol] = niak_read_vol(files_in);
opt = rmfield(opt,'flag_test');
vol_a = niak_slice_timing(vol,opt);
hdr.file_name = files_out;
niak_write_vol(hdr,vol_a);


