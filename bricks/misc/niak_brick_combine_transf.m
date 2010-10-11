function [files_in,files_out,opt] = niak_brick_combine_transf(files_in,files_out,opt)
% Combine affine transformations from multiple MAT files.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COMBINE_TRANSF(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%   FILES_IN      
%       (cell of strings) each entry in the name of a .mat file with one
%       variable TRANSF. The first variable can have multiple entries, i.e.
%       TRANSF(:,:,I) is a transformation. The name of the variable can be
%       changed, see OPT.VAR_NAME below.
%
%   FILES_OUT 
%       (string) the name of a MAT file with one TRANSF variable, which is
%       the combined transformations from all inputs, from the first to the
%       last in that order.
%
%   OPT           
%       (structure, optional) has the following fields:
%
%       VAR_NAME
%           (string, default 'transf') the name of the transformation
%           variable.
%
%       FLAG_TEST 
%           (boolean, default: 0) if FLAG_TEST equals 1, the brick does not 
%           do anything but update the default values in FILES_IN and 
%           FILES_OUT.
%
%       FLAG_VERBOSE 
%           (boolean, default 1) if the flag is 1, then the function prints 
%           some infos during the processing.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% values. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS:
%
% The TRANSF variables are standard 4*4 matrix array representation of 
% an affine transformation [M T ; 0 0 0 1] for (y=M*x+T) 
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : affine transformation

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~iscellstr(files_in)
    error('FILES_IN should be a cell of strings')
end

if isempty(files_out)
    error('Please specify FILES_OUT')
end

% Setting up options
gb_name_structure = 'opt';
gb_list_fields = {'var_name' , 'flag_verbose' , 'flag_test' };
gb_list_defaults = {'transf' , true           , false       };
niak_set_defaults

if flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% Combine transforms %%
%%%%%%%%%%%%%%%%%%%%%%%%
nb_file = length(files_in);

for num_f = 1:nb_file
    file_name = files_in{num_f};
    if flag_verbose
        fprintf('Reading %s ...\n',file_name);
    end
    data = load(file_name,var_name);
    if num_f == 1
        transf = data.(var_name);
        nb_transf = size(transf,3);
    else
        if size(data.(var_name),3)~=1
            error(sprintf('There should be only one transformation in %s',file_name));
        end
        for num_t = 1:nb_transf
            transf(:,:,num_t) = data.(var_name)*transf(:,:,num_t);
        end
    end    
end

%%%%%%%%%%%%%%%%%%
%% Save results %%
%%%%%%%%%%%%%%%%%%
if flag_verbose
	fprintf('Saving results in %s ...\n',files_out);
end
eval(sprintf('%s = transf;',var_name));
if flag_verbose
	fprintf('Done !\n',files_out);
end
save(files_out,var_name);