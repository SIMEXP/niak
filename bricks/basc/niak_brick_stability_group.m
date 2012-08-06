function [files_in,files_out,opt] = niak_brick_stability_group(files_in,files_out,opt)
% Estimate the stability of a clustering on an average stability matrix.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_GROUP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN 
%   (structure) with the following fields : 
%
%   STABILITY
%       (structure) with arbitrary field names :
%
%       <SUBJECT>
%           (string) the name of a .mat file, which contains one variable 
%           STAB. STAB is a vectorized matrix of stability coefficients. 
%           All the matrices should be in the same space. In particular, 
%           the length of the spatial dimension should be identical for all 
%           time series.
%
%   INFOS
%       (string, default 'gb_niak_omitted') the name of a CSV file. 
%       Example :
%                 , SEX , HANDEDNESS
%       <SUBJECT> , 0   , 0 
%       This type of file can be generated with Excel (save under CSV).
%       The infos will be used to "stratify" the data, i.e. resampling of
%       the data will be restricted within groups of subjects that share 
%       identical infos. All strata will be given equal weights to build
%       the consensus across subjects. If omitted, all subjects will belong
%       to the same strata.
%
% FILES_OUT
%   (string) A .mat file which contains the following variables : 
%
%   STAB
%       (array) STAB(:,s) is the vectorized version of the stability matrix
%       associated with OPT.NB_CLASSES(s) clusters.
%
%   STAB_AVG
%       (array) STAB_AVG is the vectorized version of the individual 
%       stability matrix averaged across all subjects.
%
%   NB_CLASSES
%       (vector) Identical to OPT.NB_CLASSES (see below).
%
%   NB_CLASSES_FINAL
%       (vector) Identical to OPT.NB_CLASSES_FINAL (see below).
%
%   NB_CLASSES_IND
%       (integer) The number of classes used to derive the individual
%       stability matrices (see OPT.NB_CLASSES_IND below).
%
%   PART
%       (matrix N*S) PART(:,s) is the consensus partition associated with 
%       STAB(:,s), with the number of clusters optimized using the summary
%       statistics.
%
%   ORDER
%       (matrix N*S) ORDER(:,s) is the order associated with STAB(:,s) and
%       PART(:,s) (see NIAK_PART2ORDER).
%
%   SIL
%       (matrix S*N) SIL(s,n) is the mean stability contrast associated with
%       STAB(:,s) and n clusters (the partition being defined using HIER{s}, 
%       see below).
%
%   INTRA
%       (matrix, S*N) INTRA(s,n) is the mean within-cluster stability
%       associated with STAB(:,s) and n clusters (the partition being defined 
%       using HIER{s}, see below).
%
%   INTER
%       (matrix, S*N) INTER(s,n) is the mean maximal between-cluster stability 
%       associated with STAB(:,s) and n clusters (the partition being defined 
%       using HIER{s}, see below).
%
%   HIER
%       (cell of array) HIER{S} is the hierarchy associated with STAB(:,s)
%
% OPT           
%   (structure) with the following fields.  
%
%   MIN_SUBJECT
%       (integer, default 3) the minimal number of subjects to start the group-level
%       stability analysis. An error message will be issued if this number is 
%       not reached. 
%
%   NB_CLASSES
%       (vector of integer) the number of clusters (or classes) that will
%       be investigated. This parameter will overide the parameters
%       specified in CLUSTERING.OPT_CLUST
%
%   NB_CLASSES_FINAL
%       (vector of integer, default []) the number of final (consensus) clusters. 
%       By default (empty), the number is selected to optimize the stability contrast 
%       in a neighbourhood of OPT.NB_CLASSES. 
%
%   NB_CLASSES_IND
%       (integer) The number of classes used to derive the individual
%       stability matrices. This will be used to select the individual
%       stability matrices.
%
%   RAND_SEED
%       (scalar, default []) The specified value is used to seed the random
%       number generator with PSOM_SET_RAND_SEED. If left empty, no action
%       is taken.
%
%   NB_SAMPS
%       (integer, default 100) the number of samples to use in the 
%       bootstrap Monte-Carlo approximation of stability.
%
%   CLUSTERING
%       (structure, optional) with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 'hierarchical'
%
%       OPT
%           (structure, optional) options that will be  sent to the
%           clustering command. The exact list of options depends on
%           CLUSTERING.TYPE:
%               'hierarchical' : see OPT in NIAK_HIERARCHICAL_CLUSTERING
%
%   CONSENSUS
%       (structure, optional) This structure describes
%       the clustering algorithm used to estimate a consensus clustering on 
%       each stability matrix, with the following fields :
%
%       TYPE
%           (string, default 'hierarchical') the clustering algorithm
%           Available options : 'hierarchical'
%
%       OPT
%           (structure, default see NIAK_HIERARCHICAL_CLUSTERING) options 
%           that will be  sent to the  clustering command. The exact list 
%           of options depends on CLUSTERING.TYPE:
%              'hierarchical' : see NIAK_HIERARCHICAL_CLUSTERING
%
%   FLAG_TEST
%       (boolean, default 0) if the flag is 1, then the function does not
%       do anything but update the defaults of FILES_IN, FILES_OUT and OPT.
%
%   FLAG_VERBOSE 
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY_REST, NIAK_PIPELINE_STABILITY_MULTI
%
% _________________________________________________________________________
% COMMENTS:
%
% Unless there are more clusters than atoms (trivial case), subjects with 
% a zero stability matrix are ignored. This feature makes it possible to 
% dynamically filter out subjects based on certain desirable features of the
% individual datasets during pipeline execution (if the subject is not usable, 
% just generate a zero stability matrix). 
%
% For more details, see the description of the stability analysis on a
% group clustering in the following reference :
%
% P. Bellec; P. Rosa-Neto; O.C. Lyttelton; H. Benalib; A.C. Evans,
% Multi-level bootstrap analysis of stable clusters in resting-State fMRI. 
% Neuroimage 51 (2010), pp. 1126-1139 
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap

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
if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_GROUP(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_group'' for more info.')
end
    
%% Files in
list_fields   = {'stability' , 'infos'           };
list_defaults = {NaN         , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Options
opt_clustering.type   = 'hierarchical';
opt_clustering.opt    = struct();
opt_consensus.clustering.type    = 'hierarchical';
list_fields    = {'min_subject' , 'rand_seed' , 'nb_samps' , 'nb_classes' , 'nb_classes_final' , 'nb_classes_ind' , 'clustering'   , 'consensus'   , 'flag_verbose' , 'flag_test' };
list_defaults  = {3             , []          , 100        , NaN          , []                 , NaN              , opt_clustering , opt_consensus , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Seed the random generator
if ~isempty(opt.rand_seed)
    psom_set_rand_seed(opt.rand_seed);
end

%% Read the individual stability matrices
if opt.flag_verbose
    fprintf('Reading the individual stability matrices ...\n');
end

infos = files_in.infos;
list_subject = fieldnames(files_in.stability);
files_in = struct2cell(files_in.stability);
N = length(files_in);
for num_e = 1:N
    data = load(files_in{num_e});
    if num_e == 1
        S = size(data.stab,1);
        mat_stab = zeros([S N]);
    end
    if size(data.stab,2)~=length(data.nb_classes)
        if ~max(data.stab)==0
            error('%s : the dimensions of STAB are not compatible with NB_CLASSES',files_in{num_e})
        end
    else   
        mat_stab(:,num_e) = data.stab(:,data.nb_classes==opt.nb_classes_ind);
    end
end
clear data

%% Filter out empty stability matrices, to offer support for missing data evaluated during pipeline execution
nr = size(niak_vec2mat(mat_stab(:,1),1));
if opt.nb_classes_ind < nr
    mask = max(mat_stab,[],1)>0;
    mat_stab = mat_stab(:,mask);
    list_subject = list_subject(mask);
    files_in = files_in(mask);
    N = length(files_in);
end

if N < opt.min_subject
    error('There was not enough usable subjects (%i) for the group-level analysis (either there is not enough subjects in the first place, or the individual datasets were somehow incomplete',opt.min_subject)
end

%% Build strata
if strcmp(infos,'gb_niak_omitted');
    mask = ones([N 1]);
else
    [strata,labels_x] = niak_read_csv(infos);
    strata_r = zeros([N size(strata,2)]);
    for num_s = 1:N
        ind = find(ismember(labels_x,list_subject{num_s}));
        if isempty(ind)
            error(sprintf('Could not find subject %s in INFOS. Check the CSV file.',list_subject{num_s}));
        end
        strata_r(num_s,:) = strata(ind,:);
    end
    [tmp1,tmp2,mask] = unique(strata_r,'rows');
end

%% Estimation of the stability
opt_s = rmfield(opt,{'flag_test','consensus','rand_seed','nb_classes_ind','min_subject','nb_classes_final'});
stab = niak_stability_group(mat_stab,mask,opt_s);

%% Consensus clustering
opt_c = opt.consensus;
opt_c.flag_verbose = opt.flag_verbose;
opt_c.nb_classes = opt.nb_classes_final;
[part,order,sil,intra,inter,hier,nb_classes_final] = niak_consensus_clustering(stab,opt_c);

%% Save outputs
if opt.flag_verbose
    fprintf('Save outputs ...\n');
end
nb_classes = opt.nb_classes;
nb_classes_ind = opt.nb_classes_ind;
save(files_out,'stab','nb_classes','nb_classes_ind','nb_classes_final','part','hier','order','sil','intra','inter')
