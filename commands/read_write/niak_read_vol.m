function [hdr,vol] = niak_read_vol(file_name)

% Read 3D or 3D+t data in various formats.
%
% SYNTAX:
% [HDR,VOL] = NIAK_READ_VOL(FILE_NAME)
% 
% INPUT:
% FILE_NAME         (string) a 3D+t or 3D file name of MINC(1 or 2) data,
%                       wildcards for multiple files allowed.
%                   OR (cell of string) a list of file names.
%
% OUTPUT:
% VOL           (3D+t or 3D array of double) the fMRI or MRI data
%                   (supported format : MINC1, MINC2)
%
% HDR           a structure containing a description of the data, with the
%                   following fields :
%
%               HDR.FILE_NAME   (empty string '') name of the file currently
%                   associated with the header.
%               HDR.TYPE   (string) the file format (either
%                   'minc1', 'minc2').
%               HDR.FLAG_ZIP (boolean, default 0) if the file name ended by
%                   '.gz', the file was unzipped and FLAG_ZIP is 1, and
%                   FLAG_ZIP is 0 otherwise.
%
%               HDR.INFO is a structure with the following subfields:
%                   FILE_PARENT (string) name of the file that was read.
%                   PRECISION (string, default 'float') the
%                       precision of data ('int', 'float' or 'double').
%                   VOXEL_SIZE  (vector 1*3, default [1 1 1]) the
%                       size of voxels along each spatial dimension in the same
%                       order as in vol.
%                   TR  (double, default 1) the time between two
%                       volumes (in second). This field is present only for
%                       3D+t data.
%                   MAT (2D array 4*4) an affine transform from voxel to
%                       world space.
%                   DIMENSION_ORDER (string) describes the dimensions of
%                       vol. Letter 'x' is for 'left to right, 'y' for
%                       'posterior to anterior', 'z' for 'ventral to dorsal' and
%                       't' is time. Example : 'xzyt' means that dimension 1 of 
%                       vol is 'x', dimension 2 is 'z', etc.
%                   HISTORY (string) the history of the file.
%                  
%               Additional information, specific to the format of the data,
%                   can be found in HDR.DETAILS. See NIAK_READ_HDR_MINC for more
%                   information.
% 
% COMMENTS:
% If multiple files are specified, make sure all those files are in the 
% same space and are simple 3D volumes. 
% All data will be concatenated along the 4th dimension in the VOL array, 
% i.e. VOL(:,:,:,i) is the data of the ith file.
% The HDR structure have multiple entry, each one corresponding to one
% file.
%
% In order to read MINC files, a proper installation of minc tools is
% required (see http://www.bic.mni.mcgill.ca/software/minc/).
%
% SEE ALSO:
% niak_read_hdr_minc, niak_write_minc, niak_write_vol.
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


if iscell(file_name)
    
    nb_file = length(file_name);
    
    for num_f = 1:nb_file
        if nargout == 2
            [hdr_tmp,vol_tmp] = niak_read_vol(file_name{num_f});
            if num_f == 1            
                vol = zeros([size(vol_tmp) nb_file]);
            end
            vol(:,:,:,num_f) = vol_tmp;
        else
            hdr_tmp = niak_read_vol(file_name{num_f});
        end                
        hdr(num_f) = hdr_tmp;        
    end
        
elseif ischar(file_name)
    
    if ~exist(file_name)
        cell_name = dir(file_name);
        file_name2 = {cell_name.name};
        if length(file_name2)==0
            error('niak:read_vol','Couldn''t find any file fitting the description %s\n',file_name)
        else
            if nargout == 2
                [hdr,vol] = niak_read_vol(file_name2);
            else
                hdr = niak_read_vol(file_name2);
            end
        end
    else
        
        [pat_f,name_f,type] = fileparts(file_name);

        switch type
            case '.gz'

                niak_gb_vars
                
                file_tmp_gz = niak_file_tmp('.gz');
                
                if strcmp(gb_niak_language,'matlab')
                    flag = copyfile(file_name,file_tmp_gz);
                else
                    system(cat(2,'cp ',file_name,' ',file_tmp_gz))
                end
                
                instr_unzip = cat(2,gb_niak_zip,' -df ',file_tmp_gz);
                
                try
                    system(instr_unzip);
                catch
                    error('niak:read','There was a problem unzipping the file. Please check that the program %s is properly installd, or change program using the variable gb_niak_zip in the file niak_g_vars',gb_niak_zip);
                end
                
                if nargout == 2
                    [hdr,vol] = niak_read_minc(file_tmp_gz(1:end-3));
                else
                    hdr = niak_read_minc(file_tmp_gz(1:end-3));                    
                end
                
                delete(file_tmp_gz(1:end-3)); 
                
            case {'.mnc'}
                if nargout == 2
                    [hdr,vol] = niak_read_minc(file_name);
                else
                    hdr = niak_read_minc(file_name);
                end
            case {'.nii','.img'}
                if nargout == 2
                    [hdr,vol] = niak_read_nifti(file_name);
                else
                    hdr = niak_read_nifti(file_name);
                end
            otherwise
                error('niak:read_vol','Unknown file extension %s. Only .mnc, .nii and .img are supported.\n',type)
        end
    end
    
end