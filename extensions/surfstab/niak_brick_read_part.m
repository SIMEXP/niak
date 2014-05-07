function [files_in,files_out,opt] = niak_brick_read_part(files_in,files_out,opt)
% Extract some regional time series from a 3D+t fMRI dataset.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_READ_PART(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%   PART
%      (string or cell of string) A collection of partition files.
%
%   MASK
%      (string or cell of strings) A mask of regions of interest
%      (region I is defined by MASK==I).
%
% FILES_OUT
%   (string) a matlab file containing the partitons
%
%
% OPT
%   (structure) with the following fields.
%
%   FLAG_VERBOSE
%      (boolean, default 1) if the flag is 1, then the function
%      prints some infos during the processing.
%
%   FLAG_TEST
%      (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%      do anything but update the default values in FILES_IN,
%      FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_TSERIES
%
% _________________________________________________________________________
% COMMENTS:
%
% If FILES_IN.FMRI are .mat files, for each region in MASK, the average and
% std time series are derived from all ATOMS which intersect the region.
%
% FILES_OUT.TSERIES_AVG can only be generated if FLAG_ALL is false.
%
% When a string is specified in FILES_IN.FMRI or FILES_IN.MASK, the
% argument is treated as a cell of string with one entry.
%
% If extra variables TIME_FRAMES, MASK_SUPPRESSED, CONFOUNDS or LABELS_CONFOUNDS
% are found either in a .mat file or the hdr.extra part of the header of a 3D+t
% dataset, those are saved in the output. 
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, mask, partiton

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% global NIAK variables
niak_gb_vars

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('fnak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_READ_PART(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_read_part'' for more info.')
end

%% Input files
list_fields    = { 'mask' , 'part' };
list_defaults  = { NaN    , NaN    };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

if ischar(files_in.part)
    files_in.fmri = {files_in.part};
end

if ischar(files_in.mask)
    files_in.mask = {files_in.mask};
end

%% Output files
if ~ischar(files_out) && ~iscell(files_out)
    error('Please specify the output file for niak_brick_read_part!\n');
end

%% Options
list_fields   = { 'flag_verbose' , 'flag_test' };
list_defaults = { true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Sanity checks
num_m = length(files_in.mask);
num_p = length(files_in.part);

if num_m ~= 1 && num_m ~= num_p
    error(['If more than one mask is specified, there has to be exactly one '...
           'mask per partition.\n']);
end

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Begin reading the input
% Read the first mask as an example
[~, mvol] = niak_read_vol(files_in.mask{1});
mask = logical(mvol);
% Get the number of non-zero elements in the mask
num_v = sum(mask);
% Prepare the partition store
part = zeros(num_v, num_p);
scale = zeros(num_p, 1);

if opt.flag_verbose
    fprintf(['Going to process %d partitions with %d masks and %d nonzero '...
             'elements'], num_p, num_m, num_v);
end

for pid = 1:num_p
    if opt.flag_verbose
        fprintf('    Reading file %s now...\n', files_in.part{pid});
    end
    [~, pvol] = niak_read_vol(files_in.part{pid});
    % See if we have more than one mask
    if num_m > 1
        % Load the corresponding mask
        if opt.flag_verbose
            fprintf('        Reading mask %s now...\n', files_in.mask{pid});
        end
        [~, tmp_mvol] = niak_read_vol(files_in.mask{pid});
        tmp_mask = logical(tmp_mvol);
        % Make sure the nonzero elements in the current mask match the
        % reference
        if num_v ~= sum(tmp_mask)
            error(['Mask %s does have a different number of nonzero '...
                   'elements!\n'], files_in.mask{pid});
        end
        part_vec = pvol(tmp_mask ~= 0);
    else
        part_vec = pvol(mask ~= 0);
    end
    part(:, pid) = part_vec;
    scale(pid, 1) = max(part_vec);
end

if opt.flag_verbose
    fprintf('Completed processing.\nSaving output to %s now.\n', files_out);
end
save(files_out, 'part', 'scale');