function [files_in, files_out, opt] = niak_brick_stability_average(files_in, files_out, opt)
% Average multiple estimated stability matrices
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_AVERAGE(FILES_IN, FILES_OUT, OPT)
%
% _________________________________________________________________________
% INPUTS:
% FILES_IN
%   (string or cell of strings) path or paths to the files to be averaged.
%   Each file must contain a variable OPT.NAME_DATA which contains either a
%   cell of strings indicating the variables to be individually averaged
%   across files or a matrix to be averaged across files, depending on
%   OPT.CASE. See OPT.CASE for an explanation
%
% FILES_OUT
%   (string, optional) the path to the output .mat file
%
% OPT
%   (structure) with the following fields:
%
%   NAME_DATA
%       (string) the name of the variable in the input file that contains one of
%       either a cell of strings or a matrix. See FILES_IN for an
%       explanation.
%
%   NAME_SCALE_IN
%       (string, default 'scale') the name of the variable that contains
%       the vector of scales corresponding to the stability matrices.
%
%   NAME_SCALE_OUT
%       (string, default 'scale') the name of the variable that contains
%       the vector of scales corresponding to the stability matrices.
%
%   CASE
%       (integer, default 1) the case variable that selects whether the
%       variable OPT.NAME_DATA in FILES_IN will be expected to be a cell of 
%       strings that points to variables in FILES_IN to be averaged (CASE 1) or 
%       if it will be expected to be a matrix that will be averaged (CASE 2). 
%       This is an overview of how OPT.NAME_DATA is treated in either case
%
%       CASE = 1
%           (OPT.NAME_DATA is a Cell of Strings)
%           The strings in OPT.NAME_DATA are expected to point to variables
%           in FILES_IN that contain themselves matrices which are to be
%           averaged individually across the input files.
%
%       CASE = 2
%           (OPT.NAME_DATA is a Matrix)
%           The matrix in OPT.NAME_DATA is averaged across the input files.
%
%   FLAG_VERBOSE
%      (boolean, default true) turn on/off the verbose.
%
%   FLAG_TEST
%      (boolean, default false) if the flag is true, the brick does not do anything
%      but updating the values of FILES_IN, FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Sebastian Urchs
%   Centre de recherche de l'institut de Gériatrie de Montréal
%   Département d'informatique et de recherche opérationnelle
%   Université de Montréal, 2010-2014
%   Montreal Neurological Institute, 2014
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, surface analysis, cortical thickness, stability
% analysis, bootstrap, jacknife.

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

%% TODO:

%% Initialization and syntax checks

% Syntax
if ~exist('files_in','var')||~exist('files_out','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_STABILITY_AVERAGE(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_stability_average'' for more info.')
end

% FILES_IN
if ~ischar(files_in)&&~iscellstr(files_in)
    error('FILES_IN should be a string or cell of strings');    
end

% FILES_OUT
if ~ischar(files_out)
    error('FILES_OUT should be a string!');
end

% Options
if nargin < 3
    opt = struct;
end

list_fields   = { 'name_data' , 'name_scale_in' , 'name_scale_out' , 'case' , 'flag_verbose' , 'flag_test' };
list_defaults = { NaN         , 'scale'         , 'scale'          , 1      , true           , false       };
opt = psom_struct_defaults(opt,list_fields,list_defaults);

% If the test flag is true, stop here !
if opt.flag_test == 1
    return
end

%% Read the data
scale = [];
num_files = length(files_in);
out = struct;

switch opt.case
    case 1
        % We expect cells of strings
        if opt.flag_verbose
            fprintf('Case 1. We expect a cell of strings to average\n');
        end
        out.stab = struct();
        
        for f_ind = 1:num_files
            data_file = files_in{f_ind};
            data = load(data_file);

            if opt.flag_verbose
                fprintf(sprintf('I am loading file #%d now.\n    %s\n',...
                                f_ind, data_file));
            end

            fields = fieldnames(data);
            sought_fields = { opt.name_data, opt.name_scale_in };

            % Checks
            if ~all(isfield(data, sought_fields))
                % we are missing fields
                miss_ind = ~isfield(data, sought_fields);
                error('Could not find field %s in %s\n',...
                      sought_fields{miss_ind}, data_file);
            elseif ~iscellstr(data.(opt.name_data))
                error(['A cell of strings was expected but %s in %s was of '...
                       'type %s\n'], opt.name_data, data_file,...
                      class(data.(opt.name_data))); 
            end
            
            if f_ind == 1
                % first file
                out.scale_names = data.(opt.name_data);
                out.(opt.name_scale_out) = data.(opt.name_scale_in);
                out.scale_rep = data.scale_rep;
                num_scales = length(out.scale_names);
            else
                if out.(opt.name_scale_out) ~= data.(opt.name_scale_in)
                    error(['The scale in %s doesn''t match the previous '...
                           'scales\n'], data_file);
                end
            end

            if opt.flag_verbose
                fprintf('Found %d scale fields in %s.\n',num_scales, data_file);
            end

            % iterate over the hits
            for sc_ind = 1:num_scales
                scale_name = out.scale_names{sc_ind};
                % Get the current stability matrix
                stab_mat = data.(scale_name);
                % Get the dimensions for the stability matrix
                [stab_scale, stab_V] = size(stab_mat);
                % Check if the current scale exists for the output structure
                if ~isfield(out.stab, scale_name)
                    out.stab.(scale_name) = zeros(stab_scale, stab_V);
                end
                % Add the new stability matrix
                out.stab.(scale_name) = (out.stab.(scale_name) + stab_mat);
            end
        end

        % Average the stability matrices
        for sc_ind = 1:num_scales
            scale_name = out.scale_names{sc_ind};
            out.stab.(scale_name) = out.stab.(scale_name) / num_files;    
        end
        
        % Save the results
        if opt.flag_verbose
            fprintf('Write the resuts ...\n     %s\n',files_out);
        end
        save(files_out,'-struct','out');

    case 2
        % We expect a matrix
        if opt.flag_verbose
            fprintf('Case 2. We expect a matrix to average\n');
        end

        for f_ind = 1:num_files
            data_file = files_in{f_ind};
            data = load(data_file);
            if opt.flag_verbose
                fprintf(sprintf('I am loading file #%d now.\n    %s\n', f_ind, data_file));
            end
            
            sought_fields = {opt.name_data, opt.name_scale_in};
            % Checks
            if ~all(isfield(data, sought_fields))
                % we are missing fields
                miss_ind = ~isfield(data, sought_fields);
                error('Could not find field %s in %s\n',sought_fields{miss_ind}, data_file);
            elseif ~ismatrix(data.(opt.name_data))
                error('A matrix was expected but %s in %s was of type %s\n', opt.name_data, data_file, class(data.(opt.name_data))); 
            end

            if f_ind == 1
                % first file, populate the array
                stab = data.(opt.name_data);
                out.(opt.name_scale_out) = data.(opt.name_scale_in);
            else
                stab = stab + data.(opt.name_data);
                if ~out.(opt.name_scale_out) == data.(opt.name_scale_in)
                    error('The scale in %s doesn''t match the previous scales\n', data_file);
                end
            end
        end
        out.stab = stab / num_files;

        % Save the results
        if opt.flag_verbose
            fprintf('Write the resuts ...\n     %s\n',files_out);
        end
        save(files_out,'-struct','out');

    otherwise
        % Someone set the wrong case
        error('The specified case is not implemented\n');
end
