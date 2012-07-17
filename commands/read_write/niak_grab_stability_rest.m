 function files = niak_grab_stability_rest(path_data,opt)
% Grab files created by NIAK_PIPELINE_STABILITY_REST
%
% SYNTAX:
% FILES = NIAK_GRAB_STABILITY_REST(PATH_DATA,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_STABILITY_REST. By default, the function will grab the group 
%   results. It is also possible to grab the mixed level, using OPT.FLAG_MIXED
%   below.
%
% OPT
%   (structure, optional) with the following fields :
%
%   LEVEL
%      (string, default 'group') the level of networks. Available options;
%      'group' : group-level (atlas) networks
%      'mixed' : group-level networks wraped on individual stability matrices.
%       
%   TYPE
%      (string, default 'consensus') the type of network clusters. Available options:
%      'consensus' : the original consensus clusters (identical for 'group' and
%         for 'mixed).
%      'core' : the stability core of the consensus clusters. Different for 
%         'group' and for 'mixed'.
%      'adjusted' : the clusters are defined by the stability maps associated with 
%         the stability cores.
%      'threshold' : the clusters are defined by the stability maps associated with 
%         the stability cores, and a minimal stability threshold is applied.
%
%   FLAG_TSERIES
%      (boolean, default true) if the flag is on, grab TIME_SERIES as well as MASK
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%   (structure) the exact fields depend on OPT.TYPE_FILES. 
%
%   NETWORKS
%      (structure) with the following (arbitrary) fields :
%
%      <LABEL_NETWORK>
%         (structure) LABEL_NETWORK codes for the scale of analysis (sci for 
%         the individual number of clusters, scg for the group-level number of 
%         clusters, and scf for the final number of clusters). The structure
%         has the following fields:     
%
%         MASK         
%            (string) a file name of a mask of partition into brain networks 
%            (network I is filled with Is, 0 is for the background). 
%
%         TIME_SERIES
%            (structure) with the following (arbitrary) fields:
% 
%            <SUBJECT>
%               (cell of strings) a list of time series associated with the 
%               networks in a .mat file (see OPT.FLAG_TSERIES above).
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY_REST, NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" is designed to work with the output of 
% NIAK_PIPELINE_STABILITY_REST to be fed in NIAK_PIPELINE_GLM_CONNECTOME
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2011.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series

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
niak_gb_vars

%% Default path for the database
if (nargin<1)||isempty(path_data)
    path_data = [pwd filesep];
end
path_data = niak_full_path(path_data);

%% Default options
list_fields   = { 'flag_tseries' , 'level' , 'type'      };
list_defaults = { true           , 'group' , 'consensus' };
if nargin > 1
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end
if ~ismember(opt.level,{'group','mixed'})
    error('%s is not a supported level of analysis',opt.level);
end
if ~ismember(opt.type,{'consensus','core','adjusted','threshold'})
    error('%s is not a supported type of network',opt.type)
end
list_ext = {'.mnc','.nii',['.mnc' gb_niak_zip_ext],['.nii' gb_niak_zip_ext]};

%% Grab the list of subject
files.networks = struct();
switch opt.level
case 'mixed'
    path_data = [path_data 'stability_mixed' filesep];
    if ~exist(path_data,'dir')
        error('Could not find the %s folder',path_data)
    end
    files_subject = dir(path_data);
    for num_sub = 1:length(files_subject)
        subject = files_subject(num_sub).name
        flag_subj = files_subject(num_sub).isdir&~strcmp(subject,'.')&~strcmp(subject,'..');
        if flag_subj
            path_subject = [path_data subject filesep];
            files_scales = dir(path_subject);
            for num_s = 1:length(files_scales);
                scale = files_scales(num_s).name;
                flag_scale = files_scales(num_s).isdir&~strcmp(scale,'.')&~strcmp(scale,'..');
                if ~flag_scale
                    continue
                end
                path_scale = [path_subject scale filesep];
                flag_exist = false;
                num_e = 0;
                while (~flag_exist)&&(num_e<length(list_ext))
                    num_e = num_e+1;
                    files.networks.(scale).mask = [path_scale 'brain_partition_' opt.type '_mixed_' subject '_' scale list_ext{num_e}];            
                    flag_exist = psom_exist(files.networks.(scale).mask);            
                end
                if ~flag_exist
                    error('Could not find the %s partition at scale %s for subject %s',opt.type,scale,subject);
                end
                if opt.flag_tseries
                    files_tseries = dir([path_scale '*' opt.type '*']);
                    nb_tseries = 1;
                    for num_t = 1:length(files_tseries)
                        if (~files_tseries(num_t).isdir)&&regexp(files_tseries(num_t).name,['^tseries_'])&&regexp(files_tseries(num_t).name,['*' opt.type '*'])
                            files.networks.(scale).tseries.(subject){nb_tseries} = [path_scale files_tseries(num_t).name];
                            nb_tseries = nb_tseries+1;
                        end
                    end
                end
            end                
        end 
    end

case 'group'
    path_data = [path_data 'stability_group' filesep];
    if ~exist(path_data,'dir')
        error('Could not find the %s folder',path_data)
    end
    files_scales = dir(path_data);
    
    for num_s = 1:length(files_scales);
        scale = files_scales(num_s).name;
        flag_scale = files_scales(num_s).isdir&~strcmp(scale,'.')&~strcmp(scale,'..');
        if ~flag_scale
            continue
        end
        path_scale = [path_data scale filesep];
        flag_exist = false;
        num_e = 0;
        while (~flag_exist)&&(num_e<length(list_ext))
            num_e = num_e+1;
            files.networks.(scale).mask = [path_scale 'brain_partition_' opt.type '_group_' scale list_ext{num_e}];            
            flag_exist = psom_exist(files.networks.(scale).mask);            
        end
        if ~flag_exist
            error('Could not find the %s partition at scale %s',opt.type,scale);
        end

        files_subject = dir(path_scale);
        for num_sub = 1:length(files_subject)
            subject = files_subject(num_sub).name;
            flag_subj = files_subject(num_sub).isdir&~strcmp(subject,'.')&~strcmp(subject,'..');
            if flag_subj&&opt.flag_tseries
                path_subject = [path_scale subject filesep];
                files_tseries = dir([path_subject '*' opt.type '*']);
                nb_tseries = 1;
                for num_t = 1:length(files_tseries)
                    if ~files_tseries(num_t).isdir
                        files.networks.(scale).tseries.(subject){nb_tseries} = [path_subject files_tseries(num_t).name];
                        nb_tseries = nb_tseries+1;
                    end
                end
            end                
        end
    end
end
