function opt = niak_make_multi_which_stats(opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_MULTI_WHICH_STATS
%
% Constructs a binay matrix corresponding to the desired statistical
% outputs.
% 
% SYNTAX:
% OPT = NIAK_MAKE_MULTI_WHICH_STATS(OPT)
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
%       CONTRAST
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
gb_list_fields = {'which_stats','contrast'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

which_stats = opt.which_stats;
contrast = opt.contrast;

numcontrasts = size(contrast,1);
if ~isempty(which_stats)
   if size(which_stats,1)==1
      which_stats=repmat(which_stats,numcontrasts,1);
   end
   if isnumeric(which_stats)
      which_stats=[which_stats zeros(numcontrasts,9-size(which_stats,2))];
   else
      ws=which_stats;
      which_stats=zeros(numcontrasts,9);
      fst=['_t      ';'_ef     ';'_sd     ';'_rfx    ';'_conj   ';'_resid  ';'_wresid ';'not used';'_fwhm   '];
      for i=1:numcontrasts
         for j=1:3
            which_stats(i,j)= ~isempty(strfind(ws(i,:),deblank(fst(j,:)))); 
         end
      end
      for j=4:9
         which_stats(1,j)= ~isempty(strfind(ws(1,:),deblank(fst(j,:))));
      end
   end
end
opt.which_stats = which_stats;