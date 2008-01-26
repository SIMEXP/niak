function [vols,hdr] = niak_read_minc(file_name)

% Reads fMRI data in MINC format
%
% SYNTAX
% [vols,hdr] = niak_read_minc(file_name)
% 
% INPUT
% file_name     a full path name of a 3D+t fMRI minc file or a 3D MRI minc file.
%
% OUTPUT
% vols          a 3D+t (resp. 3D) matrix containing the fMRI (resp. MRI).
% hdr           a structure containing a description of the data (TR,
%               voxel size, etc ...).
% 
% COMMENTS
% Uses shell commands mincinfo and rawtominc, which assumes a Linux architecture with a proper install of minc tools.
% The reader assumes that the dimension order in mincinfo is time, z, y x.
%
% Copyright (c) Pierre Bellec 01/2008
%
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

niak_gb_vars;

% Reading the main characteristics of the image and setting the header
hdr.type = 'minc';
hdr.parent_file = file_name;
hdr.size = zeros([1 4]);
hdr.step = zeros([1 4]);
hdr.origin = zeros([1 4]);

if strcmp(gb_niak_language,'octave')
    str_info = system(cat(2,'mincinfo ',file_name));
else
    [tmp,str_info] = system(cat(2,'mincinfo ',file_name));
end
cell_lines = niak_string2lines(str_info);
nb_lines = length(cell_lines);

for num_line = nb_lines-3:nb_lines
    
    cell_words = niak_string2words(cell_lines{num_line});
    type_line = cell_words{1};
    if strcmp(type_line,'time')
        num_e = 4;
    elseif strcmp(type_line,'xspace')
        num_e = 1;
    elseif strcmp(type_line,'yspace')
        num_e = 2;
    elseif strcmp(type_line,'zspace')
        num_e = 3;        
    else
        fprintf('Problem interpreting outputs of mincinfo !! I got confused so I do nothing...')
        return
    end
    
    hdr.size(num_e) = str2num(cell_words{2});
    hdr.step(num_e) = str2num(cell_words{3});
    hdr.origin(num_e) = str2num(cell_words{4});
    
end

% Generating a name for a temporary file
file_tmp = niak_file_tmp('.data');

% extracting the data in double precision in the temporary file
system(cat(2,'minctoraw -double -nonormalize ',file_name,' > ',file_tmp));
hf = fopen(file_tmp,'r');

% reading information
vols = fread(hf,prod(hdr.size),'double');

% Remonving temporary stuff
fclose(hf);
system(cat(2,'rm -f ',file_tmp));

% Shapping vols as 3D+t array
vols = reshape(vols,hdr.size);