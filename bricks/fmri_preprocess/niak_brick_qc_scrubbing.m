function [files_in,files_out,opt]=niak_brick_qc_scrubbing(files_in,files_out,opt)
% Regress slow time drifst, global signals, motion parameters, etc
%
% SYNTAX :
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_SCRUBBING(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS :
%
% FILES_IN.(SUBJECT)
%   (string) the name of a .mat file with the results of scrubbing for subject
%   SUBJECT.
%
% FILES_OUT 
%   (string) the name of a csv file with three metrics for each subject:
%   number of scrubbed time frames, number of remaining time frames, average FD 
%   before and after scrubbing.
%
% OPT
%   (structure, optional) with the following fields:
%
%   THRE_FD
%      (scalar, default []) the threshold on FD to define the scrubbing mask.
%      If left empty, the mask from the results is used.
%
%   FLAG_VERBOSE
%      (boolean, default true) if the flag is on, print some information
%      about progress.
%
%   FLAG_TEST
%      (boolean, default false) if FLAG_TEST is true, the brick does not do 
%      anything except update default values and perform sanity checks.  
%  
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS: 
%
% See NIAK_BRICK_REGRESS_CONFOUNDS for more details.
%
% Copyright (c) Pierre Bellec 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : pca, glm, confounds, motion parameters

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


%% Set defaults
if ~isstruct(files_in)
    error('files_in should be a structure')
end

if ~ischar(files_out)
    error('files_out should be a string')
end

if nargin<3
    opt = psom_struct_defaults(struct(),{'thre_fd','flag_verbose','flag_test'},{[],true,false});
else
    opt = psom_struct_defaults(opt,{'thre_fd','flag_verbose','flag_test'},{[],true,false});
end

if opt.flag_test
    return
end

%% Build summary
list_subject = fieldnames(files_in);
opt_w.labels_x = list_subject;
opt_w.labels_y = {'frames_scrubbed','frames_OK','FD','FD_scrubbed'};
tab = zeros(length(list_subject),4);
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    if opt.flag_verbose
        fprintf('    %s\n',subject);
    end
    data = load(files_in.(subject));
    if isempty(opt.thre_fd)
        mask_scrubbing = data.mask_scrubbing;
    else
        mask_scrubbing = false(size(data.mask_scrubbing));
        mask_scrubbing(2:end) = data.fd>opt.thre_fd;
        mask_scrubbing2 = mask_scrubbing;
        mask_scrubbing2(1:(end-1)) = mask_scrubbing2(1:(end-1))|mask_scrubbing(2:end);
        mask_scrubbing2(2:end) = mask_scrubbing2(2:end)|mask_scrubbing(1:(end-1));
        mask_scrubbing2(3:end) = mask_scrubbing2(3:end)|mask_scrubbing(1:(end-2));
        mask_scrubbing = mask_scrubbing2;
    end
    tab(num_s,1) = sum(mask_scrubbing);
    tab(num_s,2) = sum(~mask_scrubbing);
    tab(num_s,3) = mean(data.fd);
    tab(num_s,4) = mean(data.fd(~mask_scrubbing(2:end)));
end

%% Write results
niak_write_csv(files_out,tab,opt_w);
