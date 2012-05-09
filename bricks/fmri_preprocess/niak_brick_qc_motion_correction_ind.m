function [files_in,files_out,opt] = niak_brick_qc_motion_correction_ind(files_in,files_out,opt)
% Derive individual measures of quality control for fMRI motion correction.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_MOTION_CORRECTION_IND(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (cell of string) multiple file names of .mat files including one
%   variable TRANSF, such that TRANSF(:,:,I) is the 4*4 rigid-body
%   motion estimated for volume I of the corresponding FILES_IN.VOL
%
% FILES_OUT
%   (string) A pdf figure with plots of the translation/rotation parameters
%
% OPT
%   (structure) with the following fields.
%
%   LABELS_VOL
%       (cell of strings) the labels used for each entry 
%       in the tables.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_MOTION, NIAK_BRICK_QC_COREGISTER
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de
% geriatrie de Montreal, Montreal, Canada, 2010-2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, quality control, motion

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

flag_gb_niak_fast_gb = true;
niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_MOTION_CORRECTION_IND(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_qc_motion_correction_ind'' for more info.')
end

%% FILES_IN
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings')
end

%% FILES_OUT
if ~iscellstr(files_out)
    error('FILES_OUT should be a cell of strings')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'labels_vol' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {NaN          , true           , false       , ''           };
niak_set_defaults

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

folder_tmp = niak_path_tmp('_qc_motion');

%% Build a figure of motion parameters
if flag_verbose
    fprintf('Generating figures of motion parameters ...\n');
end
nb_file = length(files_in);
file_eps = cell([nb_file 1]);
hfa = figure;
for num_f = 1:nb_file
    motion_params = load(files_in{num_f});
    rot = zeros([size(motion_params.transf,3) 3]);
    tsl = zeros([size(motion_params.transf,3) 3]);
    for num_t = 1:size(motion_params.transf,3)
        [rot(num_t,:),tsl(num_t,:)] = niak_transf2param(motion_params.transf(:,:,num_t));
    end    
    subplot(2,1,1)
    plot(rot)
    legend('rotation x','rotation y','rotation z')
    title(sprintf('Rotation parameters %s',labels_vol{num_f}));
    subplot(2,1,2)
    plot(tsl)
    legend('translation x','translation y','translation z')
    title(sprintf('Translation parameters %s',labels_vol{num_f}));
    file_eps{num_f} = [folder_tmp 'motion_parameters_' labels_vol{num_f} '.eps'];
    print(hfa,'-dpsc','-r300',file_eps{num_f});
end
close(hfa)
file_eps_final = [folder_tmp 'fig_final.eps'];
instr_concat = ['gs  -q -dNOPAUSE -dBATCH -dNOPLATFONTS -sOutputFile=' file_eps_final '  -sDEVICE=pswrite ' ];
for num_e = 1:nb_file
    instr_concat = [instr_concat file_eps{num_e} ' '];
end
instr_concat = [instr_concat 'quit.ps'];
system(instr_concat)
system(['ps2pdf ',file_eps_final,' ',files_out]);

%% clean-up
if flag_verbose
    fprintf('Done !\n');
end
instr_clean = ['rm -rf ' folder_tmp];
[status,msg] = system(instr_clean);
if status~=0
    error(msg)
end