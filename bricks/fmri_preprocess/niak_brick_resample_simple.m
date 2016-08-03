function [in,out,opt] = niak_brick_resample_simple(in,out,opt)
% Resample a 3D/4D volume into a target space using nearest neighbour interpolation. 
% No transformation supported. 
%
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_RESAMPLE_SIMPLE(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN      
%       (structure) with the following fields :
%
%       SOURCE 
%           (string) name of the file to resample (can be 3D+t).
%
%       TARGET 
%           (string, default none) name of the file defining space.
%
%   FILES_OUT 
%       (string) the name of the output resampled volume.
%
%   OPT           
%       (structure, optional) has the following fields:
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function prints 
%           some infos during the processing.
%
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% This implementation is based purely on Matlab/Octave code, and currently 
% only supports nearest_neighbour interpolation.
%
% Input/output can be minc or nifti (any variant), and on-the-flight conversion 
% between formats is also supported (e.g. the input can be minc and the output
% nifti). 
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Quebec, Canada, 2016
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, resampling

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

% Setting up inputs
in = psom_struct_defaults(in, ...
           {'source', 'target' },  ...
           {NaN     , ''       });

% Cheking outputs
if ~ischar(out)
    error('OUT should be a string')
end

% Setting up options
if nargin < 3
    opt = struct();
end
opt = psom_struct_defaults(opt, ...
      { 'flag_test' , 'flag_verbose' }, ..., 
      { false       , true           });

if opt.flag_test == 1
    return
end

%% Reading source
if opt.flag_verbose
    fprintf('Reading source volume %s...\n',in.source);
end
[hdr.source,vol] = niak_read_vol(in.source);

%% Reading target
if isempty(in.target)
    if opt.flag_verbose
        fprintf('No target is specified, will resample data on itself\n')
    end
    hdr.target = [];
else
    if opt.flag_verbose
        fprintf('Reading target volume %s...\n',in.target);
    end
    hdr.target = niak_read_vol(in.target);
end

%% Resampling
vol_r = niak_resample_vol(hdr,vol);

%% Write results
hdr.target.file_name = out;
niak_write_vol(hdr.target,vol_r);
