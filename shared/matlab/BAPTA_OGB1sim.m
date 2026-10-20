function [time,Ca_f,OGB_Ca] = BAPTA_OGB1sim(kon_B,koff_B,Ca1,Btots)
%BAPTA_OGB1sim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Summary: Runs simulation of OGB1 response to calcium step in buffer system
%with specified kinetic properties. Typical approximations for rate
%constants of BAPTA and EGTA are included in the parameters section.
%Simulation assumes instantaneous mixing of low and high Ca2+ boluses upon
%introduction to maturation tubing.
%
%Note that the constants are implemented here to give a Kd of 2E-7M, an
%overestimate for BAPTA, OGB1, and EGTA.
%
%   Inputs:
%       kon_B - on rate constant for the buffer
%       koff_B - off rate constant
%       Ca1 - Ca2+ concentration of the step buffer
%       Btots - vector of buffer concentrations, 0 state and clamp
%
%   Outputs:
%       time - downsampled time from simulation
%       Ca_f - downsampled free calcium
%       OGB_Ca - downsampled bound OGB1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%with no args, input typical sample values
if nargin==0
    close all;
    kon_B = 5e8;
    koff_B = 100;
    Ca1 = 1.2e-6;
    Btots = [1.4e-5,1.4e-3];
end

%Parameters and setup
%EGTA params %kon_B = 5e7; %koff_B = 10;
%BAPTA params %konB = 5e8; %koff_B = 100
%Bparams, form: {[kon_B,koff_B],[B_tot0,B_totSS]};
Bparams = {[kon_B,koff_B],Btots};%1.4e-3 for SS, and 1.4e-5 for 0? 1.4e-3 same for both originally? -yes, per 

%OGB params
kon_OGB = 5e8;
koff_OGB = 75;
OGB_tot = 1;

%Time
dt = 1e-8;%10 nansecond steps, but output is downsampled to 1usec
tSpan = [0,0.050];
time = tSpan(1):dt:tSpan(2);
dSamp = 100;%factor by which to downsample outputs
CaEnd = length(time);%number of simulated datapoints required to see clamp efficiency
    %for EGTA in Ca_f trace

%Doing the steady state stuff
%Init conditions in unmixed buffers
%Good wedge value for seeing diff in EGTA and BAPTA buffers is Ca1 = 1.55e-3;
Ca2 = 0;%levels approximated with Fura4F in water used for making buffers
%Solve init Ca_f, B, B_Ca
%B_init = [Ca_f,B,B_Ca];
B_init = solveBinit([Ca2,Ca1],Bparams);


%%%%%%Simulation%%%%%%%

%Declaring States immediately upon instantaneous mixing
%BAPTA

B = zeros(1,length(time)+1);B(1) = B_init(2);
B_Ca = zeros(1,length(time)+1);B_Ca(1) = B_init(3);
%Ca_f
Ca_f = zeros(1,length(time)+1);Ca_f(1) = B_init(1);
%OGB1
OGB = OGB_tot;
OGB_Ca = zeros(1,length(time)+1);OGB_Ca(1) = 0;

%Run simulation
for i = 1:length(time)+1
    %Buffer evolution
    %B
    B(i+1) = B(i) + dt*...
        (koff_B*B_Ca(i)...%entering 
        - kon_B*B(i)*Ca_f(i));%exiting
    %B_Ca
    B_Ca(i+1) = B_Ca(i) + dt*...
        (kon_B*B(i)*Ca_f(i)...%entering
        - koff_B*B_Ca(i));%exiting
    %OGB evolution
    %OGB
    OGB = OGB + dt*...
        (koff_OGB*OGB_Ca(i)...%entering
        - kon_OGB*OGB*Ca_f(i));%exiting
    %OGB_Ca
    OGB_Ca(i+1) = OGB_Ca(i) + dt*...
        (kon_OGB*OGB*Ca_f(i)...%enterin
        - koff_OGB*OGB_Ca(i));%exiting
    
    CaBuffered = -kon_B*B(i)*Ca_f(i) + koff_B*B_Ca(i);%1Ca times net
    
        
    %Ca_f calculation
    Ca_f(i + 1) = Ca_f(i) + dt*(CaBuffered);

end
Ca_f = Ca_f(1:dSamp:CaEnd);
B = B(1:dSamp:CaEnd);
B_Ca = B_Ca(1:dSamp:CaEnd);
time = time(1:dSamp:end);
OGB_Ca = OGB_Ca(1:dSamp:end);
if nargin==0
    %Make summary plots
    figure;
    plot(1000*time,OGB_Ca);
    title('OGB_{Ca}')
    %set(gca,'ylim',[B_Ca(end)*0.9995,B_Ca(end)*1.0005]);

    figure;
    plot(1000*time(1:length(Ca_f)),Ca_f);
    title('Ca_f')
    %set(gca,'ylim',[Ca_f(end)*0.9995,Ca_f(end)*1.0005]);
    
    
    figure;hold on;
    plot(1000*time(1:length(Ca_f)),B);
    plot(1000*time(1:length(Ca_f)),B_Ca);
    title('Buffer');legend('Unbound','Bound');
    error('Call of function without inputs returns no outputs');
end
end

function B_init = solveBinit(ca,params)
%Solves the initial state of the clamp buffer system assuming instantaneous
%mixing but finite buffer equilibration
Kd = params{1}(2)/params{1}(1);
if ca(1)<=ca(2)%On rate exp concentrations
    B_tot = params{2};
else%off rate exp concentrations
    B_tot = params{3};
end

%[Ca] in each bolus
Ca_tot0 = B_tot(1)*ca(1)/(Kd + ca(1)) + ca(1);%For 0 starts, true value of Ca_f<2e-10M {Ca]_free
Ca_totSS = 2*(sum(B_tot)/2*ca(2)/(ca(2) + Kd) + ca(2)) - Ca_tot0;%

%Get initial buffer and Ca_f states via quadratic formula
A = 1;
B1 = -(Kd + B_tot(1) + Ca_tot0);B2 = -(Kd + B_tot(2) + Ca_totSS);
C1 = B_tot(1)*Ca_tot0; C2 = B_tot(2)*Ca_totSS;
BCa_0 = (-B1 - sqrt(B1^2 - 4*A*C1))/2*A;
BCa_SS = (-B2 - sqrt(B2^2 - 4*A*C2))/2*A;
%Conservation of mass for free calcium and buffer
Ca_f0 = Ca_tot0 - BCa_0;Ca_fSS = Ca_totSS - BCa_SS;
B_0 = B_tot(1) - BCa_0;B_SS = B_tot(2) - BCa_SS;

%Initial states
B_init = zeros(3,1);
B_init(1) = (Ca_f0 + Ca_fSS)/2;%initial free calcium
B_init(2) = (B_0 + B_SS)/2;%initial unbound buffer
B_init(3) = (BCa_0 + BCa_SS)/2;%initial bound buffer
end