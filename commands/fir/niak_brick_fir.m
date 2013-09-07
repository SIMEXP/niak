function [files_in,files_out,opt] = niak_brick_fir(files_in,files_out,opt);
% Non-parametric estimation of finite impulse response (FIR) in fMRI
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FIR(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN
%   (structure) with the following fields:
%
%   FMRI
%       (cell of strings) a list of fMRI datasets, all in the same space.
%
%   MASK
%       (string) ) The name of a 3D volume containing a binary mask used to 
%       constrain the analysis. If not specified, the analysis is applied 
%       on the full field of view.
%
%   TIMING
%       (cell of strings) a list of .csv files coding for the time of events. 
%       Note that OPT.NAME_CONDITION can be used to specify the name of the 
%       condition of interest (by default the first one is used). It is also 
%       possible to use OPT.NAME_BASELINE to specify which condition 
%       will be used as baseline (by default the first one is used).
%       Example :
%                    , TIMES , DURATION 
%         'motor'    , 4     , 8        
%         'baseline' , 12    , 5        
%         'motor'    , 17    , 8        
%         'baseline' , 25    , 5        

%
% FILES_OUT
%   (string) a file containing a 3D+t dataset. The time courses associated 
%   with each voxel is the estimated FIR response at this voxel.
%           
% OPT
%   (structure) with the following fields : 
%
%   TIME_WINDOW
%       (scalar, default 10) the length of the time window for the FIR 
%       estimation (the units need to be consistent with those used in 
%       TIME_EVENTS and TIME_FRAMES, generally seconds).
%
%   TIME_SAMPLING
%       (scalar, default 0.5) the time between two time points in the FIR 
%       estimation (again the units need to be consistent with TIME_WINDOW)
%
%   INTERPOLATION
%       (string, default 'spline') the temporal interpolation scheme.
%       See the METHOD argument of the matlab function INTERP1 for possible 
%       options.
%
%   TYPE_NORM
%       (string, default 'fir_shape') the type of temporal normalization
%       applied on each response sample. Available option 'fir' or 
%       'fir_shape'. See NIAK_BUILD_FIR for details.
%
%   MAX_INTERPOLATION
%       (scalar, default one TR) the maximal time interval where temporal 
%       interpolations can be performed. Usually interpolations are done
%       between two TRs, but if scrubbing of time frames with excessive 
%       motion is used, then the native temporal sampling grid may be 
%       irregular. This parameter can then be used to exclude events where
%       too many time frames are missing. Any response that involve an 
%       interpolation between points that are too far apart will be excluded.
% 
%   NAME_CONDITION
%       (string, default '') in case the timing of events is coded with a csv file
%       including multiple conditions, NAME_CONDITION is the name of the condition 
%       to use. By default (empty string), the first condition is used. 
%
%   NAME_BASELINE
%       (string, default '') NAME_BASELINE is the name of the condition 
%       to use as baseline. By default (empty string), the first condition is used. 
%
%   FLAG_VERBOSE
%       (boolean, default 1) if FLAG_VERBOSE == 1, print some information 
%       on the advance of computation
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT 
%       and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_FIR, NIAK_PIPELINE_STABILITY_FIR, NIAK_BRICK_FIR_TSERIES
%
% _________________________________________________________________________
% COMMENTS
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2010
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : HRF, FIR, fMRI

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('fnak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_FIR(FILES_IN,FILES_OUT,OPT)\n Type ''help niak_brick_fir'' for more info.')
end

%% Inputs
list_fields    = {'fmri' , 'mask' , 'timing' };
list_defaults  = {NaN    , []     , NaN      };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

%% Default options
list_fields    = { 'name_baseline' , 'name_condition' , 'type_norm' , 'time_window' , 'time_sampling' , 'interpolation' , 'max_interpolation' , 'flag_verbose' , 'flag_test' };
list_defaults  = { ''              , ''               , 'fir_shape' , 10            , 0.5             , 'linear'        , []                  , true           , false       };
if nargin < 3
    opt = psom_struct_defaults(struct(),list_fields,list_defaults);
else
    opt = psom_struct_defaults(opt,list_fields,list_defaults);
end

opt_norm.type = opt.type_norm;
opt_norm.time_sampling = opt.time_sampling;
niak_normalize_fir([],[],opt_norm);

%% If the test flag is true, stop here !
if opt.flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if opt.flag_verbose
    msg = sprintf('FIR estimation');
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read the mask
if ~isempty(files_in.mask)
    if opt.flag_verbose
        fprintf('Read the brain mask in file %s \n',files_in.mask);
    end
    [hdr,mask] = niak_read_vol(files_in.mask);   
    mask = round(mask)>0;
else
    mask = [];
end

%% Extract time series and perform HRF estimation
opt_fir.time_window   = opt.time_window;
opt_fir.flag_verbose  = true;
opt_fir.time_sampling = opt.time_sampling;
opt_fir.interpolation = opt.interpolation;
nb_fir_tot = 0;

for num_r = 1:length(files_in.fmri)
    if opt.flag_verbose
        fprintf('Estimation for fMRI dataset %s ...\n',files_in.fmri{num_r});
    end
    
    % Read the 3D+t dataset
    [hdr,vol] = niak_read_vol(files_in.fmri{num_r});
    
    % Read the time frames    
    if isfield(hdr,'extra')
        opt_fir.time_frames = hdr.extra.time_frames;
    else
        opt_fir.time_frames = (0:(size(vol,4)-1))*hdr.info.tr;
    end
    tseries = niak_vol2tseries(vol,mask); 
    
    % Read the event times
    [time_events,labels_conditions] = niak_read_csv(files_in.timing{num_r});
    
    % Build the timing for the condition of interest
    if isempty(opt.name_condition)
        mask_cond = ismember(labels_conditions,labels_conditions{1});
    else
        mask_cond = ismember(labels_conditions,opt.name_condition);
    end
    timing.time_events = sort(time_events(mask_cond,1));
    
    % Extract baseline time frames
    if isempty(opt.name_baseline)
        mask_base = ismember(labels_conditions,labels_conditions{1});
    else
        mask_base = ismember(labels_conditions,opt.name_baseline);
    end
    baseline = [];
    ind_b = find(mask_base);
    for ii = ind_b(:)'
        baseline = [baseline ; tseries((opt_fir.time_frames>=time_events(ii,1))&(opt_fir.time_frames<=(time_events(ii,1)+time_events(ii,2))),:)];
    end
    
    % Run the FIR estimation
    if isempty(opt.max_interpolation)
        opt_fir.max_interpolation = hdr.info.tr;
    else
        opt_fir.max_interpolation = opt.max_interpolation;
    end
    opt_fir.time_events = timing.time_events;            
    [fir_mean,nb_fir] = niak_build_fir(tseries,opt_fir);       
    
    %% Normalization
    opt_norm.time_sampling = opt.time_sampling;
    if ~strcmp(opt.type_norm,'fir_shape')
        opt_norm.type          = opt.type_norm;
    else
        opt_norm.type = 'fir';
    end
    fir_mean = niak_normalize_fir(fir_mean,baseline,opt_norm);    
    
    % Average the FIR estimation across runs
    fir_mean = nb_fir*fir_mean;
    nb_fir_tot = nb_fir + nb_fir_tot;  
    if (num_r == 1)
        fir_mean_tot = fir_mean;
    else
        fir_mean_tot = fir_mean+fir_mean_tot;
    end
end

if (nb_fir_tot == 0)
    fir_mean_tot = repmat(NaN,size(fir_mean_tot));
else
    fir_mean_tot = fir_mean_tot/nb_fir_tot;
    
    if strcmp(opt.type_norm,'fir_shape')
        %% Normalization
        opt_norm.time_sampling = opt.time_sampling;
        opt_norm.type          = opt.type_norm;    
        fir_mean_tot = niak_normalize_fir(fir_mean_tot,[],opt_norm);
    end
end

%% write the results
if opt.flag_verbose
    fprintf('Writting the FIR estimates %s ...\n',files_out);
end
clear vol fir_mean
vol_f = niak_tseries2vol(fir_mean_tot,mask);
hdr.info.tr = opt.time_sampling;
hdr.file_name = files_out;
niak_write_vol(hdr,vol_f);
