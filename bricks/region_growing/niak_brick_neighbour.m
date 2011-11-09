function [files_in,files_out,opt] = niak_brick_neighbour(files_in,files_out,opt)
% Build the list of neighbours for a list a voxels.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NEIGHBOUR(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  * FILES_IN        
%       (string) The name of a file which contains a 3D mask of regions of 
%       interest (region I is filled with Is). This volume is refered to as
%       MASK below.
%
%  * FILES_OUT
%       (string, default <base FILES_IN>_neig.mat) the name of a .mat file 
%       which will contain two variables :
%
%       NEIG
%           (2D array) NEIG(i,:) is the list of neiighbours of voxel i. 
%           All numbers refer to a position in FIND(MASK(:)). Because 
%           all voxels do not necessarily have the same number of 
%           neighbours, 0 are used to pad each line.
%
%       IND
%           (vector) IND(i) is the linear index of the ith voxel in MASK.
%           IND = FIND(MASK(:))
%
%       SIZE_VOX
%           (scalar) the size of a voxel, in mm3
%
%  * OPT           
%       (structure) with the following fields.  
%
%       FLAG_ALL
%           (boolean, default false) if FLAG_ALL is true, NEIG/IND
%           are computed for each roi independently. Those multiple
%           variables are names NEIG_<NUM_R> and IND_<NUM_R> where 
%           NUM_R is the number of the roi.
%
%       IND_ROIS
%           (vector, default []) if not empty, the analysis is restricted 
%           to the rois whose numbers are included in IND_ROIS.
%
%       TYPE_NEIG    
%           (integer value, default 26) 
%           definition of 3D-connexity (possible value 6,26)
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN) If present, the default 
%           output name will be created in the folder FOLDER_OUT. The 
%           folder needs to be created beforehand.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function 
%           prints some infos during the processing.
%
%       FLAG_TEST 
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN, 
%           FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO
%
% NIAK_BUILD_NEIGHBOUR
%
% _________________________________________________________________________
% COMMENTS
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, time series

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

%% global NIAK variables
niak_gb_vars 

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('fnak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_NEIGHBOUR(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_neighbour'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'flag_all','ind_rois','type_neig','flag_verbose','flag_test','folder_out'};
gb_list_defaults = {false,[],26,true,false,''};
niak_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = fileparts(files_in);
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,'.gz')
    [tmp,name_f,ext_f] = fileparts(name_f);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

files_out = cat(2,opt.folder_out,filesep,name_f,'_neig.mat');

%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Building the list of spatial neighours in the mask %s...\n',files_in)
end

%% Read the mask
if flag_verbose
    fprintf('     Reading the mask...\n')
end

[hdr_mask,mask] = niak_read_vol(files_in);
mask = round(mask);
if ~isempty(ind_rois)
    mask(~ismember(mask,ind_rois)) = 0;
end
if ~flag_all
    mask = mask>0;
end

%% Build neighbourhood 
if flag_verbose
    fprintf('     Building neighbourhood...\n')
end

list_num_roi = unique(mask(mask~=0))';

if flag_all
    for num_r = list_num_roi
        instr_tseries = sprintf('[neig_%i,ind_%i] = niak_build_neighbour(mask==%i,opt.type_neig);',num_r,num_r,num_r);
        eval(instr_tseries);
    end
else
    [neig,ind] = niak_build_neighbour(mask,opt.type_neig); % extract the time series in the mask
end

size_vox = prod(hdr_mask.info.voxel_size);

save(files_out,'ind*','neig*','size_vox'); % Save outputs
