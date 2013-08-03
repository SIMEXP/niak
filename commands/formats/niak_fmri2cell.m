function [fmri_c,label] = niak_fmri2cell(fmri,flag_subject);
% Convert a set of fMRI files into a cell of string
%
% SYNTAX:
% [FMRI_C,LABEL] = NIAK_FMRI2CELL(FMRI , FLAG_SUBJECT)
%
% _________________________________________________________________________
% INPUTS:
%
% FMRI
%   The canonical form of FMRI is a structure with the following fields : 
%   <SUBJECT>.<SESSION>.<RUN> or <SUBJECT>.fmri.<SESSION>.<RUN>
%      (string) the file name of an fMRI dataset.
%
% FLAG_SUBJECT
%   (boolean, default true) if the flag is false, the function ignores the 
%   <SUBJECT> IDs. 
%
% _________________________________________________________________________
% OUTPUTS:
%
% FMRI_C
%   (cell of string) FMRI_C{I} is the Ith entry of FMRI (ordered by 
%   subject / session / run, in this order).
%
% LABEL
%   (structure) with multiple entries. LABEL(I) has the following fields:
%   
%   SUBJECT 
%      (string) the name of the subject for FMRI_C{I}
%
%   SESSION
%      (string) the name of the session for FMRI_C{I}
%
%   RUN
%      (string) the name of the run for FMRI_C{I}
%
%   NAME
%      (string) SUBJECT_SESSION_RUN
%    
% _________________________________________________________________________
% SEE ALSO:
% NIAK_FMRI2STRUCT
%
% _________________________________________________________________________
% COMMENTS:
%
% NIAK_FMRI2STRUCT is first applied to get a full structure input.
%
% The following command can be used to build a cell of strings with 
% all the names:
%   label_c = {label.name};
%
% Copyright (c) Pierre Bellec, 
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : format, NIAK

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

if nargin < 2
    flag_subject = true;
end

if ~flag_subject    
    fmri2.subject = fmri;
    [fmri_c,label] = niak_fmri2cell(fmri2);
    label = rmfield(label,'subject');
    for ee = 1:length(label)
        label(ee).name = label(ee).name(9:end);
    end
    return
end
fmri = niak_fmri2struct(fmri);

list_subject = fieldnames(fmri);

nb_e = 0;
for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    list_session = fieldnames(fmri.(subject));
    for num_sess = 1:length(list_session)
        session = list_session{num_sess};
        list_run = fieldnames(fmri.(subject).(session));
        for num_r = 1:length(list_run) 
            run = list_run{num_r};
            nb_e = nb_e+1;
            label(nb_e).subject = subject;
            label(nb_e).session = session;
            label(nb_e).run     = run;
            label(nb_e).name = [subject '_' session '_' run];
        end
    end
end

fmri_c = cell(nb_e,1);
for num_e = 1:nb_e
    fmri_c{num_e} = fmri.(label(num_e).subject).(label(num_e).session).(label(num_e).run);
end