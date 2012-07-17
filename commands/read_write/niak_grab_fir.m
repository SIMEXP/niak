function files = niak_grab_fir(path_data,filter)
% Grab region-level FIR generated in the BASC-FIR pipeline
%
% SYNTAX:
% FILES = NIAK_GRAB_FIR(PATH_DATA,FILTER)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DATA
%   (string, default [pwd filesep], aka './') full path to the outputs of 
%   NIAK_PIPELINE_REGION_GROWING. There should be a file "brain_rois.EXT" 
%   where EXT can be .mnc or .nii possibly compressed (see GB_NIAK_ZIP_EXT 
%   in NIAK_GB_VARS.M for the extension, usually it is .gz). There should 
%   also be a collection of files named with the following pattern : 
%   fir_tseries_<SUBJECT>_roi.mat
%
% 
% FILTER
%   (string) a string that will be passed to select a subset of files. A 
%   file is included only if a pattern maching FILTER is found with REGEXP
%   For example :
%       '$run1.mat' : select only the first run for all subjects
%       'subject[15]' : select only subjects 1 and 5, all runs.
%       'subject[1-5]' : select only subjects 1 to 5, all runs.
%       '*subject[1-5]_run1.mat' : select only subjects 1-5, run 1.
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES
%   (structure) with the following fields, ready to feed into 
%   NIAK_PIPELINE_STABILITY_{REST,FIR,GLM} :
%
%   DATA
%       (structure) with the following fields :
%
%       <SUBJECT>
%           (cell of strings with one entry) a .mat files. The field names 
%           <SUBJECT> can be any arbitrary strings. Each .mat file contains 
%           some variables FIR_MEAN, FIR_STD and FIR_ALL, where 
%           FIR_MEAN(:,I) is the estimated FIR of region I as defined by
%           FILES.ATOMS (see below).
%
%   ATOMS
%       (string) a file name of a mask of brain regions (region I is filled 
%       with Is, 0 is for the background). The analysis will be done at the 
%       level of these atomic regions. This means that the fMRI time series
%       will be averaged in each region, and the stability analysis will be
%       carried on these regional time series. If unspecified, the regions
%       will be built using a region growing approach.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BRICK_STABILITY_FIR, REGEXP
%
% _________________________________________________________________________
% COMMENTS:
%
% This "data grabber" is designed to work with the pipelines mentioned in
% the "SEE ALSO" section, based on a folder "rois" from the outputs of
% NIAK_PIPELINE_REGION_GROWING.
%
% Copyright (c) Pierre Bellec
%               Centre de recherche de l'institut de Gériatrie de Montréal,
%               Département d'informatique et de recherche opérationnelle,
%               Université de Montréal, 2011.
% Maintainer : pbellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : clustering, stability, bootstrap, time series

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

if nargin < 2
    filter = ['.'];
end
if (nargin < 1)||isempty(path_data)
    path_data = [pwd filesep];
end
if ~strcmp(path_data(end),filesep);
    path_data = [path_data filesep];
end

list_files = dir([path_data]);
files.data = struct();
for num_f = 1:length(list_files)
    if ~list_files(num_f).isdir
        [path_f,name_f,ext_f] = niak_fileparts(list_files(num_f).name);
        if strcmp(name_f,'brain_rois');
            files.atoms = [path_data,name_f,ext_f];
        else
            flag_ok = ~isempty(regexp([name_f ext_f],'^fir_tseries_','once'))&&~isempty(regexp([name_f ext_f],'_roi.mat$','once'));
            if flag_ok
                if ~isempty(regexp([name_f ext_f],filter, 'once'))
                    ind_run = regexp(name_f,'_roi');
                    subject = name_f((length('fir_tseries_')+1):(ind_run(end)-1));
                    if ~isfield(files.data,subject)
                        files.data.(subject).fmri{1} = [path_data name_f ext_f];
                    else
                        files.data.(subject).fmri{end+1} = [path_data name_f ext_f];
                    end
                end
            end
        end
    end
end
if ~isfield(files,'atoms')
    error('I could not find the file of brain atoms called "brain_rois"')
end