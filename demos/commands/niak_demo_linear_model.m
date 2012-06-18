function [stab,tseries,opt] = niak_demo_linear_model(opt)
% This is a script to demonstrate how to specify linear models
%
% The code is organized by blocks which can be copy/pasted and executed in 
% a Matlab or Octave session.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Jalloul Bouchkara
%               Centre de recherche de l'institut de Gériatrie de Montréal
%               Département d'informatique et de recherche opérationnelle
%               Université de Montréal, 2012
% Maintainer : pierre.bellec@criugm.qc.ca
% Keywords : linear model

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

%% A toy group model
model_raw.x = [0 23 ; 0 19 ; 0 35 ; 1 19 ; 1 27 ; 1 22];
model_raw.y = [0.1  ; 0.2  ; 0.15 ; 1.1  ; 1.2  ; 1.15];
model_raw.labels_x = { 'sub1' , 'sub2' , 'sub3' , 'sub4' , 'sub5' , 'sub6' };
model_raw.labels_y = { 'sex' , 'age' };

%% test of sex effect
test.single_sex.contrast.sex = 1;
model_n.single_sex = niak_normalize_model(model_raw,test.single_sex);

%% test of sex effect, playing with the order of subjects/covariates
test.single_sex_sel.labels_x = {'sub6','sub2','sub1','sub4'};
test.single_sex_sel.contrast.sex = 1;
test.single_sex_sel.contrast.age = 0;
model_n.single_sex_sel = niak_normalize_model(model_raw,test.single_sex_sel);

%% test of sex effect for subjects over 20 years of age
test.single_sex_20.contrast.sex = 1;
test.single_sex_20.contrast.age = 0;
test.single_sex_20.select.label = 'age';
test.single_sex_20.select.min = 20;
test.single_sex_20.normalize_x.sex = 1;
model_n.single_sex_20 = niak_normalize_model(model_raw,test.single_sex_20);

%% test of sex effect after regressing out age
test.single_sex_reg.contrast.sex = 1;
test.single_sex_reg.contrast.age = 0;
test.single_sex_reg.projection.space = {'age'};
test.single_sex_reg.projection.ortho = {'sex'};
model_n.single_sex_reg = niak_normalize_model(model_raw,test.single_sex_reg);

%% test of the interaction between age and sex 
test.single_sex_int.contrast.sex = 0;
test.single_sex_int.contrast.age = 0;
test.single_sex_int.contrast.sex_x_age = 1;
test.single_sex_int.interaction.label = 'sex_x_age';
test.single_sex_int.interaction.factor{1} = 'sex';
test.single_sex_int.interaction.factor{2} = 'age';
model_n.single_sex_int = niak_normalize_model(model_raw,test.single_sex_int);
