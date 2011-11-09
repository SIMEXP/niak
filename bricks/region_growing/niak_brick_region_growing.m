function  [files_in,files_out,opt] = niak_brick_region_growing(files_in,files_out,opt)
% Region growing algorithm for fMRI data.
% This is essentially a hierarchical clustering under spatial constraints,
% such that the resulting clusters are connected in space, i.e. regions.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_REGION_GROWING(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%       (structure) with the following fields:
%
%       TSERIES
%           (cell of strings) FILES_IN.TSERIES{I} is the name of a .mat
%           file with one variable named <OPT.VAR_TSERIES>. This variable
%           is a time*space array, where the Ith column is the time series
%           of the Ith voxel of the area.
%
%       NEIG
%           (string) the file name of a .mat file with one variable named
%           <OPT.VAR_NEIG>. This variable is a space*nb_neig array where
%           row I is the list of the spatial neighbours of voxel I.
%
% FILES_OUT
%       (string) a .mat file name which will contain one variable :
%
%       PART
%           (vector) represents the partition into regions. PART(I) is the
%           number of the region including voxel I.
%
%
% OPT
%       (structure, optional) with the following fields:
%
%       CORRECTION_IND
%           (structure, default CORRECTION.TYPE = 'mean') the temporal
%           normalization to apply on the individual time series before
%           concatenation. See OPT in NIAK_NORMALIZE_TSERIES.
%
%       CORRECTION_GROUP
%           (structure, default CORRECTION.TYPE = 'mean_var') the temporal
%           normalization to apply on the individual time series before
%           region growing. See OPT in NIAK_NORMALIZE_TSERIES.
%
%       VAR_TSERIES
%           (string, default 'tseries') the name of the variable that
%           contains the time series.
%
%       VAR_NEIG
%           (string, default NEIG) the name of the variable that contains
%           the neighbourhood structure).
%
%       THRE_SIZE
%           (integer,default 1000 mm3) threshold on the region size 
%           (maximum)
%
%       THRE_SIM
%           (real value, default NaN) threshold on the similarity between
%           regions (minimum). If the value is NaN, no test is applied.
%
%       THRE_NB_ROIS
%           (integer, default 0) the minimum number of regions
%
%       SIM_MEASURE
%           (string, default 'afc') the similarity measure between regions.
%
%       FLAG_SIZE
%           (boolean, default 1) if FLAG_SIZE == 1, all regions that
%           are smaller than THRE_SIZE at the end of the growing process
%           are merged into the most functionally close neighbour iteratively
%           unless all the regions are larger than THRE_SIZE
%
%       FLAG_SIEVE
%           (boolean, default false) if FLAG_SIEVE is true, all the regions
%           smaller than THRE_SIZE are removed from the final parcelation.
%
%       SIZE_CHUNKS
%           (integer, default 100) Size of vector chunks. See the 
%           "comments" section below.
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
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_REGION_GROWING, NIAK_PIPELINE_REGION_GROWING
%
% _________________________________________________________________________
% COMMENTS:
%
% If the variables cannot be found, the partition will be created, but
% empty.
%
% This implementation of region growing was written in native matlab 
% language rather than a mex to avoid the compilation. To keep it 
% relatively fast, the operations were vectorized as much as possible, 
% which necessitated to sometimes duplicate data in memory. To avoid using 
% too much memory in large problems, the vectorized portion of the code 
% works on chunks of vectors, whose maximal size (in terms of number of 
% double elements) is SIZE_CHUNKS. If the function is too slow but the
% memory usage is OK, you may want to increase this number. On the
% contrary, if you're getting an "out of memory" problem, lower it down.
%
% To be able to vectorize the code, some tricks could not be employed. For
% example, no use is made of the symmetry of the measure (which is thus
% calculated twice), and all measures are re-calculated at each iteration.
% At the end of the day, matlab works in such a weird way that it is still 
% much faster this way than with a clever loop-based implementation ...
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_REGION_GROWING(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_region_growing'' for more info.')
end

%% Inputs
list_fields    = {'tseries','neig'};
list_defaults  = {NaN,NaN};
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Default options
opt_norm_ind.type   = 'mean';
opt_norm_group.type = 'mean_var';
list_fields      = {'correction_ind' , 'correction_group' , 'var_tseries' , 'var_neig' , 'thre_size' , 'thre_sim' , 'thre_nb_rois' , 'sim_measure'   , 'flag_size' , 'flag_sieve' , 'flag_verbose' , 'flag_test' , 'size_chunks' };
list_defaults    = {opt_norm_ind     , opt_norm_group     , 'tseries'     , 'neig'     , 1000        , []         , 0              , 'afc'           , true        , false        , 1              , false       , 100           };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

if isempty(opt.thre_sim)
    opt.thre_sim = NaN;    
end

%% If the test flag is true, stop here !
if opt.flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if opt.flag_verbose
    msg = sprintf('Region growing');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read the time series

nb_files = length(files_in.tseries);
nt = zeros([nb_files 1]);

try
    data(1) = load(files_in.tseries{1},opt.var_tseries);
    flag_empty = ~isfield(data,opt.var_tseries);
catch
    flag_empty = true;
end
if flag_empty
    warning('I could not find the time series %s from the file %s, I am going to assume that ROI is not in the field of view and produce an empty partition\n',opt.var_tseries,files_in.tseries{1});
end

for num_f = 1:nb_files
    
    if opt.flag_verbose
        fprintf('Read the time series %s from the file %s\n',opt.var_tseries,files_in.tseries{num_f});
    end
    
    if ~flag_empty
        data(num_f) = load(files_in.tseries{num_f},opt.var_tseries);
        nt(num_f) = size(data(num_f).(opt.var_tseries),1);
        if num_f == 1
            ns = size(data(num_f).(opt.var_tseries),2);
        else
            if ns ~= size(data(num_f).(opt.var_tseries),2);
                error('All time series arrays should have the same spatial dimension')
            end
        end
    else
        data(num_f).(opt.var_tseries) = []; % deal with absent data
    end
    
end

if flag_empty
    part = [];
else
    %% Concatenate the time series
    if opt.flag_verbose
        fprintf('Concatenate time series\n');
    end

    tseries = zeros([sum(nt) ns]);
    num_t = 1;

    for num_f = 1:nb_files

        tseries(num_t:num_t+nt(num_f)-1,:) = niak_normalize_tseries(data(num_f).(opt.var_tseries),opt.correction_ind);
        num_t = num_t+nt(num_f);
        
    end

    tseries = niak_normalize_tseries(tseries,opt.correction_group);

    %% Read the nerighbourhood information
    if opt.flag_verbose
        fprintf('Read the neighbourhood information %s from file %s\n',opt.var_neig,files_in.neig);
    end

    data = load(files_in.neig,opt.var_neig);
    neig = data.(opt.var_neig);
    data = load(files_in.neig,'size_vox');
    size_vox = data.size_vox;
    clear data

    %% Set up the options for region growing
    opt_grow.size_chunks      = opt.size_chunks;
    opt_grow.thre_size        = opt.thre_size/size_vox;
    opt_grow.thre_sim         = opt.thre_sim;
    opt_grow.thre_nb_rois     = opt.thre_nb_rois;
    opt_grow.sim_measure      = opt.sim_measure;
    opt_grow.flag_size        = opt.flag_size;
    opt_grow.flag_verbose     = opt.flag_verbose;
    
    %% Perform region growing
    if opt.flag_verbose
        fprintf('Performing region growing...\n');
    end

    part = niak_region_growing(tseries,neig,opt_grow);
end

%% Saving outputs
if opt.flag_verbose
    fprintf('Saving outputs...\n');
end

save(files_out,'part')