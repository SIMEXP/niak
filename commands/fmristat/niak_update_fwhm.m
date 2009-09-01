function opt = niak_update_fwhm(opt)
% _________________________________________________________________________
% SUMMARY NIAK_UPDATE_FWHM
%
% Updates the values of fwhm and df required for smoothing autocorrelations
% 
% SYNTAX:
% OPT = NIAK_UPDATE_FWHM(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% X_CACHE 
% structure with the fields TR, X ,and W, obtained from niak_fmridesign 
%
% TREND       
% 3D array) of the temporal,spatial trends and additional confounds for 
% every slice, obtained from niak_make_trends.
% 
% OPT         
%       structure with the following fields :
%
%       MATRIX_X
%            Full design matrix of the model.
%
%       CONTRASTS
%            Matrix of full contrasts of the model.
%
%       NUMLAGS
%           (integer, default 1) The order (p) of the autoregressive model.
%
%       EXCLUDE: 
%           is a list of frames that should be excluded from the analysis. 
%           Default is [].
%
%       NUM_HRF_BASES
%           row vector indicating the number of basis functions for the hrf 
%           for each response, either 1 or 2 at the moment. At least one basis 
%           functions is needed to estimate the magnitude, but two basis functions
%           are needed to estimate the delay.
%
%       NB_RESPONSE
%           number of respnses in the model, determined by the matrix x_cache
%           with niak_fmridesign.
%     
%       WHICH_STATS
%            Number of Contrasts X 9 binary matrix correspondings to the 
%            desired statistical outputs
%
%       FWHM       
%           Structure with the fields COR (default = -100) and DATA.
%
%       DF
%           Structure with the field RESID, degrees of freedom of the
%           residuals.
% _________________________________________________________________________
% OUTPUTS:
%
% OPT         
%       Updated structure with the additional fields:
%
%       FWHM       
%          (real number) Estimated value of the FWHM. 
%
%       DF
%          Structure with the field RESID, COR, T and F, degrees of freedom 
%          of the residuals, correlations, t and F statistics, respectively. 
%       
% _________________________________________________________________________
% COMMENTS:
%
% This function is a NIAKIFIED port of a part of the FMRILM function of the
% fMRIstat project. The original license of fMRIstat was : 
%
%############################################################################
% COPYRIGHT:   Copyright 2002 K.J. Worsley
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%##########################################################################
%
% Copyright (c) Felix Carbonell, Montreal Neurological Institute, 2009.
%               Pierre Bellec, McConnell Brain Imaging Center, 2009.
% Maintainers : felix.carbonell@mail.mcgill.ca, pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : fMRIstat, linear model

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


gb_name_structure = 'opt';
gb_list_fields = {'matrix_x','contrasts','numlags','exclude','num_hrf_bases','nb_response','which_stats','fwhm','df'};
gb_list_defaults = {NaN,NaN,1,[],NaN,NaN,NaN,NaN,NaN};
niak_set_defaults

matrix_x = opt.matrix_x;
contrasts = opt.contrasts;
numlags = opt.numlags;
exclude = opt.exclude;
num_hrf_bases = opt.num_hrf_bases;
numresponses = opt.nb_response;
which_stats = opt.which_stats;
df = opt.df;
FWHM_COR = opt.fwhm.cor;
fwhm_data = opt.fwhm.data;

numframes = size(matrix_x,1);
allpts = 1:numframes;
allpts(exclude) = zeros(1,length(exclude));
keep = allpts(allpts>0);
n = length(keep);
indk1=((keep(2:n)-keep(1:n-1))==1);
k1=find(indk1)+1;


numslices = size(matrix_x,3);
numcontrasts = size(contrasts,1);
numtrends = size(contrasts,2) - numresponses;

contrasts_mag_delay=[contrasts(:,num_hrf_bases==1) ...
         contrasts(:,num_hrf_bases==2)*0 ...
         contrasts(:,num_hrf_bases==2) ...
         contrasts(:,numresponses+(1:numtrends)) ];
p=rank(contrasts(find(which_stats(:,4)),:));
corX2=zeros(numcontrasts+1,numslices);

for slice=1:numslices
    X = squeeze(matrix_x(:,:,slice));
    cpinvX=contrasts_mag_delay*pinv(X);
    CovX0=cpinvX*cpinvX';
    j=find(which_stats(:,4));
    x=pinv(cpinvX(j,:)');
    if numlags==1
       CovX1=cpinvX(:,k1)*cpinvX(:,k1-1)';
       corX2(1:numcontrasts,slice)=(diag(CovX1)./diag(CovX0)).^2; 
       Covx1=x(:,k1)*x(:,k1-1)';
       corX2(numcontrasts+1,slice)=(sum(diag(Covx1*CovX0(j,j)))/(p+(p<=0))).^2*(p>0);
    else
       for lag=1:numlags
          CovX1=cpinvX(:,1:(n-lag))*cpinvX(:,(lag+1):n)';
          corX2(1:numcontrasts,slice)=corX2(1:numcontrasts,slice)+ ...
             (diag(CovX1)./diag(CovX0)).^2; 
          Covx1=x(:,1:(n-lag))*x(:,(lag+1):n)';
          corX2(numcontrasts+1,slice)=corX2(numcontrasts+1,slice)+ ...
             (sum(diag(Covx1*CovX0(j,j)))/(p+(p<=0))).^2*(p>0);
       end
    end
 end
 corX2 = mean(corX2,2);
 
if FWHM_COR(1)<0
   df_target = -FWHM_COR(1);
   df_proportion = 0.9;
   fwhm_cor_limit = 50;
   r=(df.resid/min(df_target,df_proportion*df.resid)-1)/(2*max(corX2));
   if r>=1
      fwhm_cor=0;
   else
      fwhm_cor=min(fwhm_data*sqrt(r^(-2/3)-1)/sqrt(2),fwhm_cor_limit);
   end
else
   if FWHM_COR(1)==Inf
      if length(FWHM_COR)==2
         fwhm_data=FWHM_COR(2);
      else
         fwhm_data=[];
      end
   end
   fwhm_cor=FWHM_COR(1);
end
fwhm.cor = fwhm_cor;
fwhm.data = fwhm_data;

if fwhm_cor<Inf
   df.cor=round(df.resid*(1+2*fwhm_cor^2/fwhm_data^2)^(3/2));
else
   df.cor=Inf;
end

dfts=round(1./(1/df.resid+2*corX2/df.cor));
df.t=dfts(1:numcontrasts);
if p>0
    df.F=[p dfts(1+numcontrasts)];
end
opt.df = df;
opt.fwhm = fwhm;
