function transf = niak_param2transf(rot,tsl)
%
% _________________________________________________________________________
% SUMMARY NIAK_PARAM2TRANSF
%
% Convert rotation and translation parameters to a standard
% 4*4 matrix array (y=M*x+T).
%
% SYNTAX:
% TRANSF = NIAK_PARAM2TRANSF(ROT,TSL)
% 
% _________________________________________________________________________
% INPUTS:
%
% ROT 
%       (array 3*1) the rotation parameters (in x, y and z planes). 
%       Unit is degrees.
%
% TSL 
%       (array 3*1) the translation parameters.
%
% _________________________________________________________________________
% OUTPUTS:
%
% TRANSF   (4*4 array) An lsq6 transformation, usually seen as a
%           "voxel-to-world" space transform.
%
% _________________________________________________________________________
% COMMENTS:
% 
% This code was written by Giampiero Campa,  
% PhD, Research Assistant Professor
% West Virginia University, Aerospace Engineering Dept.
% Morgantown, WV, 26506-6106, USA, Copyright 1/11/96
% See
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=956&objectType=File
%
% Modified by Pierre Bellec, McConnel Brain Imaging Center, Montreal 
% Neurological Institute, McGill University, Montreal, Canada, 2008.
% Changing inputs/outputs formats.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : rigid-body transformation, rotation, Euler angles
%
% See licensing information in the code

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

O=tsl;
r=(rot(1)/180)*pi;
p=(rot(2)/180)*pi;
y=(rot(3)/180)*pi;

R=expm(vp([0 0 1]',y))*expm(vp([0 1 0]',p))*expm(vp([1 0 0]',r));

transf=[ R, O(:); 0 0 0 1 ];

function z=vp(x,y)

% z=vp(x,y); z = 3d cross product of x and y
% vp(x) is the 3d cross product matrix : vp(x)*y=vp(x,y).
%
% by Giampiero Campa.  

z=[  0    -x(3)   x(2);
    x(3)    0    -x(1);
   -x(2)   x(1)    0   ];

if nargin>1, z=z*y; end
