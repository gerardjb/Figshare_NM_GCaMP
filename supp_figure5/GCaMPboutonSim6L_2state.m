function [DFF,G,Ca_f,fTime] = GCaMPboutonSim6L_2state(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GCaMPboutonSim1_2
%%%%
%Gerard Joey Broussard
%Princeton Neuroscience Institute
%
%
%Summary: Based on simple6 model with second intracellular compartment
%
%Model specifies N and C lobes act independently to populate a fully-bound
%high fluorescent state. An inter-process transition rate further controls
%relative contribution and speed of occupancy for each state.
%
% Inputs:
%   params - vector of input parameters: G_tot, gamma, peakAmp, Rf, and
%       t_off
%   expTime - vector of time values in observed experiments. Can pass in
%       multiple concatentated vectors for mulitple trials
%   spikes - time points at which a calcium flux, due to a spike
%       occur. Must be passed in as a cell array with elements
%       corresponding to vector of spike times within each trial
%   
% Outputs:
%   DFF - GCaMP state variable fEuler results converted DFF.
%   G - GCaMP state variable fEuler results.
%
% Parameters:
%
%   %Variable bouton attributes
%   G_tot - total concentration of GCaMP in structure ([M])
%   gamma - extrusion rate, currently does not accout for structure
%       geometry (e.g. for surface area) (s^-1)
%   peakAmp - peak amplitude of AP-gated Ca flux (pA)
%   FWHM - full width at half max of Ca flux due to AP (s)
%
%   %GCaMP fixed parameters (Gparams)
%   Ka_N - microscopic dissociation constant N lobe (M)
%   koff_N - off rate constant N lobe (s^-1)
%   H_N - Hill coefficient N lobe 
%   Ka_C - microscopic dissociation constant C lobe (M)
%   koff_C - off rate constant C lobe (s^-1)
%   H_C - Hill coefficient C lobe
%   kon_P - rate constant to enter fluorecent state (s^-1)
%   koff_P - rate constant to leave fluorescnet state (s^-1)
%   kon_C2N - rate C gate states transition to corresponding N state  (s^-1)
%   koff_C2N - rate N gate states transition to corresponding C state (s^-1)
%   G_tot - total concentration of GCaMP ([M])
%
%   calculate:  kon_N = koff_N/Ka_N^H_N
%               kon_C = koff_C/Ka_C^H_C
%
%   %Cell fixed parameters (Cparams)
%   Ca_0 - basal calcium levels ([M])
%   kon_B - on rate constant for endogenous buffer (s^-1M^-1)
%   koff_B - off rate constant for endogenous buffer (s^-1)
%   b_tot - concentration of endogenous buffer ([M])
%
%
% States:
%   y(1) = N_0 %unbound N
%   y(2) = N_1 %GCaMP, Ca on N lobe
%   y(3) = N_2* %Fluorescent N state
%   y(4) = C_0 %unbound C
%   y(5) = C_1 %GCaMP, Ca on C lobe
%   y(6) = C_2* %Fluorescent C state
%
% Variables:
%   Ca_f = free calcium ([M])
%
% Equations:
%   dN_0/dt = -kon_N*N_0*Ca_f + koff_N*N_1 + kon_C2N*C_0 - koff_C2N*N_0
%   dN_1/dt = kon_N*N_0*Ca_f - koff_N*N_1 - kon_P*N_1 + koff_P*N_2 + kon_C2N*C_1 - koff_C2N*N_1
%   dN_2/dt = kon_P*N_1 - koff_P*N_2 + kon_C2N*C_2 - koff_C2N*N_2
%   dC_0/dt = -kon_C*C_0*Ca_f + koff_C*C_1 - kon_C2N*C_0 + koff_C2N*N_0
%   dC_1/dt = kon_C*C_0*Ca_f - koff_C*C_1 - kon_P*C_1 + koff_P*C_2 - kon_C2N*C_1 + koff_C2N*N_1
%   dC_2/dt = kon_P*C_1 - koff_P*C_2 - kon_C2N*C_2 + koff_C2N*N_2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get params and independent variable values
global const;
const = 'jG8f';

%If no parameters passed, set defaults
%[G_tot,gamma,peakAmp,FWHM,Rf,t_off]
if isempty(varargin)
    close all
    params = [10e-6,20e2,1e-5,2.8e-4,5,0.004,40,0.1];
    Gparams = [...
      2.4815820465738054E-7,...
      42.872562156626792,...
      2.2925053286232377,...
      4.1615502020434435E-7,...
      0.242586292767657,...
      1.7789137249540266,...
      406.59379977617942,...
      180.10354087964473,...
      0.93399842060328775,...
      488.37198084614806,...
      244.48583832558379,...
      81.65224620222466,...
      40.421838289956717,...
      0.00997580968247646...
    ];%
    %ISI = {[0],[0,0.01],[0,0.02],[0,0.05],[0,0.1]};
    ISI = arrayfun(@(x) 0:0.01:0.01*x,[0,1,4,9],'UniformOutput',false);
    expTime = repmat([-0.02:1e-4:1]',length(ISI),1);
    plotOn = 1;
else
    params = varargin{1}{1};
    Gparams = varargin{1}{3};
    expTime = varargin{2};
    %package spikes as cell if necessary
    if ~iscell(varargin{1}{2})
        ISI = {varargin{1}{2}};
    else
        ISI = varargin{1}{2};
    end
end


%Gparams
%states that add brightness
brightStates = [3,4,6,7,9];%
%GParams, form: [Ka_N,koff_N,H_N,...
%   Ka_C,koff_C,H_C,...
%   kon_PN, koff_PN, ...
%   kon_PC, koff_PC, kon_X, koff_X]
% Gparams = [5.1e-7,280,1.6,   1.7e-7,1,2.2,...
%         300,360, 14,38, 14,10];%

%Set params to variables
G_tot = params(1);%5e-6;%M - total dye concentration
gamma = params(2);%s^-1 - Ca extrusion rate
peakAmp = params(3);%pA - level of peak current on pulse
FWHM = params(4);%s - 2*sqrt(2*log(2))*sigma, per DD data
Rf = params(5);%dynamic range of jG7f is 30.2 from Hod et. al. Nat Methods 2019
B_tot = params(6);%adjust timing of the spike application to account for small inconsistencies in the reported times
ISI = cellfun(@(x) x,ISI,'UniformOutput',false);%adding the adjustment to the spike times

%Second state rate stuff. Older paired-pulse fits did not include these
%terms, so use the no-store limit for six-parameter cell fits.
if numel(params) >= 8
    gam_in = params(7);
    gam_r = params(8);
else
    gam_in = 0;
    gam_r = 0;
end
gam_out = gam_in*gam_r;

%Fixed parameters, cell
Ca_0 = 5e-8;%M - basal calcium levels in the cell
kon_B = 1e8;%M^-1s^-1
koff_B = 1e4;%s^-1
%B_tot = 0.004;%M - buffer concentration
kapB = B_tot/(koff_B/kon_B);%binding ratio of endogenous buffer

%Convert Ka to kon values
Gparams(1) = Gparams(2)/(Gparams(1)^Gparams(3));%konN
Gparams(4) = Gparams(5)/(Gparams(4)^Gparams(6));%konC

%Finalize traces times
initDelay = repmat({0},1,numel(ISI));%s delay before first spike
tSpan = [expTime(1),expTime(end)];%s length of simulation
dt = 50e-6;%s temporal precision of simulations
Time = repmat(tSpan(1):dt:tSpan(2),1,numel(ISI));%s time vector for simulations

%Establish points at which time resets, i.e. new trace starts
[~,maxTimeIdxs] = findpeaks(Time);[~,maxExpTimeIdxs] = findpeaks(expTime);
maxTimeIdxs = [0,maxTimeIdxs,length(Time)];
maxExpIdxs = [0,maxExpTimeIdxs',length(expTime)];

%Initializing cell array to hold output forward Euler results
normfit = [];

%% Make Calcium flux due to spikes if nargin==0, get simulation initial conditions
%Make calcium traces based on input parameters
CaPulses = getCaPulse(Time,maxTimeIdxs,ISI,initDelay,dt,peakAmp,FWHM);
nCa = length(CaPulses);

%Initialize the steady state values for the simulation
G_init = solveGinit(Ca_0,Gparams)'*G_tot;
G_0 = solveGinit(0,Gparams)'*G_tot;
B_Ca_init = kon_B*Ca_0/(kon_B*Ca_0 +koff_B)*B_tot;%amount of bound endogenous buffer at initialization
%Correct Rf for saturated occupancy of fully-bound state
G_sat = solveGinit(1e-2,Gparams)'*G_tot;
F_0 = contrastStretch(sum(G_init(brightStates)),[sum(G_0(brightStates)),sum(G_sat(brightStates))],[1,Rf]);

%% Run simulation
tic;
for iCa_0 = 1:nCa   
    
    %Get variables subsets for this Ca_0
    thisCaPulse = CaPulses{iCa_0};
    
    %Get time for this simulation
    time = Time(maxTimeIdxs(iCa_0)+1:maxTimeIdxs(iCa_0 + 1));
    exptime = expTime(maxExpIdxs(iCa_0)+1:maxExpIdxs(iCa_0 + 1));
    
    %Run simulation on observed time points
    nTime = floor((time(end)-time(1))/dt);
    [G,fTime,Ca_f,Ca_in] = fEuler(nTime,dt,Ca_0,...
        G_init,Gparams,G_tot,brightStates,...
        B_Ca_init,kapB,...
        gam_in,gam_out,...
        gamma,thisCaPulse);
    fTime = fTime+Time(1);
    
    %pack out simulation results on same timepoints as data
    %streched from [0,G_sat] to [1, Rf]
    Gbright = sum(G(:,brightStates),2);%
    Gbright = contrastStretch(Gbright,[sum(G_0(brightStates)),sum(G_sat(brightStates))],[1,Rf]);
    Gbright = interp1(fTime,Gbright,exptime,'linear','extrap')';
    
    %Append simulation results to full trace
    normfit = cat(2,normfit,Gbright);
    
    %On last round, package out bound states as DFF

%     figure;hold on;plot(fTime,Ca_f);plot(fTime,Ca_in);
%     xlabel('time (s)')
%     ylabel('[Ca^{2+}] (M)')
%     legend('Cytoplasmic Ca^{2+}','Intraorganellar Ca^{2+}')
%     set(gca,'fontsize',12)

    if iCa_0==nCa
        DFF = (normfit - F_0)./F_0;% (F - F_0)/F_0
%         figure;
%         plot(reshape(expTime,[],nCa),reshape(DFF,[],nCa));
%         xlabel('time (s)')
%         ylabel('\DeltaF/F')
%         set(gca,'fontsize',12)
        DFF = DFF';

    end


    if any(isnan(Gbright))
        sprintf('instability in ISI number %1.0f',iCa_0)
    end
end%iCa_0


end

%% Function Block
function [G,fTime,Ca_f,Ca_in] = fEuler(nTime,dt,Ca_0,...
    G_init,Gparams,G_tot,brightStates,...
    B_Ca_init,kapB,...
    gam_in,gam_out,...
    gamma,s)
%This function runs a forward Euler simulation. It ensures summation to 1
%of all states after each time step
%Initialize fit matrices and Ca_0 equilibria
fTime = 0:dt:(nTime)*dt;%time;%
G = zeros(nTime-1,length(G_init));
G(1,:) = G_init;

%Buffer
B_Ca = B_Ca_init;

%Calcium
Ca_f = zeros(1,nTime-1);Ca_f(1) = Ca_0;
Ca_in = zeros(1,nTime-1);Ca_in(1) = Ca_0;

%[~,goodIdx] = max(s);
usedye = 1;
%Forward Euler

for i = 1:nTime
    
    %Buffer and free ca fluxes
    B_Ca_flux = kapB/(kapB+1)*s(i);
    Ca_f_flux = 1/(kapB+1)*s(i);
        
    if usedye
        %GCaMP evolution
        Gweight = G_weightMat(Ca_f(i),Gparams);
        G(i+1,:) = G(i,:) + [Gweight*dt*G(i,:)']';
            
        %Calculate fluxes 
        CaBuffered_G = getFlux(Ca_f(i),Gparams,G(i,:));
    else
        CaBuffered_G = 0; 
    end%usedye
    
    %Update endogenous buffer
    dB_Ca = (-gamma*(Ca_f(i)-Ca_0) - CaBuffered_G)...Ca change due to GCaMP buffereing and extrusion
        *kapB/(1+kapB);%amout Ca released by endogenous buffer to maintain binding ratio
    B_Ca = B_Ca + dt*(dB_Ca + B_Ca_flux);
    
    %Ca_f calculation
    CaBuffered = dB_Ca + CaBuffered_G;
    Ca_f(i+1) = Ca_f(i) + ...
        dt*(-gamma*(Ca_f(i) - Ca_0) +...pumped out
        -gam_in*(Ca_f(i) - Ca_0) + gam_out*(Ca_in(i) - Ca_0) +...intracellular store exchange
        Ca_f_flux - CaBuffered);
    Ca_in(i+1) = Ca_in(i) +...
        dt*(gam_in*(Ca_f(i) - Ca_0) - gam_out*(Ca_in(i) - Ca_0));
end


end


function G_init = solveGinit(ca,Gparams)
%Solve initial state of sensor in pre-clamp conditions
Gmat = G_weightMat(ca(1),Gparams);
G_initUnnormed = null(Gmat);
if rank(Gmat)>1
    G_initUnnormed = G_initUnnormed./...
        repmat(sum(G_initUnnormed,1),size(G_initUnnormed,1),1);
    G_init = sum(G_initUnnormed,2);
    return;
elseif size(G_initUnnormed,2)>1
    goodCol = ~any(abs(G_initUnnormed)>1e-15,1);
    G_initUnnormed = G_initUnnormed(:,goodCol);
end
G_init = G_initUnnormed/sum(G_initUnnormed);
end

function Gmat = G_weightMat(ca,Gparams)
%Create linear matrix of G ODE (assumes contant Ca), i.e.
%dotG = Gmat*G
konN = Gparams(1)*ca^Gparams(3);koffN = Gparams(2);
konC = Gparams(4)*ca^Gparams(6);koffC = Gparams(5);
konPN = Gparams(7);koffPN = Gparams(8);
konPC = Gparams(9);koffPC = Gparams(10);
konPN2 = Gparams(11);koffPN2 = Gparams(12);
konPC2 = Gparams(13);koffPC2 = Gparams(14);

Gmat = [-(konN+konC),koffN,koffPN,0,koffC,koffPC,0,0,0;...1
    konN,-(koffN+konPN+konC),0,0,0,0,koffPC2,koffC,0;...2
    0,konPN,-(konC+koffPN),koffC,0,0,0,0,koffPC2;...3
    0,0,konC,-(koffC+konPC2+koffPN2 ),0,0,0,konPN2,0;...4
    konC,0,0,koffPN2,-(koffC+konPC+konN),0,0,koffN,0;...5
    0,0,0,0,konPC,-(koffPC+konN),koffN,0,koffPN2;...6
    0,0,0,0,0,konN,-(koffN+konPN2+koffPC2),konPC2,0;...7
    0,konC,0,0,konN,0,0,-(koffC+koffN+konPC2+konPN2),0;...8
    0,0,0,konPC2,0,0,konPN2,0,-(koffPN2+koffPC2)];%9

end

function CaBuffered_G = getFlux(ca,Gparams,G)
global const;
%Set the Ca2+ GCaMP rate constants
konN = Gparams(1)*ca^Gparams(3);koffN = Gparams(2);
konC = Gparams(4)*ca^Gparams(6);koffC = Gparams(5);
konPN = Gparams(7);koffPN = Gparams(8);
konPC = Gparams(9);koffPC = Gparams(10);
konPN2 = Gparams(11);koffPN2 = Gparams(12);
konPC2 = Gparams(13);koffPC2 = Gparams(14);

%Calculate fluxes per binding site
N = (konN*(G(1) + G(5) + G(6)))...%binding (Note: duplication of konC*G(1) indicates this is a 4 bound state)
    -koffN*(G(2) + G(7)+ G(8)) + ...standard CaM unbinding
    -koffPN*(G(3)) + ...
    -koffPN2*(G(4) + G(9));%unbinding 
C = +(konC*(G(1) + G(2) + G(3)))...binding
    -koffC*(G(5) + G(4) + G(8))+...
    -koffPC*(G(6))+...
    -koffPC2*(G(7) + G(9));%unbinding

%Get net GCaMP Ca2+ buffering
if contains(const,'EF32');Csites = 1;else;Csites=2;end
CaBuffered_G = 2*N + Csites*C;
end

function CaPulses = getCaPulse(Time,maxTimeIdxs,ISI,initDelay,dt,peakAmp,FWHM)
% estimate Ca influx from single AP (75pA, dimensions are 700x700x1200nm, from Maria R. [DD lab])
DCaT = peakAmp;%2Ca(4/3*pi*0.7/2*0.7/2*1.2/2, peakAmp)/1e3;%1e3 corrects mM to M conversion

%Name that Florian gave to what I am calling CaPulses
spikes = {};

% create paired pulse input
for i = 1:numel(ISI)
    %time vector for this trial
    time = Time(maxTimeIdxs(i) + 1:maxTimeIdxs(i + 1));
    
    %Index when first spike occurs
    thisInitDelay = initDelay{i};
    d = round((thisInitDelay-time(1))/dt);
    
    %
    s = zeros(size(time));
    for ii = 1:length(ISI{i})
        s(d+round(ISI{i}(ii)/dt)) = 1;
    end
    sind = find(s);
    % setup gauss function
    %FWHM = 280mu s base
    t = (-0.001:dt:0.001); %[s]
    %FWHM = 2.8e-4;%0.280; %[s] = 2*sqrt(2*log(2))*sigma
    g = exp(-(4*log(2)).*(t./FWHM).^2); %calc Gauss from  FWHM
    Ag = sqrt(2*pi())*FWHM/(2*sqrt(2*log(2))); %Area under graph
    g = DCaT.*g./Ag;% normalize gaussian so area is equivalent to total Ca per AP
    pos = find(s);
    sg = floor((length(g)-1)/2);
    % zeropad 
    s = [zeros(1,sg),s,zeros(1,sg)];
    %shift indices
    pos = pos+sg;
    s(pos) = 0; %reset to zero
    for ii = 1:length(pos)
        s(pos(ii)-sg:pos(ii)+sg) = s(pos(ii)-sg:pos(ii)+sg)+g;
    end
    %remove zeropadding again
    s(1:sg) = [];
    s(end-sg+1:end) = [];
    spikes{i} = s;
    
    if 0%plotOn for Ca QC
        figure(200);hold on;
        subplot(5,1,i);
        yyaxis right
        plot(time,s);
    end
end

CaPulses = spikes;
end

function parseHelper(p)
[~,goodIdxs] = setdiff(p.Parameters,p.UsingDefaults);
for i = 1:length(goodIdxs)
    assignin('caller',p.Parameters{goodIdxs(i)},p.Results.(p.Parameters{goodIdxs(i)}));
end
end
