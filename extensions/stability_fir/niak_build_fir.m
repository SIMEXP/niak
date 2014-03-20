function [fir_mean,nb_fir,fir_all,time_samples] = niak_build_fir(tseries,opt)
% Non-parametric estimation of the finite impulse response in fMRI.
%
% SYNTAX:
% [FIR_MEAN,NB_FIR,FIR_ALL,TIME_SAMPLES] = NIAK_BUILD_FIR(TSERIES,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   TSERIES
%       (2D array) TSERIES(:,I) is the time series at spatial location I.
%
%   OPT
%       (structure) with the following fields :
%
%       TIME_FRAMES
%           (vector) a list of times (in ms) corresponding to each row 
%           of TSERIES.
%
%       TIME_EVENTS
%           (vector) a list of event time that will be used to derive a FIR
%           estimation.
%
%       TIME_WINDOW
%           (scalar, default 10) the length of the time window for the 
%           hrf estimation (the units need to be consistent with those 
%           used in TIME_EVENTS and TIME_FRAMES, generally seconds).
%
%       TIME_SAMPLING
%           (scalar, default 0.5) the time between two time points in the 
%           hrf estimation (again the units need to be consistent with
%           TIME_WINDOW).
%
%       MAX_INTERPOLATION
%           (scalar, default Inf) the maximal time interval where temporal 
%           interpolations can be performed. Any response that involve an 
%           interpolation between points that are too far apart will be excluded.
% 
%       INTERPOLATION
%           (string, default 'linear') the temporal interpolation scheme.
%           See the METHOD argument of the matlab function INTERP1 for
%           possible options.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if FLAG_VERBOSE == 1, print some
%          information on the advance of computation
%
% _________________________________________________________________________
% OUTPUTS
%
%   FIR_MEAN
%       (2D array) FIR_MEAN(:,I) is the mean FIR response estimated at
%       the spatial location I.
%
%   NB_FIR
%       (integer) the number of events that were usable in the estimation
%       i.e. such that the estimation window did not fall outside the time
%       series.
%
%   FIR_ALL
%       (3D array) FIR_ALL(:,I,J) is the FIR response at the spatial
%       location I for the Jth event.
%
%   TIME_SAMPLES
%       (vector) TIME_SAMPLES(T) is the time associated with the Tth row of
%       FIR_(MEAN,STD,ALL). Note that time 0 would correspond the event
%       time.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_FIR, NIAK_BRICK_FIR_TSERIES, NIAK_PIPELINE_STABILITY_FIR
%
% _________________________________________________________________________
% COMMENTS
%
% if the time windows associated with some events fall outside of the
% acquisition time of the time series, these events are ignored.
%
% Copyright (c) Pierre Bellec
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2010-2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : FIR, fmri

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

%% Default options
list_fields    = {'max_interpolation' , 'time_frames' , 'time_events' , 'time_window' , 'time_sampling' , 'interpolation' , 'flag_verbose' };
list_defaults  = {Inf                 , NaN           , NaN           , 10            , 0.5             , 'linear'        , true           };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

time_frames = opt.time_frames(1:size(tseries,1));

%% FIR estimation
if opt.flag_verbose
    sprintf('   FIR estimation : ');    
end

time_samples = 0:opt.time_sampling:opt.time_window;
if time_samples(end)<opt.time_window;
    time_samples(end+1) = time_samples(end)+opt.time_sampling;
end
time_samples = time_samples(:);

[nt,nr] = size(tseries);
nb_events = length(opt.time_events);
if nargout > 2
    fir_all = zeros([length(time_samples),nr,nb_events]);
end
fir_mean = zeros([length(time_samples),nr]);
mask_nan = false([nb_events 1]);
nb_fir = 0;
all_delta = time_frames(2:end)-time_frames(1:(end-1));
for num_e = 1:nb_events
    if opt.flag_verbose
        fprintf('%i - ',num_e);
    end
    %% Test that there are enough time points to perform a reasonable interpolation
    ind_start = find(time_frames>opt.time_events(num_e),1);
    ind_end = find(time_frames>(opt.time_events(num_e)+time_samples(end)),1);
    if isempty(ind_start)||isempty(ind_end)
        mask_nan(num_e) = true;
        continue
    end
    max_delta = max(all_delta(ind_start:(ind_end-1)));    
    if max_delta > (opt.max_interpolation+0.001)
        mask_nan(num_e) = true;
        continue
    end
    fir_est = interp1(time_frames(:),tseries,time_samples+opt.time_events(num_e),opt.interpolation,NaN);
    mask_nan(num_e) = any(isnan(fir_est(:)));
    if ~mask_nan(num_e)
        nb_fir = nb_fir+1;
        if nargout > 2
            fir_all(:,:,num_e) = fir_est;
        end
        fir_mean = fir_mean+fir_est;
    end
end

if nb_fir > 0
    fir_mean = fir_mean/nb_fir;    
end

if nargout > 2
    fir_all = fir_all(:,:,~mask_nan);
end

if opt.flag_verbose
    fprintf('\nDone\n')
end