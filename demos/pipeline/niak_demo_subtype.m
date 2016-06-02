function [pipeline,opt_pipe,files_in] = niak_demo_subtype(path_demo,opt)
% This function runs NIAK_PIPELINE_SUBTYPE on the preprocessed DEMONIAK dataset
%
% SYNTAX:
% [PIPELINE,OPT_PIPE,FILES_IN] = NIAK_DEMO_SUBTYPE(PATH_DEMO,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%   (string) the full path to the preprocessed NIAK demo dataset. The dataset 
%   can be found at http://www.nitrc.org/frs/?group_id=411
%
% OPT
%   (structure, optional) Any argument passed to NIAK_PIPELINE_SUBTYPE
%   will do here. The demo only changes one default and enforces a few 
%   parameters (see COMMENTS below):
%
%   FILES_IN 
%      (structure, default grab the preprocessed demoniak) the input files 
%      for the region growing.

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
% The demo will apply the subtyping pipeline on preprocessed version of 
% the DEMONIAK dataset. It is possible to configure the pipeline manager to 
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
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2013
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

if nargin < 1
    error('Please specify the path to the preprocessed DEMONIAK database in PATH_DEMO')
end
if nargin < 2
    opt = struct();
end

path_demo = niak_full_path(path_demo);
opt = psom_struct_defaults(opt,{'files_in','folder_out'                        ,'flag_test' },...
						       {''        ,[path_demo,filesep,'subtype',filesep],false       });

if isempty(opt.files_in)&&~strcmp(opt.files_in,'gb_niak_omitted')
    %% Grab the results from the NIAK fMRI preprocessing pipeline
    opt_g.min_nb_vol = 30; % the demo dataset is very short, so we have to lower considerably the minimum acceptable number of volumes per run 
    opt_g.type_files = 'scores'; % Specify to the grabber to prepare the files for the scores pipeline
    files_in = niak_grab_fmri_preprocess(path_demo,opt_g); % Replace the folder by the path where the results of the fMRI preprocessing pipeline were stored. 
else
    files_in = opt.files_in;
end
[pipeline,opt_pipe] = niak_pipeline_subtype(files_in,rmfield(opt,'files_in'));