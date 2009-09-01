function trend = niak_make_trends(opt)

% _________________________________________________________________________
% SUMMARY NIAK_MAKE_TRENDS
%
% Create temporal an spatial trends to be include in the design matrix.
% 
% SYNTAX:
% TREND = NIAK_MAKE_TRENDS(OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% 
% OPT         
%       structure with the following fields :
%
%       NB_TRENDS_TEMPORAL
%           (integer, default 3) number of cubic spline temporal trends to 
%           be removed per 6 minutes of scanner time. Temporal trends are 
%           modeled by cubic splines, so for a 6 minute run.
%           N_TEMPORAL<=3 will model a polynomial trend of degree N_TEMPORAL 
%           in frame times, and N_TEMPORAL>3 will add (N_TEMPORAL-3) equally 
%           spaced knots. N_TEMPORAL=0 will model just the constant level 
%           and no temporal trends. N_TEMPORAL=-1 will not remove anything.
%
%       NB_TRENDS_SPATIAL 
%           (integer, default 1) order of the polynomial in the spatial 
%           average (SPATIAL_AV)  weighted by first non-excluded frame; 
%           0 will remove no spatial trends.
%
%       EXCLUDE
%           (vector, default []) a list of frames that should be excluded 
%           from the analysis. 
%
%       TR
%           (real number, default 1) the repetition time of the time series
%
%       CONFOUNDS
%           (matrix, default []) extra columns for the design matrix that 
%           are not convolved with the HRF, e.g. movement artifacts. 
%           If a matrix, the same columns are used for every slice; 
%           if a 3D array, the first two dimensions are the matrix, 
%           the third is the slice.
%
%       SPATIAL_AV
%           colum vector of the spatial average time courses.
%
%       NB_SLICES
%           number of slices in the data.
%
%       NB_FRAMES
%           number of frames in the data.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TREND       
%       (3D array) temporal, spatial trends and additional 
%       confounds for every slice.
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
gb_list_fields = {'nb_trends_temporal','nb_trends_spatial','exclude','tr','confounds','spatial_av','nb_slices','nb_frames'};
gb_list_defaults = {3,0,[],1,[],[],NaN,NaN};
niak_set_defaults


n_temporal = opt.nb_trends_temporal;
n_spatial = opt.nb_trends_spatial;
n_frames = opt.nb_frames;

% Keep time points that are not excluded:
allpts = 1:n_frames;
allpts(opt.exclude) = zeros(1,length(opt.exclude));
keep = allpts( ( allpts >0 ) );
n = length(keep);

% Create temporal trends:

n_spline = round(n_temporal*opt.tr*n/360);
if n_spline>=0 
   trend=((2*keep-(max(keep)+min(keep)))./(max(keep)-min(keep)))';
   if n_spline<=3
      temporal_trend=(trend*ones(1,n_spline+1)).^(ones(n,1)*(0:n_spline));
   else
      temporal_trend=(trend*ones(1,4)).^(ones(n,1)*(0:3));
      knot=(1:(n_spline-3))/(n_spline-2)*(max(keep)-min(keep))+min(keep);
      for k=1:length(knot)
         cut=keep'-knot(k);
         temporal_trend=[temporal_trend (cut>0).*(cut./max(cut)).^3];
      end
   end
else
   temporal_trend=[];
end 

% Create spatial trends:

if n_spatial>=1 
   trend=opt.spatial_av(keep)-mean(opt.spatial_av(keep));
   spatial_trend=(trend*ones(1,n_spatial)).^(ones(n,1)*(1:n_spatial));
else
   spatial_trend=[];
end 

trend = [temporal_trend spatial_trend];

% Add confounds:

numtrends = size(trend,2)+size(opt.confounds,2);
Trend = zeros(n,numtrends,opt.nb_slices);
for slice=1:opt.nb_slices
   if isempty(opt.confounds)
      Trend(:,:,slice)=trend;
   else  
      if length(size(opt.confounds))==2
         Trend(:,:,slice)=[trend opt.confounds(keep,:)];
      else
         Trend(:,:,slice)=[trend opt.confounds(keep,:,slice)];
      end
   end
end
trend = Trend;
