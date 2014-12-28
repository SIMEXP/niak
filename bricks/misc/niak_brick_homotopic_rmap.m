function [files_in,files_out,opt] = niak_brick_homotopic_rmap(files_in,files_out,opt)
% Compute correlations between homotopic regions. 
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_HOMOTOPIC_RMAP(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%    (string) a file name of a 3D+t dataset .
%
% FILES_OUT       
%    (string) a 3D volume where each voxel has the value of the correlation between
%    this voxel and its symmetric in stereotaxic space. 
%
% OPT           
%    (structure) with the following fields.  
%
%    FLAG_FISHER
%        (boolean, default true) if the flag is true, the correlation coefficients
%        are Fisher-transformed. 
%
%    FLAG_VERBOSE 
%        (boolean, default 1) if the flag is 1, then the function 
%        prints some infos during the processing.
%
%    FLAG_TEST 
%        (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%        do anything but update the default values in FILES_IN, 
%        FILES_OUT and OPT.
%        
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%           
% _________________________________________________________________________
% COMMENTS
%
% This module assumes that the fMRI data has been resampled in stereotaxic 
% symmetric space. Otherwise the results are meaningless.
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec
% Centre de recherche de l'institut de gériatrie de Montréal, 
% Department of Computer Science and Operations Research
% University of Montreal, Québec, Canada, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: fMRI, homotopic correlations

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

%% Seting up default arguments

%% files_in
if ~ischar(files_in)
    error('FILES_IN should be a string')
end

%% files_out
if (nargin<2)||~ischar(files_out)||isempty(files_out)
    error('Please specify a string in FILES_OUT')
end

%% Options
if nargin < 3
    opt = struct();
end
opt = psom_struct_defaults( opt , ...
      { 'flag_fisher' , 'flag_verbose' ,'flag_test'} , ...
      { false         , true           , false     } );
      
if opt.flag_test == 1
    return
end

%% The brick starts here 

% Read the input 3D+t fMRI time series
[hdr,vol] = niak_read_vol(files_in);

% Generate a list of voxel coordinates
[nx,ny,nz,nt] = size(vol);
mask = true(nx,ny,nz);
ind = find(mask);
[x,y,z] = ind2sub(size(mask),ind);

% Convert the list into homotopic regions
coord_w = niak_coord_vox2world([x,y,z],hdr.info.mat);
coord_w(:,1) = -coord_w(:,1);
coord = niak_coord_world2vox(coord_w,hdr.info.mat);
ind_s = round(niak_sub2ind_3d(size(mask),coord));

% Reorganize 3D+t into a time-space array
tseries = niak_vol2tseries(vol,mask);
tseries = niak_normalize_tseries(tseries);
rmap = (1/(nt-1))*sum(tseries.*tseries(:,ind_s),1);
if opt.flag_fisher
    rmap = niak_fisher(rmap);
end

%% Write results
hdr.file_name = files_out;
niak_write_vol(hdr,niak_tseries2vol(rmap,mask));