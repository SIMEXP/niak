function [selection,selecvector,selecinfo] = niak_component_sel(tc_cell,regressors,thr_p_s,nbsamp,nbclass,indextype,selthres,is_verbose)
%
% _________________________________________________________________________
% SUMMARY NIAK_COMPONENT_SEL
%
% Automatic selection of regressors explaining prior time courses using stepwise regression
%
% SYNTAX:
% [SELECTION,SELECVECTOR,SELECINFO] = NIAK_COMPONENT_SEL(TC_CELL,REGRESSORS,THR_P_S,NB_SAMP,WW,NBCLASS,INDEXTYPE,SELTHRES,IS_VERBOSE)
% 
% _________________________________________________________________________
% INPUTS:
% 
% TC_CELL
%       (cell array) Prior time courses in column of each region
%
% REGRESSORS
%       (2D array). Regressors used to explain TC_CELL (in column)
%
% THR_P_S           
%       (real value) p-value for stepwise regression
%
% NBSAMP            
%       (integer) number of process repetition for score computation
%
% NBCLASS
%       (integer) number of clusters used for the kmeans clustering
%
% INDEXTYPE
%       (string) type of computed score. 
%       'freq' : frequency of selection of the regressor 
%       'inertia' : relative part of inertia explained by the clusters 
%       "selecting" the regressor
%
% SELTHRES
%       (real value) score threshold used to determine the final selection
%
% _________________________________________________________________________
% OUTPUTS:
%
% SELECTION
%       (integer) number of selected regressors
%
% SELECVECTOR
%       (vector) scores for each regressor
%
% SELECINFO
%       (structure) some intermediary results
%
% IS_VERBOSE
%       ('on' or 'off') gives progression infos (includes a graphical wait 
%       bar highly unstable in batch mode)
%       
% _________________________________________________________________________
% REFERENCE
%
% Perlbarg, V., Bellec, P., Anton, J.-L., Pelegrini-Issac, P., Doyon, J. and 
% Benali, H.; CORSICA: correction of structured noise in fMRI by automatic
% identification of ICA components. Magnetic Resonance Imaging, Vol. 25,
% No. 1. (January 2007), pp. 35-46.
%
% _________________________________________________________________________
% COMMENTS
%
% Copyright (c) Vincent Perlbarg, U678, LIF, Inserm, UMR_S 678, Laboratoire
% d'Imagerie Fonctionnelle, F-75634, Paris, France, 2006.
% Maintainer : vperlbar@imed.jussieu.fr
% See licensing information in the code.
% Keywords : NIAK, ICA, CORSICA

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

if nargin < 8
    is_verbose = 'on';
end
flag_verbose = strcmp(is_verbose,'on');

% Initialization
X = [];
for numRoi=1:length(tc_cell)
     X = tc_cell{numRoi};

    I=find(isnan(X(1,:))==1);
    if ~isempty(I)
        [T,N]=size(X)
        mtmp = zeros(T,N);
        mtmp(:,I) = 1;
        X=X(mtmp==0);
        X=reshape(X,T,N-length(I));
    end

    [T,N] = size(X);
    selecvector = zeros(1,size(regressors,2));
   
    nbClust = 0;
    
    opt_kmeans.nb_classes = nbclass;
    opt_kmeans.type_death = 'none';
    opt_kmeans.nb_iter = 1;
    opt_kmeans.flag_verbose = 0;
    
    if flag_verbose
        fprintf('     Percentage done : ');
        curr_perc = -1;
    end

    for s = 1:nbsamp
        if flag_verbose
            new_perc = 5*floor(20*s/nbsamp);
            if curr_perc~=new_perc
                fprintf(' %1.0f',new_perc);
                curr_perc = new_perc;
            end
        end
%         nb_b = ceil(T/ww);
%         tp = floor(rand([1,nb_b])*T);
%         tp = ((0:(ww-1))')*ones([1,length(tp)]) + ones([ww 1])*tp;
%         tp = mod(tp(:),T)+1;
%         tp = tp(1:T);
%         [P,Y,I_intra,I_inter,I_total] = st_kmeans(X(tp,:),nbclass);
        [P,Y,I_intra,I_inter] = niak_kmeans_clustering(X,opt_kmeans);

        I_total = sum(I_intra)+I_inter;
        inertia = I_intra/I_total + I_inter/(length(I_intra)*I_total);

        siz_p = [];
        for num_p = 1:max(P)
            siz_p(num_p) = sum(P==num_p);
        end
        OK = siz_p > 3;

        if sum(OK) == 0
            [val_max,i_max] = max(siz_p);
            OK(i_max) = 1;
        end

        %fprintf('Number of classes : %i - ',sum(OK))
        %fprintf('bornes de tp : %i, %i \n',min(tp),max(tp))
        %[selection,num_comp_cell,Freq_tmp,nbRegions,Inert_tmp]=st_get_stepwise_comp(Y(OK,:)',regressors(tp,:),thr_p_s,inertia);
        [selection,num_comp_cell,Freq_tmp,nbRegions,Inert_tmp]=niak_sub_get_stepwise_comp(Y(OK,:)',regressors,thr_p_s,inertia);
        FreqSel(s,:) =  Freq_tmp/nbRegions;
        nbClust = nbClust + nbRegions;
        InertSel(s,:) = Inert_tmp;


        selecinfo(s).compsel = num_comp_cell;
        selecinfo(s).inertia = inertia;
        
    end
    tFreq(numRoi,:) = mean(FreqSel,1);
    tInert(numRoi,:) = mean(InertSel,1);
    warning on    
    
end

if flag_verbose
    fprintf('\n');
end
        
Freq = max(tFreq,[],1);
Inert = max(tInert,[],1);
if strcmp(indextype,'freq') 
    selection = find(Freq>selthres);
    selecvector = Freq;
elseif strcmp(indextype,'inertia')
    selection = find(Inert>selthres);
    selecvector = Inert;
end

function [num_comp,num_comp_cell,Freq,nb_regions,Inert]=niak_sub_get_stepwise_comp(data_tc,regressors,thr_p_s,inertia)

% Selection of components among regressors by stepwise regression to explain each column of data_tc
%
% [num_comp,num_comp_cell,F,p]=niak_sub_get_stepwise_comp(data,regressors,thr_p_s,inertia)
%
% INPUTS
% data_tc           2D datasets : time courses to explain in column.
% regressors        regressors used in stepwise in column.
% thr_p_s           statistical threshold
% inertia           total inertia represented by each data_tc
%
% OUTPUTS
% num_comp          global number of the regressors selected.
% num_comp_cell     number of the regressors selected for each time course
% Freq              frequency of selection of each regressor
% nb_regions        number of clusters
% Inert             relative inertia of each regressor
%
% COMMENTS
% Vincent Perlbarg 02/07/05

nb_regions = size(data_tc,2);
num_comp_tmp = [];
thr_p = thr_p_s/nb_regions;
%thr_p = thr_p_s;
X = regressors;
clear regressors;
%h1 = waitbar(0,'Please wait...');
Freq = zeros(1,size(X,2));
Inert = zeros(1,size(X,2));
for k=1:nb_regions
    Y = data_tc(:,k);
    
    [M,num_X,Ftmp,ptmp]=niak_sub_do_stepwise_regression(Y,X,thr_p,0);
    F(:,k)=Ftmp;
    p(:,k)=ptmp;
    num_comp_tmp = [num_comp_tmp num_X];
    num_comp_cell{k}=num_X;
    Freq(num_X) = Freq(num_X)+1;
    if nargin == 4
        Inert(num_X) = Inert(num_X)+inertia(k);
    end
    %waitbar(k/nb_regions,h1)
end
num_comp = unique(num_comp_tmp);
%close(h1)

function [M,num_X,F_out,p_out]=niak_sub_do_stepwise_regression(Y,X,thr,visu)

% stepwise regression forward-backward
%
% [M,num_X,F_out,p_out]=niak_sub_do_stepwise_regression(Y,X,thr,visu)
% 
% INPUTS
% Y         signal to explain
% X         matrix of regressors in column
% thr       threshold of F-partial distribution
% visu	    1, for plotting signals 0, otherwise
%
% OUTPUTS
% M         matrix of selected regressors
% num_X     vector containing the number of the selected regressors in X
% F_out     F-value of the regressors (last step)
% p_out     p-value of the regressors (last step)
%
% COMMENTS
% Vincent Perlbarg 02/07/05

if nargin<4
    visu=0;
end

nb_reg = size(X,2);

nt = size(X,1);
Y = niak_correct_mean_var(Y);
X = niak_correct_mean_var(X);

% Initialisation
liste_reg = (1:nb_reg)';
liste_select = [];
liste_unselect = liste_reg;
Y1 = [];
reg = [];
n_r = length(liste_unselect);
test = 0;
E1 = zeros(size(Y));
taille = 0;
F = zeros(size(liste_reg));
p = zeros(size(liste_reg));
Ychap = zeros(nt,nb_reg);
R2 = zeros(size(liste_reg));
R1 = (1/(nt-1))*E1'*E1;
out=0;
while test == 0
    % forward
    taille = taille+1;
    n_r = length(liste_unselect);
    for k=1:n_r
        Xk = X(:,liste_unselect(k));
        reg_c = [reg Xk];
        Ychap(:,liste_unselect(k)) = reg_c*((reg_c'*reg_c)^(-1))*(reg_c'*Y);
        R2(liste_unselect(k)) = (1/(nt-1))*Ychap(:,liste_unselect(k))'*Ychap(:,liste_unselect(k));
        F(liste_unselect(k)) = (nt-taille-1)*(R2(liste_unselect(k)) - R1)/(1-R2(liste_unselect(k)));
        p(liste_unselect(k)) = 1-spm_Fcdf(F(liste_unselect(k)),1,nt-taille-1);
        p(isnan(p))=Inf;
    end
    out=out+1;
    if out==1
        F_out=F;
        p_out=p;
    end
    score_f = min(p(liste_unselect));
    if score_f<thr
        num_cand_f = liste_reg(find(p==score_f));
        if length(num_cand_f>1)
            num_cand_f = liste_reg(find(F==max(F)));
        end
        reg = [reg X(:,num_cand_f)];
        num_X(taille)=num_cand_f;
        liste_select(taille) = num_cand_f;
        liste_unselect = liste_unselect(find(liste_unselect~=num_cand_f));
        R2 = R2(num_cand_f);
        Y_approx=Ychap(:,num_cand_f);
        if visu
        plot(1:nt,Y,'b',1:nt,Y_approx,'r')
        legend('Y','Yapprox')
        title(strcat('Y vs Yapprox -- #',num2str(liste_select)))
        pause(0.3)
        end
        Ychap = zeros(nt,nb_reg);
    else
        test = 1;
        taille = taille-1;
    end
    F = zeros(size(liste_reg));
    p = zeros(size(liste_reg));
    
    if test == 0
        % backward
        n_r = length(liste_select);
        R1=[];
        for k=1:n_r
            reg_c = reg(:,1:n_r~=k);
            Ychap(:,liste_select(k)) = reg_c*((reg_c'*reg_c)^(-1))*(reg_c'*Y);
            R1(liste_select(k)) = (1/(nt-1))*Ychap(:,liste_select(k))'*Ychap(:,liste_select(k));
            F(liste_select(k)) = (nt-taille-1)*(R2 - R1(liste_select(k)))/(1-R2);
            p(liste_select(k)) = 1-spm_Fcdf(F(liste_select(k)),1,nt-taille-1);
            p(isnan(p))=Inf;
        end
        score_b = min(p(liste_select));
        if score_b>thr
            num_cand_b = liste_reg(find(p>thr));
            for j=1:length(num_cand_b)
                if num_cand_b(j) ~= num_cand_f 
                    for q=1:length(num_cand_b)
                        I=find(num_X~=num_cand_b(q));
                        reg = reg(:,I);
                        num_X=num_X(I);
                        liste_select=liste_select(find(liste_select~=num_cand_b(q)));
                        liste_unselect = sort([liste_unselect; num_cand_b(q)]);
                        %R1 = R1(num_cand_b);
                        taille = taille-1;
                        n_r = n_r-1;
                    end
                end
            end
            Y_approx = reg*((reg'*reg)^(-1))*(reg'*Y);
            if visu
            plot(1:nt,Y,'b',1:nt,Y_approx,'r')
            legend('Y','Yapprox')
            title(strcat('Y vs Yapprox -- #',num2str(liste_select)))
            pause(0.3)
            end
            R1 = (1/(nt-1))*Y_approx'*Y_approx;
        else
            R1 = R2;
        end
        F = zeros(size(liste_reg));
        R2 = zeros(size(liste_reg));
        num_cand_b=0;
        num_cand_f=0;
        Ychap = zeros(nt,nb_reg);
    end
    if length(liste_select)>1
        R2_out(length(liste_select))=R1-sum(R2_out(1:length(liste_select)-1));
    elseif length(liste_select)==1
        R2_out(length(liste_select))=R1;
    else
        R2_out = 0;
    end
end
M = reg;
num_X = liste_select;
