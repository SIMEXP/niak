function [] = niak_write_nifti(hdr,vol)
% Write a 3D or 3D+t dataset into a NIFTI file (.NII or .IMG/.HDR) or an
% Analyze 7.5 file (.IMG/.HDR/.MAT).
% See http://nifti.nimh.nih.gov/nifti-1
%
% SYNTAX:
% [] = NIAK_WRITE_NIFTI(HDR,VOL)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL           
%       (3D or 4D array) a 3D or 3D+t dataset
%
% HDR           
%       (structure) a header structure (usually modified from the output 
%       of NIAK_READ_VOL). The relevant fields of HDR are :
%
%       FILE_NAME   
%           (string) the name of the file that will be written.
%
%       TYPE   
%           (string, default 'nii') the output format (either 'nii' for 
%           NIFTI-1 one file data, 'img' for a couple '*.img'/'*.hdr' in 
%           NIFTI-1 format or 'analyze' for a '*.img'/'*.hdr'/'*.mat')
%
%       INFO 
%           (structure) The subfields are optional, yet they give control 
%           on critical space information. See NIAK_WRITE_VOL for more 
%           info.
%
%       DETAILS 
%           (structure) the fields are the standard list of a NIFTI header.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The data called VOL is stored into a file called FILENAME written in
% nifti format.
% In the case of ANALYZE 7.5 file format, a file '.MAT' will also be
% created with the affin transform.
% 
% _________________________________________________________________________
% SEE ALSO:
%
% NIAK_READ_HDR_NIFTI, NIAK_READ_NIFTI, NIAK_WRITE_VOL, NIAK_READ_VOL
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
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=
% 8797&objectType=file
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, writer, nifti

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

%% Checking for the syntax
if ~exist('vol','var') | ~exist('hdr','var') 
    error('niak:write','Usage: niak_write_nifti(hdr,vol)');
end

%% Setting up default values for the header
gb_name_structure = 'hdr';
gb_list_fields = {'file_name','type','info','details','flag_zip'};
gb_list_defaults = {NaN,'nii',struct(),struct([]),0};
niak_set_defaults

%% Setting up default values for the 'info' part of the header
hdr.info.dimensions = size(vol);
gb_name_structure = 'hdr.info';
gb_list_fields = {'file_parent','precision','voxel_size','mat','dimension_order','tr','history','machine','dimensions'};
gb_list_defaults = {'','float',[1 1 1],[eye(3) ones([3 1]) ; zeros([1 3]) 1],'xyzt','',1,'','native',size(vol)};
niak_set_defaults

%% Seting up the name of the header
file_name = hdr.file_name;
[path_f,name_f,ext_f] = fileparts(file_name);
if isempty(path_f)
    path_f = '.';
end

switch hdr.type
    case 'nii'
        file_hdr = file_name;
    case 'img'
        file_hdr = cat(2,path_f,filesep,name_f,'.hdr');
    case 'analyze'
        file_hdr = cat(2,path_f,filesep,name_f,'.hdr');
        file_mat = cat(2,path_f,filesep,name_f,'.mat');
    otherwise
        error('niak:read','Unkown extension type : %s. I am expecting ''.nii'' or ''.img''',ext_f)
end

%% Updating information of the header
hdr.info.precision = class(vol);
precision = hdr.info.precision;

hdr.info.dimensions = size(vol);
if length(size(vol))==3
    hdr.details.dim(2:4) = size(vol);
    hdr.details.dim(5) = 1;
elseif length(size(vol))==4
    hdr.details.dim(2:5) = size(vol);
    hdr.details.pixdim(5) = hdr.info.tr;
else
    error('VOL need to be a 3D or 4D array!');
end

hdr.descrip = hdr.info.history;

if ndims(vol)==3
    hdr.details.dim(2:4) = size(vol);
    hdr.details.dim(1) = 3;
elseif ndims(vol)==4
    hdr.details.dim(2:5) = size(vol);
    hdr.details.dim(1) = 4;
end

hdr.details.srow_x = hdr.info.mat(1,1:4);
hdr.details.srow_y = hdr.info.mat(2,1:4);
hdr.details.srow_z = hdr.info.mat(3,1:4);

switch hdr.info.precision
    case 'uint8'
        hdr.details.datatype = 2;
        hdr.details.bitpix = int16(8);
        vol = uint8(vol);
    case 'int16' 
        hdr.details.datatype = 4;
        hdr.details.bitpix = int16(16);
        vol = int16(vol);
    case 'int32'
        hdr.details.datatype = 8;
        hdr.details.bitpix = int16(32);
        vol = int32(vol);
    case 'float32'
        hdr.details.datatype = 16;
        hdr.details.bitpix = int16(32);        
    	vol = single(vol);
    case 'double'
        hdr.details.datatype = 64;
        hdr.details.bitpix = int16(64);
        vol = double(vol);
end

hdr.details.glmax = round(double(max(vol(:))));
hdr.details.glmin = round(double(min(vol(:))));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writting the header part %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen(file_hdr,'w');

if fid < 0,
    msg = sprintf('Cannot open file %s',file_hdr);
    error(msg);
end

switch hdr.type
    case 'nii'
        hdr.details.vox_offset = 352;
        hdr.details.magic = 'n+1';
    case {'img','analyze'}
        hdr.details.vox_offset = 0;
        hdr.details.magic = 'ni1';
end

if hdr.details.qform_code == 0 & hdr.details.sform_code == 0
    hdr.details.sform_code = 1;
    hdr.details.srow_x(1) = hdr.details.pixdim(2);
    hdr.details.srow_x(2) = 0;
    hdr.details.srow_x(3) = 0;
    hdr.details.srow_y(1) = 0;
    hdr.details.srow_y(2) = hdr.details.pixdim(3);
    hdr.details.srow_y(3) = 0;
    hdr.details.srow_z(1) = 0;
    hdr.details.srow_z(2) = 0;
    hdr.details.srow_z(3) = hdr.details.pixdim(4);
    hdr.details.srow_x(4) = (1-hdr.details.originator(1))*hdr.details.pixdim(2);
    hdr.details.srow_y(4) = (1-hdr.details.originator(2))*hdr.details.pixdim(3);
    hdr.details.srow_z(4) = (1-hdr.details.originator(3))*hdr.details.pixdim(4);
end

%  struct header_key                      /* header key      */
%       {                                /* off + size      */
%       int sizeof_hdr                   /*  0 +  4         */
%       char data_type[10];              /*  4 + 10         */
%       char db_name[18];                /* 14 + 18         */
%       int extents;                     /* 32 +  4         */
%       short int session_error;         /* 36 +  2         */
%       char regular;                    /* 38 +  1         */
%       char dim_info;   % char hkey_un0;        /* 39 +  1 */
%       };                               /* total=40 bytes  */

fwrite(fid, hdr.details.sizeof_hdr(1),    'int32');	% must be 348.
pad = zeros(1, 10-length(hdr.details.data_type));
hdr.details.data_type = [hdr.details.data_type  char(pad)];
fwrite(fid, hdr.details.data_type(1:10), 'uchar');
pad = zeros(1, 18-length(hdr.details.db_name));
hdr.details.db_name = [hdr.details.db_name  char(pad)];
fwrite(fid, hdr.details.db_name(1:18), 'uchar');
fwrite(fid, hdr.details.extents(1),       'int32');
fwrite(fid, hdr.details.session_error(1), 'int16');
fwrite(fid, hdr.details.regular(1),       'uchar');	% might be uint8
fwrite(fid, hdr.details.dim_info(1),      'uchar');

%  Original header structures
%  struct image_dimension
%       {                                /* off + size      */
%       short int dim[8];                /* 0 + 16          */
%       float intent_p1;   % char vox_units[4];   /* 16 + 4       */
%       float intent_p2;   % char cal_units[8];   /* 20 + 4       */
%       float intent_p3;   % char cal_units[8];   /* 24 + 4       */
%       short int intent_code;   % short int unused1;   /* 28 + 2 */
%       short int datatype;              /* 30 + 2          */
%       short int bitpix;                /* 32 + 2          */
%       short int slice_start;   % short int dim_un0;   /* 34 + 2 */
%       float pixdim[8];                 /* 36 + 32         */
%			/*
%				pixdim[] specifies the voxel dimensions:
%				pixdim[1] - voxel width
%				pixdim[2] - voxel height
%				pixdim[3] - interslice distance
%				pixdim[4] - volume timing, in msec
%					..etc
%			*/
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

fwrite(fid, hdr.details.dim(1:8),        'int16');
fwrite(fid, hdr.details.intent_p1(1),  'float32');
fwrite(fid, hdr.details.intent_p2(1),  'float32');
fwrite(fid, hdr.details.intent_p3(1),  'float32');
fwrite(fid, hdr.details.intent_code(1),  'int16');
fwrite(fid, hdr.details.datatype(1),     'int16');
fwrite(fid, hdr.details.bitpix(1),       'int16');
fwrite(fid, hdr.details.slice_start(1),  'int16');
fwrite(fid, hdr.details.pixdim(1:8),   'float32');
fwrite(fid, hdr.details.vox_offset(1), 'float32');
fwrite(fid, hdr.details.scl_slope(1),  'float32');
fwrite(fid, hdr.details.scl_inter(1),  'float32');
fwrite(fid, hdr.details.slice_end(1),    'int16');
fwrite(fid, hdr.details.slice_code(1),   'uchar');
fwrite(fid, hdr.details.xyzt_units(1),   'uchar');
fwrite(fid, hdr.details.cal_max(1),    'float32');
fwrite(fid, hdr.details.cal_min(1),    'float32');
fwrite(fid, hdr.details.slice_duration(1), 'float32');
fwrite(fid, hdr.details.toffset(1),    'float32');
fwrite(fid, hdr.details.glmax(1),        'int32');
fwrite(fid, hdr.details.glmin(1),        'int32');

% Original header structures
%struct data_history
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

pad = zeros(1, 80-length(hdr.details.descrip));
hdr.details.descrip = [hdr.details.descrip  char(pad)];
fwrite(fid, hdr.details.descrip(1:80), 'uchar');
pad = zeros(1, 24-length(hdr.details.aux_file));
hdr.details.aux_file = [hdr.details.aux_file  char(pad)];
fwrite(fid, hdr.details.aux_file(1:24), 'uchar');
fwrite(fid, hdr.details.qform_code,    'int16');
fwrite(fid, hdr.details.sform_code,    'int16');
fwrite(fid, hdr.details.quatern_b,   'float32');
fwrite(fid, hdr.details.quatern_c,   'float32');
fwrite(fid, hdr.details.quatern_d,   'float32');
fwrite(fid, hdr.details.qoffset_x,   'float32');
fwrite(fid, hdr.details.qoffset_y,   'float32');
fwrite(fid, hdr.details.qoffset_z,   'float32');
fwrite(fid, hdr.details.srow_x(1:4), 'float32');
fwrite(fid, hdr.details.srow_y(1:4), 'float32');
fwrite(fid, hdr.details.srow_z(1:4), 'float32');
pad = zeros(1, 16-length(hdr.details.intent_name));
hdr.details.intent_name = [hdr.details.intent_name  char(pad)];
fwrite(fid, hdr.details.intent_name(1:16), 'uchar');
pad = zeros(1, 4-length(hdr.details.magic));
hdr.details.magic = [hdr.details.magic  char(pad)];
fwrite(fid, hdr.details.magic(1:4),        'uchar');

fbytes = ftell(fid);

if ~isequal(fbytes,348),
    msg = sprintf('For some reason, the header size is not 348 bytes. That should not be the case...');
    warning(msg);
end

fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writting the image part %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen(file_name,'a');

ScanDim = double(hdr.details.dim(5));		% t
SliceDim = double(hdr.details.dim(4));		% z
RowDim   = double(hdr.details.dim(3));		% y
PixelDim = double(hdr.details.dim(2));		% x
SliceSz  = double(hdr.details.pixdim(4));
RowSz    = double(hdr.details.pixdim(3));
PixelSz  = double(hdr.details.pixdim(2));

x = 1:PixelDim;

if strcmp(hdr.type,'nii')
    skip_bytes = double(hdr.details.vox_offset) - 348;
else
    skip_bytes = 0;
end

if skip_bytes
    fwrite(fid, ones(1,skip_bytes), 'uint8');
end

fwrite(fid, vol, precision);

fclose(fid);

%% Adding a .mat file for old versions of SPM
if strcmp(hdr.type,'analyze')
    M=[[diag(hdr.details.pixdim(2:4)) -[hdr.details.originator(1:3).*hdr.details.pixdim(2:4)]'];[0 0 0 1]];
    save(file_mat, 'M');
end
