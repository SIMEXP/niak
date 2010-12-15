function [files_in,files_out,opt] = niak_brick_vol2avi(files_in,files_out,opt)
% Convert a 3D+t volume into a movie in the .AVI format.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_VOL2AVI(FILES_IN,[FILES_OUT],[OPT])
%
% _________________________________________________________________________
% INPUTS:
%
% FILES_IN        
%   (string) a file name of a 3D+t fMRI dataset .
%
% FILES_OUT
%   (string, default <BASE FILES_IN>.avi) with the following fields:
%       
%
% OPT           
% 	(structure) with the following fields.  
%
%   ARG
%       (string, default '') extra arguments that will be passed to the
%       FFMPEG command.
%
%   MONTAGE
%   	(structure) the options of NIAK_MONTAGE. Note that by default, the
%   	field OPT.VISU.VOL_LIMITS will be set to the median of the volume
%   	+/- 2 MAD estimates of the standard deviation (this computation
%   	will be restricted to a brain mask).
%
%	FOLDER_OUT 
%   	(string, default: path of FILES_IN) If present, all default outputs 
%       will be created in the folder FOLDER_OUT. The folder needs to be 
%       created beforehand.
%
%   FLAG_VERBOSE 
%   	(boolean, default 1) if the flag is 1, then the function prints 
%       some infos during the processing.
%
%   FLAG_TEST 
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do 
%       anything but update the default values in FILES_IN, FILES_OUT and 
%       OPT.
%           
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%              
% _________________________________________________________________________
% SEE ALSO:
% NIAK_MONTAGE
%
% _________________________________________________________________________
% COMMENTS:
%
% This brick needs the package FFMPEG to be installed. There are a huge
% number of output formats actually supported. See 'man ffmpeg' for more
% infos.
%
% _________________________________________________________________________
% Copyright (c) <NAME>, <INSTITUTION>, <START DATE>-<END DATE>.
% Maintainer : <EMAIL ADDRESS>
% See licensing information in the code.
% Keywords : NIAK, documentation, template, brick

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization and syntax checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Syntax
if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_VOL2MPEG(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_vol2mpeg'' for more info.')
end

%% Inputs
if ~ischar(files_in)
    error('FILES_IN should be a string');
end

if ~exist('files_out','var')
    files_out = '';
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'arg' , 'montage' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {''    , struct()  , true           , false       , ''           };
niak_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = niak_fileparts(files_in); % parse the folder, file name and extension of the input

if strcmp(opt.folder_out,'') % if the output folder is left empty, use the same folder as the input
    opt.folder_out = path_f;    
end

if isempty(files_out)
    files_out = [opt.folder_out name_f '.avi'];
end

%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_verbose
    fprintf('Conversion from 3D+t image to video.\nVolume : %s\n',files_in);
end

if flag_verbose
    fprintf('Reading volume ...\n');
end
[hdr,vol] = niak_read_vol(files_in);
sampling_rate = 1/hdr.info.tr;
path_tmp = niak_path_tmp('_mpg');

nt = size(vol,4);

if ~isfield(opt.montage,'vol_limits')
    mask = niak_mask_brain(abs(vol));
    tseries = niak_vol2tseries(vol,mask);
    med_vol = median(tseries(:));
    std_vol = niak_mad(tseries(:));   
    opt.montage.vol_limits = [med_vol-2*std_vol,med_vol+2*std_vol];
end

list_num = zeros([nt 1]);
nb_dig = length(num2str(nt));
if flag_verbose
    fprintf('Generating individual png volume montage ...\n    volume : ');
end
    
for num_t = 1:nt    
    if flag_verbose
        fprintf(' %i',num_t);
    end

    file_tmp = [path_tmp 'vol_' repmat('0',[1 nb_dig-length(num2str(num_t))]) num2str(num_t) '.png'];
    niak_montage(vol(:,:,:,num_t),opt.montage);
    print(file_tmp,'-dpng');    
end
if flag_verbose
        fprintf('\nConversion to video using FFMPEG ...\n');
end
instr_ffmpeg = ['ffmpeg -f image2 -r ' num2str(sampling_rate) ' -i ' path_tmp 'vol_%0' num2str(nb_dig) 'd.png ' files_out];
[st,msg] = system(instr_ffmpeg);
if st~=0
    warning(sprintf('The conversion with ffmpeg failed.\nThe command line was:\n    %s\nThe message was:\n   %s\n',instr_ffmpeg,msg));
end
if flag_verbose
        fprintf('Cleaning up temporary folder ...\n');
end

instr_rm = ['rm -rf ' path_tmp];
[st,msg] = system(instr_rm);
if st~=0
    warning(sprintf('Removing the temporary folder failed.\nThe command line was:\n    %s\nThe message was:\n   %s\n',instr_rm,msg));
end
