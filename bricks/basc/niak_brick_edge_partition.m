function [files_in,files_out,opt] = niak_brick_edge_partition(files_in,files_out,opt)
% Extract the edges of each element of a 3D partition
%
% SYNTAX:ac
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_EDGE_PARTITION(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN        
%    (string) a file name of a 3D volume filled with integer labels.
%
% FILES_OUT       
%    (string, default <BASE_NAME>_edge.<EXT>) File name for output. Same as 
%    FILES_IN, except that all voxels but the edges of the elements of the 
%    partition are set to zero. 
%
% OPT           
%    (structure) with the following fields.  
%
%    NB_ERODE
%        (integer, default 1) the number of erosions used to define the edges of
%        a binary mask.
%
%    FOLDER_OUT 
%        (string, default: path of FILES_IN) If present, all default 
%        outputs will be created in the folder FOLDER_OUT. The folder 
%        needs to be created beforehand.
%
%    FLAG_VERBOSE 
%        (boolean, default 1) if the flag is 1, then the function 
%        prints some infos during the processing.
%
%    FLAG_TEST 
%        (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%        do anything but update the default values in FILES_IN, 
%        FILES_OUT and OPT.
%        
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%           
% _________________________________________________________________________
% COMMENTS
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: erosion, partition, edges

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_EDGE_PARTITION(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_edge_partition'' for more info.')
end

%% Check input
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

%% Check output
if nargin < 2 
    files_out = '';
end
if ~ischar(files_out)
    error('FILES_out should be a string');
end

%% Options
list_fields      = { 'nb_erode' , 'flag_verbose' , 'flag_test' , 'folder_out' };
list_defaults    = { 1          , 1              , 0           , ''           };
if nargin < 3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% Output files
[path_f,name_f,ext_f] = niak_fileparts(files_in);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

%% Building default output name
if isempty(files_out)
    files_out = [opt.folder_out filesep name_f '_edge' ext_f];
end

if opt.flag_test == 1
    return
end

%% Read input partition
if opt.flag_verbose
    fprintf('Reading input partition %s ...\n',files_in);
end
[hdr,vol] = niak_read_vol(files_in);
vol = round(vol);
labels = unique(vol(:));
labels = labels(labels>0);
nb_label = length(labels);
opt_m.pad_size = 1;
vol_e = vol;
if opt.flag_verbose
    fprintf('Performing erosion of each element of the partition ...\n    ')
end
for num_l = 1:nb_label
    if opt.flag_verbose
        niak_progress(num_l,nb_label);
    end    
    num_c = labels(num_l);
    mask = vol==num_c;
    mask_inside = niak_morph(mask,['-successive ',repmat('E',[1 opt.nb_erode])],opt_m);
    vol_e(mask_inside>0) = 0;
end

%% write results
if opt.flag_verbose
    fprintf('Write edges of the partition in %s ...\n',files_out);
end
hdr.file_name = files_out;
niak_write_vol(hdr,vol_e);