function full_contrast = niak_make_contrasts(contrast,opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_CONTRASTS
%
% Creates full contrasts for the Linear Model
% 
% SYNTAX:
% [FULL_CONTRAST] = NIAK_MAKE_CONTRASTS(CONTRAST,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% CONTRAST         
%       matrix of contrast of interest for the responses or a structure
%       with fields x,c,t,s for the contrast associated to the responses,
%       confounds, temporal trends and spatial trends, respectively.
% 
% OPT         
%       structure with the following fields :
%
%       NB_RESPONSE
%           number of respnses in the model, determined by the matrix x_cache
%           with niak_fmridesign.
%
%       NB_TRENDS
%           vector of 3 components with the number of temporal trends, 
%           spatial trends and confounds
% _________________________________________________________________________
% OUTPUTS:
%
% FULL_CONTRAST       
%       updated matrix of full contrasts of the model.
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


% Setting up default
gb_name_structure = 'opt';
gb_list_fields = {'nb_response','nb_trends'};
gb_list_defaults = {NaN,NaN};
niak_set_defaults

numresponses = opt.nb_response;
n_temporal_trend = opt.nb_trends(1);
n_spatial_trend = opt.nb_trends(2);
n_confounds = opt.nb_trends(3);

% Make full contrasts:

if isstruct(contrast)
   contrasts = contrast; 
   numcontrasts=0;
   if isfield(contrast,'x') 
       numcontrasts=size(contrast.x,1); 
   end
   if isfield(contrast,'c') 
       numcontrasts=size(contrast.c,1); 
   end
   if isfield(contrast,'t') 
       numcontrasts=size(contrast.t,1); 
   end
   if isfield(contrast,'s') 
       numcontrasts=size(contrast.s,1); 
   end
else
    numcontrasts=size(contrast,1);
    contrasts.x = contrast;
end

if ~isfield(contrasts,'x')
    contrasts.x = zeros(numcontrasts,numresponses); 
end
if ~isfield(contrasts,'c') 
   contrasts.c = zeros(numcontrasts,n_confounds); 
end
if ~isfield(contrasts,'t') 
    contrasts.t=zeros(numcontrasts,n_temporal_trend); 
end
if ~isfield(contrasts,'s') 
    contrasts.s=zeros(numcontrasts,n_spatial_trend); 
end

full_contrast = [contrasts.x contrasts.t contrasts.s contrasts.c];

