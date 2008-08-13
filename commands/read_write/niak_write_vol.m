function [] = niak_write_vol(hdr,vol)

% Write a 3D or 3D+t dataset into a file
%
% SYNTAX:
% [] = NIAK_WRITE_VOL(HDR,VOL)
%
% INPUTS:
% VOL          (3D or 4D array) a 3D or 3D+t dataset
%
% HDR           (structure) a header structure (usually modified from the
%               output of niak_read_vol). The following fields are of
%               particular importance :
%
%               HDR.FILE_NAME   (string) a single 4D fMRI image file with multiple  
%                  frames, or a matrix of image file names, each with a single 3D frame,
%                   either NIFIT (*.nii,*.img/hdr) ANALYZE (.img/hdr) or MINC (.mnc) format. 
%                   Extra blanks are ignored. Frames are assumed to be
%                   equally spaced in time.
%                   If the file name contains an additional extension
%                   '.gz', the output will be zipped using 'gzip'.
%
%               HDR.TYPE   (string, default 'minc2') the output format (either
%                   'minc1' or 'minc2').
%
%               The following subfields are optional :
%               HDR.INFO.PRECISION      (string, default 'float') the
%                   precision for writting data ('int', 'float' or
%                   'double').
%
%               HDR.INFO.VOXEL_SIZE     (vector 1*3, default [1 1 1]) the
%                   size of voxels along each spatial dimension in the same
%                   order as in vol.
%
%               HDR.INFO.TR     (double, default 1) the time between two
%                   volumes (in second)
%
%               HDR.MAT (2D array 4*4, default identity) an affine transform from voxel to
%                   world space.
%
%               HDR.DIMENSION_ORDER (string, default 'xyz') describes the dimensions of
%                  vol. Letter 'x' is for 'left to right, 'y' for
%                  'posterior to anterior', 'z' for 'ventral to dorsal' and
%                  't' is time. Example : 'xzyt' means that dimension 1 of
%                   vol is 'x', dimension 2 is 'z', etc.
%
%               HDR.HISTORY (string, default '') history of the operations applied to
%                  the data.
%
%               HDR.DETAILS (structure, default struct()) This field
%                  contains some format specific information, but is not
%                  necessary to write a file. If present, the information
%                  will be inserted in the new file. Note that the fields
%                  of HDR.INFO override HDR.DETAILS. See NIAK_WRITE_MINC
%                  for more information under the minc format.
%
% OUTPUTS:
% Case 1: HDR.FILE_NAME is a string.
% The data is written in a file called HDR.FILE_NAME in HDR.TYPE format.
%
% Case 2: HDR.FILE_NAME is a matrix of strings
% Each row of file names has to correspond to the one element in the fourth 
% dimension of VOL. One file will be written for each volume VOL(:,:,:,i) in the file
% HDR.FILE_NAME(i,:) after blanks have been removed.
%
% Case 3: HDR.FILE_NAME is a string, ending by '_'.
% One file will be written for each volume VOL(:,:,:,i) in the file
% [HDR.FILE_NAME 000i]. The '000i' part meaning that i is converted to a
% string and padded with '0' to reach at least four digits.
%
% COMMENTS:
% If HDR.FLAG_ZIP is 1, the file is zipped and a .gz is appended at the end
% of the file name. 
%
% The extension of zipped file is assumed to be .gz. The tools used to
% zip files in 'gzip'. This setting can be changed by changing the
% variables GB_NIAK_ZIP_EXT and GB_NIAK_UNZIP in the file NIAK_GB_VARS.
%
% SEE ALSO:
% niak_read_header_minc, niak_read_minc, niak_read_vol, niak_read_vol
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

if isempty(vol)
    warning('you are trying to write an empty dataset (I honestly do not know what is going to happen)!');
end

try
    file_name = hdr.file_name;
catch
    error('niak_write_vol: Please specify a file name in hdr.file_name.\n')
end

if ~ischar(file_name)
    error('niak_write_vol: FILE_NAME should be a string or a matrix of strings')
end

nb_file = size(file_name,1);

if nb_file > 1

    %% Case 1: multiple file names have been specified

    if size(vol,4)~= nb_file
        warning('The number of files in hdr.file_name does not correspond to size(vol,4)! Try to proceed anyway...')
    end

    hdr2 = hdr;

    for num_f = 1:nb_file
        hdr2.file_name = deblank(hdr.file_name(num_f,:));
        niak_write_vol(hdr2,vol(:,:,:,num_f));
        if num_f == 1
            warning('off','niak:default')
        end
    end
    warning('on','niak:default')

elseif ischar(file_name)

    %% Case 2: a single file name has been specified
    
    if isempty(file_name)
        error('niak_write_vol: Please specify a non-empty file name in hdr.file_name')
    end

    if strcmp(file_name(end),'_')
        
        %% Case 2a : A string ending by '_'

        nt = size(vol,4);
        nb_digits = max(4,ceil(log10(nt)));

        try
            type_f = hdr.type;
        catch
            error('niak:write_vol: Please specify a file format in hdr.type.\n')
        end

        switch type_f
            case {'minc1','minc2'} % That's a minc file
                ext_f = '.mnc';
            case {'nii'}
                ext_f = '.nii';
            case{'img','analyze'}
                ext_f = '.img';                
            otherwise
                error('niak:write: %s : unrecognized file format\n',type_f);
        end

        base_name = hdr.file_name;
        for num_f = 1:nt
            file_names = cat(2,base_name,repmat('0',1,nb_digits-length(num2str(num_f))),num2str(num_f),ext_f);
            hdr.file_name = file_names;
            if num_f > 1
                warning('off','niak:default')
            end
            niak_write_vol(hdr,vol(:,:,:,num_f));
        end
        warning('on','niak:default')

    else

        %% Case 2b : a regular string
        try
            type_f = hdr.type;
        catch
            error('niak:write: Please specify a file format in hdr.type.\n')
        end

        [path_f,name_f,ext_f] = fileparts(hdr.file_name);
        
        if strcmp(ext_f,gb_niak_zip_ext)
            hdr.file_name = cat(2,path_f,name_f);
        end
        switch type_f
            case {'minc1','minc2'} % That's a minc file
                niak_write_minc(hdr,vol);
            case {'nii','img','analyze'}
                niak_write_nifti(hdr,vol);
            otherwise
                error('niak:write: %s : unrecognized file format\n',type_f);
        end

        if strcmp(ext_f,gb_niak_zip_ext)
            instr_zip = cat(2,gb_niak_zip,' ',hdr.file_name);
            [succ,msg] = system(instr_zip);
            if succ~=0
                error(cat(2,'niak:write: ',msg,'. There was a problem when attempting to zip the file. Please check that the command ''',gb_niak_zip,''' works, or change program using the variable GB_NIAK_ZIP in the file NIAK_GB_VARS'));
            end

        end

    end
else
    error('niak:write: hdr.filename has to be a string or a char array')
end