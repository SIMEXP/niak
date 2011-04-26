function [files_in,files_out,opt] = niak_brick_qc_corsica(files_in,files_out,opt)
% Quality-control for the ICA-based correction of structured noise in fMRI.
% The output is a PDF file representing the spatial and temporal components
% of the ICA ordered according to the selection score, and optionnally
% indicating if this component would be selected at a given threshold.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_QC_CORSICA(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields : 
%
%   SPACE
%       (string) The name of a file with the spatial components of the ICA.
%
%   TIME 
%       (string) The name of a mat file with a variable TSERIES (2D array). 
%       TSERIES(:,K) is the temporal distribution of the Kth ICA source. 
%
%   MASK
%       (string) The name of a file with a binary mask of the brain.
%
%   SCORE
%       (cell of string, default 'gb_niak_omitted') each entry is a mat 
%       file with one variable SCORE. SCORE(K) is the score of selection 
%       for the Kth component. The maximal score across all entries of 
%       SCORE will be derived, and used to sort components in decreasing 
%       order of score. The scores associated with each component will be 
%       indicated in the title, see OPT.LABELS_SCORE below. 
%
% FILES_OUT
%   (string, default <BASE_NAME_SPACE>_qc_corsica.pdf )
%   a pdf figure showing the spatial distribution of the components on 
%   axial slices after robust correction to normal distribution, as well as 
%   the time, spectral and time frequency representation of the 
%   time component. The components can be ordered according to a selection
%   score.
%
% OPT
%   (structure) with the following fields :
%
%   LABELS_SCORE
%       (cell of string, default {'',...,''}) LABELS_SCORE{I} will be used 
%       in the title to refer to scores from FILES_IN.SCORE{I}.
%
%   FWHM
%       (scalar, default 5) the FWHM of a Gaussian smoothing that will be
%       applied on every spatial component.
%
%   THRESHOLD
%       (scalar, default Inf) A * will be added after the scores that are
%       above THRESHOLD in the title of the figures.
%
%   FOLDER_OUT
%       (string, default: path of FILES_IN) If present, all default outputs 
%       will be created in the folder FOLDER_OUT. The folder needs to be 
%       created beforehand.
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
% NIAK_BRICK_SICA, NIAK_COMPONENT_SEL, NIAK_BRICK_COMPONENT_SUPP, NIAK_SICA
% NIAK_PIPELINE_CORSICA
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : ICA, CORSICA, fMRI, physiological noise

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
niak_gb_vars; % Importing NIAK global variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SICA(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_sica'' for more info.')
end

%% Inputs
gb_name_structure = 'files_in';
gb_list_fields    = {'space' , 'time' , 'mask' , 'score'           };
gb_list_defaults  = {NaN     , NaN    , NaN    , 'gb_niak_omitted' };
niak_set_defaults

%% Output files
if nargin<2
    files_out = '';
end

if ~ischar(files_out)
    error('FILES_OUT should be a string');
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'labels_score' , 'fwhm'      , 'threshold' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {''             , 5           , Inf         , true           , false       , ''           };
niak_set_defaults

%% Default outputs
[path_f,name_f,ext_f] = niak_fileparts(files_in.space);

if isempty(opt.folder_out)
    opt.folder_out = path_f;
end

if isempty(files_out)
    files_out = [opt.folder_out,filesep,name_f,'_qc_corsica.pdf'];
end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%
%% Reading inputs %%
%%%%%%%%%%%%%%%%%%%%

% Space components
if flag_verbose
    fprintf('Reading spatial components %s ...\n',files_in.space);
end
[hdr,vol_space] = niak_read_vol(files_in.space);

% Brain mask
if flag_verbose
    fprintf('Reading the brain mask %s ...\n',files_in.mask);
end
[hdr,mask] = niak_read_vol(files_in.mask);
mask = mask>0;

% Time components
if flag_verbose
    fprintf('Reading temporal components %s ...\n',files_in.time);
end
load(files_in.time,'tseries');

% Selection scores
if ~ischar(files_in.score)
    for num_s = 1:length(files_in.score)
        if flag_verbose
            fprintf('Reading the selection score %s ...\n',files_in.score{num_s});
        end
        tmp = load(files_in.score{num_s});
        if num_s == 1
            score = zeros([length(tmp.score) length(files_in.score)]);
        end
        score(tmp.order,num_s) = tmp.score;
    end
    score_max = max(score,[],2);
else    
    score     = zeros([size(tseries,2) 1]);
    score_max = score;
    threshold = Inf;
end

%%%%%%%%%%%%%%%%%%%%%%%
%% Generating figure %%
%%%%%%%%%%%%%%%%%%%%%%%
if flag_verbose
    fprintf('Generating a pdf summary of the ICA ...\n');
end

%% Options & temporary folders
folder_tmp = niak_path_tmp('_qc_corsica');
file_space = cell([size(tseries,2) 1]);
file_time  = cell([size(tseries,2) 1]);

opt_visu.voxel_size = hdr.info.voxel_size;
opt_visu.fwhm       = opt.fwhm;
opt_visu.vol_limits = [0 3];
opt_visu.type_slice = 'axial';
opt_visu.type_color = 'jet';

[tmp,order] = sort(score_max,'descend');
order = order(:)';

for num_c = order
    
    file_space{num_c} = sprintf('%sfig_corsica_space_%i.eps',folder_tmp,num_c);
    file_time{num_c}  = sprintf('%sfig_corsica_time_%i.eps',folder_tmp,num_c);
    
    %% Score title
    if ~ischar(files_in.score)
        title_score = '(';
        for num_s = 1:size(score,2)
            if ~ isempty(labels_score)
                title_score = [title_score labels_score{num_s} ': '];
            end
            title_score = [title_score num2str(score(num_c,num_s))];
            if score(num_c,num_s)>=threshold
                title_score = [title_score '*'];
            end
            if num_s==size(score,2)
                title_score = [title_score ')'];
            else
                title_score = [title_score ' ; '];
            end
        end
    else
        title_score = '';
    end
    
    %% Spatial distribution
    hf = figure;
    subplot(1,1,1)
    vol_c = niak_correct_vol(vol_space(:,:,:,num_c),mask);
    niak_montage(abs(vol_c),opt_visu);    
    title(sprintf('Component %i %s',num_c,title_score));        
    print(file_space{num_c},'-dpsc2');    
    close(hf)
    
    %% temporal distribution
    hf = figure;
    nt = size(tseries,1);
    subplot(3,1,1)
    
    if isfield(hdr.info,'tr')
        if hdr.info.tr~=0
            plot(hdr.info.tr*(1:nt),tseries(:,num_c));
        else
            plot(tseries(:,num_c));
        end
    else
        plot(tseries(:,num_c));
    end
    
    xlabel('time')
    ylabel('a.u.')
    title(sprintf('Time component %i, file %s',num_c,name_f));
    
    %% Frequency distribution
    subplot(3,1,2)
    if isfield(hdr.info,'tr')
        if hdr.info.tr~=0
            niak_visu_spectrum(tseries(:,num_c),hdr.info.tr);
        else
            niak_visu_spectrum(tseries(:,num_c),1);
        end
    else
        niak_visu_spectrum(tseries(:,num_c),1);
    end
    
    %% Time-frequency distribution
    subplot(3,1,3)
    if isfield(hdr.info,'tr')
        if hdr.info.tr~=0
            niak_visu_wft(tseries(:,num_c),hdr.info.tr);
        else
            niak_visu_wft(tseries(:,num_c),1);
        end
    else
        niak_visu_wft(tseries(:,num_c),1);
    end    
    print(file_time{num_c},'-dpsc2');    
    close(hf)    
end

%% Merge all eps figures into a single file
file_eps_final = [folder_tmp 'fig_corsica.eps'];
instr_concat = ['gs  -q -dNOPAUSE -dBATCH -sOutputFile=' file_eps_final '  -sDEVICE=pswrite ' ];
for num_c = order
    instr_concat = [instr_concat file_space{num_c} ' ' file_time{num_c} ' '];
end
instr_concat = [instr_concat 'quit.ps'];
[status,msg] = system(instr_concat);
if status~=0
    error(['There was a problem concatenating the EPS figures with ghostscript (gs): ',msg]);
end

%% In octave, use ps2pdf to convert the result into PDF format
instr_ps2pdf = cat(2,'ps2pdf -dEPSCrop ',file_eps_final,' ',files_out);
[succ,msg] = system(instr_ps2pdf);
if succ~=0
    warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf with ps2pdf: ',msg));
end

%% Clean up
instr_clean = ['rm -rf ' folder_tmp];
[status,msg] = system(instr_clean);
if status~=0
    error(['There was a problem cleaning-up the temporary folder : ' msg]);
end

if flag_verbose
    fprintf('Done!\n');
end