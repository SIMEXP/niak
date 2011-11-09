function  [files_in,files_out,opt] = niak_brick_merge_part(files_in,files_out,opt)

%
% _________________________________________________________________________
% SUMMARY NIAK_BRICK_MERGE_PART
%
% Merge multiple partitions into one. This brick is used by
% NIAK_PIPELINE_REGION_GROWING, and is not that usefull by itself.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MERGE_PART(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%       (structure) with the following fields:
%
%       AREAS
%           (string) the name of a mask of brain areas.
%
%       PART
%           (cell of strings) PART{I} is the name of a .mat file which
%           contains one partion PART. PART defines a partition on the
%           region OPT.IND_ROIS(I) of AREAS.
%
%       TSERIES
%           (cell of strings) each entry TSERIES{J} is the name of a .mat
%           file with variables names TSERIES_<NUM_R> where NUM_R is the
%           number of a roi in AREAS.
%
% FILES_OUT
%
%       SPACE
%           (string) a 3D volume with Is in the Ith region. The regions
%           from all areas are merged.
%
%       TSERIES
%           (cell of strings, default same as FILES_IN.TSERIES with a 
%           '_rois' suffix) a .mat file with a variable TSERIES.
%           TSERIES(:,I) is the time series associated with region I in the
%           dataset FILES_IN.TSERIES.
%
% OPT
%       (structure, optional) with the following fields:
%
%       IND_ROIS
%           (vector) the list of region numbers corresponding to the
%           entries of FILES_IN.PART.
%
%       CORRECTION
%           (structure, default CORRECTION.TYPE = 'mean') the temporal
%           normalization to apply on the individual time series before
%           averaging. See OPT in NIAK_NORMALIZE_TSERIES.
%
%       FOLDER_OUT 
%           (string, default: path of FILES_IN.FMRI{1}) If present,
%           all default outputs will be created in the folder FOLDER_OUT.
%           The folder needs to be created beforehand.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if FLAG_VERBOSE == 1, print some
%          information on the advance of computation
%
%       FLAG_TEST
%           (boolean, default 0) if FLAG_TEST equals 1, the
%           brick does not do anything but update the default
%           values in FILES_IN, FILES_OUT and OPT.
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
% NIAK_PIPELINE_REGION_GROWING
%
% _________________________________________________________________________
% COMMENTS
%
% If the variables cannot be found, the partition will be created, but
% empty.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,Montreal
%               Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : spatial neighbour, adjacency matrix, connexity, graph

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

%% global NIAK variables
flag_gb_niak_fast_gb = true; % Only load the most important global variables for fast initialization
niak_gb_vars

%% Check syntax
if ~exist('files_in','var')|~exist('files_out','var')
    error('fnak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MERGE_PART(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_merge_part'' for more info.')
end

%% Inputs
gb_name_structure = 'files_in';
gb_list_fields = {'areas','part','tseries'};
gb_list_defaults = {NaN,NaN,'gb_niak_omitted'};
niak_set_defaults

%% Outputs
gb_name_structure = 'files_out';
gb_list_fields = {'space','tseries'};
gb_list_defaults = {NaN,'gb_niak_omitted'};
niak_set_defaults

%% Options
opt_norm.type = 'mean';
gb_name_structure = 'opt';
gb_list_fields = {'folder_out','correction','ind_rois','flag_verbose','flag_test'};
gb_list_defaults = {'',opt_norm,[],true,false};
niak_set_defaults

%% Building default output names
flag_out = isempty(opt.folder_out);
flag_init_tseries = isempty(files_out.tseries);

if flag_init_tseries
    
    for num_f = 1:length(files_in.tseries)
        
        [path_t,name_t,ext_t] = fileparts(files_in.tseries{num_f});
        
        if flag_out
            opt.folder_out = path_t;
        end
        
        if flag_init_tseries
            files_out.tseries{num_f} = cat(2,opt.folder_out,filesep,name_t,'_roi.mat');
        end
    
    end
end

if ~ischar(files_out.tseries)&&ischar(files_in.tseries)
    error('The time series need to be specified in a cell of string FILES_IN.TSERIES')
end
    
%% If the test flag is true, stop here !
if flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    msg = sprintf('Merging partitions');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read the areas
if flag_verbose
    fprintf('Read the areas %s\n',files_in.areas);
end

[hdr,mask] = niak_read_vol(files_in.areas);
mask = round(mask);

%% Merge the masks
mask_merge = zeros(size(mask));

list_area = opt.ind_rois;
list_area = list_area(:)';
nb_areas = length(list_area);
part_merge = cell([nb_areas 1]);
list_num_roi = cell([nb_areas 1]);
nb_rois = 0;

for num_e = 1:nb_areas
    num_a = list_area(num_e);
    if flag_verbose
        fprintf('Merge regions from area %i\n',num_a);
    end

    load(files_in.part{num_e},'part');
    
    if ~isempty(part)
        nb_rois_area = max(part);
        part(part~=0) = part(part~=0) + nb_rois;
        mask_merge(mask == num_a) = part;
        part_merge{num_e} = part;
        list_num_roi{num_e} = nb_rois+1:nb_rois+nb_rois_area;
        nb_rois = nb_rois + nb_rois_area;
    else
        mask_merge(mask == num_a) = part;
        list_num_roi{num_e} = [];
    end
end

hdr.file_name = files_out.space;
niak_write_vol(hdr,mask_merge);

%% Build tseries
if ~ischar(files_out.tseries)    
    nb_files = length(files_in.tseries);
    for num_f = 1:nb_files
        if flag_verbose
            fprintf('Building regional time series from %s to %s\n',files_in.tseries{num_f},files_out.tseries{num_f});
        end
        
        data = load(files_in.tseries{num_f});
        flag_init = true;
        for num_e = 1:nb_areas
            num_a = list_area(num_e);
            var_name = ['tseries_',num2str(num_a)];
            if flag_init&&~isempty(data.(var_name))
                nt = size(data.(var_name),1);
                tseries = zeros([nt,nb_rois]);
                flag_init = false;
            end
            for num_r = list_num_roi{num_e}
                tseries(:,num_r) = mean(niak_normalize_tseries(data.(var_name)(:,part_merge{num_e}==num_r),opt.correction),2);
            end
        end
        save(files_out.tseries{num_f},'tseries');
    end
end