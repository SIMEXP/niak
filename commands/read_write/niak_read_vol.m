function [hdr,vol] = niak_read_vol(file_name)
% Read brain image in 3D or 3D+t files (analyze, nifti, minc) 
% The data can also be zipped (see the COMMENTS section below)
%
% SYNTAX :
% [HDR,VOL] = NIAK_READ_VOL(FILE_NAME)
%
% _________________________________________________________________________
% INPUTS :
%
% FILE_NAME
%    (string) a single 3D or 3D+t image file, or a matrix of image file 
%    names, each with a single 3D frame.
%    Supported formats are either NIFIT (*.nii,*.img/hdr), ANALYZE 
%    (.img/.hdr/.mat) or MINC1/MINC2 (.mnc). Extra blanks are ignored. 
%    File separator can be / or \ on Windows. Gzipped files (with an 
%    additional .gz) are supported. Frames must be equally spaced in 
%    time. For single file names, wild cards are supported (mutliple 
%    files are treated in the same way as a matrix of image files 
%    names).
%
% _________________________________________________________________________
% OUTPUTS :
%
% VOL           
%    (3D+t or 3D array of double) the 3d or 3d+t raw data.
%
% HDR
%    a structure containing a description of meta-information on the 
%    data, with the following fields :
%
%    FILE_NAME   
%        (empty string '') name of the file currently associated with the 
%        header.
%
%    TYPE   
%        (string) the file format (either 'minc1', 'minc2','nii','img' 
%        or 'analyze').
%
%    INFO 
%        (structure) with the following subfields:
%
%        FILE_PARENT 
%            (string) name of the file that was read.
%
%        DIMENSIONS 
%            (vector 3*1) the number of elements in each dimensions of the 
%            data array. Warning : the first dimension is not necessarily 
%            the "x" axis. See the DIMENSION_ORDER field below.
%   
%        PRECISION 
%            (string, default 'float') the precision of data 
%            ('int', 'float' or 'double').
%
%        VOXEL_SIZE  
%            (vector 1*3, default [1 1 1]) the size of voxels along each 
%            spatial dimension in the same order as in VOL.
%
%        TR  
%            (double, default 1) the time between two volumes (in second). 
%            This field is present only for 3D+t data.
%
%        MAT 
%            (2D array 4*4) an affine transform from voxel to world space.
%
%        DIMENSION_ORDER 
%            (string) describes the dimensions of vol. Letter 'x' is for 
%            'left to right, 'y' for 'posterior to anterior', 
%            'z' for 'ventral to dorsal' and 't' is time. 
%            Example : 'xzyt' means that dimension 1 of vol is 'x', 
%            dimension 2 is 'z', etc.
%
%        HISTORY 
%            (string) the history of the file.
%
%    DETAILS 
%        (structure) Additional information, specific to the format 
%        of the data. See NIAK_READ_HDR_MINC or NIAK_READ_HDR_NIFTI 
%        for more information.
%
% _________________________________________________________________________
% SEE ALSO :
% NIAK_READ_HDR_MINC, NIAK_WRITE_MINC, NIAK_WRITE_VOL, NIAK_READ_HDR_NIFTI,
% NIAK_READ_NIFTI, NIAK_HDR_MAT2MINC, NIAK_HDR_MINC2MAT,
% NIAK_COORD_VOX2WORLD, NIAK_COORD_WORLD2VOX.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1:
% If multiple files are specified, make sure all those files are in the
% same space and are simple 3D volumes.
% All data will be concatenated along the 4th dimension in the VOL array,
% i.e. VOL(:,:,:,i) is the data of the ith file.
% The HDR structure have multiple entries, each one corresponding to one
% file.
%
% NOTE 2:
% In order to read MINC files, a proper installation of minc tools is
% required (see http://www.bic.mni.mcgill.ca/software/minc/).
%
% NOTE 3:
% The extension of zipped file is assumed to be .gz. The tools used to
% unzip files in 'gunzip'. This setting can be changed by changing the
% variables GB_NIAK_ZIP_EXT and GB_NIAK_UNZIP in the file NIAK_GB_VARS.
%
% NOTE 4:
% "voxel coordinates" start from 0. This is not the default matlab
% behaviour, that indexes array starting from 1. To convert coordinates
% from (matlab) voxel system to world system see NIAK_COORD_WORLD2VOX and
% NIAK_COORD_VOX2WORLD.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc

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

niak_gb_vars
  
if ~ischar(file_name)
    error('niak_read_vol: FILE_NAME should be a string or a matrix of strings')
end

nb_file = size(file_name,1);

if nb_file > 1
    
    %% Multiple files have been selected. 
    for num_f = 1:nb_file
        
        if nargout == 2
            [hdr_tmp,vol_tmp] = niak_read_vol(deblank(file_name(num_f,:)));
            if num_f == 1
                vol = zeros([size(vol_tmp) nb_file]);
            end
            vol(:,:,:,num_f) = vol_tmp;
        else
            hdr_tmp = niak_read_vol(deblank(file_name(num_f,:)));
        end
        
        hdr(num_f) = hdr_tmp;
    end

else

    %% Single file (either 3D or 3D+t)
    file_name = deblank(file_name);
    
    if ~exist(file_name)

        %% The file does not exist ... check for wild cards !
        cell_name = dir(file_name);
        [path_f,name_f,ext_f] = niak_fileparts(file_name);
        path_f = [path_f filesep];
        if isempty(cell_name)
            error('Couldn''t find any file fitting the description %s\n',file_name)
        end
        if length(cell_name) > 1
            file_name2 = char({cell_name.name});
            file_name2 = [repmat(path_f,[size(file_name2,1) 1]) file_name2];
            if nargout == 2
                [hdr,vol] = niak_read_vol(file_name2);
            else
                hdr = niak_read_vol(file_name2);
            end
            return
        end
            
        file_name2 = [path_f char(cell_name.name)];
        if length(file_name2)==0
            error('Couldn''t find any file fitting the description %s\n',file_name)
        else
            if nargout == 2
                [hdr,vol] = niak_read_vol(file_name2);
            else
                hdr = niak_read_vol(file_name2);
            end
        end

    else

        %% The file exists
        [path_f,name_f,type] = fileparts(file_name);

        switch type

            case gb_niak_zip_ext

                %% The file is zipped... Unzip it first and restart reading              

                [path_f,name_f,type] = fileparts(name_f);
                
                file_tmp_gz = niak_file_tmp([name_f type gb_niak_zip_ext]);
                
                [succ,msg] = system(cat(2,'cp ',file_name,' ',file_tmp_gz));
                if succ~=0
                    error(msg)
                end
                
                instr_unzip = cat(2,gb_niak_unzip,' ',file_tmp_gz);

                [succ,msg] = system(instr_unzip);
                if succ ~= 0
                    error(cat(2,'niak:read: ',msg,'. There was a problem unzipping the file. Please check that the command ''',gb_niak_unzip,''' works, or change this command using the variable GB_NIAK_UNZIP in the file NIAK_GB_VARS'));
                end

                if nargout == 2
                    [hdr,vol] = niak_read_vol(file_tmp_gz(1:end-length(gb_niak_zip_ext)));
                else
                    hdr = niak_read_vol(file_tmp_gz(1:end-length(gb_niak_zip_ext)));
                end

                delete(file_tmp_gz(1:end-length(gb_niak_zip_ext)));               
                hdr.info.file_parent = file_name;

            case {'.mnc'}
                
                %% This is either a minc1 or minc2 file
                if nargout == 2
                    [hdr,vol] = niak_read_minc(file_name);
                else
                    hdr = niak_read_minc(file_name);
                end

            case {'.nii','.img'}
                
                %% This is a nifti file (either one file .nii, or two files
                %% .img/hdr
                if nargout == 2
                    [hdr,vol] = niak_read_nifti(file_name);
                else
                    hdr = niak_read_nifti(file_name);
                end

            otherwise

                %% Unsupported extension
                error('niak:read: Unknown file extension %s. Only .mnc, .nii and .img are supported.\n',type)
        end
    end

end