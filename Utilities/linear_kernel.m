function [DFF_synth] = linear_kernel(params,spikes,time)
%%%
%Returns the synthetic DFF trace that results from the a convolution of
%spike times with a linear kernel desribed by parameters as below
%
%   Inputs:
%       params - vector as [tau_d1,tau_r,Fm]
%           tau_d1 - decay inverse rate constant (s^-1)
%           tau_r - rise inverse rate constant (s^-1)
%           Fm - scaling factor that sets maximum amplitude of response
%       spikes - vector of spike times
%       time - vector of time
%
%   Ouputs:
%       DFF_synth - output fluorescence trace as DFF
%%%
% unpack params
tau_d1 = params(1);tau_r = params(2);
Fm = params(3);%

% functions
%c(t) spike convolution
h = @(x,spike) Fm.*(exp(-(x-spike)/tau_d1)).*...%slow decay
    (1 - exp(-(x-spike)/tau_r));%rise

% Timing
t = time(1):0.001:time(end);
spikes = round(spikes,3);

% Get c(t) per spike
DFF = 0*t;
for i=1:length(spikes)
    u = zeros(1,sum(t<spikes(i)));
    thisc = [u,h(t(t>=spikes(i)),spikes(i))];
    DFF = DFF+thisc;
end

% interpolate on time requested time basis and return
DFF_synth = interp1(t,DFF,time,'linear','extrap');