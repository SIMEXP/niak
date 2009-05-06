function [vol_a,opt] = niak_slice_timing(vol,opt)
%
% _________________________________________________________________________
% SUMMARY NIAK_SLICE_TIMING
%
% Correct for differences in slice timing in a 4D fMRI acquisition via
% temporal interpolation
%
% SYNTAX:
% [VOL_A,OPT] = NIAK_SLICE_TIMING(VOL,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL
%       (4D array) a 3D+t dataset.
%
% OPT
%       (structure) with the following fields :
%
%       INTERPOLATION
%           (string, default 'spline') the method for temporal interpolation,
%           Available choices : 'linear', 'spline', 'cubic' or 'sinc'.
%
%       SLICE_ORDER
%           (vector of integer) SLICE_ORDER(i) = k means that the kth slice
%           was acquired in ith position. The order of the slices is
%           assumed to be the same in all volumes.
%           ex : slice_order = [1 3 5 2 4 6] for 6 slices acquired in
%           'interleaved' mode, starting by odd slices(slice 5 was acquired
%           in 3rd position). Note that the slices are assumed to be axial,
%           i.e. slice z at time t is vols(:,:,z,t).
%
%       REF_SLICE
%           (integer, default midle slice in acquisition time) slice for
%           time 0
%
%       TIMING
%           (vector 2*1) TIMING(1) : time between two slices
%           TIMING(2) : time between last slice and next volume
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function prints
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% VOL_A
%       (4D array) same as VOL after slice timing correction has
%       been applied through temporal interpolation
%
% OPT
%       (structure) same as the input, but fields have been updated
%       with default values.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_BRICK_SLICE_TIMING, NIAK_DEMO_SLICE_TIMING
%
% _________________________________________________________________________
% COMMENTS:
%
% The linear/cubic/spline interpolations were coded by P Bellec, MNI 2008.
% They are all based on the INTERP1 matlab function, please refer to the
% associated documentation for more details regarding the interpolation
% schemes.
%
% The sinc interpolation is a port from SPM5, under the GNU license.
% First code : Darren Gitelman at Northwestern U., 1998
% Based (in large part) on ACQCORRECT.PRO from Geoff Aguirre and
% Eric Zarahn at U. Penn.
% Subsequently modified by R Henson, C Buechel, J Ashburner and M Erb.
% Adapted to NIAK format and patched to avoid loops by P Bellec, MNI 2008.
%
% Copyright (C) Wellcome Department of Imaging Neuroscience 2005
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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
gb_list_fields = {'interpolation','slice_order','ref_slice','timing','flag_verbose'};
gb_list_defaults = {'sinc',NaN,[],NaN,1};
niak_set_defaults

nb_slices = length(slice_order);
if length(size(vol))>3
    [nx,ny,nz,nt] = size(vol);
else
    [nx,ny,nz] = size(vol);
    nt = 1;
end

if ~(nz == nb_slices)
    fprintf('Error : the number of slices in slice_order should correspond to the 3rd dimension of vol. Try to proceed anyway...')
end

if isempty(ref_slice)
    opt.ref_slice = slice_order(ceil(nb_slices/2));
    ref_slice = opt.ref_slice;
end

TR 	= (nb_slices-1)*timing(1)+timing(2);

if flag_verbose == 1
    fprintf('Your TR is %1.1f\n',TR);
end

vol_a = zeros(size(vol));

switch interpolation

    case {'linear','spline','cubic'}

        [tmp,time_slices] = sort(slice_order);
        time_slices = time_slices * timing(1);
        time_slices = time_slices-time_slices(ref_slice);

        for num_z = 1:nz
            times_ref = (1:nt)*TR;
            times_z = (0:nt+1)*TR+time_slices(num_z);

            slices_z = squeeze(vol(:,:,num_z,:));
            slices_z = reshape(slices_z,[nx*ny,nt])';
            slices_z_a = interp1(double(times_z(:)),double([slices_z(1,:) ; slices_z ; slices_z(nt,:)]),double(times_ref(:)),'linear');
            %slices_z_a = interp1(times_z(:),[slices_z(1,:) ; slices_z ; slices_z(nt,:)],times_ref(:),interpolation);
            vol_a(:,:,num_z,:) = reshape(slices_z_a',[nx ny nt]);
        end

    case 'sinc'

        nt2	= 2^(floor(log2(nt))+1);

        %  signal is odd  -- impacts how Phi is reflected
        %  across the Nyquist frequency. Opposite to use in pvwave.
        OffSet  = 0;

        factor = timing(1)/TR;

        for num_z = 1:nb_slices

            rslice = find(slice_order==ref_slice);

            % Set up time acquired within slice order
            shiftamount  = (find(slice_order == num_z) - rslice) * factor;

            % Extracting all time series in a slice.
            slices_z = zeros([nt2 nx*ny]);
            slices_tmp = squeeze(vol(:,:,num_z,:));
            slices_z(1:nt,:) = reshape(slices_tmp,[nx*ny nt])';

            % linear interpolation to avoid edge effect
            vals1 = slices_z(nt,:);
            vals2 = slices_z(1,:);
            xtmp = 0:(nt2-nt-1);
            slices_z(nt+1:nt2,:) = (xtmp'*ones([1 nx*ny])).*( ones([nt2-nt 1])*(vals2-vals1)/(nt2-nt-1)) + ones([nt2-nt 1])*vals1;

            % Phi represents a range of phases up to the Nyquist frequency
            % Shifted phi 1 to right.
            phi = zeros(1,nt2);
            list_f = 1:nt2/2;
            phi(list_f+1) = -1*shiftamount*2*pi./(nt2./list_f);

            % Mirror phi about the center
            % 1 is added on both sides to reflect Matlab's 1 based indices
            % Offset is opposite to program in pvwave again because indices are 1 based
            phi(nt2/2+1+1-OffSet:nt2) = -fliplr(phi(1+1:nt2/2+OffSet));

            % Transform phi to the frequency domain and take the complex transpose
            shifter = [cos(phi) + sin(phi)*sqrt(-1)].';
            shifter = shifter(:,ones(size(slices_z,2),1)); % Tony's trick

            % Applying the filter in the Fourier domain, and going back in the real
            % domain
            fslices_z = real(ifft(fft(slices_z).*shifter));
            vol_a(:,:,num_z,:) = reshape(fslices_z(1:nt,:)',[nx ny nt]);

        end

    otherwise

        fprintf('Unkown interpolation method : %s',interpolation)
        
end