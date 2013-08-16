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
%   NIAK_PIPELINE_STABILITY_REST at the group level.
%
% OPT
%   (structure, optional) with the following fields :
%
%   TYPE
%      (string, default 'consensus') the type of network clusters. Available options:
%      'consensus' : the original consensus clusters 
%      'core' : the stability core of the consensus clusters. 
%      'adjusted' : the clusters are defined by the stability maps associated with 
%         the stability cores.
%      'threshold' : the clusters are defined by the stabilitsy maps associated with 
%         the stability cores, and a minimal stability threshold is applied.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%   (structure) the exact fields depend on OPT.TYPE_FILES. 
%
%   NETWORKS.<LABEL_NETWORK>
%      (string) a file name of a mask of partition into brain networks 
%      (network I is filled with Is, 0 is for the background). 
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
%               Université de Montréal, 2011-2013.
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
list_fields   = { 'type'      };
list_defaults = { 'consensus' };
if nargin > 1
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end
if ~ismember(opt.type,{'consensus','core','adjusted','threshold'})
    error('%s is not a supported type of network',opt.type)
end
list_ext = {'.mnc','.nii',['.mnc' gb_niak_zip_ext],['.nii' gb_niak_zip_ext]};

%% Grab the list of subject
files.networks = struct();
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
        files.networks.(scale) = [path_scale 'brain_partition_' opt.type '_group_' scale list_ext{num_e}];            
        flag_exist = psom_exist(files.networks.(scale));
    end
    if ~flag_exist
        error('Could not find the %s partition at scale %s',opt.type,scale);
    end    
end