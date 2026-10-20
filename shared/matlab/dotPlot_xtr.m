function dotPlot_xtr( data,groupNum,thres,moveStep,varargin )
%DOTPLOT_XTR Summary of this function goes here
%Give a dot plot rather than scatter plot by Taorong Xie(taorongxie@gmail.com), 2011
%
%   Detailed explanation goes here
%   Give a dot plot for one data group. It could rerun the function by
%   changing the 'data' and 'groupNum' for multi-group. It should run the
%   function one times for each group, and they will show in the same 
%   diagram. The dot plot could also combine with box plot.
%
%   Syntax
%       dotPlot_xtr( data )
%       dotPlot_xtr( data,groupNum )
%       dotPlot_xtr( data,groupNum,thres )
%       dotPlot_xtr( data,groupNum,thres,moveStep )
%   Description
%       data --     data of one group
%       groupNum -- the x-position of this data group. Defaut value: 1
%       thres --    the maximum ratio of every two data's split to mean value
%                   which can stay in the same column (x-position). Defaut value: 0.1
%       moveStep -- the distance of each column. Defaut value: 0.05
if ~exist('thres','var')
    thres = 0.1;
end
if ~exist('groupNum','var')
    groupNum = 1;
end
if ~exist('moveStep','var')
    moveStep = 0.05;
end
if size(varargin,1)~=0
    color = varargin{1};
end
data = data(:);
ave_data = mean(data);
length = size(data,1);
x = zeros(length,1)+groupNum;
y = sort(data,1);
ind_M = zeros(length,1);
ind_R = ind_M;
ind_L = ind_M;
ind_M = [1:1:length]';
n_ind_M = ind_M;
num_excludeM = 1;
while num_excludeM > 0
    num_excludeM = 0;    
    for i = 1:1:numel(n_ind_M)-2        
        if ( y(n_ind_M(i+1))-y(n_ind_M(i)) )/ave_data < thres
            if mean(x) <= groupNum
                x(n_ind_M(i+1)) = x(n_ind_M(i+1)) + moveStep;
                ind_R(n_ind_M(i+1)) = n_ind_M(i+1);
            else
                x(n_ind_M(i+1)) = x(n_ind_M(i+1)) - moveStep;
                ind_L(n_ind_M(i+1)) = n_ind_M(i+1);
            end
            n_ind_M(i+1) = 0;
            num_excludeM = num_excludeM + 1;
            break
        end         
    end      
    n_ind_M = n_ind_M(n_ind_M~=0);
end
if ( y(n_ind_M(numel(n_ind_M)))-y(n_ind_M(numel(n_ind_M)-1)) )/ave_data < thres
    if mean(x) <= groupNum
        x(n_ind_M(numel(n_ind_M)-1)) = x(n_ind_M(numel(n_ind_M)-1)) + moveStep;
        ind_R(n_ind_M(numel(n_ind_M)-1)) = n_ind_M(numel(n_ind_M)-1);
    else
        x(n_ind_M(numel(n_ind_M)-1)) = x(n_ind_M(numel(n_ind_M)-1)) - moveStep;
        ind_L(n_ind_M(numel(n_ind_M)-1)) = n_ind_M(numel(n_ind_M)-1);
    end
end
ind_R = ind_R(ind_R~=0);
be_excludeR = ind_R;
while numel(be_excludeR) > 1
    n_be_excludeR = zeros(numel(be_excludeR),1);
    n_ind_R = be_excludeR;
    num_excludeR = 1;
    while num_excludeR > 0
        num_excludeR = 0;      
        for i = 1:1:numel(n_ind_R)-1
            if ( y(n_ind_R(i+1))-y(n_ind_R(i)) )/ave_data < thres
                x(n_ind_R(i+1)) = x(n_ind_R(i+1)) + moveStep;     
                n_be_excludeR(n_ind_R(i+1)) = n_ind_R(i+1);                 
                n_ind_R(i+1) = 0;
                num_excludeR = num_excludeR + 1;
                break
            end
        end
        n_ind_R = n_ind_R(n_ind_R~=0);  
    end
    n_be_excludeR = n_be_excludeR(n_be_excludeR~=0);
    clear be_excludeR
    be_excludeR = n_be_excludeR;
end
ind_L = ind_L(ind_L~=0);
be_excludeL = ind_L;
while numel(be_excludeL) > 1
    n_be_excludeL = zeros(numel(be_excludeL),1);
    n_ind_L = be_excludeL;
    num_excludeL = 1;
    while num_excludeL > 0
        num_excludeL = 0;      
        for i = 1:1:numel(n_ind_L)-1
            if ( y(n_ind_L(i+1))-y(n_ind_L(i)) )/ave_data < thres
                x(n_ind_L(i+1)) = x(n_ind_L(i+1)) - moveStep;     
                n_be_excludeL(n_ind_L(i+1)) = n_ind_L(i+1);                 
                n_ind_L(i+1) = 0;
                num_excludeL = num_excludeL + 1;
                break
            end
        end
        n_ind_L = n_ind_L(n_ind_L~=0);  
    end
    n_be_excludeL = n_be_excludeL(n_be_excludeL~=0);
    clear be_excludeL
    be_excludeL = n_be_excludeL;
end
gca;
hold on
mm = scatter(x,y,10,color,...
    'markerfacecolor',color,'markeredgealpha',0,'markerfacealpha',0.5);%'.','markersize',6,'markeredgecolor',color);
end