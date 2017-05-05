function [pipeline,opt_pipe,files_in] = niak_demo_subtype(path_demo,opt)
% Run NIAK_PIPELINE_SUBTYPE on the output of NIAK_PIPELINE_CONNECTOME
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_SUBTYPE(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the output of the connectome pipeline, 
%   generated from the NIAK demo dataset. 
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_SUBTYPE
%   will do here. The demo only changes one default and enforces a few 
%   parameters (see COMMENTS below):
%
%   EXT 
%      (string, default '.mnc.gz') file name extension, either: 
%      '.mnc' or '.mnc.gz' or '.nii' or '.nii.gz'
%
%   FOLDER_OUT
%      (string, default PATH_DEMO/SUBTYPE) where to store the 
%      results of the pipeline.
%
% _________________________________________________________________________
% OUTPUT
%
% PIPELINE
%   (structure) a formal description of the pipeline. See
%   PSOM_RUN_PIPELINE.
%
% OPT_PIPE
%   (structure) the option to call NIAK_PIPELINE_SUBTYPE
%
% FILES_IN
%   (structure) the description of input files used to call 
%   NIAK_PIPELINE_SUBTYPE
%
% _________________________________________________________________________
% COMMENTS
%
% Note 1:
% It is possible to configure the pipeline manager to 
% use parallel computing using OPT.PSOM, see : 
% http://code.google.com/p/psom/wiki/PsomConfiguration
%
% NOTE 2:
% The demo database exists in multiple file formats. NIAK looks into the demo 
% path and is supposed to figure out which format you are intending to use 
% by itself. 
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Sebastian Urchs, Angela Tam
% Centre de recherche de l'institut de griatrie de Montral, 
% Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2013
% Maintainer : sebastian.urchs@mail.mcgill.ca
% See licensing information in the code.
% Keywords : subtyping, fMRI

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

if nargin < 1
    error('Please specify the path to the preprocessed DEMONIAK database in PATH_DEMO')
end
if nargin < 2
    opt = struct();
end

path_demo = niak_full_path(path_demo);
opt = psom_struct_defaults(opt,{'ext'     , 'folder_out'                         ,'flag_test'},...
						                   {'.mnc.gz' , [path_demo,filesep,'subtype',filesep],false     });

if ~ismember(opt.ext,{'.mnc','.mnc.gz','.nii','.nii.gz'})
    error('OPT.EXT must be one of ''.mnc'', ''.mnc.gz'', ''.nii'' or ''.nii.gz'' ')
end

%% The model
files_in.model = [GB_NIAK.path_niak 'demos' filesep 'data' filesep 'demoniak_model_group.csv'];

%% The mask
files_in.mask = [path_demo 'network_rois' opt.ext];

%% Duplicate subjects
files_in.data.aMPFC.subject1a = [path_demo 'rmap_seeds' filesep 'rmap_subject1_aMPFC' opt.ext];
files_in.data.aMPFC.subject1b = [path_demo 'rmap_seeds' filesep 'rmap_subject1_dMPFC3' opt.ext];
files_in.data.aMPFC.subject1c = [path_demo 'rmap_seeds' filesep 'rmap_subject1_FUS' opt.ext];
files_in.data.aMPFC.subject1d = [path_demo 'rmap_seeds' filesep 'rmap_subject1_MTL' opt.ext];
files_in.data.aMPFC.subject2a = [path_demo 'rmap_seeds' filesep 'rmap_subject2_aMPFC' opt.ext];
files_in.data.aMPFC.subject2b = [path_demo 'rmap_seeds' filesep 'rmap_subject2_dMPFC3' opt.ext];
files_in.data.aMPFC.subject2c = [path_demo 'rmap_seeds' filesep 'rmap_subject2_FUS' opt.ext];
files_in.data.aMPFC.subject2d = [path_demo 'rmap_seeds' filesep 'rmap_subject2_MTL' opt.ext];

%% Options for the subtyping pipeline
opt.stack.regress_conf = {'site'};
opt.association.age.contrast.age = 1;
opt.chi2 = 'subject1';
opt.rand_seed = 1;

%% Run the pipeline
[pipeline,opt_pipe] = niak_pipeline_subtype(files_in,rmfield(opt,'ext'));
