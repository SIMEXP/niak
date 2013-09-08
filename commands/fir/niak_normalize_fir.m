function fir_c = niak_normalize_fir(fir,baseline,opt)
% Normalize finite-impulse response functions
%
% SYNTAX:
% FIR_C = NIAK_NORMALIZE_FIR(FIR,BASELINE,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FIR
%    (array TxN) T time samples, N regions. Each column is 
%    a (mean) response to a stimulus in a brain region.
%
% BASELINE
%    (array T2xN) T2 time samples, N regions. Each column is a series of 
%    observation at baseline.
%
% OPT
%    (structure) with the following fields:
%
%    TYPE
%        (string) the type of applied normalization of the response. 
%        Available options:
%
%        'fir' : (1) Correction to a zero mean at baseline; 
%                (2) Express changes as a percentage of the baseline.
%            
%        'fir_shape' : correction to a zero mean at baseline and a unit 
%           energy of the response.  
%
%    TIME_SAMPLING
%        (scalar) the time between two samples of the response.
%    
% _________________________________________________________________________
% OUTPUTS:
%
% FIR_C
%    (array, T*N) same as FIR, expect that each FIR has been normalized.
%
% _________________________________________________________________________
% COMMENT:
% If FIR is empty, the function just checks that the options in OPT
% are admissible
%
% _________________________________________________________________________
% EXAMPLE:
%
% % Raw responses
% fir = 10*randn([20 100]) + 100 + 20*(0:19)'*(rand([1 100])+0.5);
% baseline = randn([30 100])+100;
% figure
% plot(fir)
% title('Raw responses')
%
% % 'fir' normalization
% opt.type = 'fir';
% opt.time_sampling = 0.5;
% fir_c = niak_normalize_fir (fir,baseline,opt);
% figure
% plot(fir_c)
% title('''fir'' normalization')
%
% % 'fir_shape' normalization
% opt.type = 'fir_shape';
% fir_c = niak_normalize_fir (fir,baseline,opt);
% figure
% plot(fir_c)
% title('''fir\_shape'' normalization')
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_PIPELINE_STABILITY_FIR, NIAK_STABILITY_FIR, NIAK_BRICK_FIR, 
% NIAK_BRICK_FIR_TSERIES
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
% Département d'informatique et de recherche opérationnelle
% Centre de recherche de l'institut de Gériatrie de Montréal
% Université de Montréal, 2011-2013
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : finite-impulse response

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

list_fields   = { 'type' , 'time_sampling' };
list_defaults = { NaN    , NaN             };
opt = psom_struct_defaults ( opt , list_fields, list_defaults );

if ~ismember(opt.type,{'fir','fir_shape'});
    error('%s is an unknown type of normalization',opt.type);
end

if isempty(fir)
    return
end

if isempty(baseline)
    if strcmp(opt.type,'fir')
        error('Please specify BASELINE to run a ''fir'' normalization')
    end
    baseline = zeros(1,size(fir,2));
end

if strcmp(opt.type,'none')
    fir_c = fir;
    return
end
fir_m = mean(baseline,1);
if ndims(fir) == 2
    fir_c = fir - repmat(fir_m , [size(fir,1) 1]);
    if strcmp(opt.type,'fir_shape')        
        weights = repmat(sqrt(sum(fir_c.^2,1)*opt.time_sampling),[size(fir_c,1) 1]);
        fir_c = fir_c./weights;
    elseif strcmp(opt.type,'fir')
        fir_c = fir_c./repmat(fir_m, [size(fir,1) 1]);
    end
else 
    fir_c = fir - repmat(fir_m , [size(fir,1) 1 size(fir,3)]);
    if strcmp(opt.type,'fir_shape')        
        weights = repmat(sqrt(sum(fir_c.^2,1)*opt.time_sampling),[size(fir_c,1) 1 1]);
        fir_c = fir_c./weights;
    elseif strcmp(opt.type,'fir')    
        fir_c = fir_c./repmat(fir_m, [size(fir,1) 1 size(fir,3)]);
    end
end
