function cmap = k2colorCmap(color,nstep)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%k2colorCmap
%Joey Broussard
%06/29/2018
%UC Davis, Tian Lab
%
%This function supplies a color map from black to the specified color of
%size nstep.
%
%   Inputs:
%       color - target color for the top of the map
%       nstep - number of steps in the color map
%   
%   Output:
%       cmap - target color map
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%convert recognized char or non-double type values to double float triplets
%in RGB
if length(color)~=3
    color = convert_color(color);
end

%Construct map
cmap = [linspace(0,color(1),nstep)',...%R
    linspace(0,color(2),nstep)',...%G
    linspace(0,color(3),nstep)'];%B