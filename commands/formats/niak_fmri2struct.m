function fmri_s = niak_fmri2struct(fmri);
% Convert a set of fMRI files into a structure form
%
% SYNTAX:
% FMRI_S = NIAK_FMRI2STRUCT(FMRI)
%
% _________________________________________________________________________
% INPUTS:
%
% FMRI
%    The canonical form of FMRI is a structure with the following fields : 
%    <SUBJECT>.<SESSION>.<RUN> or <SUBJECT>.fmri.<SESSION>.<RUN>
%       (string) the file name of an fMRI dataset.
%       The RUN level can be replaced by a cell of strings, in which case 
%       a default label is used (RUN1, RUN2, etc for runs).
%       If a fmri field is present for one subject, it is assumed to contain
%       the <SESSION> fields and all other fields are ignored.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FMRI_S
%    Same as FMRI, except that every level (SUBJECT, SESSION, RUN) is
%    present (i.e. FILES_IN does not include any .
%    
% _________________________________________________________________________
% SEE ALSO:
% NIAK_FMRI2CELL
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

list_subject = fieldnames(fmri);

for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    files_sub = fmri.(subject);
    if isfield(files_sub,'fmri')
        files_sub = files_sub.fmri;
    end
    list_session = fieldnames(files_sub);
    for num_sess = 1:length(list_session)
        session = list_session{num_sess};
        files_sess = files_sub.(session);
        if iscellstr(files_sess)
            for num_r = 1:length(files_sess)
                run = sprintf('run%i',num_r);
                fmri_s.(subject).(session).(run) = files_sess{num_r};
            end
        else
            list_run = fieldnames(files_sess);
            for num_r = 1:length(list_run) 
                run = list_run{num_r};
                fmri_s.(subject).(session).(run) = files_sess.(run);
            end
        end
    end
end