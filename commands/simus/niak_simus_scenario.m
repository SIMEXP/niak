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
%           'onescale' : same as 'mplm' but with a single scale, but the
%               variance can be specified on a cluster-by-cluster basis.
%
%	    'mplm_gaussian' : same as mplm, but with a gaussian spatial 
%               distribution of the variance associated with each cluster 
%	        (i.e. better SNR at the center of each cluster, and 
%	        overlaping signals to define the clusters).
%
%           'checkerboard': same as mplm, except that (1) clusters are organized as 
%               dyadic subdivision of a square; (2) a 2D Gaussian filter is applied
%               in space; (3) noise is added (i.e. the noise is not smoothed).
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
%   Case 'onescale'
%       T : (integer, default 100) the number of time samples.
%       N : (integer, default 1024) the number of regions. Needs to be a multiple of NB_CLUSTERS.
%       NB_CLUSTERS : (vector, 4) NB_CLUSTER is the number 
%           of clusters.
%       VARIANCE: (scalar, default 1) VARIANCE(I) is the variance of the signal 
%           defining clusters #I. If a single value is specified, all clusters have 
%           identical variance. The i.i.d. Gaussian noise has a variance of 1.
%
%   Case 'checkerboard'
%       T : (integer, default 100) the number of time samples.
%       N : (integer, default 1024) the number of regions. Needs to be 
%           of the form 2^N
%       NB_CLUSTERS : (vector, default [2 4 8]) NB_CLUSTER(I) is the number 
%           of clusters in partition number I. Needs to be of the form 4^N.
%       FWHM: (scalar, default 1) the full-width at half maximum for a 
%           2D Gaussian filter applied spatially on the data. 
%       VARIANCE: (scalar, default 1) the variance of the signal defining clusters. 
%           The i.i.d. Gaussian noise has a variance of 1.
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

     case 'onescale'
        opt = psom_struct_defaults(opt,{ 'type' , 't' , 'n'  , 'nb_clusters' , 'variance' }, ...
                                       { NaN    , 100 , 1024 , 4             , 1          });
        nb_points = opt.n;
        nb_clusters = opt.nb_clusters;        
        part = zeros([1 nb_points]);
        size_c = (nb_points/nb_clusters);
        if size_c ~= round(size_c)
            error('The number of points must be a multiple of the number of clusters');
        end
        tmp = repmat(1:nb_clusters,[size_c 1]);
        opt_s.space.mpart{1} = tmp(:);
        opt_s.space.variance{1} = opt.variance(:);
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
        
    case 'checkerboard'
        opt = psom_struct_defaults(opt,{ 'type' , 't' , 'n'  , 'nb_clusters' , 'variance' , 'fwhm' }, ...
                                       { NaN    , 100 , 1024 , [4,16]        , 1          , 1      });
        nb_points = opt.n;
        if log2(nb_points)~=floor(log2(nb_points))
            error('Please specify a number of points in the form 2^N')
        end
        nb_clusters = opt.nb_clusters;
        nb_scales = length(nb_clusters);
        for ss = 1:nb_scales
            if (log2(nb_clusters(ss))/log2(4))~=floor(log2(nb_clusters(ss))/log2(4))
                error('Please specify numbers of clusters in the form 4^N')
            end
            if nb_clusters(ss)>(nb_points/2)
                error('The requested number of clusters %i is too large compared to the number of points %i',nb_clusters(ss),nb_points)
            end
        end
        
        for ss = 1:nb_scales
            part_tmp = zeros(2^(log2(nb_points)/2),2^(log2(nb_points)/2));
            nx = sqrt(nb_clusters(ss));
            dx = size(part_tmp,1)/nx;
            num_c = 1;
            for xx = 1:nx
                for yy = 1:nx
                    part_tmp(1+(xx-1)*dx:xx*dx,1+(yy-1)*dx:yy*dx) = num_c;
                    num_c = num_c+1;
                end
            end
            opt_s.space.mpart{ss} = part_tmp(:);
            opt_s.space.variance{ss} = opt.variance;
        end        
        opt_s.time.t = opt.t;
        opt_s.time.tr = 2;
        opt_s.time.rho = 0.8;
        opt_s.noise.variance = 0;        
        tseries = niak_sample_mplm(opt_s);
        std_tseries = std(tseries,[],1);        
        tseries = reshape(tseries,[opt.t,2^(log2(nb_points)/2),2^(log2(nb_points)/2)]);                
        if opt.fwhm > 0
            h = fspecial('gaussian',5,opt.fwhm/sqrt(2*log(2)));
            for num_t = 1:opt.t
                tseries(num_t,:,:) = imfilter(squeeze(tseries(num_t,:,:)),h,'same');
            end
        end
        % Restore original variance
        tseries = reshape(tseries, [opt.t , nb_points]);
        std_tseries_new = std(tseries,[],1);
        weights = std_tseries./std_tseries_new;
        tseries = tseries .* repmat(weights,[size(tseries,1) 1]);
        tseries = tseries + randn(size(tseries));
        
        
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
