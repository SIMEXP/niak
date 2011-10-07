function [y,Ybis] = niak_gaussian_fit(par)
% This function is used by NIAK_CORRECT_VOL, and is not supposed to be used
% independently.
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec, McConnell Brain Imaging Center,
% Montreal Neurological Institute, McGill University, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging

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
 
% INPUT
% par               par(1) is the mean of the gaussian function
%                   par(2) is the standard deviation of the gaussian function
%
% OUTPUTS
% Ybis              value of the gaussian function with parameters par at X (global) 
% y                 quadratic error between Ybis and Y (global)
%                   
% COMMENTS
% Vincent Perlbarg 11/04/06

global niak_gb_X niak_gb_Y
mu = par(1);
sig = par(2);

Ybis = 1/(sqrt(2*pi)*sig)*exp(-0.5*((niak_gb_X-mu)/sig).^2);

y = sum((niak_gb_Y-Ybis).^2);
return