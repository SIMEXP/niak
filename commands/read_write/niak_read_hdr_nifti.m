function hdr = niak_read_hdr_nifti(file_name)
% Read the header of a NIFTI file (.NII or .HDR). 
% The old Analyze 7.5 is also supported, and if a .MAT file is present, the
% affine transformation information will be included.
% http://nifti.nimh.nih.gov/nifti-1
% 
% SYNTAX:
% HDR = NIAK_READ_HDR_NIFTI(FILE_NAME)
%
% _________________________________________________________________________
% INPUT:
%
% FILE_NAME     
%    (string) name of a single 3D+t minc file or a 3D minc file.
%
% _________________________________________________________________________
% OUTPUT:
%
% HDR           
%    (structure) contain a description of the data. For a list of fields 
%    common to all data types, see NIAK_READ_VOL.
%
%    HDR.DETAILS 
%        (structure) contains the standard fields of a nifti file. 
%        See http://nifti.nimh.nih.gov/nifti-1.
%
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_READ_NIFTI, NIAK_WRITE_NIFTI, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% _________________________________________________________________________
% COMMENTS:
%
% Part of this file is copied and modified under GNU license from
% MRI_TOOLBOX developed by CNSP in Flinders University, Australia
%
% Important parts of this code are copied and modified from a matlab
% toolbox by Jimmy Shen (pls@rotman-baycrest.on.ca). Unfortunately, this
% toolbox did not include a copyright notice.
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=8797&objectType=file
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, nifti

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

%% Checking for inputs
if ~exist('file_name','var'),
    error('Usage: hdr = niak_read_hdr_nifti(file_name)');
end

%% Checking for existence of the file
if ~exist(file_name)
    error('niak:read: File %s not found',file_name)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% reading the details of the header %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Opening the file
list_formats = {'native','ieee-le','ieee-be'};
fid = -1;
tag_OK = 0;
num_f = 1;

while ((tag_OK == 0)|(fid < 0))&(num_f <= length(list_formats))
    fid = fopen(file_name,'r',list_formats{num_f});
    if ~(fid<0)
        fseek(fid,0,'bof');
        test_hdr = fread(fid, 1,'int32')';
        tag_OK = (test_hdr==348);
    end
    num_f = num_f+1;
end

if tag_OK == 0
    error('niak:read: Could not open file %s',file_name)    
end

hdr.info.machine = list_formats{num_f-1};

%%  Reading header key
%  struct header_key                     /* header key      */
%       {                                /* off + size      */
%       int sizeof_hdr                   /*  0 +  4         */
%       char data_type[10];              /*  4 + 10         */
%       char db_name[18];                /* 14 + 18         */
%       int extents;                     /* 32 +  4         */
%       short int session_error;         /* 36 +  2         */
%       char regular;                    /* 38 +  1         */
%       char dim_info;   % char hkey_un0;        /* 39 +  1 */
%       };                               /* total=40 bytes  */
%
% int sizeof_header   Should be 348.
% char regular        Must be 'r' to indicate that all images and
%                     volumes are the same size.

fseek(fid,0,'bof');
hdr.details.sizeof_hdr    = fread(fid, 1,'int32')';
hdr.details.data_type     = deblank(fread(fid,10,'*char')');
hdr.details.db_name       = deblank(fread(fid,18,'*char')');
hdr.details.extents       = fread(fid, 1,'int32')';
hdr.details.session_error = fread(fid, 1,'int16')';
hdr.details.regular       = fread(fid, 1,'*char')';
hdr.details.dim_info      = fread(fid, 1,'char')';

%%  Reading dimension information
%  struct image_dimension
%       {                                /* off + size      */
%       short int dim[8];                /* 0 + 16          */
%       /*
%           dim[0]      Number of dimensions in database; usually 4.
%           dim[1]      Image X dimension;  number of *pixels* in an image row.
%           dim[2]      Image Y dimension;  number of *pixel rows* in slice.
%           dim[3]      Volume Z dimension; number of *slices* in a volume.
%           dim[4]      Time points; number of volumes in database
%       */
%       float intent_p1;   % char vox_units[4];   /* 16 + 4       */
%       float intent_p2;   % char cal_units[8];   /* 20 + 4       */
%       float intent_p3;   % char cal_units[8];   /* 24 + 4       */
%       short int intent_code;   % short int unused1;   /* 28 + 2 */
%       short int datatype;              /* 30 + 2          */
%       short int bitpix;                /* 32 + 2          */
%       short int slice_start;   % short int dim_un0;   /* 34 + 2 */
%       float pixdim[8];                 /* 36 + 32         */
%	/*
%		pixdim[] specifies the voxel dimensions:
%		pixdim[1] - voxel width, mm
%		pixdim[2] - voxel height, mm
%		pixdim[3] - slice thickness, mm
%		pixdim[4] - volume timing, in msec
%					..etc
%	*/
%       float vox_offset;                /* 68 + 4          */
%       float scl_slope;   % float roi_scale;     /* 72 + 4 */
%       float scl_inter;   % float funused1;      /* 76 + 4 */
%       short slice_end;   % float funused2;      /* 80 + 2 */
%       char slice_code;   % float funused2;      /* 82 + 1 */
%       char xyzt_units;   % float funused2;      /* 83 + 1 */
%       float cal_max;                   /* 84 + 4          */
%       float cal_min;                   /* 88 + 4          */
%       float slice_duration;   % int compressed; /* 92 + 4 */
%       float toffset;   % int verified;          /* 96 + 4 */
%       int glmax;                       /* 100 + 4         */
%       int glmin;                       /* 104 + 4         */
%       };                               /* total=108 bytes */

hdr.details.dim        = fread(fid,8,'int16')';
hdr.details.intent_p1  = fread(fid,1,'float32')';
hdr.details.intent_p2  = fread(fid,1,'float32')';
hdr.details.intent_p3  = fread(fid,1,'float32')';
hdr.details.intent_code = fread(fid,1,'int16')';
hdr.details.datatype   = fread(fid,1,'int16')';
hdr.details.bitpix     = fread(fid,1,'int16')';
hdr.details.slice_start = fread(fid,1,'int16')';
hdr.details.pixdim     = fread(fid,8,'float32')';
hdr.details.vox_offset = fread(fid,1,'float32')';
hdr.details.scl_slope  = fread(fid,1,'float32')';
hdr.details.scl_inter  = fread(fid,1,'float32')';
hdr.details.slice_end  = fread(fid,1,'int16')';
hdr.details.slice_code = fread(fid,1,'char')';
hdr.details.xyzt_units = fread(fid,1,'char')';
hdr.details.cal_max    = fread(fid,1,'float32')';
hdr.details.cal_min    = fread(fid,1,'float32')';
hdr.details.slice_duration = fread(fid,1,'float32')';
hdr.details.toffset    = fread(fid,1,'float32')';
hdr.details.glmax      = fread(fid,1,'int32')';
hdr.details.glmin      = fread(fid,1,'int32')';

%%  Reading history
%  struct data_history
%       {                                /* off + size      */
%       char descrip[80];                /* 0 + 80          */
%       char aux_file[24];               /* 80 + 24         */
%       short int qform_code;            /* 104 + 2         */
%       short int sform_code;            /* 106 + 2         */
%       float quatern_b;                 /* 108 + 4         */
%       float quatern_c;                 /* 112 + 4         */
%       float quatern_d;                 /* 116 + 4         */
%       float qoffset_x;                 /* 120 + 4         */
%       float qoffset_y;                 /* 124 + 4         */
%       float qoffset_z;                 /* 128 + 4         */
%       float srow_x[4];                 /* 132 + 16        */
%       float srow_y[4];                 /* 148 + 16        */
%       float srow_z[4];                 /* 164 + 16        */
%       char intent_name[16];            /* 180 + 16        */
%       char magic[4];   % int smin;     /* 196 + 4         */
%       };                               /* total=200 bytes */

hdr.details.descrip     = deblank(fread(fid,80,'*char')');
hdr.details.aux_file    = deblank(fread(fid,24,'*char')');
hdr.details.qform_code  = fread(fid,1,'int16')';
hdr.details.sform_code  = fread(fid,1,'int16')';
hdr.details.quatern_b   = fread(fid,1,'float32')';
hdr.details.quatern_c   = fread(fid,1,'float32')';
hdr.details.quatern_d   = fread(fid,1,'float32')';
hdr.details.qoffset_x   = fread(fid,1,'float32')';
hdr.details.qoffset_y   = fread(fid,1,'float32')';
hdr.details.qoffset_z   = fread(fid,1,'float32')';
hdr.details.srow_x      = fread(fid,4,'float32')';
hdr.details.srow_y      = fread(fid,4,'float32')';
hdr.details.srow_z      = fread(fid,4,'float32')';
hdr.details.intent_name = deblank(fread(fid,16,'*char')');
hdr.details.magic       = deblank(fread(fid,4,'*char')');
fseek(fid,253,'bof');
hdr.details.originator  = fread(fid, 5,'int16')';
%%  For Analyze data format
if ~strcmp(hdr.details.magic, 'n+1') & ~strcmp(hdr.details.magic, 'ni1')
    hdr.details.qform_code = 0;
    hdr.details.sform_code = 0;
end

fclose(fid);

%% Check for the existence of a .mat file, in case this is ANALYZE 7.5
[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    path_f = '.';
end
file_mat = cat(2,path_f,filesep,name_f,'.mat');
if exist(file_mat)
    try
        load('-mat',file_mat,'M')
        hdr.details.srow_x = M(1,:);
        hdr.details.srow_y = M(2,:);
        hdr.details.srow_z = M(3,:);
    catch
        warning('A mat file %s was found but the affine transform could not be parsed',file_mat);
    end
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% converting details into the informative part of the reader %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% file_name
hdr.file_name = '';

%% hdr.type
if strcmp(hdr.details.magic, 'n+1')
    hdr.type = 'nii';
elseif strcmp(hdr.details.magic, 'ni1')
    hdr.type = 'img';
else
    hdr.type = 'analyze';
end

%% hdr.info.file_parent
[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    hdr.info.file_parent = cat(2,pwd,filesep,name_f,'.img');
else
    hdr.info.file_parent = [path_f name_f '.img'];
end

%% hdr.info.precision
switch hdr.details.datatype    
    case 1
        hdr.info.precision = 'binary'; % bitpix=1
    case 2
        hdr.info.precision = 'uint8'; %  bitpix=8
    case 4
        hdr.info.precision = 'int16'; %  bitpix=16
    case 8
        hdr.info.precision = 'int32'; %  bitpix=32
    case 16
        hdr.info.precision = 'float32'; %  bitpix=32
    case 32
        hdr.info.precision = 'complex64'; %  bitpix=64
    case 64
        hdr.info.precision = 'double'; %  bitpix=64
    case 128
        hdr.info.precision = 'rgb24'; %  bitpix=24
    case 256
        hdr.info.precision = 'rgb96'; %  bitpix=96
    case 511
        hdr.info.precision = 'rgb96'; %  bitpix=96
    case 512
        hdr.info.precision = 'uint16'; %  bitpix=16
    case 768
        hdr.info.precision = 'uint32'; %  bitpix=32
    case 1024
        hdr.info.precision = 'int64'; %  bitpix=64
    case 1280
        hdr.info.precision = 'uint64'; %  bitpix=64
    case 1792
        hdr.info.precision = 'complex128'; %  bitpix=128
    case 2048
        hdr.info.precision = 'complex256'; %  bitpix=258
    otherwise
        hdr.info.precision = 'unknown'; %  bitpix=?
end

%% hdr.info.voxel_size
hdr.info.voxel_size = hdr.details.pixdim(2:4);

%% hdr.info.dimensions    
hdr.info.dimensions = hdr.details.dim(2:5);

%% hdr.info.tr
if length(hdr.details.pixdim)>=5 
    hdr.info.tr = hdr.details.pixdim(5);
end

%% hdr.info.mat
if length(hdr.details.srow_x)~=4
    hdr.detais.srow_x = [hdr.details.pixdim(2) 0 0 -hdr.details.dim(2)*hdr.details.pixdim(2)];
end
if length(hdr.details.srow_y)~=4
    hdr.detais.srow_y = [hdr.details.pixdim(3) 0 0 -hdr.details.dim(3)*hdr.details.pixdim(3)];
end
if length(hdr.details.srow_z)~=4
    hdr.detais.srow_z = [hdr.details.pixdim(4) 0 0 -hdr.details.dim(4)*hdr.details.pixdim(4)];
end

if any(hdr.details.srow_x)&any(hdr.details.srow_y)&any(hdr.details.srow_z)
    hdr.info.mat = [hdr.details.srow_x ; hdr.details.srow_y ; hdr.details.srow_z ; [0 0 0 1]];
else
    hdr.info.mat = [[diag(hdr.info.voxel_size) [0;0;0]]; [0 0 0 1]];
end

%% hdr.info.dimension_order
hdr.info.dimension_order = '';

%% hdr.info.history
hdr.info.history = hdr.details.descrip;

