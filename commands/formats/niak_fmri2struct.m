function fmri_s = niak_fmri2struct(fmri,label,flag_cell);
% Convert a set of fMRI files into a structure form
%
% SYNTAX:
% FMRI_S = NIAK_FMRI2STRUCT( FMRI , [LABEL] , [FLAG_CELL] )
%
% _________________________________________________________________________
% INPUTS:
%
% FMRI
%    The canonical form of FMRI is a structure with the following fields : 
%    <SUBJECT>.<SESSION>.<RUN> or <SUBJECT>.fmri.<SESSION>.<RUN>
%       (string) the file name of an fMRI dataset.
%       The SESSION level can be replaced by a cell of strings, in which case
%       a default label is used (sess1_run1, sess1_run2, etc)
%       The RUN level can be replaced by a cell of strings, in which case 
%       a default label is used (run1, run2, etc for runs).
%       If a fmri field is present for one subject, it is assumed to contain
%       the <SESSION> fields and all other fields are ignored.
%    Another possible form for FMRI is a cell of strings, where each entry
%    is an fMRI dataset. In this case, the second argument LABEL is 
%    mandatory.
%
% LABEL
%    (structure, necessary if FMRI is a cell of strings) LABEL(I) is a 
%    structure with fields SUBJECT / SESSION / RUN, indicating the labels
%    associated with FMRI{I}
%
% FLAG_CELL
%    (boolean, default false) if FLAG_CELL is true, the run level is a cell
%    of string rather than a structure in FMRI_S
%
% _________________________________________________________________________
% OUTPUTS:
%
% FMRI_S
%    Same as FMRI, organized in the form of a structure (except for the RUN
%    level, which can be either a structure or a cell of strings, depending 
%    on FLAG_CELL).
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

if (nargin < 2) && iscellstr(fmri)
     error('Please specify LABEL if FMRI is a cell of strings')
end

if nargin < 3
   flag_cell = false;
end

if iscellstr(fmri)
    for num_e = 1:length(fmri)
        fmri_s.(label(num_e).subject).(label(num_e).session).(label(num_e).run) = fmri{num_e};
    end
    if flag_cell
        list_subject = fieldnames(fmri_s);
        for num_s = 1:length(list_subject)
            list_session = fieldnames(fmri_s.(list_subject{num_s}));
            for num_sess = 1:length(list_session)
                fmri_s.(list_subject{num_s}).(list_session{num_sess}) = psom_files2cell(fmri_s.(list_subject{num_s}).(list_session{num_sess}));
            end
        end
    end
    return
end
list_subject = fieldnames(fmri);

for num_s = 1:length(list_subject)
    subject = list_subject{num_s};
    files_sub = fmri.(subject);
    if isfield(files_sub,'fmri')
        files_sub = files_sub.fmri;
    end
    if iscellstr(files_sub)
        if flag_cell
            fmri_s.(subject).sess1 = files_sub;
        else
            for num_e = 1:length(files_sub)            
                fmri_s.(subject).sess1.(sprintf('run%i',num_e)) = files_sub{num_e};
            end
        end
        continue
    end    
    list_session = fieldnames(files_sub);
    for num_sess = 1:length(list_session)
        session = list_session{num_sess};
        files_sess = files_sub.(session);        
        if iscellstr(files_sess)
            if flag_cell
                fmri_s.(subject).(session) = files_sess;
            else
                for num_r = 1:length(files_sess)
                    run = sprintf('run%i',num_r);
                    fmri_s.(subject).(session).(run) = files_sess{num_r};
                 end
            end
        else
            if flag_cell
                fmri_s.(subject).(session) = psom_files2cell(files_sess);
            else
                fmri_s.(subject).(session) = files_sess;
            end
        end
    end
end