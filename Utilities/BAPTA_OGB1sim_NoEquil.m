function [time,OGB_Ca] = BAPTA_OGB1sim_NoEquil(Ca)
%BAPTA_OGB1sim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Summary: Runs simulation of OGB1 response to calcium step in buffer system
%with specified kinetic properties. Typical approximations for rate
%constants of BAPTA and EGTA are included in the parameters section.
%Simulation assumes instantaneous clamp value, thus Ca_f does not vary.
%
%Note that the constants are implemented here to give a Kd of 2E-7M, an
%overestimate for OGB1. Clamping buffer is not included as explicit
%definition unneccesary with instantaneous clamp.
%
%   Inputs:
%       Ca1 - Ca2+ concentration of the step buffer
%
%   Outputs:
%       time - downsampled time from simulation
%       Ca_f - downsampled free calcium
%       OGB_Ca - downsampled bound OGB1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%with no args, input typical sample values
if nargin==0
    close all;
    Ca = 1e-7;
end

%Parameters and setup
%OGB params
kon_OGB = 5e8;
koff_OGB = 75;
Kd_OGB = koff_OGB/kon_OGB;
OGB_tot = 1;

%Time, Ca0
Ca0 = 0;
dt = 1e-8;%10 nansecond steps, but output is downsampled to 1usec
tSpan = [0,0.050];
time = tSpan(1):dt:tSpan(2);
dSamp = 100;%factor by which to downsample outputs
CaEnd = 500000;%number of simulated datapoints required to see clamp efficiency
    %for EGTA in Ca_f trace

%Doing the steady state stuff
OGB_Ca0 = Ca0/(Kd_OGB + Ca0);%Hill relationship
OGB0 = OGB_tot - OGB_Ca0;%conservation mass

%%%%%%Simulation%%%%%%%

%Declaring States immediately upon instantaneous clamp
%OGB1
OGB = OGB0;
OGB_Ca = zeros(1,length(time)+1);OGB_Ca(1) = OGB_Ca0;

%Run simulation
for i = 1:length(time)+1
    %OGB evolution
    %OGB
    OGB = OGB + dt*...
        (koff_OGB*OGB_Ca(i)...%entering
        - kon_OGB*OGB*Ca);%exiting
    %OGB_Ca
    OGB_Ca(i+1) = OGB_Ca(i) + dt*...
        (kon_OGB*OGB*Ca...%enterin
        - koff_OGB*OGB_Ca(i));%exiting

end
time = time(1:dSamp:end);
OGB_Ca = OGB_Ca(1:dSamp:end);
if nargin==0
    %Make summary plots
    figure;
    plot(1000*time,OGB_Ca);
    title('OGB_{Ca}')
    %set(gca,'ylim',[B_Ca(end)*0.9995,B_Ca(end)*1.0005]);

    error('Call of function without inputs returns no outputs');
end
end