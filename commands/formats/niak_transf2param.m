function [rot,tsl] = niak_transf2param(transf)
%
% _________________________________________________________________________
% SUMMARY NIAK_TRANSF2PARAM
%
% Convert a lsq6 transformation (3 rotations, 3 translations) from the standard
% 4*4 matrix array (y=M*x+T) to the x/y/z rotation and translation
% parameters.
%
% SYNTAX:
% [ROT,TSL] = NIAK_TRANSF2PARAM(TRANSF)
% 
% _________________________________________________________________________
% INPUT:
%
% TRANSF   
%       (4*4 array) An lsq6 transformation, usually seen as a 
%       "voxel-to-world" space transform.
%
% _________________________________________________________________________
% OUTPUTS:
%
% ROT 
%       (array 3*1) the rotation parameters (in x, y and z planes). 
%       Unit is degrees.
%
% TSL 
%       (array 3*1) the translation parameters.
%
% _________________________________________________________________________
% COMMENTS:
%
% This code was written by Giampiero Campa,  
% PhD, Research Assistant Professor
% West Virginia University, Aerospace Engineering Dept.
% Morgantown, WV, 26506-6106, USA, Copyright 1/11/96
% See
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=
% 956&objectType=File
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

O=transf(1:3,4);
R=transf(1:3,1:3);
d=round([0 0 1]*R(:,1)*1e12)/1e12;

if d==1,
   y=atan2([0 1 0]*R(:,2),[1 0 0]*R(:,2));
   p=-pi/2;
   r=-pi/2;

elseif d==-1
   y=atan2([0 1 0]*R(:,2),[1 0 0]*R(:,2));
   p=pi/2;
   r=pi/2;

else 
   sg=vp([0 0 1]',R(:,1));
   j2=sg/sqrt(sg'*sg);
   k2=vp(R(:,1),j2);

   r=atan2(k2'*R(:,2),j2'*R(:,2));
   p=atan2(-[0 0 1]*R(:,1),[0 0 1]*k2);
   y=atan2(-[1 0 0]*j2,[0 1 0]*j2);
end

y1=y+(1-sign(y)-sign(y)^2)*pi;
p1=p+(1-sign(p)-sign(p)^2)*pi;
r1=r+(1-sign(r)-sign(r)^2)*pi;

% takes smaller values of angles

if norm([y1 p1 r1]) < norm([y p r])
    rot = [r1;-p1;y1];
else
    rot = [r;p;y];       
end

rot = (rot/pi)*180; % Conversion in degrees
tsl = O;

function z=vp(x,y)

% z=vp(x,y); z = 3d cross product of x and y
% vp(x) is the 3d cross product matrix : vp(x)*y=vp(x,y).
%
% by Giampiero Campa.  

z=[  0    -x(3)   x(2);
    x(3)    0    -x(1);
   -x(2)   x(1)    0   ];

if nargin>1, z=z*y; end

