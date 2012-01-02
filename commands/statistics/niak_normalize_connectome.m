function conn_n = niak_normalize_connectome(conn,opt)
% Apply some normalization rule to a connectome
%
% SYNTAX:
% CONN_N = NIAK_NORMALIZE_TSERIES(CONN,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% CONN_N             
%   (vector) a vectorized connectome (see NIAK_MAT2VEC, NIAK_VEC2MAT).
%
% OPT
%   (structure or string) If string, see TYPE below. If structure, 
%   the following fields are supported :
%
%   TYPE
%      (string, default 'none')  the type of normalization. Available options:
%
%      'none'
%         Don't do anything
%
%      'med_mad'
%         Correct the connectome to a zero median and unit median
%
% _________________________________________________________________________
% OUTPUTS :
%
% CONN_N
%       (vector) the connectome after normalization
%
% _________________________________________________________________________
% COMMENTS :
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de geriatrie 
% de Montreal, Departement d'informatique et de recherche operationnelle, 
% Universite de Montreal, 2008-2011.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : Statistics, Normalization, Connectome

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax 
if ~exist('conn','var')
    error('Syntax : CONN_N = NIAK_NORMALIZE_CONNECTOME(CONN,OPT) ; for more infos, type ''help niak_normalize_connectome''.')
end

if nargin < 2
    opt = 'none';
end

if ischar(opt)
    opt2.type = opt;
    opt = opt2;
    clear opt2;
end

conn = conn(:);

switch opt.type
    case 'none'
        conn_n = conn;
    case 'med_mad'
        conn_n = (conn-median(conn))/niak_mad(conn);
    otherwise
        error('%s is an unknown normalization method',opt.type)
end