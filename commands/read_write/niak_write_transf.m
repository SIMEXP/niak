function flag = niak_write_transf(transf,file_name)
%
% _________________________________________________________________________
% SUMMARY NIAK_WRITE_TRANSF
%
% Save a lsq12 transformation matrix into an xfm file
%
% _________________________________________________________________________
% SYNTAX
%
% [FLAG,MSG] = NIAK_WRITE_TRANSF(TRANSF,FILE_NAME)
%
% _________________________________________________________________________
% INPUTS
%
% TRANSF        
%       (matrix 4*4) a classical matrix representation of an lsq12
%       transformation.
%
% FILE_NAME     
%       (string) the name of the xfm file (usually ends in .xfm)
% 
% _________________________________________________________________________
% OUTPUTS
%
% FLAG          
%       (real number) if FLAG == -1, an error occured
%
% _________________________________________________________________________
% SEE ALSO
% NIAK_PARAM2TRANSF, NIAK_TRANSF2PARAM, NIAK_READ_TRANSF
%
% _________________________________________________________________________
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : xfm, minc


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

niak_gb_vars

hf = fopen(file_name,'w');
if hf == -1
    flag = -1;
    error('could not create file %s',file_name)
else
    flag = 1;
end

fprintf(hf,'MNI Transform File\n');
fprintf(hf,'%%Created using NIAK v.%s, %s, by %s\n',gb_niak_version,datestr(now),gb_niak_user)  ;
fprintf(hf,'\nTransform_Type = Linear;\nLinear_Transform =\n');
fprintf(hf,'%s\n',num2str(transf(1,:),15));
fprintf(hf,'%s\n',num2str(transf(2,:),15));
fprintf(hf,'%s;\n',num2str(transf(3,:),15));

fclose(hf);
