function hdr = niak_read_hdr_minc(file_name)
%
% _________________________________________________________________________
% SUMMARY NIAK_READ_HDR_MINC
%
% Read the header of a MINC(1/2) file (.mnc)
% http://www.bic.mni.mcgill.ca/software/minc/
%
% SYNTAX:
% HDR = NIAK_READ_HDR_MINC(FILE_NAME)
%
% _________________________________________________________________________
% INPUT:
%
% FILE_NAME     
%       (string) name of a single 3D+t minc file or a 3D minc file.
%
% _________________________________________________________________________
% OUTPUT:
%
% HDR           
%       (structure) contain a description of the data. For a list of fields 
%       common to all data types, see NIAK_READ_VOL.
%
%       HDR.DETAILS 
%           (structure) describe the standard variables of a minc file.
%           Each field of HDR.DETAILS is one variable of the MINC files, 
%           and is a structure with two fields.
%
%           HDR.DETAILS.<VAR_NAME>.VARATTS 
%               (cell of string) the list of the attribute name.
%                   
%           HDR.DETAILS.<VAR_NAME>.ATTVALUE
%               (cell of string/double) a list of the attribute values.
%
% _________________________________________________________________________
% COMMENTS:
%
% The reader uses system calls to MINCINFO and MINCHEADER, which requires
% a version of minc tools available.
%
% SEE ALSO:
% NIAK_READ_MINC, NIAK_WRITE_MINC, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center, Montreal Neurological Institute, McGill, 2008.
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

%% Initialization of variables
niak_gb_vars
list_vars = {'image','image-min','image-max','time','xspace','yspace','zspace','acquisition','patient','study'};

%% Checking for existence of the file
if ~exist(file_name)
    error('niak:read: File %s not found',file_name)
end

hdr.file_name = '';
path_f = fileparts(file_name);
if isempty(path_f)
    hdr.info.file_parent = cat(2,pwd,filesep,file_name);
else
    hdr.info.file_parent = file_name;
end


%% Reading the header with 'mincheader'
[flag,str_header] = system(cat(2,'mincheader ',file_name));

cell_header = niak_string2lines(str_header);

num_l = 1;
while (num_l<length(cell_header))&&isempty(findstr(cell_header{num_l},'netcdf'))&&isempty(findstr(cell_header{num_l},'hdf5'))
    num_l = num_l + 1;
end
if num_l == length(cell_header)
    error('niak:read: Could not parse the minc header !')
else
    cell_header = cell_header(num_l:end);
end

%% Setting up the file type and file name
if ~isempty(strfind(cell_header{1},'netcdf'))
    hdr.type = 'minc1';
elseif~isempty(strfind(cell_header{1},'hdf5'))
    hdr.type = 'minc2';
else
    error('niak:read: Could not parse the minc header !')
end


%% Initialization of variables for parsing the header
cell_header = cell_header(2:end-1);

flag_var_mode = 0;
flag_var = 0;
flag_end = 0;

hdr.details.image = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parsing the header into HDR.DETAILS  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while ~isempty(cell_header)&~flag_end

    str_line = cell_header{1};

    if ~isempty(str_line) % Do not process empty lines

        flag_root = ~strcmp(str_line(1),char(9)); % lines which do not start with a tabulation represent big categories of entries

        if flag_root
            if flag_var_mode    % we're just interested in the variables. If a new category is reached (after the variable one), then stop
                flag_end = 1>0;
            end
            flag_var_mode = 0;
        end

        if flag_var_mode    % To pass this flag we must have entered the 'variables' category

            flag_var = isempty(findstr(str_line,':'));  % Within the 'variables', lines without : contain the name of variables

            if flag_var % To pass this flag, the line must be defining a variable

                %% we parse the line to get the name of the variable. If it
                %% does not work, then it must be a weird attribute field
                %% that will be ignored.
                cell_words = niak_string2words(str_line,{' ',char(9),'('});
                nb_atts = 0;

                if length(cell_words)>1
                    var_name = cell_words{2};
                else
                    var_name = '';
                end

                if ismember(var_name,list_vars) % The name of the variable is a classic one. Let's parse the attributes (flag_OK=1).
                    flag_OK = 1;
                    if strcmp(var_name,'image-min')
                        var_name = 'image_min';
                    elseif strcmp(var_name,'image-max')
                        var_name = 'image_max';
                    end
                    setfield(hdr.details,var_name,{});
                else % The name of the variable is weird (probably a dicom header or something of the kind). Let's skip it (flag_OK = 0).
                    flag_OK = 0>0;
                end

            else % If the line does not define a variable, then it defines the attribute of a variable

                flag_pb = false;
                
                if flag_OK % The attribute is from a standard variable

                    %% Parse the attribute line
                    cell_words = niak_string2words(str_line,{' ',char(9),':',';','='});

                    nb_atts = nb_atts+1;
                    try
                        hdr.details.(var_name).varatts{nb_atts} = cell_words{2};                        
                    catch
                        warning('There was a problem setting up the attribute %s in %s. It will be ignored',cell_words{2},var_name)
                        flag_pb = true;
                        nb_atts = nb_atts-1;
                    end

                    if ~flag_pb
                        pos = findstr(str_line,'"');
                        if ~isempty(pos)
                            att_value = str_line(pos(1)+1:pos(2)-1);
                            att_value = niak_replace_str(att_value,'\''','''');
                            try
                                hdr.details.(var_name).attvalue{nb_atts} = att_value;
                            catch
                                nb_atts = nb_atts-1;
                                hdr.details.(var_name).varatts = hdr.details.(var_name).varatts(1:nb_atts);
                                warning('There was a problem setting up the value %s to the attribute %s in %s. It will be ignored',att_value,cell_words{2},var_name)
                            end
                        else
                            str_val = niak_rm_blank([cell_words{3:end}],{'b','d','f'}); % we get rid of type marks
                            try
                                hdr.details.(var_name).attvalue{nb_atts} = str2num(str_val);
                            catch
                                nb_atts = nb_atts-1;
                                hdr.details.(var_name).varatts = hdr.details.(var_name).varatts(1:nb_atts);
                                warning('There was a problem setting up the (numerical) value %s to the attribute %s in %s. It will be ignored',str_val,cell_words{2},var_name)
                            end
                        end
                    end
                end
            end
        end

        flag_var_mode = strcmp(str_line,'variables:')|flag_var_mode; % When meeting for the first time the 'variables:' line, we switch on the 'variables' mode (flag_var_mode = 1)
    end
    cell_header = cell_header(2:end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Building a simplified version of the header common %%
%% to all data formats in the NIAK                    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

list_dim_long = {'xspace','yspace','zspace','time'};
list_dim_short = 'xyzt';

hdr.info.precision = 'float'; % by default, data are imported/exported in float.

%% Get information on history
[flag,str_info] = system(cat(2,'mincinfo -attvalue :history ',file_name));
hdr.info.history = str_info;

%% Get information on the order of the dimensions
if strcmp(hdr.type,'minc1')
    [flag,str_info] = system(cat(2,'mincinfo ',file_name));
    cell_lines = niak_string2lines(str_info);
    str_dim = cell_lines{niak_find_str_cell(cell_lines,'image dimensions')};
end

if strcmp(hdr.type,'minc2')
    pos_do = find(niak_find_str_cell(hdr.details.image.varatts,'dimorder'));
    str_dim = hdr.details.image.attvalue{pos_do};
end

pos_xyzt = zeros([length(list_dim_long) 1]);
for num_e = 1:length(list_dim_long)
    pos = findstr(str_dim,list_dim_long{num_e});
    if ~isempty(pos)
        pos_xyzt(num_e) = pos(1);
    end
end

nb_dim = sum(pos_xyzt ~=  0);

for num_f = 1:length(list_dim_long)
    if num_f <= nb_dim
        [flag,str_dim] = system(cat(2,'mincinfo -dimlength ',list_dim_long{num_f},' ',file_name));
        cell_dim = niak_string2lines(str_dim);
        if flag == 0
            hdr.info.dimensions(num_f) = str2num(cell_dim{end});
        else
            error('niak:read: Could not find the spatial dimensions. I expect ''xspace'', ''yspace'' and ''zspace'' to be defined')
        end
    end
end

[tmp,order_xyzt] = sort(pos_xyzt);
order_xyzt = order_xyzt(tmp~=0);
order_xyzt = order_xyzt(end:-1:1); % the order convention for dimensions in Matlab and Minc are reverse
hdr.info.dimensions = hdr.info.dimensions(order_xyzt);
hdr.info.dimension_order = list_dim_short(order_xyzt);

%% For each dimension, get the step, start and cosines information
start_v = zeros([3 1]);
cosines_v = eye([3 3]);
step_v = zeros([1 3]);
hdr.info.voxel_size = zeros([1 3]);

num_e = 1;
list_dim_long = list_dim_long(pos_xyzt~=0);
list_dim_long = list_dim_long(order_xyzt);

for num_d = 1:length(list_dim_long)

    struct_dim = getfield(hdr.details,list_dim_long{num_d});

    if ~strcmp(list_dim_long{num_d},'time')
        pos = find(niak_find_str_cell(struct_dim.varatts,'step'));
        if ~isempty(pos)
            step_v(num_e) = struct_dim.attvalue{pos};
        end


        pos = find(niak_find_str_cell(struct_dim.varatts,'direction_cosines'));
        if ~isempty(pos)
            cosines_v(:,num_e) = struct_dim.attvalue{pos}(:);
        else
            switch list_dim_long{num_d}
                case 'xspace'
                    cosines_v(:,num_e) = [1;0;0];
                case 'yspace'
                    cosines_v(:,num_e) = [0;1;0];
                case 'zspace'
                    cosines_v(:,num_e) = [0;0;1];
            end
        end

        pos = find(niak_find_str_cell(struct_dim.varatts,'start'));
        if ~isempty(pos)
            start_v(num_e) = struct_dim.attvalue{pos};
        end

        num_e = num_e + 1;
    else
        pos = find(niak_find_str_cell(struct_dim.varatts,'step'));
        hdr.info.tr =  abs(struct_dim.attvalue{pos});
    end

end

hdr.info.voxel_size = abs(step_v);
hdr.info.mat = niak_hdr_minc2mat(cosines_v,step_v,start_v); % Constructing the voxel-to-worldspace affine transformation