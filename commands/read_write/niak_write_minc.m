function [] = niak_write_minc(hdr,vol)
% Write a 3D or 3D+t dataset into a MINC file
% http://www.bic.mni.mcgill.ca/software/minc/
%
% SYNTAX:
% [] = NIAK_WRITE_MINC(HDR,VOL)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL
%    (3D or 4D array) a 3D or 3D+t dataset
%
% HDR
%    (structure) a header structure (usually modified from the output of
%    NIAK_READ_VOL). The relevant fields of HDR are :
%
%    FILE_NAME
%        (string) the name of the file that will be written.
%
%    TYPE
%        (string, default 'minc2') the output format (either 'minc1' or
%        'minc2').
%
%    INFO
%        (structure) The subfields are optional, yet they give control
%        on critical space information. See NIAK_WRITE_VOL for more
%        info.
%
%    DETAILS
%        (structure) The subfields are also optional, and specific to
%        the minc format. Note that a minc file with correct space
%        information can be created without it.
%
%        <VAR_NAME>
%         where VAR_NAME is a string. Such field will define a new
%         variable called <VAR_NAME> in the minc file. <VAR_NAME> is
%         a structure with the following fields :
%
%         VARATTS
%             (cell of strings) Each string will define a new
%             attribute in variable <VAR_NAME>.
%
%         ATTVALUES
%             (cell of double array and/or strings) Each entry
%             defines the value of the corresponding attribute.
%
%    LIKE
%        (string, default '') the name of a model file. The header of
%        the new file will be identical to the model. If left empty, the
%        info in the header structure is used. Using a model file is
%        much faster than writting the header.
%
%    RAW
%        (string, default temporary file) the name of a temporary file
%        to store raw data. If that field is specified, the raw data
%        will not be flushed after writting the minc file.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The data called VOL is stored into a file called FILENAME written in
% minc format. If the extension of FILE_NAME is '.mnc.gz' or '.mnc.zip' or
% '.mnc.Z', the file will be compressed (choose the zipper by setting the
% variable NIAK_GB_ZIP in the file NIAK_GB_VARS with the appropriate
% command line).
%
% Specifying the name of the raw data file can also save a significant 
% amount of time.
% _________________________________________________________________________
% SEE ALSO:
% NIAK_READ_HDR_MINC, NIAK_READ_MINC, NIAK_READ_VOL, NIAK_WRITE_VOL
%
% _________________________________________________________________________
% COMMENTS:
%
% The values of HDR.INFO override the values of HDR.DETAILS.
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
if ~isfield(hdr,'like')||(isempty(hdr.like))

    %% Setting up default values for the details in the header
    info_default.voxel_size = [1 1 1];
    details_default.image.varatts = {};
    details_default.image.attvalue = {};
    details_default.xspace.varatts = {};
    details_default.xspace.attvalue = {};
    details_default.yspace.varatts = {};
    details_default.yspace.attvalue = {};
    details_default.zspace.varatts = {};
    details_default.zspace.attvalue = {};
    if length(size(vol))>3
        details_default.time.varatts = {};
        details_default.time.attvalue = {};
    end

    %% Defaults for the header
    gb_name_structure = 'hdr';
    gb_list_fields = {'file_name','type','info','details','flag_zip','like','raw'};
    gb_list_defaults = {NaN,'minc2',info_default,details_default,0,'',''};
    niak_set_defaults

    %% Setting up default values for the 'info' part of the header
    hdr.info.dimensions = size(vol);
    gb_name_structure = 'hdr.info';
    gb_list_fields = {'precision','voxel_size','mat','dimension_order','tr','history','file_parent','dimensions'};
    gb_list_defaults = {'float',[1 1 1],[],'xyzt',1,'','',[]};
    niak_set_defaults

    if isempty(hdr.info.mat)
        hdr.info.mat = [diag(hdr.info.voxel_size) ones([3 1]) ; zeros([1 3]) 1];
    end
else
    if ~isfield(hdr,'raw')
        hdr.raw = '';
    end
    file_name = hdr.file_name;
end

%% Generating a temporary raw data file
[path_tmp,name_tmp,ext_tmp] = fileparts(file_name);

if isempty(hdr.raw)
    flag_flush = true;
    file_tmp = niak_file_tmp([name_tmp '.raw']);
else
    flag_flush = false;
    file_tmp = hdr.raw;
end
[hf,err_msg] = fopen(file_tmp,'w');

if hf == -1
    error('niak:write: %s %s',file_tmp,err_msg)
end

fwrite(hf,vol(:),hdr.info.precision);
fclose(hf);

%% Converting the raw data into a minc file
if ~isempty(hdr.like)
    str_raw = ['rawtominc -float -clobber -like ' hdr.like,' -input ' file_tmp ' ' file_name];
    [flag_fail,err_msg] = system(str_raw);
    
    if flag_fail
        error(err_msg)
    end
    if flag_flush
        delete(file_tmp); % deleting temporary file
    end
else
    str_raw = 'rawtominc '; % rawtominc is used to create the file

    %% Setting up "rawtominc" arguments
    if ndims(vol)~=4
        tmp = findstr(hdr.info.dimension_order,'t');
        if ~isempty(tmp)
            list_ind_order = 1:4;
            list_ind_order = list_ind_order(list_ind_order~=tmp);
            hdr.info.dimension_order = hdr.info.dimension_order(list_ind_order);
        end
    end
    dim_order = zeros([ndims(vol) 1]);
    if (ndims(vol) == 4)&&(length(hdr.info.dimension_order)==3)
        hdr.info.dimension_order = [hdr.info.dimension_order 't'];
    end    
    for num_d = 1:ndims(vol)    
        dim_order(num_d) = findstr('xyzt',hdr.info.dimension_order(num_d));
    end
    
    %% Build the dimension order argument for minc to raw
    dim_names = {'xspace,','yspace,','zspace,','time,'};    
    arg_dim_order = [dim_names{dim_order(end:-1:1)}]; % the order notations in NetCDF/HDF5 is reversed compared to matlab

    %% While we're at it, build a list of order field names for spatial
    %% dimensions
    dim_names = {'xspace','yspace','zspace','time'};
    list_dim = dim_names(dim_order);
    list_dim = list_dim(~ismember(list_dim,{'time'}));

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

    size_vol = size(vol);
    if length(size_vol)==4
        if size_vol(4) == 1
            size_vol = size_vol(1:3);
        end
    end

    size_vol = num2str(size_vol(end:-1:1));
    str_raw = [str_raw ' ' size_vol]; % set up the size

    system(str_raw); % Writting the new minc file

    if flag_flush
        delete(file_tmp); % deleting temporary file
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Override the inherited header informations with user-specified values %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    hdr_minc = hdr.details;

    %% For 3D volume, get rid of the time information
    if size(vol,4) == 1;
        if isfield(hdr_minc,'time')
            hdr_minc = rmfield(hdr_minc,'time');
        end
    end
    hdr_minc.image = sub_set_att(hdr_minc.image,'dimorder',arg_dim_order);
    [cosines_v,step_v,start_v] = niak_hdr_mat2minc(hdr.info.mat);

    %% Time
    if length(size(vol))==4
        if ~isfield(hdr_minc,'time')
            hdr_minc.time.varatts{1} = 'step';
            hdr_minc.time.attvalue{1} = hdr.info.tr;
        else
            hdr_minc.time = sub_set_att(hdr_minc.time,'step',hdr.info.tr);
        end
        hdr_minc.time = sub_set_att(hdr_minc.time,'start',0);
    end

    for num_d = 1:length(list_dim);
        dim = list_dim{num_d};

        hdr_minc.(dim) = sub_set_att(hdr_minc.(dim),'step',step_v(num_d)); % step values
        hdr_minc.(dim) = sub_set_att(hdr_minc.(dim),'start',start_v(num_d)); % start values
        hdr_minc.(dim) = sub_set_att(hdr_minc.(dim),'direction_cosines',cosines_v(:,num_d)'); % cosines values

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Updating the variables of the minc file %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% history
    hist = niak_string2lines(hdr.info.history);
    for num_l = 1:length(hist)
        if num_l == 1
            system(cat(2,'minc_modify_header -sinsert :history=''',deblank(hist{num_l}),''' ',file_name));
        else
            system(cat(2,'minc_modify_header -sappend :history=''\n',deblank(hist{num_l}),''' ',file_name));
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

                if ~strcmp(att,'length')&&~isempty(att_val)
                    if ischar(att_val)
                        att_val = niak_replace_str(att_val,'''','"');
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
end

%%%%%%%%%%%%%%%%%%
%% Subfunctions %%
%%%%%%%%%%%%%%%%%%
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
