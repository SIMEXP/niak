function [files_in,files_out,opt] = niak_demo_sica(path_demo)
%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_SICA
%
% This is a script to demonstrate the usage of :
% NIAK_BRICK_SICA
%
% SYNTAX:
% NIAK_DEMO_SICA(PATH_DEMO)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS) 
%       the full path to the NIAK demo dataset. The dataset can be found in 
%       multiple file formats at the following address : 
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% _________________________________________________________________________
% OUTPUTS:
%
% _________________________________________________________________________
% COMMENTS:
%
% This script will run a spatial independent component analysis on the
% functional data of subject 1 (motor condition), and use the default names
% of the outputs.
%
% It will also select the independent components using a spatial prior map.
% and suppress the selected component (the spatial map is actually not in
% the same space as the functional data, so the selection is pretty random,
% but this is to demonstrate how to use the scripts).
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

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

if nargin>=1
    gb_niak_path_demo = path_demo;
end

niak_gb_vars
%% Setting input/output files
switch gb_niak_format_demo
    
    case 'minc2' % If data are in minc2 format
        
        files_demo = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc');
        
    case 'minc1' % If data are in minc1 format

        files_demo = cat(2,gb_niak_path_demo,filesep,'func_motor_subject1.mnc.gz');

    otherwise 
        
        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',gb_niak_format_demo)
        
end

%%%%%%%%%%%%%%%%
%% Mask brain %%
%%%%%%%%%%%%%%%%
files_in_mask  = files_demo;
files_out_mask = '';
[files_in_mask,files_out_mask,opt_mask] = niak_brick_mask_brain(files_in_mask,files_out_mask);

%%%%%%%%%%%
%% SICA %%%
%%%%%%%%%%%
files_in_sica.fmri   = files_demo;
files_in_sica.mask   = files_out_mask;
files_out_sica.space = ''; % The default output name will be used
files_out_sica.time  = ''; % The default output name will be used
opt_sica.nb_comp     = 10; % Estimate 10 components
opt_sica.flag_test   = 0;  % This is not a test, the spatial ICA is actually performed
[files_in_sica,files_out_sica,opt_sica] = niak_brick_sica(files_in_sica,files_out_sica,opt_sica);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Component selection : ventricle %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
files_in_comp_sel.fmri       = files_demo;
files_in_comp_sel.component  = files_out_sica.time;
files_in_comp_sel.mask       = cat(2,gb_niak_path_niak,filesep,'template',filesep,'roi_ventricle.mnc');
%files_in_comp_sel.component_to_keep = cat(2,gb_niak_path_demo,filesep,'motor_design.dat');
files_out_comp_sel           = '';
opt_comp_sel.flag_test       = 0;
[files_in_comp_sel,files_out_comp_sel,opt_comp_sel] = niak_brick_component_sel(files_in_comp_sel,files_out_comp_sel,opt_comp_sel);

%%%%%%%%
%% QC %%
%%%%%%%%
files_in_qc.space    = files_out_sica.space;
files_in_qc.time     = files_out_sica.time;
files_in_qc.mask     = files_out_mask;
files_in_qc.score{1} = files_out_comp_sel;
files_out_qc         = '';
opt_qc.labels_score  = {'ventricle'};
opt_qc.threshold     = 0.15;
[files_in_qc,files_out_qc,opt_qc] = niak_brick_qc_corsica(files_in_qc,files_out_qc,opt_qc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Suppression of physiological noise %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
files_in_supp.fmri       = files_demo;
files_in_supp.space      = files_out_sica.space;
files_in_supp.time       = files_out_sica.time;
files_in_supp.mask_brain = files_out_mask;
files_in_supp.compsel{1} = files_out_comp_sel;
files_out_supp           = '';
opt_supp.flag_test       = 0;
opt_supp.threshold       = 0.15;
[files_in_supp,files_out_supp,opt_supp] = niak_brick_component_supp(files_in_supp,files_out_supp,opt_supp);
