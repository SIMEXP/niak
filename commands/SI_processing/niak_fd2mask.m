function mask = niak_fd2mask(fd,time_frames,opt)
% Generate a mask of acceptable time points based on frame displacement measures
% Syntax: MASK = NIAK_FD2MASK( FD, [TIME_FRAMES] ,OPT )
%
% INPUTS:
%   FD (vector) a series of measures of frame displacement. Last time point in FD is 0 (estimation is not possible). 
%   TIME_FRAMES (vector, default 1:length(fd)) the time points associated with each measure in FD. 
%   OPT.THRE (scalar, default 0.5) the threshold on acceptable frame displacement.
%   OPT.WW (vector, default [1 2]) defines the time window to be removed around each time frame
%      identified with excessive motion. First value is for time prior to motion peak, and second value 
%      is for time following motion peak. 
%   OPT.NB_MIN_VOL (scalar, default 40) the minimum number of volumes to retain. The scrubbing 
%      procedure is interrupted before this number is reached. 
%
% See licensing information in the code
 
% (c) Pierre Bellec
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2016
% Maintainer : pierre.bellec@criugm.qc.ca
%
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

%% Defaults
if (nargin < 2)||isempty(time_frames)
    time_frames = 1:length(fd);
end

if nargin < 3
    opt = struct;
end

opt = psom_struct_defaults( opt, ...
         { 'ww'  , 'nb_min_vol' , 'thre' }, ...
         { [1 2] , 40           , 0.5    });

%% Now build the mask         
mask = false(length(fd),1);
list_peak = find(fd>opt.thre);
for pp = 1:length(list_peak)
    peak = list_peak(pp);
    mask_before = time_frames>=(time_frames(peak)-opt.ww(1));
    mask_after  = time_frames<=(time_frames(peak)+opt.ww(2));
    mask_scrub = mask_before & mask_after;
    if sum(~(mask|mask_scrub))>=opt.nb_min_vol
        mask = mask|mask_scrub(:);
    else
        warning('There was not enough time frames left after scrubbing, kept %i time frames. See OPT.NB_VOL_MIN.',sum(~mask))
        break
    end
end