function part = niak_region_growing(tseries,neig,opt);
% Region growing : build connex region that are functionally homogeneous.
%
% SYNTAX:
% PART = NIAK_REGION_GROWING(TSERIES,NEIG,OPT)
%
% _________________________________________________________________________
% INPUTS
%
%  TSERIES
%       (matrix, size T*N) TSERIES(:,i) is the time series of
%       region i
%
%  NEIG
%       (2D array) NEIG(i,:) is the list of neighbors of region i (padded
%       with zeros). See NIAK_BUILD_NEIGHBOUR.
%
%  OPT
%       (structure, optional) with the following fields:
%
%       THRE_SIZE
%           (integer,default Inf) threshold on the region size (maximum)
%
%       THRE_SIM
%           (real value, default NaN) threshold on the similarity between
%           regions (minimum for similarity, maximum for distances). If
%           NaN is the specified value, no test is performed.
%
%       THRE_NB_ROIS
%           (integer, default 0) the minimum number of regions
%
%       SIM_MEASURE
%           (string, default 'afc') the similarity measure between
%           regions. Available choice :
%
%           'afc'
%               correlation of mean time series within each roi
%
%           'square_diff'
%               averge square difference between the mean time series
%               within each roi (which is a distance rather than a 
%               similarity measure ...).
%
%       SIZE_CHUNKS
%           (integer, default 100) Size of vector chunks. See the 
%           "comments" section below.
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
%       FLAG_VERBOSE
%           (boolean, default 1) if FLAG_VERBOSE == 1, print some
%          information on the advance of computation
%
% _________________________________________________________________________
% OUTPUTS:
%
%  PART
%       (vector) P(i) = j if region is in cluster (or homogeneous region) j
%
%  NEIG
%       (2D array) NEIG(I,:) is the list of neighbors of homogeneous
%       region I (padded with zeros)
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_NEIGHBOUR
%
% _________________________________________________________________________
% COMMENTS:
%
% This implementation of region growing was written in native matlab 
% language rather than a mex to avoid the compilation stage. To keep it 
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

%%% Default options
gb_name_structure = 'opt';
gb_list_fields    = {'size_chunks' , 'thre_size' , 'thre_sim' , 'thre_nb_rois' , 'sim_measure'   , 'flag_size' , 'flag_sieve' , 'flag_verbose' , 'flag_fast_init' };
gb_list_defaults  = {100           , Inf         , []         , 0              , 'afc'           , 1           , false        , 1              , false            };
niak_set_defaults

if isempty(thre_sim)
    thre_sim = NaN;
end

% getting parameters
n = size(tseries,2);
nt = size(tseries,1);

% Setting the "nogo" value
switch sim_measure
    case {'afc','afc_penalized'}
        nogo = -Inf;
    case {'square_diff','square_diff_penalized'}
        nogo = Inf;
    otherwise
        error('%s is an unkown similarity measure',sim_measure);
end

%%%%%%%%%%%%%%%%%%
% Initialization %
%%%%%%%%%%%%%%%%%%
part = (1:n)'; % Each initial space location is a region
neig_init = neig;
if (thre_size <= 0)||(thre_sim == nogo)||(thre_nb_rois>=n)
    return % for some values of the parameters, there is simply nothing to do ...
end

if (thre_size>=n)&&(thre_sim==-nogo)&&(thre_nb_rois<=1)
    part = ones(size(part));
    return % There will be just one ROI with these parameters
end

nb_mnn = Inf; % Always attempt to start the growing algorithm
list_size = ones([n 1]); % Each region has one element
nb_rois = n;

%% Initialization of the similarity matrix
if flag_verbose
    fprintf('     Initialization of the functional similarity matrix...\n')
end

switch sim_measure
    case 'afc'
        tseries = niak_correct_mean_var(tseries,'mean_var'); % To simplify computation, time series are corrected of mean and variance when the AFC measure of similarity is used.
        flag_sim = true;
    case 'afc_penalized'
        tseries = niak_correct_mean_var(tseries,'mean_var'); % To simplify computation, time series are corrected of mean and variance when the AFC measure of similarity is used.
        tseries = tseries/(max(tseries(:))*size(tseries,1));
        flag_sim = true;
    case 'square_diff'
        flag_sim = false;
    case 'square_diff_penalized'
        tseries = tseries/(max(tseries(:))*size(tseries,1));
        flag_sim = false;
end
sim_mat = sub_measure(neig,tseries,sim_measure,nogo,size_chunks,list_size);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Competitive region growing %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('     Number of merging : ');
end
val_sim = zeros([1 size(neig,1)]);
pos_nneig = zeros([1 size(neig,1)]);
list_update = 1:size(neig,1);
list_ind_roi = (1:size(neig,1)); % label attached to each row
list_roi_ind = (1:size(neig,1)); % row attached to each label

while (nb_rois>thre_nb_rois)&&(nb_mnn>0)
    
    %% Seek mutual nearest neighbours (MNN) that fulfill the merging
    %% condition    
    [val_sim,pos_nneig,is_mnn,ind_nneig,nneig] = sub_ismnn(val_sim,pos_nneig,neig,list_ind_roi,flag_sim,list_update,sim_mat,thre_sim,list_roi_ind);
   
    %% Build the list of pairs of regions to merge.   
    ind_mnn1 = find(is_mnn); % The indices of the row in NEIG that satisfy mnn
    list_mnn1 = list_ind_roi(is_mnn); % The labels associated with each row satisfying MNN
    list_mnn2 = nneig(is_mnn); % The label of the nearest neighbour associated with each row
    ind_mnn2 = list_roi_ind(list_mnn2);    
    mask_diag = list_mnn1<list_mnn2; % if (I,J) satisfies mnn, (J,I) does too. Use (I,J) with I<J
    list_mnn1 = list_mnn1(mask_diag);
    list_mnn2 = list_mnn2(mask_diag);
    ind_mnn1 = ind_mnn1(mask_diag);
    ind_mnn2 = ind_mnn2(mask_diag);
    
    %% Number of merging, number of rois
    nb_mnn = length(list_mnn1);
    nb_rois = nb_rois-nb_mnn;
    mask_change = false([size(neig,1) 1]); % This mask will be used to keep track of the ROIs whose neighbourhood have been updated
    to_keep = true([size(neig,1) 1]); % A mask of the row of NEIG that will be retained at the next iteration. The same mask will apply on LIST_SIZE, TSERIES, SIM_MAT, MASK_CHANGE, LIST_UPDATE, VAL_SIM, POS_NEIG
    to_keep(ind_mnn2) = false;
    if flag_verbose
        fprintf(' %i',nb_mnn);
    end
    
    if (nb_rois>=thre_nb_rois)&(nb_mnn>0)
        
        %% Update tseries
        tseries = sub_update_tseries(tseries,list_size,ind_mnn1,ind_mnn2,size_chunks);        
        
        %% Update size               
        list_size(ind_mnn1) = list_size(ind_mnn1)+list_size(ind_mnn2);
        
        %% Update partition
        [to_replace,ind_replace] = ismember(uint32(part),list_mnn2);
        part(to_replace) = list_mnn1(ind_replace(to_replace));
        
        %% Update the adjacency         
        mask_change(is_mnn) = true;
        neig(ind_nneig) = 0; % get rid of adjacency relationships between merged regions
       
        % Case 1 : Adults
        mask_adult = list_size(ind_mnn1)>thre_size;
        if any(mask_adult)                      
            neig(ind_mnn1(mask_adult),:) = 0;
            neig(ind_mnn2(mask_adult),:) = 0;
            sim_mat(ind_mnn1(mask_adult),:) = nogo;
            sim_mat(ind_mnn2(mask_adult),:) = nogo;                 
            mask_neig_adult = ismember(neig,uint32([list_mnn1(mask_adult) list_mnn2(mask_adult)]));
            mask_neig_adult = reshape(mask_neig_adult,size(neig)); % Bug in ismember for octave : the output is vectorized
            neig(mask_neig_adult) = 0;
            sim_mat(mask_neig_adult) = nogo;
            mask_change(max(mask_neig_adult,[],2)>0) = true;
        end
       
        % Case 2 : Children
        list_child = find(~mask_adult);
        for num_mnn = list_child(:)'            
            [neig,mask_change] = sub_merge_neig(neig,list_mnn1(num_mnn),list_mnn2(num_mnn),ind_mnn1(num_mnn),ind_mnn2(num_mnn),mask_change,list_roi_ind);
        end
                        
        %% Update the similarity
        list_update = find(mask_change);        
        if size(neig,2)>size(sim_mat,2)
            sim_mat = [sim_mat nogo*ones([size(sim_mat,1) size(neig,2)-size(sim_mat,2)])];
        end
        sim_mat(list_update,:) = sub_measure(neig,tseries,sim_measure,nogo,size_chunks,list_size,list_update,list_roi_ind);
        
        %% Remove rows that correspond to merged regions
        neig = neig(to_keep,:);
        tseries = tseries(:,to_keep);
        list_size = list_size(to_keep);
        val_sim = val_sim(to_keep);
        pos_nneig = pos_nneig(to_keep);
        list_ind_roi = list_ind_roi(to_keep);     
        mask_roi_nan = isnan(list_roi_ind);
        list_roi_ind_update = list_roi_ind(~mask_roi_nan);
        list_roi_ind_update(to_keep) =  1:length(list_ind_roi);
        list_roi_ind_update(~to_keep) =  NaN;
        list_roi_ind(~mask_roi_nan) = list_roi_ind_update;        
        mask_change = mask_change(to_keep);
        list_update = find(mask_change);
        sim_mat = sim_mat(to_keep,:);
    end
end

if flag_verbose
    fprintf('     Done ! \n')
end

%% Get rid of small regions
if flag_size
    nb_iter_max = 100;
    ind_merge = find(list_size<=thre_size);
    while (~isempty(ind_merge))&(nb_iter_max>0)
        ind_merge_with = zeros(size(ind_merge));
        num_e = 1;
        for num_r = ind_merge(:)'
            ind_r = find(part==list_ind_roi(num_r));
            list_neig = unique(neig_init(ind_r,:));
            list_neig = list_neig(list_neig~=0);
            list_neig = list_roi_ind(unique(part(list_neig)));
            list_neig = list_neig(~ismember(list_neig,ind_merge));
            if isempty(list_neig)
                ind_merge_with(num_e) = num_r;
            else
                switch sim_measure
                    case {'afc','afc_penalized'}
                        sim_mat = (1/(size(tseries,1)-1))*sum(tseries(:,repmat(num_r,size(list_neig))).*tseries(:,list_neig),1);
                    case {'square_diff','square_diff_penalized'}
                        sim_mat = sqrt(sum((tseries(:,repmat(num_r,size(list_neig)))-tseries(:,list_neig)).^2,1));
                end
                if flag_sim
                    [tmp,ind_merge_with(num_e)] = max(sim_mat);
                else
                    [tmp,ind_merge_with(num_e)] = min(sim_mat);
                end
                ind_merge_with(num_e) = list_neig(ind_merge_with(num_e));
            end
            num_e = num_e+1;
        end
        
        for num_e = 1:length(ind_merge)
            num_r = ind_merge(num_e);
            if num_r~=ind_merge_with(num_e)
                tseries = sub_update_tseries(tseries,list_size,num_r,ind_merge_with(num_e),size_chunks);
                tseries = tseries(:,[1:(num_r-1) (num_r+1):length(list_size)]);
                part(part==list_ind_roi(num_r)) = list_ind_roi(ind_merge_with(num_e));
                list_size(ind_merge_with(num_e)) = list_size(ind_merge_with(num_e))+list_size(num_r);
                list_size = list_size([1:(num_r-1) (num_r+1):length(list_size)]);
                list_ind_roi = list_ind_roi([1:(num_r-1) (num_r+1):length(list_ind_roi)]);
                list_roi_ind(list_roi_ind>num_r) = list_roi_ind(list_roi_ind>num_r)-1;
                ind_merge(ind_merge>num_r) = ind_merge(ind_merge>num_r)-1;
                ind_merge_with(ind_merge_with>num_r) = ind_merge_with(ind_merge_with>num_r)-1;           
            end
        end
        ind_merge = find(list_size<=thre_size);
        nb_iter_max = nb_iter_max-1;
    end    
end

if flag_sieve
    part(ismember(part,list_ind_roi(list_size<thre_size))) = 0;
end

%% Re-label the homogeneous roi
if flag_verbose
    fprintf('\nRandomizing ROIs order ...\n')        
end
flag_0 = any(part==0);
[list_labels,I,part] = unique(part);
if flag_0
    part = part-1;
end
labels_rand = randperm(max(part));
part(part~=0) = labels_rand(part(part~=0));

%%%%%%%%%%%%%%%%%
%% SUBFUNCTION %%
%%%%%%%%%%%%%%%%%
function [val_sim,pos_nneig,is_mnn,ind_nneig,nneig] = sub_ismnn(val_sim,pos_nneig,neig,list_ind_roi,flag_sim,list_update,sim_mat,thre_sim,list_roi_ind);
%% build a mask of regions that verify the mutual nearest neighbour
%% conition
if flag_sim
    [val_sim(list_update),pos_nneig(list_update)] = max(sim_mat(list_update,:),[],2); % For each region, look for its nearest neighbor
else
    [val_sim(list_update),pos_nneig(list_update)] = min(sim_mat(list_update,:),[],2); % For each region, look for its nearest neighbor
end
ind_nneig = sub2ind(size(neig),(1:size(neig,1)),pos_nneig); % Indices of nearest neighbours in NEIG
nneig = neig(ind_nneig); % The nearest neighbours labels
list_todo = find(nneig~=0); % List of ROIS who have a nearest neighbour ...
is_mnn = false(size(nneig)); % Initialization of a mask of ROIs that satisfy the mutual nearest neighbour condition
nneig1 = nneig(list_todo); % Non-zero nearest neighbours
loc = list_roi_ind(nneig1); % Find out to what row of NEIG each roi label is associated
is_mnn(list_todo) = nneig(loc) == list_ind_roi(list_todo); % For each roi, test if the nearest neighbour of its nearest neighbour is itself (mutual nearest neighbor condition)
if ~isnan(thre_sim)
    if flag_sim
        is_mnn = is_mnn & (val_sim > thre_sim); % The similarity between rois has to be higher than a threshold.
    else
        is_mnn = is_mnn & (val_sim < thre_sim); % The distance between rois has to be smaller than a threshold.
    end
end
ind_nneig = ind_nneig(is_mnn); % indices of nearest neighbours that satisfy the mutual nearest neighbour condition

function sim_mat = sub_measure(neig,tseries,sim_measure,nogo,size_chunks,list_size,list_update,list_roi_ind)

if nargin<7
    list_update = 1:size(neig,1);
    list_roi_ind = 1:size(neig,1);
end
neig = neig(list_update,:);

%% Compute the similarity measure between neighbours
sim_mat = nogo*ones([length(list_update) size(neig,2)]);
indxy = find(neig);
[xi,yi] = ind2sub([length(list_update) size(neig,2)],indxy);
xi = list_update(xi);
if length(xi)>size_chunks;
    list_chunk = 1:size_chunks:length(xi);
    list_chunk(end) = length(xi);
else
    list_chunk = [1 length(xi)];
end
for num_c = 1:(length(list_chunk)-1)
    chunk = list_chunk(num_c):list_chunk(num_c+1);
    yi_chunk = list_roi_ind(neig(indxy(chunk)));    
    switch sim_measure
        case 'afc'
            sim_mat(indxy(chunk)) = (1/(size(tseries,1)-1))*sum(tseries(:,xi(chunk)).*tseries(:,yi_chunk),1);
        case 'afc_penalized'            
            sim_mat(indxy(chunk)) = (1/(size(tseries,1)-1))*sum(tseries(:,xi(chunk)).*tseries(:,yi_chunk),1) + abs((list_size(xi(chunk))-list_size(yi_chunk))./max([list_size(xi(chunk)) list_size(yi_chunk)],[],2))';
        case 'square_diff'
            sim_mat(indxy(chunk)) = sqrt(sum((tseries(:,xi(chunk))-tseries(:,yi_chunk)).^2,1));
        case 'square_diff_penalized'
            sim_mat(indxy(chunk)) = sqrt(sum((tseries(:,xi(chunk))-tseries(:,yi_chunk)).^2,1)) - abs((list_size(xi(chunk))-list_size(yi_chunk))./max([list_size(xi(chunk)) list_size(yi_chunk)],[],2))';

    end
end

function tseries_up = sub_update_tseries(tseries,list_size,list_mnn1,list_mnn2,size_chunks)

%% Compute the average time series after merging
if length(list_mnn1)>size_chunks;
    list_chunk = 1:size_chunks:length(list_mnn1);
    list_chunk(end) = length(list_mnn1);
else
    list_chunk = [1 length(list_mnn1)];
end
tseries_up = tseries;
for num_c = 1:(length(list_chunk)-1)
    chunk = list_chunk(num_c):list_chunk(num_c+1);
    wgt = repmat(((list_size(list_mnn1(chunk))+list_size(list_mnn2(chunk))).^(-1))',[size(tseries,1) 1]);
    tseries_up(:,list_mnn1(chunk)) = ((tseries(:,list_mnn1(chunk)).*repmat(list_size(list_mnn1(chunk))',[size(tseries,1) 1]))+(tseries(:,list_mnn2(chunk)).*repmat(list_size(list_mnn2(chunk))',[size(tseries,1) 1]))).*wgt;
end

function [neig,mask_change] = sub_merge_neig(neig,num_roi1,num_roi2,ind1,ind2,mask_change,list_roi_ind)

%% part I : Merge the neighbourhoods of two regions
new_neig = unique([neig(ind1,:),neig(ind2,:)]);
if new_neig(1) == 0
    new_neig = new_neig(2:end);
end

if length(new_neig) > size(neig,2)
    neig = [neig zeros([size(neig,1) length(new_neig)-size(neig,2)])];
end

if size(neig,2)>length(new_neig)
    neig(ind1,:) = [new_neig zeros([1 size(neig,2)-length(new_neig)])];
else
    neig(ind1,:) = new_neig;
end
neig(ind2,:) = 0; % The roi #2 is now empty. It does not have any neighbour

%% part II: update the neighbourhood of the neighbours of roi1 and roi2
ind_new = list_roi_ind(new_neig);
mask_change(ind_new) = true;
neig0 = neig(ind_new,:); % Neighbourhoods of the neighbours of the merged ROI
mask1 = neig0==num_roi1; % position of ROI 1 in neighbourhood
mask2 = neig0==num_roi2; % position of ROI 2 in neighbourhood
mask12 = max(mask1,[],2)&max(mask2,[],2); % mask of neighbours of roi1 and roi2
neig1 = neig0(mask12,:); % neighbourhood of neighbours of ROI 1&2
neig2 = neig0(~mask12,:); % neighbourhood of neighbours of just ROI 1 or just ROI 2
neig1(mask2(mask12,:)) = 0; % Roi #1&2 are neighbours of this guy. Suppress roi #2
neig2(mask2(~mask12,:)) = num_roi1; % Roi 2 only is neighbour of this guy. Replace ROI 2 by ROI 1
neig0(mask12,:) = neig1; % Update the values in the full neighbourhood matrix
neig0(~mask12,:) = neig2; % Update the values in the full neighbourhood matrix
neig(ind_new,:) = neig0; % Update the values in the full neighbourhood matrix
