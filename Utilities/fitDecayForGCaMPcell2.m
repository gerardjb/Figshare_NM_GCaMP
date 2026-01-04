function [models,gofs,maxIdx] = fitDecayForGCaMPcell2(t,F,st)
%%%
% Fit a biexponential decay model to the post-peak portion of a trace.
%
% This utility is adapted from the local helper defined in
% `supp_figure1/suppfigure1_A_to_D_code.m` so it can be reused by other
% scripts/functions.
%
% Inputs:
%   t  - time vector (seconds)
%   F  - fluorescence vector (dF/F)
%   st - initialization of the exp2 fit params (optional)
%
% Outputs:
%   models - fit object of type a*exp(b*t) + c*exp(d*t) + e
%   gofs   - adjusted R^2 for the model fit
%   maxIdx - index of the maximum (from smoothed F)
%%%

if nargin < 3
    st = [0.7,-3,0.2,-0.1];
end

models = [];
gofs = nan;
maxIdx = nan;

if isempty(t) || isempty(F) || numel(t) ~= numel(F)
    return;
end

t = t(:);
F = F(:);

% Defining the model
exp2_b = fittype(@(a,b,c,d,e,tt) a*exp(b*tt) + c*exp(d*tt) + e,'independent','tt');

% Get max from smoothed data
F_smooth = smooth(F,9);
[~,maxIdx] = max(F_smooth);
lastIdx = find(t-t(maxIdx)>1.9,1)-1;
if isempty(lastIdx)
    lastIdx = length(F);
end

% Init and bounds for exp2
ub2 = [inf,0,inf,-0.3];
ub2_b = [ub2,0.015];
lb2 = [0,-inf,0,st(2)];
lb2_b = [lb2,-0.005];
st2_b = [st,0];

tt = t(maxIdx:lastIdx)-t(maxIdx);
FF = F_smooth(maxIdx:lastIdx);
weights = ones(1,length(FF));

try
    [fp2_b,fp2_b_gof] = fit(tt,FF,exp2_b,'start',st2_b,'upper',ub2_b,'lower',lb2_b,'weights',weights);
    gofs = fp2_b_gof.adjrsquare;
    models = fp2_b;
catch
    models = [];
    gofs = nan;
end

end

