function [] = niak_progress(num_i,nb_it,perc)
% Print percentage of progress in a loop
%
% SYNTAX:
% NIAK_PROGRESS( NUM_I , NB_IT , [PERC] )
%
% _________________________________________________________________________
% INPUTS:
%
% NUM_I
%   (integer) the current number of the iteration
%
% NB_IT
%   (integer) the total number of iteration
%
% PERC
%   (optional, default 5) a new message will be issued every PERC.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : 

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

if nargin<3
    perc = 5;
end

if num_i == 1
    fprintf('    Percentage done:')
    return
end

old_perc = perc*floor((100/perc)*(num_i-1)/nb_it);
new_perc = perc*floor((100/perc)*num_i/nb_it);
if old_perc~=new_perc
    fprintf(' %1.0f',new_perc);
end
if num_i == nb_it
    fprintf('\n')
end