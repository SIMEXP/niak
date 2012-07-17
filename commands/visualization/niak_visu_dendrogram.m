function niak_visu_dendrogram(X,IM,expH)
% Plot a dendogram from a hierarchy
%
% SYNTAX:
% NIAK_VISU_DENDROGRAM(HIER)
%
% _________________________________________________________________________
% INPUTS:
%
% HIER      
%       (matrix) must have the following form:
%             Column 1: Level of new link
%             Column 2: Entity no x
%             Column 3: joining entity no y
%             Column 4: To form entity no z
%             Where the entity numbers take the values 1 to number of
%             entities, and the new entity numbers carry on increasing
%             numerically.
%
% _________________________________________________________________________
% OUTPUTS:
%
% A dendrogram representation of the hierarchy in a figure.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_HIERARCHICAL_CLUSTERING, 
%
% _________________________________________________________________________
% COMMENTS:
%
% EXAMPLE:
% hier =
% 2.1     1     2     6
% 2.8     4     5     7
% 4.3     3     7     8
% 5.9     6     8     9
%
% Written by Paul Terrill, July 1996.
% E-mail: pkt1@ukc.ac.uk
% Modified by P.Bellec, 2003
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : hierarchical clustering, dendrogram

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

if X(1,1)<=X(end,1)
    flag_sim = false;
else
    flag_sim = true;
    X(:,1) = -X(:,1);
end

% Notes:
% sc holds position of entities along the x-axis
% ct holds x co-ordinate used for plotting
% yc holds y coord according to level of joins

if iscell(X);
    nb_dendo = length(X);
    M = sqrt(nb_dendo);
    N = ceil(nb_dendo/M);
    for i = 1:nb_dendo
        subplot(M,N,i)
        if nargin == 2
            dendogram(X{i},IM{i});
        else
            dendogram(X{i});
        end
    end
else
    [m,n]=size(X);
    
    % Firstly sort out the order that the entities appear on
    % the x-axis and stor in sc
    
    sc=X(m,[2 3]);                   
    for i=1:m-1
        j=m-i;
        l=length(sc);
        sci=find(sc==X(j,4));        
        if isempty(sci)
            sc = [X(j,[2 3]) sc(1:l)];
        else
            sc(sci)=[];
            sc=[sc(1:sci-1) X(j,[2 3]) sc(sci:l-1)];
        end
    end
    
    rg=max(X(:,1))-min(X(:,1));
    ymin=min(X(:,1))-(rg)/10;
    ymax=max(X(:,1))+(rg)/10;
    if ymin==ymax
        ymax = 1;
        ymin = 0;
    end
%    clf
    axis([0 m+1 ymin ymax])                    % Set axis ranges
    set(gca,'XTick',[1:m+1])                   % Set position of X tic marks
    set(gca,'XTickLabel',sc(1:m+1))            % Set x tic labels 
    hold on
    
    if flag_sim
        list_y = (ymin:rg/10:ymax);
        set(gca,'Ytick',list_y);
        set(gca,'YTickLabel',-list_y);
    end
    if nargin == 3
        yc = expH(1,:);
    else
        yc=ymin*ones(1,m+1);                       % Set initial yc as x-axis
    end
    ct=1:m+1;                                  % Set initial x co-ord for plotting
    i = 1;
    while (i<=m)&&(X(i,1)~=Inf)
        y10=yc(X(i,2));
        y20=yc(X(i,3));
        y2=X(i,1);                               % y2 = level of join
        x1=ct(find(ct(X(i,2))==sc));             % Find plotting co-ords for
        x2=ct(find(ct(X(i,3))==sc));             % the entities joined                
        plot([x1 x1],[y10 y2]);                  % Plot first vertical line
        plot([x2 x2],[y20 y2]);                  % Plot second vertical line
        plot([x1 x2],[y2 y2]);                   % Plot horizontal connecting line
        if nargin > 2
            text((x1+x2)/2,y2+(ymax-ymin)*0.02,num2str(IM(i),2),'FontSize',12,'FontWeight','bold');
        end
        ct=[ct (x1+x2+0.0001)/2];                %
        sc=[sc (x1+x2+0.0001)/2];                % Update ct, sc and yc
        yc=[yc y2];                              %
        i = i+1;
    end
    ylabel('Level')
end