function [in,out,opt] = niak_brick_init_qc_report(in,out,opt)
% Initialize the quality control report for fMRI preprocessed data
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_INIT_QC_REPORT( IN , OUT , OPT )
%
% IN not used. Available to conform to the syntax of "bricks". 
% OUT (string) the name of spreadsheet with tabular-separated values.
% OPT.LIST_SUBJECT (cell of strings) the ID of the subject
% OPT.FLAG_TEST (boolean, default false) if the flag is true, 
%   nothing is done but update IN, OUT and OPT. 
%
% _________________________________________________________________________
% Copyright (c) Yassine Benhajali, Pierre Bellec
% Centre de recherche de l'institut de geriatrie de Montreal, 
% Department of Computer Science and Operations Research
% University of Montreal, Quebec, Canada, 2013-2016
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI preprocessing, quality control

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

%% Set default options
if ~ischar(out)
    error('OUT should be a string');
end

opt = psom_struct_defaults(opt, ...
    { 'list_subject' , 'flag_test' }, ...
    { NaN              , false});
    
if opt.flag_test
    return
end

%% Initialize the QC report
qc_report = cell(length(opt.list_subject)+1,4);
qc_report(2:end,1) = opt.list_subject;
qc_report(1,1) = 'id_subject';
qc_report(1,2) = 'status';
qc_report(1,3) = 'anat';
qc_report(1,4) = 'func';
qc_report(2:end,2:end) = repmat({''},[length(opt.list_subject),3]);
    
%% Save the report
niak_write_csv_cell(out,qc_report);