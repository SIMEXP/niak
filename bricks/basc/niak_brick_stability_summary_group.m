function [files_in,files_out,opt] = niak_brick_stability_summary_group(files_in,files_out,opt)
% Group summary measures of clustering stability analysis.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SUMMARY_GROUP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (cell array of strings) FILES_IN{N} is a .mat file with some variables
%   SIL, NB_CLASSES_IND and NB_CLASSES. SIL is a matrix S*K, with various 
%   summary measures of the group-level cluster stability. All measures in 
%   column K of SIL have been derived with NB_CLASSES_IND individual 
%   clusters and NB_CLASSES(K) group clusters. The row S of SIL is the 
%   stability contrast with S final clusters. 
%
% FILES_OUT
%   (structure) with the following fields :
%
%   SIL_ALL
%       (string) a .mat file with the following variables : 
%
%       SCALES
%           (array) SCALES(K,1) is the number of individual clusters
%           associated with SIL_ALL(:,K) and SCALES(K,2) is the number of
%           group clusters associated with SIL_ALL(:,K).
%
%       SIL_ALL
%           (array) SIL_ALL corresponds to all matrices SIL from FILES_IN,
%           concatenated in columns.
%
%       SIL_MAX
%           (vector) SIL_MAX(K) is the maximal contrast SIL_ALL(S,K) for 
%           K in a neighbourhood of S.
%
%       SCALES_MAX
%           (array) SCALES_MAX(S,1) and SCALES_MAX(S,2) are 
%           respectively the number of individual and group scales that
%           achieved maximal contrast for S final clusters.
%
%       PEAKS
%           (array) the list of final scales S that are local maxima of 
%           stability (for SIL_MAX)
%
%   FIGURE_SIL_MAX
%       (string) the name of a pdf file with a plot of SIL_MAX with local 
%       maxima PEAKS highlighted
%
%   TABLE_SIL_MAX
%       (string) a text file with the local maxima of the stability
%       contrast, with corresponding values. There are 
%       multiple columns per entry, first the number of clusters 
%       (individual level, group level , final), and then the last 
%       one with the value of the local maximum.
%
% OPT
%   (structure) with the following fields.
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
% NIAK_BUILD_MAX_SIL, NIAK_BRICK_STABILITY_SUMMARY_IND
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2010
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
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_SUMMARY_GROUP(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_summary_group'' for more info.')
end

%% Files in
if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings');
end

%% Files out
list_fields   = {'sil_all'         , 'figure_sil_max'  , 'table_sil_max'     };
list_defaults = {'gb_niak_omitted' , 'gb_niak_omitted' , 'gb_niak_omitted' };
files_out     = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
list_fields =   {'neigh'   , 'flag_verbose' , 'flag_test' };
list_defaults = {[0.7,1.3] , true           ,false        };
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
scales  = []; % The array of scales parameters will be generated by concatenation across FILES_IN{N}
sil_all = []; % The array of stability contrast will be generated by concatenation across FILES_IN{N}
N       = length(files_in); % The number of input files

for num_n = 1:N
    if opt.flag_verbose
        fprintf('    %s\n',files_in{num_n});
    end    
    data = load(files_in{num_n},'sil','nb_classes','nb_classes_ind');
    sil_all = [sil_all data.sil];
    scales = [scales ; [repmat(data.nb_classes_ind,[length(data.nb_classes) 1]) data.nb_classes(:)]];
end
S = size(sil_all,2);
        
%% Extract maximal measures over clustering parameters for each individual
[sil_max,scales_max] = niak_build_max_sil(sil_all,scales,opt.neigh,1);
mask = ~isnan(sil_max);
[val_max,peaks] = niak_find_local_max_1d(find(mask),sil_max(mask),opt.neigh);

if ~strcmp(files_out.sil_all,'gb_niak_omitted')
    save(files_out.sil_all,'sil_all','scales','sil_max','scales_max','peaks');
end

%% Table of local max of the stability contrast
if opt.flag_verbose
    fprintf('Building table of local max ...\n');
end
lab_x = {};
lab_y = {'K','L','S','max'};

if isempty(peaks)
    tab = [NaN NaN NaN NaN]
else    
    tab = [scales_max(peaks,:) peaks val_max];
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
        file_eps = niak_file_tmp('_summary_group.eps');
    end
    hfa = figure;
    plot(find(mask),sil_max(mask));
    hold on        
    plot(peaks,sil_max(peaks),'r*')
    str_title = sprintf('Group stability contrast');        
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
