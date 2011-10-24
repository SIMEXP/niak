function [files_in,files_out,opt] = niak_brick_math_vol(files_in,files_out,opt)
% Apply an arbitrary matlab operation on multiple brain volumes.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MATH_VOL(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN        
%    (cell of strings) each entry is a file name of a volume. All
%    datasets need to be in the same space (either one individual, or
%    stereotaxic space).
%
% FILES_OUT    
%    (string) the name for the resulting volume.
%   
% OPT        
%    (structure) with the following fields.  
%
%    OPT_OPERATION
%        (any type, default [])
%
%    OPERATION
%        (string) An operation that will be submitted to EVAL in order
%        to generate the resulting volume. Note that the data in
%        FILES_IN{I} is accessible in a variable VOL_IN{I}. 
%        The final result should be stored in a variable called VOL. 
%        The variable OPT_OPERATION is also available in memory.
%
%    FLAG_VERBOSE 
%        (boolean, default 1) if the flag is 1, then the function 
%        prints some infos during the processing.
%
%    FLAG_TEST 
%        (boolean, default 0) if FLAG_TEST equals 1, the brick does not 
%        do anything but update the default values in FILES_IN, 
%        FILES_OUT and OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MASK_BRAIN
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, volume

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

niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')||~exist('files_out','var')||~exist('opt','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_MATH_VOL(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_math_vol'' for more info.')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields = {'opt_operation','operation','flag_verbose','flag_test'};
gb_list_defaults = {[],NaN,true,false};
niak_set_defaults

if flag_test
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

nb_files = length(files_in);

%% Read inputs
for num_f = 1:nb_files
    
    if flag_verbose
        fprintf('Reading vol%i from file %s ...\n',num_f,files_in{num_f});
    end
    
    [hdr,vol_tmp] = niak_read_vol(files_in{num_f});
    vol_in{num_f} = vol_tmp;

    if num_f == 1
        hdr_func = hdr;
    end   

end

%% Apply operation
if flag_verbose
    fprintf('Evaluating the following operation: \n      %s\n',opt.operation);
end
eval(opt.operation);

%% Save outputs
if flag_verbose
    fprintf('Saving output in %s\n',files_out);
end

hdr_func.file_name = files_out;
niak_write_vol(hdr_func,vol);