function [files_in,files_out,opt] = niak_brick_fig_fir(files_in,files_out,opt)
% Generate a figure of average/std of finite-impulse response (with significance)
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FIG_FIR(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
% 
% FILES_IN
%   (string) the name of a mat file with the FDR tests on FIR
%
% FILES_OUT
%   (string) the name of a pdf file to save the figure.
%
% OPT
%   (structure, with the following fields):
% 
%   IND_FIR
%      (vector 1*n, default []) the numbers of the network to include in the figure
%      e.g. [1 3 4]. If left empty all networks are used
%
%   COLOR
%      (array n*3, default generated with a jet colormap) COLOR(n,:) is the color of 
%      the plot associated with the nth response.
%
%   BACKGROUND
%      (vector 1*3, default [0.75 0.75 0.75]) the color of the background for 
%      significant responses (or differences in responses).
%
%   FLAG_DIFF
%      (boolean, default false) if the flag is true, the significance level
%      will be on differences rather than on the difference with 0. 
%      WARNING: in this case only the two first elements of OPT.IND_FIR are used
%      i.e. only the two first FIR are represented (alongside with the significance
%      of the difference between these responses.
%
%   LINEWIDTH
%      (scalar, default 1.5) sets the width of the plot.
%
%   AXIS
%      (vector 1*4, default []) the min/max of each axis (set with the AXIS command).
%      If left empty, values based on min/max are used.
%
%   THRE_FDR
%      (scalar, default 0.05) the FDR threshold. If empty, no significance is 
%      indicated.
%
%   FLAG_STD
%      (boolean, default true) turn on/off the error bars
%
%   FLAG_LEGEND
%      (boolean, default false) indicate which color corresponds to which 
%      network on the figure
%
%   FLAG_TEST 
%      (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%      do anything but update the default values in FILES_IN, 
%      FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS:
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, CA, 2011.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : FIR, figure

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

%% Set defaults

list_fields   = { 'background'     , 'axis' , 'linewidth' , 'color' , 'flag_diff' , 'ind_fir' , 'thre_fdr' , 'flag_legend' , 'flag_std' , 'flag_test' };
list_defaults = { [0.75 0.75 0.75] , []     ,  1.5         , []      , false       , []        , 0.05       , false         , true       , false       };

if nargin < 2
    files_out = '';
end

if nargin > 2
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
else
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
end

if opt.flag_test 
    return
end

%% The brick starts here
if ~isempty(files_out)
    hf = figure;
end

load(files_in)
if isempty(opt.ind_fir)
    opt.ind_fir = 1:size(test_fir.mean,2);
end

if opt.flag_diff
    if length(opt.ind_fir)<2
        error('Two FIR needs to be specified in OPT.IND_FIR to display the significance of differences')
    end
    opt.ind_fir = opt.ind_fir(1:2);
end
nr = size(test_fir.mean,2);
if isempty(opt.color)
    opt.color = jet(nr+1);
    opt.color = opt.color(2:end,:);
end

test_fir.mean = test_fir.mean(:,opt.ind_fir);
test_fir.std = test_fir.std(:,opt.ind_fir);
test_fir.fdr = test_fir.fdr(:,opt.ind_fir);
color_plot = opt.color(opt.ind_fir,:);

if isempty(opt.axis)
    axis_values(1) = 1;
    axis_values(2) = size(test_fir.mean,1);
    axis_values(3) = min(test_fir.mean(:)-test_fir.std(:))-0.1;
    axis_values(4) = max(test_fir.mean(:)+1.5*test_fir.std(:))+0.1;
else
    axis_values = opt.axis;
end

hold on
axis(axis_values);

%% Add the significance
if ~isempty(opt.thre_fdr)
    hold on
    if opt.flag_diff
        tmp = false(nr);
        tmp(opt.ind_fir(1),opt.ind_fir(2)) = true;
        tmp(opt.ind_fir(2),opt.ind_fir(1)) = true;
        ind_tmp = find(niak_mat2vec(tmp));
        mask = test_diff.fdr(:,ind_tmp)>=opt.thre_fdr;              
    else
        plot_fdr = repmat(NaN,size(test_fir.mean));
        mask = test_fir.fdr>=opt.thre_fdr;
    end    
    
    changes = abs(mask(2:end)-mask(1:(end-1)))~=0;
    changes = [false changes(:)'];
    list_d = find(changes);
    list_d = list_d(:)';
    
    if mask(1)==0
       list_d = [1 list_d];
    end
    if (length(list_d)/2)~=floor(length(list_d)/2)
       list_d = [list_d length(mask)];
    end
    for num_d = 1:(length(list_d)/2)
       posx = list_d(1+((num_d-1)*2));
       posy = list_d(2+((num_d-1)*2));
       if posx~=1
           posx = posx-0.5;
       end
       if posy~=length(mask)
           posy = posy-0.5;
       end
       X = [posx ; posx ; posy ; posy];
       Y = [axis_values(3)+.01 ; axis_values(4)-.01 ; axis_values(4)-.01    ; axis_values(3)+.01  ];
       hfill = fill(X,Y,opt.background);
       set(hfill,'edgecolor',opt.background)
    end
end    

%% Plot curve(s) and std
for num_p = 1:length(opt.ind_fir)
    
    if opt.flag_std
        jbfill(1:size(test_fir.mean,1),(test_fir.mean(:,num_p)+test_fir.std(:,num_p))',(test_fir.mean(:,num_p)-test_fir.std(:,num_p))',color_plot(num_p,:),color_plot(num_p,:),0,0.25);
        %jbfill(1:size(test_fir.mean,1),(test_fir.mean(:,num_p)+test_fir.std(:,num_p))',(test_fir.mean(:,num_p)-test_fir.std(:,num_p))',[0 0 0],[0 0 0],0,0.25);
    end
    p = plot(test_fir.mean(:,num_p));
    set(p,'color',color_plot(num_p,:))
    set(p,'linewidth',opt.linewidth)
end
ha = gca;
set(ha,'linewidth',opt.linewidth)

if opt.flag_legend
    labels = cell(size(opt.ind_fir));
    for num_e = 1:length(labels)
        labels{num_e} = num2str(opt.ind_fir(num_e));
    end    
    legend(labels)
end

if ~isempty(files_out)
  print(files_out,'-dpdf')
  close(hf)
end