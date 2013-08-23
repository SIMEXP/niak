function ssurf = niak_read_surf(file_name,flag_neigh)
% Read a surface in the MNI .obj or Freesurfer format
%
% SYNTAX:
% SSURF = NIAK_READ_SURF_OBJ(FILE_NAME,FLAG_NEIGH,FLAG_VERBOSE)
%
% _________________________________________________________________________
% INPUTS :
%
% FILE_NAME
%    (string or cell of strings, default mid surface in MNI 2009 space) 
%    string: a single surface file. cell of strings : all the surfaces are 
%    concatenated.
%
% FLAG_NEIGH
%    (boolean, default false) if FLAG_NEIGH is true, a neighborhood array 
%    is derived.
%
% FLAG_VERBOSE
%    (boolean, default true) if FLAG_VERBOSE is true, progress is indicated
%    when deriving the neighborhood structure.
%
% _________________________________________________________________________
% OUTPUTS :
%
% SSURF
%    (structure, with the following fields) 
%
%    COORD
%        (array 3 x v) node coordinates. v=#vertices.
%
%    NORMAL
%        (array, 3 x v) list of normal vectors, only .obj files.
%
%    TRI
%        (vector, t x 3) list of triangle elements. t=#triangles.
%
%    NEIGH
%        (array) list of neighbour nodes. Only present if FLAG_NEIGH is true.
%
%    COLR
%        (vector or matrix) 4 x 1 vector of colours for the whole surface,
%        or 4 x v matrix of colours for each vertex, either uint8 in [0 255], 
%        or float in [0 1], only .obj files.
%
% _________________________________________________________________________
% COMMENTS:
%
% .obj file is the montreal neurological institute (MNI) specific ASCII or
% binary triangular mesh data structure. For FreeSurfer software, a slightly 
% different data input coding is used.
%
% (C) Keith Worsley, McGill University, 2008
%     Moo K. Chung, 2004-2007, http://www.stat.wisc.edu/softwares/hk/hk.html
%     Pierre Bellec, Centre de recherche de l'institut de Gériatrie de Montréal,
%        Département d'informatique et de recherche opérationnelle,
%        Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : surface, reader

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

if (nargin<1)||isempty(file_name)
    niak_gb_vars
    path_surf = [gb_niak_path_niak 'template' filesep 'mni-models_icbm152-nl-2009-1.0_surface' filesep];
    file_name = {[path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_mid_left.obj'],[path_surf 'mni_icbm152_t1_tal_nlin_sym_09a_surface_mid_right.obj']};
end

if nargin < 2
    flag_neigh = false;
end

if nargin < 3
    flag_verbose = true;
end

%% Multiple surfaces
if iscellstr(file_name)
    k = length(file_name);
    ssurf.tri=[];
    ssurf.coord = [];
    ssurf.colr = [];
    ssurf.normal = [];
    ssurf.neigh = [];
    for j=1:k
        s = niak_read_surf(file_name{j},flag_neigh);
        ssurf.tri=[ssurf.tri; int32(s.tri)+size(ssurf.coord,2)];
        ssurf.coord = [ssurf.coord s.coord];
        if isfield(s,'neigh')
            mask = s.neigh ~= 0;
            s.neigh(mask) = s.neigh(mask) + size(ssurf.neigh,1);
            ssurf.neigh = [ssurf.neigh ; s.neigh];
        end
        if isfield(s,'colr') 
            if size(s.colr,2)==1
                ssurf.colr = s.colr;
            else
                ssurf.colr = [ssurf.colr s.colr];
            end
        end
        if isfield(s,'normal')
            ssurf.normal = [ssurf.normal s.normal];
        end
    end
    if isempty(ssurf.colr)
        ssurf = rmfield(ssurf,'colr');
    end
    if isempty(ssurf.neigh)
        ssurf = rmfield(ssurf,'neigh');
    end
    if isempty(ssurf.normal)
        ssurf = rmfield(ssurf,'normal');
    end
    return
end

%% Single surface
ab='a';
numfields = 4;
[pathstr,name,ext] = fileparts(file_name);
if strcmp(ext,'.obj')
    % It's a .obj file
    if ab(1)=='a'
        fid=fopen(file_name);
        FirstChar=fscanf(fid,'%1s',1);
        if FirstChar=='P' % ASCII
            fscanf(fid,'%f',5);
            v=fscanf(fid,'%f',1);
            ssurf.coord=fscanf(fid,'%f',[3,v]);
            if numfields>=2
                ssurf.normal=fscanf(fid,'%f',[3,v]);
                if numfields>=3
                    ntri=fscanf(fid,'%f',1);
                    ind=fscanf(fid,'%f',1);
                    if ind==0
                        ssurf.colr=fscanf(fid,'%f',4);
                    else
                        ssurf.colr=fscanf(fid,'%f',[4,v]);
                    end
                    if numfields>=4
                        fscanf(fid,'%f',ntri);
                        ssurf.tri=fscanf(fid,'%f',[3,ntri])'+1;
                    end
                end
            end
            fclose(fid);
        else
            fclose(fid);
            fid=fopen(file_name,'r','b');
            FirstChar=fread(fid,1);
            if FirstChar==uint8(112) % binary
                fread(fid,5,'float');
                v=fread(fid,1,'int');
                ssurf.coord=fread(fid,[3,v],'float');
                if numfields>=2
                    ssurf.normal=fread(fid,[3,v],'float');
                    if numfields>=3
                        ntri=fread(fid,1,'int');
                        ind=fread(fid,1,'int');
                        if ind==0
                            ssurf.colr=uint8(fread(fid,4,'uint8'));
                        else
                            ssurf.colr=uint8(fread(fid,[4,v],'uint8'));
                        end
                        if numfields>=4
                            fread(fid,ntri,'int');
                            ssurf.tri=fread(fid,[3,ntri],'int')'+1;
                        end
                    end
                end
                fclose(fid);
                ab='b';
            else
                fprintf(1,'%s\n',['Unable to read ' file_name ', first character ' char(FirstChar)]);
            end
        end
    else
        fid=fopen(file_name,'r','b');
        FirstChar=fread(fid,1);
        if FirstChar==uint8(112) % binary
            fread(fid,5,'float');
            v=fread(fid,1,'int');
            ssurf.coord=fread(fid,[3,v],'float');
            if numfields>=2
                ssurf.normal=fread(fid,[3,v],'float');
                if numfields>=3
                    ntri=fread(fid,1,'int');
                    ind=fread(fid,1,'int');
                    if ind==0
                        ssurf.colr=uint8(fread(fid,4,'uint8'));
                    else
                        ssurf.colr=uint8(fread(fid,[4,v],'uint8'));
                    end
                    if numfields>=4
                        fread(fid,ntri,'int');
                        ssurf.tri=fread(fid,[3,ntri],'int')'+1;
                    end
                end
            end
            fclose(fid);
        else
            fclose(fid);
            fid=fopen(file_name);
            FirstChar=fscanf(fid,'%1s',1);
            if FirstChar=='P' %ASCII
                fscanf(fid,'%f',5);
                v=fscanf(fid,'%f',1);
                ssurf.coord=fscanf(fid,'%f',[3,v]);
                if numfields>=2
                    ssurf.normal=fscanf(fid,'%f',[3,v]);
                    if numfields>=3
                        ntri=fscanf(fid,'%f',1);
                        ind=fscanf(fid,'%f',1);
                        if ind==0
                            ssurf.colr=fscanf(fid,'%f',4);
                        else
                            ssurf.colr=fscanf(fid,'%f',[4,v]);
                        end
                        if numfields>=4
                            fscanf(fid,'%f',ntri);
                            ssurf.tri=fscanf(fid,'%f',[3,ntri])'+1;
                        end
                    end
                end
                fclose(fid);
                ab='a';
            else
                fprintf(1,'%s\n',['Unable to read ' file_name ', first character ' char(FirstChar)]);
            end
        end
    end
else
    % Assume it's a FreeSurfer file
    fid = fopen(file_name, 'rb', 'b') ;
    b1 = fread(fid, 1, 'uchar') ;
    b2 = fread(fid, 1, 'uchar') ;
    b3 = fread(fid, 1, 'uchar') ;
    magic = bitshift(b1, 16) + bitshift(b2,8) + b3 ;
    if magic==16777214
        fgets(fid);
        fgets(fid);
        v = fread(fid, 1, 'int32') ;
        t = fread(fid, 1, 'int32') ;
        ssurf.coord = fread(fid, [3 v], 'float32') ;
        if numfields==4
            ssurf.tri = fread(fid, [3 t], 'int32')' + 1 ;
        end
        fclose(fid) ;
    else
        fprintf(1,'%s\n',['Unable to read ' file_name ', magic = ' num2str(magic)]);
    end
    ab='b';
end

% If requested, find out the neighboring nodes
if flag_neigh
    % compute the maximum degree of node
    degree = niak_build_size_roi(ssurf.tri(:));
    max_degree = max(degree);
    n_points = size(ssurf.coord,2);
    n_tri = size(ssurf.tri,1);
    nbr = zeros(n_points,max_degree);
    pos = ones(n_points,1);
    for i_tri=1:n_tri
        if flag_verbose
            niak_progress(i_tri,n_tri);
        end
        for j=1:3
            cur_point = ssurf.tri(i_tri,j);
            for k=1:3
                if (j ~= k)
                    nbr_point = ssurf.tri(i_tri,k);
                    if ~any(nbr(cur_point,:)==nbr_point)
                        nbr(cur_point,pos(cur_point)) = nbr_point;
                        pos(cur_point) = pos(cur_point)+1;
                    end;
                end;
            end;
        end;
    end;
    ssurf.neigh = nbr;
end

return
end
