function [tseries,opt_s] = niak_simus_scenario(opt)
% Generate simulated time series following a given scenario
%
% SYNTAX:
% [TSERIES,OPT_S] = NIAK_SIMUS_SCENARIO(OPT)
%
%__________________________________________________________________________
% INPUTS :
%
% OPT
%   (structure) with the following fields : 
%
%   TYPE
%       (string) the type of scenarion. Available options :
% 
%           'mplm' : a simplified version of the multi-partition linear
%               model (see NIAK_SAMPLE_MPLM).
%
%           'mplm_var' : a simplified version of the multi-partition linear
%               model (see NIAK_SAMPLE_MPLM) with hetereogeneous variances.
%
%	    'mplm_gaussian' : same as mplm, but with a gaussian spatial 
%               distribution of the variance associated with each cluster 
%	        (i.e. better SNR at the center of each cluster, and 
%	        overlaping signals to define the clusters).
%
%           'stick' : a stick topology, i.e. 1D spatial distance on a segment.
%               In practice, this is a simple linear model aX + bY + e, 
%               where X and Y are AR1 independent Gaussian signals, 
%               (a+b = 1), e is an iid Gaussian noise, and (a,b) vary in 
%               space with (a=1,b=0) at one end of the stick, (a=0,b=1) at 
%               the other end. This model is implemented through 
%               NIAK_SAMPLE_MPLM
%
%           'two-circles' : two nested circles
%
%   The rest of the fields depend on TYPE : 
%
%   Case 'mplm', 'mplm_var'
%       T : (integer, default 100) the number of time samples.
%       N : (integer, default 100) the number of regions.
%       NB_CLUSTERS : (vector) NB_CLUSTER(I) is the number of clusters 
%           in partition number I.
%
%   Case 'two-circles'
%       N : (integer, default 100) the number of regions (points).
%       RADIUS : (vector 2*1, default [1;2]) the radius of circles
%       STD_NOISE : (vector 2*1, default [0.1;0.1] the standard deviation 
%           of the noise on the radius.
%
%__________________________________________________________________________
% OUTPUTS :
%  
% TSERIES
%   (2D array) each column is one simulated time series.
%
% OPT_S
%   (structure) the option structure passed to NIAK_SAMPLE_MPLM to generate
%   time series.
%
%__________________________________________________________________________
% COMMENTS : 
%
% Copyright (c) Pierre Bellec, Centre de recherche de l'institut de 
% Gériatrie de Montréal, Département d'informatique et de recherche 
% opérationnelle, Université de Montréal, 2011.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, FIR

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

switch opt.type
    
    case 'mplm_gaussian'
        nb_points = opt.n;
        nb_clusters = opt.nb_clusters;
        nb_scales = length(nb_clusters);
        part = zeros([nb_scales nb_points]);    
        for num_sc = 1:nb_scales
           tmp = zeros([nb_points 1]);
           size_c = repmat(ceil(nb_points/nb_clusters(num_sc)),[nb_clusters(num_sc) 1]);
           to_rem = size_c(1)*nb_clusters(num_sc) - nb_points;
           ind_rem = randperm(nb_clusters(num_sc));
           size_c(ind_rem(1:to_rem)) = size_c(ind_rem(1:to_rem))-1;
           nb_pc = 0;
           for num_c = 1:nb_clusters(num_sc)
               tmp(nb_pc+1:nb_pc+size_c(num_c)) = num_c;
               nb_pc = nb_pc+size_c(num_c);
           end           
           opt_s.space.mpart{num_sc} = tmp(:);
           opt_s.space.variance{num_sc} = 1;
        end
        opt_s.space.type = 'gaussian';
        opt_s.space.var_c = 0.3;
        opt_s.time.t = opt.t;
        opt_s.time.tr = 2;
        opt_s.time.rho = 0.8;
        opt_s.noise.variance = 0.6;
        tseries = niak_sample_mplm(opt_s);
        
    case 'mplm'
        
        nb_points = opt.n;
        nb_clusters = opt.nb_clusters;
        nb_scales = length(nb_clusters);
        part = zeros([nb_scales nb_points]);
    
        for num_sc = 1:nb_scales           
           tmp = zeros([nb_points 1]);
           size_c = repmat(ceil(nb_points/nb_clusters(num_sc)),[nb_clusters(num_sc) 1]);
           to_rem = size_c(1)*nb_clusters(num_sc) - nb_points;
           ind_rem = randperm(nb_clusters(num_sc));
           size_c(ind_rem(1:to_rem)) = size_c(ind_rem(1:to_rem))-1;
           nb_pc = 0;
           for num_c = 1:nb_clusters(num_sc)
               tmp(nb_pc+1:nb_pc+size_c(num_c)) = num_c;
               nb_pc = nb_pc+size_c(num_c);
           end           
           opt_s.space.mpart{num_sc} = tmp(:);
           opt_s.space.variance{num_sc} = 1;
        end
        opt_s.time.t = opt.t;
        opt_s.time.tr = 2;
        opt_s.time.rho = 0.8;
        opt_s.noise.variance = 1;
        tseries = niak_sample_mplm(opt_s);

     case 'stick'
        
        N = opt.n;
        opt_t.space.type     = 'independent';
        opt_t.space.n        = 1;
        opt_t.space.variance = 1;
        opt_t.time.type      = 'exponential';
        opt_t.time.par       = 0.8;
        opt_t.time.t         = opt.t;
        x = niak_sample_gsst(opt_t);
        y = niak_sample_gsst(opt_t);        
        var1 = (1:N)/(N+1);
        var2 = (N:-1:1)/(N+1);            
        tseries = x*sqrt(var1) + y*sqrt(var2) + sqrt(opt.variance)*randn([opt.t N]);       
        opt_s = NaN;
        
    case 'mplm_var'
        
        nb_points = opt.n;
        nb_clusters = opt.nb_clusters;
        nb_scales = length(nb_clusters);
        part = zeros([nb_scales nb_points]);
    
        for num_sc = 1:nb_scales
           tmp = repmat(1:nb_clusters(num_sc),[floor(nb_points/nb_clusters(num_sc)) 1]);
           opt_s.space.mpart{num_sc} = tmp(:);
           opt_s.space.variance{num_sc} = ((0:(nb_clusters(num_sc)-1))/(nb_clusters(num_sc)-1))*4/3  + 1/4;
        end
        opt_s.time.t = opt.t;
        opt_s.time.tr = 2;
        opt_s.time.rho = 0.8;
        opt_s.noise.variance = 1;
        tseries = niak_sample_mplm(opt_s);
        
    case 'squares'
        list_fields   = {'t' , 'type' };
        list_defaults = {100 , NaN    };        
        opt = psom_struct_defaults(opt,list_fields,list_defaults);
        
        part1 = zeros([32 32]);
        part1(1:16,1:16)   = 1;
        part1(1:16,17:32)  = 2;
        part1(17:32,1:16)  = 3;
        part1(17:32,17:32) = 4;
        
        part2 = zeros([32 32]);
        for num1 = 1:4
            for num2 = 1:4
                part2((1+(num1-1)*8):(num1*8),(1+(num2-1)*8):(num2*8)) = num1+(num2-1)*8;
            end            
        end
        opt_s.space.mpart{1} = part1(:);
        opt_s.space.mpart{2} = part2(:);
        opt_s.space.variance{1} = 1;
        opt_s.space.variance{2} = 1;
        opt_s.time.t = opt.t;
        opt_s.time.tr = 2;
        opt_s.time.rho = 0.8;
        opt_s.noise.variance = 1;
        [tseries,opt_s] = niak_sample_mplm(opt_s);
        tseries = reshape(tseries,[opt.t 32 32]);
        h = fspecial('gaussian',5,2/sqrt(2*log(2)));
        for num_t = 1:opt.t
            tseries(num_t,:,:) = imfilter(squeeze(tseries(num_t,:,:)),h,'same');
        end                
        
    case 'two-circles'
        list_fields   = {'n' , 'radius', 'std_noise' , 'type' };
        list_defaults = {100 , [1 ; 2] , [0.1 ; 0.1] , NaN    };        
        opt = psom_struct_defaults(opt,list_fields,list_defaults);
        n = opt.n;
        angles = 2*pi*rand([1 2*n]);
        tseries = [cos(angles) ; sin(angles)];
        tseries(:,1:n) = tseries(:,1:n) .* repmat(opt.radius(1)+opt.std_noise(1)*randn([1 n]),[2 1]);
        tseries(:,(n+1):(2*n)) = tseries(:,(n+1):(2*n)) .* repmat(opt.radius(2)+opt.std_noise(2)*randn([1 n]),[2 1]);
        opt_s = struct();

    otherwise
    
        error('%s is an unkown scenario',opt.type);
        
end
