function [] = niak_write_minc(hdr,vol)

% Write a 3D or 3D+t dataset into a MINC file
% http://www.bic.mni.mcgill.ca/software/minc/
%
% SYNTAX:
% [] = niak_write_minc(hdr,vol)
%
% INPUTS:
% VOL           (3D or 4D array) a 3D or 3D+t dataset
%
% HDR           (structure) a header structure (usually modified from the 
%               output of niak_read_vol). The relevant fields of HDR are :
%
%               HDR.FILE_NAME   (string) the name of the file that will be
%                   written.
%               HDR.TYPE   (string, default 'minc2') the output format (either
%                   'minc1' or 'minc2').
%
%               HDR.INFO (structure) The subfields are optional, yet they 
%                   give control on critical space information. See
%                   NIAK_WRITE_VOL for more info.
%                  
%               HDR.DETAILS (structure) The subfields are also optional, 
%                   and specific to the minc format. Note that a minc file 
%                   with correct space information can be created without
%                   it.
%               HDR.DETAILS.<VAR_NAME> : where var_name is a string. Such 
%                   field will define a new variable called <VAR_NAME> in 
%                   the minc file.
%               HDR.DETAILS.<VAR_NAME>.VARATTS : a cell of strings. Each
%                   string will define a new attribute in variable
%                   <VAR_NAME>.
%               HDR.DETAILS.<VAR_NAME>.ATTVALUES : a cell (of double array
%                   and/or strings). Each entry defines the value of the
%                   corresponding attribute.          
%               Note that the values of HDR.INFO override the values of
%               HDR.DETAILS.
%
% OUTPUTS:
% The data called VOL is stored into a file called FILENAME written in
% minc format. If the extension of FILE_NAME is '.mnc.gz' or '.mnc.zip' or '.mnc.Z', the file
% will be compressed (choose the zipper by setting the variable NIAK_GB_ZIP in the
% file NIAK_GB_VARS with the appropriate command line).
% 
% COMMENTS:
%
% SEE ALSO:
% niak_read_header_minc, niak_read_minc, niak_read_vol, niak_write_vol
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

%% Setting up default values for the header
gb_name_structure = 'hdr';
gb_list_fields = {'file_name','type','info','details','flag_zip'};
gb_list_defaults = {NaN,'minc2',struct(),struct(),0};
niak_set_defaults

%% Setting up default values for the 'info' part of the header
hdr.info.dimensions = size(vol);
gb_name_structure = 'hdr.info';
gb_list_fields = {'precision','voxel_size','mat','dimension_order','tr','history','file_parent','dimensions'};
gb_list_defaults = {'float',[1 1 1],[eye(3) ones([3 1]) ; zeros([1 3]) 1],'xyzt','',1,'','',[]};
niak_set_defaults

%% Generating a temporary file with the data in float format
file_tmp = niak_file_tmp('.data');
[hf,err_msg] = fopen(file_tmp,'w');

if hf == -1
    error('niak:write: %s',err_msg)    
end

fwrite(hf,vol(:),hdr.info.precision);

fclose(hf);

%% Testing if the file need to be gzipped
[path_f,name_f,ext_f] = fileparts(file_name);

if strcmp(ext_f,'.gz')|strcmp(ext_f,'.zip')|strcmp(ext_f,'.Z')
    file_name = fullfile(path_f,name_f);
    flag_zip = 1;
else
    flag_zip = 0;
end

%% Converting the raw data into a minc file

str_raw = 'rawtominc '; % rawtominc is used to create the file

dim_order(1) = findstr(hdr.info.dimension_order,'x'); % setting up the dimension order
dim_order(2) = findstr(hdr.info.dimension_order,'y');
dim_order(3) = findstr(hdr.info.dimension_order,'z');
if length(hdr.info.dimension_order)==4
    dim_order(4) = findstr(hdr.info.dimension_order,'t');
end
dim_names = {'xspace,','yspace,','zspace,','time,'};
dim_order = dim_order(dim_order);
arg_dim_order = [dim_names{dim_order(end:-1:1)}]; % the order notations in NetCDF/HDF5 is reversed compared to matlab

str_raw = [str_raw '-dimorder ' arg_dim_order(1:end-1),' '];

str_raw = [str_raw '-' hdr.info.precision ' ']; % setting up the precision of the file


str_raw = [str_raw '-scan_range ']; % scan input to set up min and max

str_raw = [str_raw '-clobber ']; % overwrites existing files

if strcmp(hdr.type,'minc2')
    str_raw = [str_raw '-2 ']; % Creates a minc2 file. Otherwise it will produce minc1
end

if ~isempty(file_name)
    str_raw = [str_raw '-input ' file_tmp ' ' file_name]; % read the temporary raw file and write it in minc format
else
    error('niak:write: hdr.file_name is empty !')
end

for num_d = 1:length(hdr.info.dimension_order)
    size_vol(num_d) = size(vol,num_d);
end
size_vol = num2str(size_vol(end:-1:1));
str_raw = [str_raw ' ' size_vol]; % set up the size

system(str_raw); % Writting the new minc file

delete(file_tmp); % deleting temporary file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Override the inherited header informations with user-specified values %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hdr_minc = hdr.details;

hdr_minc.image = sub_set_att(hdr_minc.image,'dimorder',arg_dim_order);
dim_order = dim_order(dim_order);

[cosines_v,step_v,start_v] = niak_hdr_mat2minc(hdr.info.mat);

%% step values
hdr_minc.xspace = sub_set_att(hdr_minc.xspace,'step',step_v(1));
hdr_minc.yspace = sub_set_att(hdr_minc.yspace,'step',step_v(2));
hdr_minc.zspace = sub_set_att(hdr_minc.zspace,'step',step_v(3));
if length(size(vol))==4
    hdr_minc.time = sub_set_att(hdr_minc.time,'step',TR);
end

%% start values
hdr_minc.xspace = sub_set_att(hdr_minc.xspace,'start',start_v(1));
hdr_minc.yspace = sub_set_att(hdr_minc.yspace,'start',start_v(2));
hdr_minc.zspace = sub_set_att(hdr_minc.zspace,'start',start_v(3));
if length(size(vol))==4
    hdr_minc.time = sub_set_att(hdr_minc.time,'start',0);
end

%% cosines values
hdr_minc.xspace = sub_set_att(hdr_minc.xspace,'direction_cosines',cosines_v(:,1)');
hdr_minc.yspace = sub_set_att(hdr_minc.yspace,'direction_cosines',cosines_v(:,2)');
hdr_minc.zspace = sub_set_att(hdr_minc.zspace,'direction_cosines',cosines_v(:,3)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Updating the variables of the minc file %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% history
for num_l = 1:size(hdr.info.history,1)
    if num_l == 1
        system(cat(2,'minc_modify_header -sinsert :history=''',deblank(hdr.info.history(num_l,:)),''' ',file_name));
    else
        system(cat(2,'minc_modify_header -sappend :history=''',deblank(hdr.info.history(num_l,:)),''' ',file_name));
    end
end

%% Other fields ...
list_var = fieldnames(hdr_minc);

for num_v = 1:length(list_var)

    var = list_var{num_v};

    if ~(strcmp(var,'image')|strcmp(var,'image_min')|strcmp(var,'image_max'))

        struct_var = getfield(hdr_minc,var);
        list_att = struct_var.varatts;

        str_hdr = ['minc_modify_header ' file_name];
        for num_a = 1:length(list_att)

            att = list_att{num_a};
            att_val = struct_var.attvalue{num_a};
            
            if ~strcmp(att,'length')
                if ischar(att_val)
                    str_hdr = [str_hdr ' -sinsert ' var ':' att '=''' att_val ''''];
                elseif isnumeric(att_val)
                    str_val = sprintf('%0.15f',att_val(1));
                    
                    for num_v = 2:length(att_val)
                        str_val = [str_val ',' sprintf('%0.15f',att_val(num_v))];
                    end

                    str_hdr = [str_hdr ' -dinsert ' var ':' att '=' str_val];
                end
            end
        end        
        system(str_hdr);
    end
end
            


function struct_var2 = sub_set_att(struct_var,att_name,val_att)

struct_var2 = struct_var;

list_att = struct_var.varatts;

mask_att = niak_find_str_cell(list_att,att_name);

pos = find(mask_att);

if ~isempty(pos)
    struct_var2.attvalue{pos} = val_att;
else
    struct_var2.varatts{end+1} = att_name;
    struct_var2.attvalue{end+1} = val_att;
end