function [files_in,files_out,opt] = niak_brick_connectome(files_in,files_out,opt)
% Generate connectomes for a fMRI dataset based on one or several parcellations
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_CONNECTOME(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields :
%
%   FMRI
%       (string or cell of strings) one or multiple fMRI datasets. 
%
%   MASK
%       (string or cell of strings) one or multiple brain parcellations.
%
% FILES_OUT
%   (string or cell of strings) one entry per mask. Each entry is a .mat file 
%   with the following variables:
%
%   CONN 
%      (vector) a vectorized version of the connectome
%
%   TYPE
%      (string) the type of connectome (see OPT.TYPE below)
%
%   IND_ROI
%      (vector) the Nth row/column of CONN corresponds to the region IND_ROI(n) 
%      in the mask.
%
% OPT
%   (structure) with the following fields:
%       
%   TYPE
%      (string, default 'Z') the type of connectome. Available options:
%         'S' : covariance
%         'R' : correlation
%         'Z' : Fisher transform of the correlation
%         'U' : concentration
%         'P' : partial correlation
%
%   FLAG_TEST
%       (boolean, default: 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
%   FLAG_VERBOSE
%       (boolean, default: 1) If FLAG_VERBOSE == 1, write messages 
%       indicating progress.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_GEN_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% If multiple datasets are specified, the connectomes are generated independently 
% for each dataset and then averaged. 
%
% For 'R' and 'P' connectomes, use NIAK_VEC2MAT to get back the square form. 
%
% For 'S' and 'U' connectomes, use NIAK_VEC2LMAT to get back the square form.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Christian L. Dansereau, 
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, connectome, atoms, fMRI
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

% FILES_IN
list_fields    = { 'fmri' , 'mask' };
list_defaults  = { NaN    , NaN    };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

if ischar(files_in.fmri)
    files_in.fmri = {files_in.fmri};
end

if ischar(files_in.mask)
    files_in.mask = {files_in.mask};
end

if ~iscellstr(files_in.fmri)
    error('FILES_IN.FMRI should be a string or a cell of strings')
end

if ~iscellstr(files_in.mask)
    error('FILES_IN.MASK should be a string or a cell of strings')
end

% FILES_OUT
if ischar(files_out)
    files_out = {files_out};
end
if ~iscellstr(files_out)
    error('FILES_OUT should be a string or a cell of strings')
end

% OPTIONS
list_fields      = { 'type' , 'flag_test'    , 'flag_verbose' };
list_defaults    = { 'Z'    , false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);
type = opt.type;

% Check input/output match
if length(files_in.mask) ~= length(files_out)
    error('Please specify one output per mask')
end

if opt.flag_test == 1
    return
end

%% The brick starts here

nb_fmri = length(files_in.fmri);
nb_mask = length(files_in.mask);
all_conn = cell(nb_mask,1);
all_ind_roi = cell(nb_mask,1);
all_mask = cell(nb_mask,1);
all_hdr = cell(nb_mask,1);
if opt.flag_verbose
    fprintf('Generating ''%s'' connectomes ...\n',type)
end
for num_f = 1:nb_fmri    
    if opt.flag_verbose
        fprintf('Reading fMRI dataset %s ...\n',files_in.fmri{num_f});
    end
    [hdr,vol] = niak_read_vol(files_in.fmri{num_f});
    [nx,ny,nz,nt] = size(vol);
    for num_m = 1:nb_mask
        if num_f == 1
            if opt.flag_verbose
                fprintf('Reading mask %s ...\n',files_in.mask{num_m});
            end
            [all_hdr{num_m},all_mask{num_m}] = niak_read_vol(files_in.mask{num_m});
        end             
        hdr2 = all_hdr{num_m};        
        [nx2,ny2,nz2] = size(all_mask{num_m});
        if ~psom_cmp_var(hdr.info.mat,hdr2.info.mat)||(nx~=nx2)||(ny~=ny2)||(nz~=nz2)
            error('%s and %s should be in the same space and spatial grid',files_in.fmri{num_f},files_in.mask{num_m});
        end
        if num_f == 1
            [all_ind_roi{num_m},I,J] = unique(all_mask{num_m});
            all_mask{num_m} = reshape(J,size(all_mask{num_m}));
            if all_ind_roi{num_m}(1) == 0
                all_mask{num_m} = all_mask{num_m} - 1;
                all_ind_roi{num_m} = all_ind_roi{num_m}(2:end);
            end
        end
        tseries = niak_build_tseries(vol,all_mask{num_m});
        switch type
            case 'S'
                conn = niak_build_srup(tseries,true);
            case 'R' 
                [tmp,conn] = niak_build_srup(tseries,true);
            case 'Z' 
                [tmp,conn] = niak_build_srup(tseries,true);
                conn = niak_fisher(conn);
            case 'U'
                [tmp,tmp2,conn] = niak_build_srup(tseries,true);
            case 'P' 
                [tmp,tmp2,tmp3,conn] = niak_build_srup(tseries,true);
            otherwise
                error('%s is an unknown type of connectome',type)
        end
        if num_f == 1
            all_conn{num_m} = zeros(length(conn),nb_fmri);
        end
        all_conn{num_m}(:,num_f) = conn;
    end
end

%% Save results
if opt.flag_verbose
    fprintf('Saving results ...\n')
end
for num_o = 1:length(files_out)
    if opt.flag_verbose
        fprintf('   %s\n',files_out{num_o})
    end
    conn = mean(all_conn{num_o},2);
    ind_roi = all_ind_roi{num_o};
    save(files_out{num_o},'conn','ind_roi','type');
end