function [files_in,files_out,opt] = niak_brick_rmap(files_in,files_out,opt)
% Generate connectivity maps based on seeds and some fMRI datasets
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_RMAP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with two fields:
%
%   FMRI
%      (string or cell of strings) one or multiple fMRI datasets. 
%
%   SEEDS
%      (structure, or string) with arbitrary fields (SEED). FILES_IN.SEEDS.(SEED) is 
%      the name of either a .csv file with world coordinates for one 
%      or multiple seeds, or a 3D volume with one or multiple seed regions. 
%      If more than one seed is present in the CSV/volume, use OPT.IND_SEEDS.(SEED)
%      to select one seed. SEEDS can also be a string, in which case it is the 
%      name of a .csv file. All seeds listed in that CSV will be used.
%
% FILES_OUT
%    (structure) with two fields
%
%    MAPS
%       (structure, default 'gb_niak_omitted') FILES_OUT.MAPS.(SEED) is the functional 
%       connectivity map associated with FILES_IN.SEEDS.(SEED). Note that the connectivity 
%       maps are averaged across all fMRI datasets. 
%
%    SEEDS
%       (structure, default 'gb_niak_omitted') FILES_OUT.SEEDS.(SEED) is the seed associated 
%       with FILES_IN.SEEDS.(SEED). This is particularly useful when using .csv description of the seeds.
%
% OPT
%   (structure, optional) with the following fields:
%
%   FLAG_FISHER
%       (boolean, default false) apply a Fisher transform on the correlation coefficients
% 
%   IND_SEEDS
%       (structure) with arbitrary field names IND_SEEDS.(SEED) which can be a string indicating a 
%       a row (if FILES_IN.SEEDS.(SEED) is a .csv file) or a numerical index (if FILES_IN.SEEDS.(SEED) 
%       is a 3D volume, in which case the seed is assumed to be filled with OPT.IND_SEEDS.(SEED)
%
%   RADIUS_SEED
%       (scalar, default 0) the radius of the sphere centered at the coordinates, if a csv file is used
%       to specify the seed. For a value of 0, only the seed is used. 
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
% NIAK_BRICK_CONNECTOME, NIAK_PIPELINE_CONNECTOME, CLUSTERING_COEF_BU
%
% __________________________________________________________________________
% COMMENTS:
%
% The csv file should have the following format:
%
%        ,  x ,   y ,  z
% seed1  ,  4 ,  -3 ,  0
% seed2  , 23 , -24 , 13
%
% where seed1, seed2 etc can be arbitray names, yet acceptable as field names for matlab 
% no special characters (+ - / * space) and relatively short. 
%
% Copyright (c) Pierre Bellec,  
% Centre de recherche de l'Institut universitaire de gériatrie de Montréal, 2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, functional connectivity
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
files_in = psom_struct_defaults(files_in,{'fmri','seeds'},{NaN,NaN});

% If the input seed is a single .csv file, convert that into an appropriate format
if ischar(files_in.seeds)
    [coord,list_seed,lspace] = niak_read_vol(files_in.seeds);
    seeds = struct();
    for num_s = 1:length(list_seed)
        seeds.(list_seed{num_s}) = files_in.seeds;
        opt.ind_seeds.(list_seed{num_s}) = list_seed{num_s};
    end
end
    
list_seed = fieldnames(files_in.seeds);
if isempty(list_seed)
    error('Please specify seeds in FILES_IN.SEEDS')
end
if ischar(files_in.fmri)
    files_in.fmri = {files_in.fmri};
end

% FILES_OUT
files_out = psom_struct_defaults(files_out,{'maps','seeds'},{'gb_niak_omitted','gb_niak_omitted'});
if ~ischar(files_out.maps)&&strcmp(files_out.maps,'gb_niak_omitted')
    files_out.maps = psom_struct_defaults(files_out.maps,list_seed,repmat({NaN},[1 length(list_seed)]));
end
if ~ischar(files_out.seeds)&&strcmp(files_out.seeds,'gb_niak_omitted')
    files_out.seeds = psom_struct_defaults(files_out.seeds,list_seed,repmat({NaN},[1 length(list_seed)]));
end

% OPTIONS
list_fields      = { 'flag_fisher' , 'radius_seed' , 'ind_seeds' , 'flag_test'    , 'flag_verbose' };
list_defaults    = { false         , 0             , struct()    , false          , true           };
if nargin<3
    opt = struct();
end
opt = psom_struct_defaults(opt,list_fields,list_defaults,false);

%% Test stops here 
if opt.flag_test
    return
end

%% Generate seeds
hdr = niak_read_vol(files_in.fmri{1}); % get dimension info on the fMRI space
dim_vol = hdr.info.dimensions;
dim_vol = dim_vol(1:3);
all_seed = false([dim_vol(:)' length(list_seed)]);

for num_s = 1:length(list_seed)
    seed = list_seed{num_s};
    [path_f,name_f,ext_full,flag_zip,ext_f] = niak_fileparts(files_in.seeds.(seed));
    if opt.flag_verbose
        fprintf('Generating seed %s from file %s ...\n',seed,files_in.seeds.(seed));
    end       
    switch ext_f
        case '.csv'
            [coord,lseeds,laxis] = niak_read_csv(files_in.seeds.(seed));
            if isfield(opt.ind_seeds,seed)
                mask_seed = ismember(opt.ind_seeds.seed,lseeds);
                if ~any(mask_seed)
                     error('I could not find seed %s in the file %s',opt.ind_seeds.(seed),files_in.seeds.(seed));
                end
                coord = coord(mask_seed,:);
            else
                error('Please specify the label of seed %s in the .csv file %s',opt.ind_seeds.(seed),files_in.seeds.(seed));
            end
            coord_v = niak_coord_world2vox(coord,hdr.info.mat);
            if opt.radius_seed == 0
                vol_seed = all_seed(:,:,:,num_s);
                vol_seed(coord_v(1),coord_v(2),coord_v(3)) = true;
                all_seed(:,:,:,num_s) = vol_seed;
            else
                tmp = true(dim_vol);
                ind = find(tmp(:));
                [x,y,z] = ind2sub(size(tmp),ind);
                coord_vox = niak_coord_vox2world([x,y,z],hdr.info.mat);
                u = coord_vox-repmat(coord,[size(coord_vox,1) 1]);
                dist_map = sqrt(sum(u.^2,2));
                tmp(ind) = dist_map;
                tmp = tmp <= opt.radius_seed;
                tmp(coord_v(1),coord_v(2),coord_v(3)) = true;
                all_seed(:,:,:,num_s) = tmp;
            end
        case {'.mnc','.nii'}
            [hdr_s,vol_seed] = niak_read_vol(files_in.seeds.(seed));
            if isfield(opt.ind_seeds,seed)
                all_seed(:,:,:,num_s) = vol_seed == opt.ind_seeds.(seed);
            else
                all_seed(:,:,:,num_s) = vol_seed>0;
            end
        otherwise
            error('The file associated with the seed is neither a .csv or a .mnc(.gz)/.nii(.gz) file')
    end
end

%% Generate the functional connectivity maps 
if ~ischar(files_out.maps)
    maps = zeros(size(all_seed));
    for num_f = 1:length(files_in.fmri)
        if opt.flag_verbose
            fprintf('Generating connectivity map from fMRI dataset %s, processing seeds:\n    ',files_in.fmri{num_f});
        end
        [hdr,vol] = niak_read_vol(files_in.fmri{num_f});
        for num_s = 1:length(list_seed)
            seed = list_seed{num_s};
            if opt.flag_verbose
                fprintf('%s , ',seed)
            end
            maps(:,:,:,num_s) = maps(:,:,:,num_s) + niak_build_rmap(vol,all_seed(:,:,:,num_s));  
        end
        if opt.flag_verbose
            fprintf('\n')    
        end
    end
    maps = maps / length(files_in.fmri);
end

%% Write the results: seeds
if ~ischar(files_out.seeds)
    for num_s = 1:length(list_seed)
        seed = list_seed{num_s};
    
        %% The seeds
        if opt.flag_verbose
            fprintf('Saving seeds %s ...\n')
        end
        if opt.flag_verbose
            fprintf('    %s\n',files_out.seeds.(seed))
        end
        hdr.file_name = files_out.seeds.(seed);
        niak_write_vol(hdr,all_seed(:,:,:,num_s));    
    end
end

%% Write the results: maps
if ~ischar(files_out.maps)
    for num_s = 1:length(list_seed)
        seed = list_seed{num_s};
    
        %% The seeds
        if opt.flag_verbose
            fprintf('Saving maps %s ...\n')
        end
        if opt.flag_verbose
            fprintf('    %s\n',files_out.maps.(seed))
        end
        hdr.file_name = files_out.maps.(seed);
        niak_write_vol(hdr,maps(:,:,:,num_s));    
    end
end