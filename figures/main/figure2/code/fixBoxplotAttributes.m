function fixBoxplotAttributes(h,nGroup,colors,endCap,linWid,outMarker)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fixBoxplotColors
%Joey Borussard
%PNI 12/7/2020
%
%This function changes the appearance of matlab boxplot output figure
%to 1) make all lines the same color, 2) make all lines solid, 3) remove
%endcaps, and 4) makes outliers invisible (the idea being to use this in
%conjunction with a dot plot tool that puts these back);
%
%   Inputs:
%       h - handle for the current axis
%       nGroup - number of groups in the boxplot
%       colors - mx3 color map. These will applied sequentially to the data
%           if m = nGroup, else the first row will be repeated
%       linWid - width of the lines
%       endCap - boolean for if we want endcap
%       outMarker - marker symbol to mark outliers in the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Isolate boxplot elements from current axes
h = findall(h,'Tag','boxplot');
h = h.Children;

%Handle input cases
if nargin==2
    colors = repmat([0,0,0],length(h)/7,1);
    endCap = 0;
    linWid = 1;
    outMarker = '+';
elseif nargin == 3
    endCap = 0;
    linWid = 1;
    outMarker = '+';
elseif nargin ==4
    linWid = 1;
    outMarker = '+';
elseif nargin==5
    outMarker = '+';
end
if size(colors,1)~=nGroup
    colors = repmat(colors(1,:),nGroup,1);
end
colors = flipud(colors);

%Remove endcaps, set outliers symbols as specified
if ~endCap
    set(h(contains({h.Tag},'Adjacent')),'linestyle','none')
end
set(h(contains({h.Tag},'Outliers')),'Marker',outMarker)

%Specifying different box, median, and whisker locations, set to target
%properties
targetLines = [2,3,4,5,6,7];
for i = 1:nGroup
    targets = i+size(colors,1)*(targetLines-1);
    set(h(targets),'linewidth',linWid,'color',colors(i,:),'linestyle','-')
    %Do color for outlier symbols
    set(h(i),'markeredgecolor',colors(i,:));
end
