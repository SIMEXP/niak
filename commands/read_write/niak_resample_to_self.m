function [] = niak_resample_to_self(file_name,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_RESAMPLE_TO_SELF
%
% Apply MINCRESAMPLE to resample a volume in its own space, i.e. such that 
% the direction cosines are x, y and z
%
% SYNTAX:
% [] = NIAK_BRICK_RESAMPLE_TO_SELF(FILE_NAME)
%
% _________________________________________________________________________
% INPUTS:
%
% FILE_NAME      
%       (string) name of the file to resample (can be 3D+t).
%
% OPT            
%       (structure) same as in NIAK_BRICK_RESAMPLE_VOL
%
% _________________________________________________________________________
% OUTPUTS:
%
% Overwrites the file with its resampled version.
%
% _________________________________________________________________________
% COMMENTS:
%
% This is a simple wrapper of MINCRESAMPLE and NIAK_BRICK_RESAMPLE_VOL.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, minc

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

if ~exist(file_name,'file')
    error(sprintf('I can''t find file %s',file_name));
end

file_tmp = niak_file_tmp('_res.mnc');
files_in.source = file_name;
files_in.target = file_name;
files_out = file_tmp;

opt.flag_tfm_space = 1;

niak_brick_resample_vol(files_in,files_out,opt);
[succ,msg] = system(cat(2,'mv ',file_tmp,' ',file_name));
if ~(succ==0)
    error(msg);
end
