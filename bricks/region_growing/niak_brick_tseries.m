function [files_in,files_out,opt] = niak_brick_tseries(files_in,files_out,opt)
% Extract some regional time series from a 3D+t fMRI dataset.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_TSERIES(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS:
%
%  FILES_IN
%       (structure) with the following fields :
%
%       FMRI
%           (string or cell of string) A collection of fMRI datasets. They 
%           need to be all in the same world and voxel space. A .mat file 
%           can also be used instead with a variable TSERIES (the name can 
%           actually be changed, see OPT.NAME_TSERIES) associated with a 
%           set of ROIS, see FILES_IN.ATOMS below.
%
%       MASK
%           (string or cell of strings) A mask of regions of interest
%           (region I is defined by MASK==I).
%
%       ATOMS
%           (string, default 'gb_niak_omitted') can be used if FILES_IN.FMRI
%           is already represented through region time series averaged on
%           ATOMS, i.e. a 3D volume of ROIs.
%
%  FILES_OUT
%
%       TSERIES
%           (cell of string, default {<BASE_FMRI>_<BASE_MASK>.mat})
%           FILES_OUT.TSERIES{K,L} is derived using FILES_IN.FMRI{K} and
%           FILES_IN.MASK{L}. Each entry is a MAT file with the following
%           variables :
%
%               TSERIES_MEAN
%                   (2D array) the time series of the ROIs for each fMRI
%                   dataset. TSERIES_MEAN(:,I) is the time series of region I.
%
%               TSERIES_STD
%                   (2D array) TSERIES_STD(:,I) is the standard deviation
%                   of the time series  in region I in FILES_IN.MASK{L}
%
%               TIMING
%                   (vector) TIMING(T) is the time associated with
%                   TSERIES_MEAN(T,:). The first volume is assumed to
%                   correspond to time 0.
%
%       TSERIES_AVG
%           (cell of string, default {tseries_avg_<BASE_MASK>.mat})
%           FILES_OUT.TSERIES_MEAN{L} is derived using all entries of 
%           FILES_IN.FMRI and FILES_IN.MASK{L}. Each entry is a MAT file 
%           with the following variables :
%
%               TSERIES_MEAN
%                   (2D array) the mean time series of the ROIs averaged
%                   over all fMRI datasets. TSERIES_MEAN(:,I) is the time
%                   series of region I in FILES_IN.MASK{L}
%
%               TSERIES_STD
%                   (2D array) the standard deviation of the mean regional
%                   time series over all fMRI datasets. TSERIES_STD(:,I) is
%                   standard deviation of the time series in region I in
%                   FILES_IN.MASK{L}
%
%               TIMING
%                   (vector) TIMING(T) is the time associated with
%                   TSERIES_MEAN(T,:). The first volume is assumed to
%                   correspond to time 0.
%
%
%  OPT
%       (structure) with the following fields.
%
%       IND_ROIS
%           (vector, default []) if not empty, the analysis is restricted
%           to the rois whose numbers are included in IND_ROIS.
%
%       FLAG_ALL
%           (boolean, default false) if FLAG_ALL is true, the time series
%           of all the voxels of each roi are saved. Instead of having one
%           variable TSERIES in FILES_OUT.TSERIES, there are multiple
%           variables TSERIES_<NUM_R> where NUM_R is the number of a roi.
%           Note that in this case STD_TSERIES and TIMING are not saved.
%           This option is supported only if FILES_IN.ATOMS is not used.
%
%       FLAG_STD
%           (boolean, default true) save the standard deviation of the time
%           series, as well as the timing information. Otherwise, only the
%           mean time series are saved.
%
%       CORRECTION
%           (structure, default CORRECTION.TYPE = 'mean_var') the temporal
%           normalization to apply on the individual time series before
%           averaging in each ROI. See OPT in NIAK_NORMALIZE_TSERIES.
%
%       NAME_TSERIES
%           (string, default 'tseries') If FILES_IN.FMRI is a mat file,
%           NAME_TSERIES is the name of the variable with the array of
%           time series associated with the atoms.
%
%       FOLDER_OUT
%           (string, default: path of FILES_IN.MASK) If present, all default
%           outputs will be created in the folder FOLDER_OUT. The folder
%           needs to be created beforehand.
%
%       FLAG_VERBOSE
%           (boolean, default 1) if the flag is 1, then the function
%           prints some infos during the processing.
%
%       FLAG_TEST
%           (boolean, default 0) if FLAG_TEST equals 1, the brick does not
%           do anything but update the default values in FILES_IN,
%           FILES_OUT and OPT.
%
% _________________________________________________________________________
% OUTPUTS:
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_BUILD_TSERIES
%
% _________________________________________________________________________
% COMMENTS:
%
% If FILES_IN.FMRI are .mat files, for each region in MASK, the average and
% std time series are derived from all ATOMS which intersect the region.
%
% FILES_OUT.TSERIES_AVG can only be generated if FLAG_ALL is false.
%
% When a string is specified in FILES_IN.FMRI or FILES_IN.MASK, the
% argument is treated as a cell of string with one entry.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008-2010.
%       Centre de recherche de l'institut de Gériatrie de Montréal
%       Département d'informatique et de recherche opérationnelle
%       Université de Montréal, 2011
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : medical imaging, fMRI, time series

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

%% global NIAK variables
niak_gb_vars

%% Syntax
if ~exist('files_in','var')|~exist('files_out','var')|~exist('opt','var')
    error('fnak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_TSERIES(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_tseries'' for more info.')
end

%% input files
list_fields    = {'fmri' , 'mask' , 'atoms'           };
list_defaults  = {NaN    , NaN    , 'gb_niak_omitted' };
files_in = psom_struct_defaults(files_in,list_fields,list_defaults);

if ischar(files_in.fmri)
    files_in.fmri = {files_in.fmri};
end

if ischar(files_in.mask)
    files_in.mask = {files_in.mask};
end

%% output files
list_fields    = {'tseries'         , 'tseries_avg'     };
list_defaults  = {'gb_niak_omitted' , 'gb_niak_omitted' };
files_out = psom_struct_defaults(files_out,list_fields,list_defaults);

%% Options
opt_norm.type     = 'mean_var';
gb_name_structure = 'opt';
gb_list_fields    = {'name_tseries', 'flag_std' , 'flag_all' , 'ind_rois' , 'correction' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {'tseries'     , true       , false      , []         , opt_norm     , true           , false       , ''           };
psom_set_defaults

%% Building default output names
[path_f,name_f,ext_f] = niak_fileparts(files_in.mask{1});
if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end

if isempty(files_out.tseries)
    for num_m = 1:length(files_in.mask)
        [path_m,name_m,ext_m] = niak_fileparts(files_in.mask{num_m});
        for num_f = 1:length(files_in.fmri)
            [path_t,name_t,ext_t] = niak_fileparts(files_in.fmri{num_f});
            files_out.tseries{num_f,num_m} = cat(2,opt.folder_out,filesep,name_t,'_',name_m,'.mat');           
        end
    end
end

if isempty(files_out.tseries_avg)
    if opt.flag_all
        error('IT is not possible to generate FILES_OUT.TSERIES_AVG if FLAG_ALL is true')
    end
    for num_m = 1:length(files_in.mask)
        [path_m,name_m,ext_m] = niak_fileparts(files_in.mask{num_m});
        files_out.tseries_avg{num_m} = cat(2,opt.folder_out,filesep,'tseries_avg_',name_m,'.mat');                  
    end
end

if flag_all & ~strcmp(files_in.atoms,'gb_niak_omitted')
    error('The FLAG_ALL option is not supported with time series');
end


%% If the test flag is true, stop here !
if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The core of the brick starts here %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
niak_gb_vars

if flag_verbose
    msg = sprintf('Extracting time series with a ''%s'' temporal correction',opt.correction.type);
    stars = repmat('*',[length(msg) 1]);
    fprintf('\n%s\n%s\n%s\n',stars,msg,stars);
end

%% Read the atoms
if ~strcmp(files_in.atoms,'gb_niak_omitted')
    [hdr_atoms,vol_atoms] = niak_read_vol(files_in.atoms);
end

%% Extract the time series
opt_tseries.correction = opt.correction;
opt_tseries.flag_all = opt.flag_all;
avg_tseries = cell([length(files_in.mask) 1]);
std_tseries = cell([length(files_in.mask) 1]);
for num_f = 1:length(files_in.fmri)
    
    if flag_verbose
        fprintf('Dataset %s...\n',files_in.fmri{num_f});
    end
    clear tseries timing
    
    if ~strcmp(files_in.atoms,'gb_niak_omitted')
        data = load(files_in.fmri{num_f});
        atoms_tseries = data.(opt.name_tseries);
        if isfield(data,'timing')
            timing = data.timing;
        else
            timing = 1:size(atoms_tseries,1);
        end
    else
        [hdr,vol] = niak_read_vol(files_in.fmri{num_f}); % read fMRI data
        timing = (0:(size(vol,4)-1))*hdr.info.tr;
        timing = timing(1:size(vol,4)); % An apparently useless line to get rid of a really weird bug in Octave
    end
    
    for num_m = 1:length(files_in.mask)
        clear tseries_*
        
        %% Read the mask
        [hdr_mask,mask] = niak_read_vol(files_in.mask{num_m});
        mask = round(mask);
        if ~isempty(ind_rois)
            mask(~ismember(mask,ind_rois)) = 0;
        end
        list_num_roi = unique(mask(mask~=0))';
        
        if flag_all
            for num_r = list_num_roi
                instr_tseries = sprintf('tseries_%i = niak_build_tseries(vol,mask==%i,opt_tseries);',num_r,num_r);
                eval(instr_tseries);
            end
        else
            if ~strcmp(files_in.atoms,'gb_niak_omitted')
                tseries = zeros([size(atoms_tseries,1) max(mask(:))]);
                tseries_std = zeros([size(atoms_tseries,1) max(mask(:))]);
                atoms_v = vol_atoms(mask>0);
                mask_v = mask(mask>0);
                for num_r = 1:max(mask(:))
                    ind = unique(atoms_v(mask_v==num_r));
                    ind = ind(ind~=0);
		    if ~isempty(ind)
	                tseries(:,num_r) = mean(atoms_tseries(:,ind),2);
        	        tseries_std(:,num_r) = std(atoms_tseries(:,ind),[],2);
                    else
                        tseries(:,num_r) = NaN;
                        tseries_std(:,num_r) = NaN;
                    end
                end
            else
                [tseries,tseries_std] = niak_build_tseries(vol,mask,opt_tseries); % extract the time series in the mask
            end
        end
        
        if ~ischar(files_out.tseries)
            if flag_all
                save(files_out.tseries{num_f,num_m},'tseries*'); % Save outputs
            else
                if flag_std
                    save(files_out.tseries{num_f,num_m},'tseries','tseries_std','timing'); % Save outputs
                    if ~ischar(files_out.tseries_avg)
                        if num_f == 1
                            avg_tseries{num_m} = tseries;
                            std_tseries{num_m} = tseries.^2;
                        else
                            avg_tseries{num_m} = tseries + avg_tseries{num_m};
                            std_tseries{num_m} = tseries.^2 + std_tseries{num_m};
                        end
                    end
                else
                    save(files_out.tseries{num_f,num_m},'tseries'); % Save outputs
                    if ~ischar(files_out.tseries_avg)
                        if num_m == 1
                            avg_tseries{num_m} = tseries;
                        else
                            avg_tseries{num_m} = tseries + avg_tseries{num_m};
                        end
                    end
                end
                
            end
        end
    end
end

if ~ischar(files_out.tseries_avg)
    N = length(files_in.fmri);
    for num_m = 1:length(files_in.mask)
        tseries = avg_tseries{num_m}/N;
        if flag_std
            tseries_std = sqrt(std_tseries{num_m}/N - tseries.^2);
            save(files_out.tseries_avg{num_m},'tseries','tseries_std','timing');
        else
            save(files_out.tseries_avg{num_m},'tseries');
        end
    end
end
