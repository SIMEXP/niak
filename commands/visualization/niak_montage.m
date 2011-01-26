function [] = niak_montage(vol,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_MONTAGE
%
% Visualization of a 3D volume in a montage style (all slices in one image)
%
% SYNTAX:
% [] = NIAK_MONTAGE(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL           
%       (3D array) a 3D volume
%
% OPT           
%       (structure, optional) has the following fields:
%
%       NB_ROWS 
%           (integer, default : optimized for a square montage) the number 
%           of rows in the montage.
%               
%       NB_COLUMNS 
%           (integer, default : optimized for a square montage) the number 
%           of columns in the montage.
%
%       VOXEL_SIZE 
%           (vector 1*3, default [1 1 1]) resolution in x, y and z 
%           dimensions (used if smoothing the volume).
%
%       TYPE_SLICE 
%           (string, default 'axial') the plane of slices in the montage. 
%           Available options : 'axial', 'coronal', 'sagital', 'all'. 
%           This option assumes the volume is in 'xyz' convention (left to 
%           right, posterior to anterior, ventral to dorsal). With 'all' 
%           option, three subplots will be made, one for each slice type.
%
%       VOL_LIMITS 
%           (vector 1*2, default [min(vol(:)) max(vol(:))]) limits of the 
%           color scaling.
%
%       TYPE_COLOR 
%           (string, default 'jet') colormap name. Any regular type of 
%			matlab colormap can be used. Additional options : 
%				'jet_rev' a revert jet color map (red for low values, 
%					blue for high values). Good for representing 
%					distances.
%				'hotcold' designed for maps with both positive & 
%					negative matrices.					
%
%       FWHM 
%           (double, default 0) smooth the image with a isotropic Gaussian 
%           kernel of SMOOTH fwhm (in voxels).
%
%       TYPE_FLIP 
%           (string, default 'rot90') make rotation and flip of the slice 
%           representation. see NIAK_FLIP_VOL for options. 
%           'rot90' will work for axial slices of a volume oriented
%           from left to right, from anterior to posterior, and 
%           from ventral to dorsal. In this case, left is left on the 
%           image.
%
%       FLAG_COLORBAR 
%           (boolean, default 1) if flag_colorbar is true, a colorbar is 
%           included in the figure.
%
%       COMMENT 
%           (string, default '') a string that will appear in all figure 
%           titles.
%
% _________________________________________________________________________
% OUTPUTS:
%
% a 'montage' style visualization of each slice of the volume
%
% _________________________________________________________________________
% COMMENTS:
%
% If both the number of rows ans the number of columns are specified, the
% number of slices are adapted to match the montage.
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, montage, visualization

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
gb_list_fields    = {'type_slice' ,'vol_limits','type_color','fwhm','type_flip','flag_colorbar','nb_rows','nb_columns','voxel_size','comment'};
gb_list_defaults  = {'axial'      ,[min(vol(:)) max(vol(:))],'jet',0,'rot90',1,0,0,[1 1 1],''};
niak_set_defaults

switch type_color
	case 'hot_cold'
		c1 = hot(128);
		c1 = c1(1:100,:);
		c2 = c1(:,[3 2 1]);
		c= [c2(size(c2,1):-1:1,:) ; c1];
		colormap(c)   
	case 'jet_rev'
		c = jet(256);
		c = c(end:-1:1,:);
		colormap(c)
	otherwise
		colormap(type_color)
end

switch type_slice
    case 'coronal'

    vol = permute(vol,[1 3 2]);
    voxel_size = voxel_size([1 3 2]);

    case 'sagital'

    vol = permute(vol,[2 3 1]);
    voxel_size = voxel_size([2 3 1]);

    case 'axial'

    case 'all'

    list_view = {'axial','sagital','coronal'};
    
    for num_v = 1:length(list_view)
        opt.type_slice = list_view{num_v};
        subplot(3,1,num_v)
        niak_montage(vol,opt);
        title(sprintf('%s - %s',list_view{num_v},opt.comment));
    end
    return

    otherwise
        fprintf('%s is an unkwon view type.\n',type_slice);
        return
end

[nx,ny,nz] = size(vol);

if nb_rows == 0
    N = ceil(sqrt(nz));
else
    N = nb_rows;
end

if nb_columns == 0
    M = ceil(nz/N);
else    
    M = nb_columns;
end

if nz > M*N
    samp_slice = 1:max(floor(nz/(M*N)),1):nz;
    samp_slice = samp_slice(1+ceil((length(samp_slice)-M*N)/2):(length(samp_slice)-floor((length(samp_slice)-M*N)/2)));
    vol = vol(:,:,samp_slice);
    [nx,ny,nz] = size(vol);
end

if fwhm>0
    opt_smooth.fwhm = opt.fwhm;
    opt_smooth.voxel_size = opt.voxel_size;
    opt_smooth.flag_verbose = false;
    vol = niak_smooth_vol(vol,opt_smooth);
end

if strcmp(type_flip,'rot270')|strcmp(type_flip,'rot90')
    vol2 = zeros([ny*N nx*M]);
else
    vol2 = zeros([nx*N ny*M]);    
end

[indy,indx] = find(ones([M,N]));
ind = find(ones([M*N]));

for num_z = 1:nz
    if strcmp(type_flip,'rot270')|strcmp(type_flip,'rot90')
        vol2(1+(indx(num_z)-1)*ny:indx(num_z)*ny,1+(indy(num_z)-1)*nx:indy(num_z)*nx) = niak_flip_vol(squeeze(vol(:,:,ind(num_z))),type_flip);
    else
        vol2(1+(indx(num_z)-1)*nx:indx(num_z)*nx,1+(indy(num_z)-1)*ny:indy(num_z)*ny) = niak_flip_vol(squeeze(vol(:,:,ind(num_z))),type_flip);
    end
end

imagesc(vol2,vol_limits);
if strcmp(type_flip,'rot270')|strcmp(type_flip,'rot90')    
    %axis([1 ny*N 1 nx*M]);
    siz_tot = [size(vol2).*voxel_size([2 1])];
    siz_tot = siz_tot/sum(siz_tot);    
    set(gca,'DataAspectRatio',[siz_tot 1]);
else
    %axis([1 nx*N 1 ny*M]);    
    set(gca,'DataAspectRatio',[size(vol2).*voxel_size([1 2]) 1]);
end

if flag_colorbar
    colorbar
end
