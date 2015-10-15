function [status,msg] = niak_register(file1,file2,varargin)
% Visualize one or two registered volume using the "register" MINC tool
% 
% SYNTAX: [STATUS,MSG] = NIAK_REGISTER(FILE1,FILE2,OPT)
%
% FILE1 (string) the name of a minc or nifti file.
% FILE2 (string) the name of a minc or nifti file.
% OPT (string) any argument to send to register.
% STATUS (integer) 0 if call to register was successful, non-zero otherwise.
% MSG (string) the feedback from the call to register. 
%
% File names can be either relative or absolute, and .gz compression is supported. 
%
% It is possible to use niak_register like the command line tool, e.g.
%   niak_register file1.mnc file2.mnc 
% This also works for options, that need to be specified at the end. 
% 
% Copyright (c) Pierre Bellec, 
% Montreal Neurological Institute, 2008-2010
% Departement d'informatique et de recherche operationnelle
% Centre de recherche de l'institut de Geriatrie de Montreal
% Universite de Montreal, 2011-2015
% See licensing information in the code.
% Keywords : MINC, register, visualization

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

%% Syntax
if nargin < 2
    error('Syntax: niak_register file1 file2. See ''help niak_register''')
end

if nargin < 3
    opt = '';
else
    opt_str = '';
    for vv = 1:length(varargin)
        opt_str = [opt_str ' ' varargin{vv}];
    end
    opt = opt_str;
end

%% Convert files from nii to mnc, if necessary
[path1,fname1,ext1,zip1,type1] = niak_fileparts(file1);
if ismember(type1,{'.nii','.img'})
    file1_mnc = psom_file_tmp([fname1,'.mnc']);
    [hdr,vol] = niak_read_vol(file1);
    hdr_mnc = rmfield(hdr,'details');
    hdr_mnc.type = 'minc2';
    hdr_mnc.file_name = file1_mnc;
    niak_write_vol(hdr_mnc,vol);
    flag_tmp1 = true;
elseif strcmp(type1,'.mnc')
    file1_mnc = file1;
    flag_tmp1 = false;
else
    error('FILE1 needs to be either a minc or nifti file (extensions .nii(.gz), .img, .mnc(.gz))')
end

%% Convert files from nii to mnc, if necessary
[path2,fname2,ext2,zip2,type2] = niak_fileparts(file2);
if ismember(type2,{'.nii','.img'})
    file2_mnc = psom_file_tmp([fname2,'.mnc']);
    [hdr,vol] = niak_read_vol(file2);
    hdr_mnc = rmfield(hdr,'details');
    hdr_mnc.type = 'minc2';
    hdr_mnc.file_name = file2_mnc;
    niak_write_vol(hdr_mnc,vol);
    flag_tmp2 = true;
elseif strcmp(type2,'.mnc')
    file2_mnc = file2;
    flag_tmp2 = false;
else
    error('FILE2 needs to be either a minc or nifti file (extensions .nii(.gz), .img, .mnc(.gz))')
end
    
%% Finally call register
instr_register = ['register ' opt ' ' file1_mnc ' ' file2_mnc];
[status,msg] = system(instr_register);

%% Clean up
if flag_tmp1
    psom_clean(file1_mnc,struct('flag_verbose',false));
end
if flag_tmp2
    psom_clean(file2_mnc,struct('flag_verbose',false));
end