function [files_in,files_out,opt] = niak_brick_summary_glm_connectome(files_in,files_out,opt)
% Summarize the findings for multiple networks in a GLM_CONNECTOME analysis
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUMMARY_GLM_CONNECTOME(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN 
%   (structure) with arbitrary fields:
%
%   <TEST>
%      (cell of strings) the name of a mat file with the results of 
%      NIAK_BRICK_GLM_CONNECTOME_PERM. Multiple batches of permutation
%      analysis are merged into one result.
%
% FILES_OUT
%   (string) the name of a .csv file which reports the number of 
%   discoveries for each test & network.
%
% OPT
%   (structure) with the following fields:
%
%   P 
%      (scalar, default 0.05) the significance level of discoveries across
%      scales.
%
%   LABEL_NETWORK
%      (cell of strings) the labels associated with each network.
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
% NIAK_PIPELINE_GLM_CONNECTOME
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : GLM, functional connectivity, connectome

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%mode
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_SUMMARY_BASC_GLM(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_glm_connectome'' for more info.')
end

%% Files in
if ~isstruct(files_in)
    error('FILES_IN should be a structure')
end

%% Files out
if ~ischar(files_out)
    error('FILES_OUT should be a string')
end

%% Options
list_fields   = { 'p'  , 'label_network' , 'flag_verbose' , 'flag_test'  };
list_defaults = { 0.05 , NaN             , true           , false        };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

%% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% The brick starts here
list_test = fieldnames(files_in);
perc_disc = zeros([length(list_test) length(opt.label_network)]);
p_vol_disc = zeros([length(list_test) 1]);
hetero = zeros([length(list_test) 1]);
for num_test = 1:length(list_test)
    test = list_test{num_test};
    for num_b = 1:length(files_in.(test))
        data = load(files_in.(test){num_b},'p_vol_disc','vol_disc_scale','perc_disc_scale','q_hetero');
        if num_b == 1            
            perc_disc(num_test,:) = data.perc_disc_scale(:)';
            hetero(num_test) = data.q_hetero;
        end
        p_vol_disc(num_test) = p_vol_disc(num_test) + data.p_vol_disc;
    end    
    p_vol_disc(num_test) = p_vol_disc(num_test) / length(files_in.(test));
end

%% Sort scales
scale_num = zeros(length(opt.label_network(:)),1);
for ss = 1:length(scale_num)
    scale = opt.label_network{ss};
    ind = regexp(scale,'\d');
    if ~isempty(ind)
        if length(ind)==1
            scale_num(ss) = str2num(scale(ind));
        else
            ind_s = find((ind(2:end)-ind(1:end-1))>1,1,'last');
            if isempty(ind_s)
                scale_num(ss) = str2num(scale(ind(1):ind(end)));
            else
                scale_num(ss) = str2num(scale(ind(ind_s+1):ind(end)));
            end
        end
    end
end
[val,order] = sort(scale_num);
%% Write results
opt_w.labels_x = list_test;
opt_w.labels_y = [opt.label_network(order)' {'p'}];
niak_write_csv(files_out,[perc_disc(:,order),p_vol_disc],opt_w);
