function versions = niak_version()
% Is a wraper of psom_version_svn and provide release number of psom and niak.
%
% SYNTAX :
% VERSIONS = NIAK_VERSION()
%
% _________________________________________________________________________
% INPUTS :
%
%   
% _________________________________________________________________________
% OUTPUTS:
%
%   VERSIONS
%       (structure) SVN.NAME Name of the svn lib.
%                   SVN.VERSION version number of the lib.
%                   SVN.PATH path of the svn root lib.
%                   SVN.INFO information from the function svnversion.
%
%                   RELEASE.NAME name of the lib.
%                   RELEASE.RELEASE release number.
%
% _________________________________________________________________________
% COMMENTS : 
%
%
% Copyright (c) Christian L. Dansereau, Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2011.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : svn,release,version

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


%%%%%%%%%%%%%%%%%
%%     SVN     %%
%%%%%%%%%%%%%%%%%

    versions.svn = psom_version_svn();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%     Release number     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    k=0;
    % Look for the PSOM version release
    if exist('psom_gb_vars') == 2
        k=k+1;
        psom_gb_vars;
        versions.release(k).name = 'psom';
        versions.release(k).release = gb_psom_version;
    end

    % Look for the NIAK version release
    if exist('niak_gb_vars') == 2
        k=k+1;
        niak_gb_vars;
        versions.release(k).name = 'niak';
        versions.release(k).release = gb_niak_version;
    end
   

end
