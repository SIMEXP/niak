% This script is an execution loop that red stdin and run command in an octave session.
%
% SYNTAX:
%
% _________________________________________________________________________
% INPUTS:
%
%
% _________________________________________________________________________
% OUTPUTS:
%
%
% _________________________________________________________________________
% COMMENTS:
%
%
% It is possible to configure the pipeline manager to use parallel 
% computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% Copyright (c) Pierre-Olivier Quirion, Centre de recherche de l'institut de 
% Griatrie de Montral, Dpartement d'informatique et de recherche 
% oprationnelle, Universit de Montral, 2013-2014.
% Maintainer : poq@criugm.qc.ca
% See licensing information in the code.
% Keywords : test, NIAK, fMRI preprocessing, pipeline, DEMONIAK

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

function niak_exit

end

line = '';
while !strcmp(line, "OCTAVE_DONE")
    printf('\nCROUTE\n')
    line = input('hey','s');
    printf("here it is %s\n", line);
end
