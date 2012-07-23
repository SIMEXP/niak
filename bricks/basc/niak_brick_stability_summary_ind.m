function [files_in,files_out,opt] = niak_brick_stability_summary_ind(files_in,files_out,opt)
% Summary measures of clustering stability analysis.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SUMMARY_IND(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (cell array of strings) FILES_IN{N} is a .mat file with a variable
%   SIL. SIL is a matrix S*K, with various summary measures of 
%   cluster stability. The column K of SIL has been derived with 
%   OPT.NB_CLASSES(K) clusters. The row S of SIL has been derived with S 
%   final clusters. The different entries of FILES_IN usually correspond to
%   different subjects and will ultimately be averaged.
%
% FILES_OUT
%   (structure) with the following fields :
%
%   SIL_ALL
%       (string) a .mat file with the following variables : 
%
%       SCALES
%           (array) identical to OPT.NB_CLASSES
%
%       SIL_ALL
%           (array) SIL(S,K,N) is SIL(S,K) drawn from FILES_IN{N}
%
%       SIL_ALL_MAX
%           (array) SIL_ALL_MAX(S,N) is the maximal contrast for K in 
%           a neighbourhood of S and subject N.
%
%       SCALES_ALL_MAX
%           (array) SCALES_ALL_MAX(S,N) is the number of classes K that
%           achieved maximal contrast.
%
%       PEAKS_ALL
%           (cell array) PEAKS_ALL{N} is the list of scales achieving local 
%           maxima of stability for subject N.
%
%       SIL_AVG_MAX
%           (array) SIL_AVG_MAX(S,N) is the maximal contrast for K in 
%           a neighbourhood of S, averaged across all subjects.
%
%       SIL_STD_MAX
%           (array) SIL_STD_MAX(S,N) is the standard deviation (across all 
%           subjects) associated with SIL_AVG_MAX(S,N).
%
%       SCALES_AVG_MAX
%           (array) SCALES_AVG_MAX(S,N) is the number of classes K that
%           achieved maximal average contrast.
%
%       PEAKS_AVG
%           (vector) PEAKS_AVG is the list of scales achieving local 
%           maxima of stability averaged across all subjects.
%
%   FIGURE_SIL_MAX
%       (string) the name of a pdf file with a plot of SIL_AVG_MAX and 
%       SIL_STD_MAX with local maxima PEAKS_AVG highlighted
%
%   TABLE_SIL_MAX
%       (string) a text file with the local maxima of the stability
%       contrast, with corresponding values. There are multiple columns per
%       entry (first the number of clusters, the last one with
%       the value of the local maximum).
%
% OPT
%   (structure) with the following fields.
%
%   NB_CLASSES
%       (vector) SIL(:,K) was analyzed NB_CLASSES(K) clusters. 
%
%   NEIGH
%       (vector, default [0.7 1.3]) defines the local neighbourhood of
%       a number of clusters. If NEIGH has more than two elements, the
%       first and last element will be used to define the neighbourhood.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function
%       prints some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%       do anything but update the default values in FILES_IN, FILES_OUT 
%       and OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_MAX_SIL, NIAK_BRICK_STABILITY_SUMMARY_GROUP
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : BASC, clustering, stability contrast
%
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

if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SUMMARY_IND(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_summary_ind'' for more info.')
end

%% Files in
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings');
end

%% Files out
list_fields   = {'sil_all'         , 'figure_sil_max'   , 'table_sil_max'   };
list_defaults = {'gb_niak_omitted' , 'gb_niak_omitted'  , 'gb_niak_omitted' };
files_out     = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
list_fields =   {'nb_classes' , 'neigh'   , 'flag_verbose' , 'flag_test' };
list_defaults = {NaN          , [0.7,1.3] , true           ,false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

if opt.flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
niak_gb_vars

if opt.flag_verbose
    fprintf('Generating a summary of the stability contrast analysis\n')
end

%% Reading all summary measures
if opt.flag_verbose
    fprintf('Reading the measures of stability contrast ...\n');
end
nb_classes = opt.nb_classes;
K = length(nb_classes);
N = length(files_in);
mask_ok = true(N,1);
for num_n = 1:N
    if opt.flag_verbose
        fprintf('    %s\n',files_in{num_n});
    end
    data = load(files_in{num_n},'sil');
    sil = data.sil;
    if ~any(abs(data.sil))
       warning('All silhouette values are equal to zero. I am going to assume that the dataset of this subject was not usable.');
       mask_ok(num_n) = false;
       continue
    end
    if ~exist('sil_all','var')
        [S,K] = size(sil);
        sil_all = zeros([S,K,N]);
    end
    if max(size(sil)~=[S,K])
        error('All SIL arrays should have the same length')
    end
    sil_all(:,:,num_n) = sil;
end

%% Filter out subjects with unusable silhouette values
files_in = files_in(mask_ok);
N = length(files_in);
sil_all = sil_all(:,:,mask_ok);
        
%% Extract maximal measures over clustering parameters for each individual
scales = nb_classes;
sil_all_max = zeros([S N]);
scales_all_max = zeros([S,N]);
for num_n = 1:N
    [sil_all_max(:,num_n),scales_all_max(:,num_n)] = niak_build_max_sil(sil_all(:,:,num_n),nb_classes(:),opt.neigh,1);    
    mask = ~isnan(sil_all_max(:,num_n));
    list_s = find(mask);
    [val_max,ind_max] = niak_find_local_max_1d(list_s,sil_all_max(mask,num_n),opt.neigh);
    peaks_all{num_n} = list_s(ind_max);
end

%% Extract maximal measures over clustering parameters averaged across
%% individuals
if ndims(sil_all)>2
    sil_avg = mean(sil_all,3);
    sil_std = std(sil_all,[],3);
else
    sil_avg = sil_all;
    sil_std = zeros(size(sil_avg));
end
[sil_avg_max,scales_avg_max] = niak_build_max_sil(sil_avg,nb_classes(:),opt.neigh,1);
mask = ~isnan(sil_avg_max);
list_s = find(mask);
[val_max,ind_max] = niak_find_local_max_1d(list_s,sil_avg_max(mask),opt.neigh);
peaks_avg = list_s(ind_max);
sil_std_max = zeros(size(sil_avg_max));
for num_s = list_s(:)'
    sil_std_max(num_s) = sil_std(num_s,scales==scales_avg_max(num_s));
end
sil_std_max(~mask) = NaN;

if ~strcmp(files_out.sil_all,'gb_niak_omitted')
    save(files_out.sil_all,'sil_all','scales','sil_all_max','scales_all_max','peaks_all','sil_avg_max','scales_avg_max','peaks_avg','sil_std_max');
end

%% Table of local max of the stability contrast
if opt.flag_verbose
    fprintf('Building table of local max ...\n');
end
lab_x = {};
lab_y = {'K','S'};

if isempty(peaks_avg)
    tab = [NaN NaN]
else
    c1 = scales_avg_max(peaks_avg);
    c2 = peaks_avg;
    tab = [c1(:) c2(:)];
end

if ~strcmp(files_out.table_sil_max,'gb_niak_omitted')
    niak_write_tab(files_out.table_sil_max,tab,lab_x,lab_y);
end

%% Figure of stability contrast
if ~strcmp(files_out.figure_sil_max,'gb_niak_omitted')
    if opt.flag_verbose
        fprintf('Building a figure of group summary measures ...\n');
    end
    
    if strcmp(gb_niak_language,'octave')
        file_eps = psom_file_tmp('_stability_contrast.eps');
    end
    hfa = figure;
    errorbar(1:S,sil_avg_max,sil_std_max);
    hold on        
    plot(peaks_avg,sil_avg_max(peaks_avg),'r*')
    str_title = sprintf('Average individual stability contrast');        
    title(str_title);
    if strcmp(gb_niak_language,'octave')
        print(hfa,'-dpsc','-r300',file_eps);
    else
        print(hfa,'-dpdf',files_out.figure_sil_max);            
    end
    close(hfa)
    
    if strcmp(gb_niak_language,'octave')               
        % Conversion in pdf
        instr_ps2pdf = ['ps2pdf -dEPSCrop ',file_eps,' ',files_out.figure_sil_max];
        [succ,msg] = system(instr_ps2pdf);
        if succ~=0
            warning(cat(2,'There was a problem in the conversion of the figure from ps to pdf with ps2pdf: ',msg));
        end
        
        % Clean up
        instr_clean = ['rm -rf ' file_eps];
        [status,msg] = system(instr_clean);
        if status~=0
            error(['There was a problem cleaning-up the temporary folder : ' msg]);
        end
   end
   if opt.flag_verbose
      fprintf('Done!\n');
   end
end
