function opt = niak_make_which_stats(opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_WHICH_STATS
%
% Constructs a binay matrix corresponding to the desired statistical
% outputs.
% 
% SYNTAX:
% OPT = NIAK_MAKE_WHICH_STATS(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% OPT         
%       structure with the following fields :
%
%       WHICH_STATS
%            String correspondings to the desired statistical outputs
%
%       CONTRASTS
%            Matrix of full contrasts of the model.
%
% _________________________________________________________________________
% OUTPUTS:
%
% OPT      
%       Updated structure with the following fields :
%       
%      WHICH_STATS
%            Number of Contrasts X 9 binary matrix correspondings to the 
%            desired statistical outputs
%
%      CONTRASTS
%            Matrix of full contrasts of the model.
%
%      CONTRAST_IS_DELAY
%            Binary vector specifying the desired contrasts for delays 
%            (to be used in NIAK_WHITEN_GLM)
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
gb_list_fields = {'which_stats','contrasts'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

which_stats = opt.which_stats;
contrasts = opt.contrasts;

numcontrasts = size(contrasts,1);
contrast_is_delay = [];

if size(which_stats,1)==1 & numcontrasts>0
   which_stats=repmat(which_stats,numcontrasts,1);
end
if isnumeric(which_stats)
   which_stats = [which_stats zeros(numcontrasts,9-size(which_stats,2))];
   contrast_is_delay = [contrast_is_delay; ...
        zeros(numcontrasts-length(contrast_is_delay),1)];
else
   ws=which_stats; 
   which_stats=[];
   c = contrasts;
   contrasts=[];
   contrast_is_delay=[];
   fst=['_t ';'_ef';'_sd';'_f '];
   fmd=['_mag';'_del'];
   for i=1:numcontrasts
      for k=1:2
         wsn=zeros(1,9);
         for j=1:(5-k)
            wsn(j) = ~isempty(findstr(ws(i,:),[deblank(fmd(k,:)) deblank(fst(j,:))])); 
         end
         if any(wsn)
            which_stats = [which_stats; wsn];
            contrasts = [contrasts; c(i,:)];
            contrast_is_delay = [contrast_is_delay; k-1];
         end
      end
   end
   f2=['_cor   ';'_resid ';'_wresid';'_ar    ';'_fwhm  '];
   for j=5:9
      which_stats(1,j) = ~isempty(findstr(ws(1,:),deblank(f2(j-4,:))));
   end
   if isempty(contrasts)
      contrasts = c;
      contrast_is_delay = zeros(size(c,1),1);
      if size(c,1)>1
         which_stats=[which_stats; zeros(size(c,1)-1,9)];
      end
   end
end
opt.contrasts = contrasts;
opt.contrast_is_delay = contrast_is_delay;
opt.which_stats = which_stats;