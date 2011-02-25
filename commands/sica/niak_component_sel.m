function [selection,selecvector,selecinfo] = niak_component_sel(tc_cell,regressors,thr_p_s,nbsamp,nbclass,indextype,selthres,is_verbose)
% Automatic selection of regressors explaining prior time courses 
% using stepwise regression
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
        N-length(I)        
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
        
        [P,Y,I_intra,I_inter] = niak_kmeans_clustering(X,opt_kmeans);        
        
        I_total = sum(I_intra)+I_inter;
        inertia = I_intra/I_total + I_inter/(length(I_intra)*I_total);
                
        siz_p = zeros([1 max(P)]);
        for num_p = 1:max(P)
            siz_p(num_p) = sum(P==num_p);            
        end
        
        OK = siz_p > 3;        
        
        if sum(OK) == 0
            [val_max,i_max] = max(siz_p);
            OK(i_max) = 1;
        end        
                
        [selection,num_comp_cell,Freq_tmp,nbRegions,Inert_tmp]=niak_sub_get_stepwise_comp(Y(:,OK),regressors,thr_p_s,inertia);
        
        FreqSel(s,:) =  Freq_tmp/nbRegions;
        nbClust = nbClust + nbRegions;
        InertSel(s,:) = Inert_tmp;


        selecinfo(s).compsel = num_comp_cell;
        selecinfo(s).inertia = inertia;
        
    end
    tFreq(numRoi,:) = mean(FreqSel,1);
    tInert(numRoi,:) = mean(InertSel,1);    
    
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
        if isempty(reg)
            reg_c = Xk;
        else
            reg_c = [reg Xk];
        end
      
        Ychap(:,liste_unselect(k)) = reg_c*((reg_c'*reg_c)^(-1))*(reg_c'*Y);
        
        R2(liste_unselect(k)) = (1/(nt-1))*Ychap(:,liste_unselect(k))'*Ychap(:,liste_unselect(k));
        F(liste_unselect(k)) = (nt-taille-1)*(R2(liste_unselect(k)) - R1)/(1-R2(liste_unselect(k)));
        p(liste_unselect(k)) = 1-sub_spm_Fcdf(F(liste_unselect(k)),1,nt-taille-1);
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
        if n_r>1
            for k=1:n_r
                reg_c = reg(:,1:n_r~=k);
                Ychap(:,liste_select(k)) = reg_c*((reg_c'*reg_c)^(-1))*(reg_c'*Y);
                R1(liste_select(k)) = (1/(nt-1))*Ychap(:,liste_select(k))'*Ychap(:,liste_select(k));
                F(liste_select(k)) = (nt-taille-1)*(R2 - R1(liste_select(k)))/(1-R2);
                p(liste_select(k)) = 1-sub_spm_Fcdf(F(liste_select(k)),1,nt-taille-1);
                p(isnan(p))=Inf;
            end
        else
            R1 = [];
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

function F = sub_spm_Fcdf(x,v,w)
% Cumulative Distribution Function (CDF) of F (Fisher-Snedecor) distribution
% FORMAT F = spm_Fpdf(x,df)
% FORMAT F = spm_Fpdf(x,v,w)
%
% x  - F-variate   (F has range [0,Inf) )
% df - Degrees of freedom, concatenated along last dimension
%      Eg. Scalar (or column vector) v & w. Then df=[v,w];
% v  - Shape parameter 1 /   numerator degrees of freedom (v>0)
% w  - Shape parameter 2 / denominator degrees of freedom (w>0)
% F  - CDF of F-distribution with [v,w] degrees of freedom at points x
%_______________________________________________________________________
%
% spm_Fcdf implements the Cumulative Distribution Function of the F-distribution.
%
% Definition:
%-----------------------------------------------------------------------
% The CDF F(x) of the F distribution with degrees of freedom v & w,
% defined for positive integer degrees of freedom v & w, is the
% probability that a realisation of an F random variable X has value
% less than x F(x)=Pr{X<x} for X~F(v,w). The F-distribution is defined
% for v>0 & w>0, and for x in [0,Inf) (See Evans et al., Ch16).
%
% Variate relationships: (Evans et al., Ch16 & 37)
%-----------------------------------------------------------------------
% The square of a Student's t variate with w degrees of freedom is
% distributed as an F-distribution with [1,w] degrees of freedom.
%
% For X an F-variate with v,w degrees of freedom, w/(w+v*X^2) has
% distributed related to a Beta random variable with shape parameters
% w/2 & v/2.
%
% Algorithm:
%-----------------------------------------------------------------------
% Using the relationship with the Beta distribution: The CDF of the
% F-distribution with v,w degrees of freedom is related to the
% incomplete beta function by:
%       Pr(X<x) = 1 - betainc(w/(w+v*x^2),w/2,v/2)
% See Abramowitz & Stegun, 26.6.2; Press et al., Sec6.4 for
% definitions of the incomplete beta function. The relationship is
% easily verified by substituting for w/(w+v*x^2) in the integral of the
% incomplete beta function.
%
% MatLab's implementation of the incomplete beta function is used.
%
%
% References:
%-----------------------------------------------------------------------
% Evans M, Hastings N, Peacock B (1993)
%       "Statistical Distributions"
%        2nd Ed. Wiley, New York
%
% Abramowitz M, Stegun IA, (1964)
%       "Handbook of Mathematical Functions"
%        US Government Printing Office
%
% Press WH, Teukolsky SA, Vetterling AT, Flannery BP (1992)
%       "Numerical Recipes in C"
%        Cambridge
%
%__________________________________________________________________________
% @(#)spm_Fcdf.m	2.2 Andrew Holmes 99/04/26

%-Format arguments, note & check sizes
%-----------------------------------------------------------------------
if nargin<2, error('Insufficient arguments'), end

%-Unpack degrees of freedom v & w from single df parameter (v)
if nargin<3
	vs = size(v);
	if prod(vs)==2
		%-DF is a 2-vector
		w = v(2); v = v(1);
	elseif vs(end)==2
		%-DF has last dimension 2 - unpack v & w
		nv = prod(vs);
		w  = reshape(v(nv/2+1:nv),vs(1:end-1));
		v  = reshape(v(1:nv/2)   ,vs(1:end-1));
	else
		error('Can''t unpack both df components from single argument')
	end
end

%-Check argument sizes
ad = [ndims(x);ndims(v);ndims(w)];
rd = max(ad);
as = [	[size(x),ones(1,rd-ad(1))];...
	[size(v),ones(1,rd-ad(2))];...
	[size(w),ones(1,rd-ad(3))]     ];
rs = max(as);
xa = prod(as,2)>1;
if sum(xa)>1 & any(any(diff(as(xa,:)),1))
	error('non-scalar args must match in size'), end

%-Computation
%-----------------------------------------------------------------------
%-Initialise result to zeros
F = zeros(rs);

%-Only defined for strictly positive v & w. Return NaN if undefined.
md = ( ones(size(x))  &  v>0  &  w>0 );
if any(~md(:)), F(~md) = NaN;
	warning('Returning NaN for out of range arguments'), end

%-Non-zero where defined and x>0
Q  = find( md  &  x>0 );
if isempty(Q), return, end
if xa(1), Qx=Q; else Qx=1; end
if xa(2), Qv=Q; else Qv=1; end
if xa(3), Qw=Q; else Qw=1; end

%-Compute
F(Q) = 1 - betainc(w(Qw)./(w(Qw) + v(Qv).*x(Qx)),w(Qw)/2,v(Qv)/2);
