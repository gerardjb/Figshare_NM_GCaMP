function ftrace = Fitting_function_eig_WD_simple6(ca,Gparams,time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Joey Broussard
%Wang lab, PNI, 20210216
%
%Purpose: Trying out a simplified model with two F states over two Ca
%dependent transitions. Full symmetry model. Re-routing the decay pathways
%to reflect calcium state of the protein. Playing with a new rate constant
%for peptide binding.

%Summary: 
%
%
%Model WD2_9 is an instantiation of the HH-like approach to GCaMP
%fluorescence production. It consists of two gates, each with a Ca unbound,
%Ca bound, and fluorescent state. The transition from Ca bound to
%fluorescent is Ca independnet. 
%
%Params:
%   KaN - gate 1 Ca2+ affinity constant
%   koff_N - gate 1 off rate
%   H_N - cooperativity of gate 1
%   Ka_C - gate 2 Ca2+ affinity constant
%   koff_C - gate 2 off rate
%   H_C - gate 2 cooperativity
%   kon_R - Ca independent on rate constant
%   koff_R - Ca independent off rate constant
%   konN2C - transition from C to N
%   koffN2C - transition from N to C
%   pRatio - increase upper N <-> C; decrease C_Ca <-> C_F
%   
%Gates with states:
%   N <-> N_Ca <-> N_F
%   ^v             ^v
%   C <-> C_Ca <-> C_F
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main case
paramList = {'Ka_N','koff_N','H_N',...
    'Ka_C','koff_C','H_C',...
    'kon_PN','koff_PN','kon_PC','koff_PC',...
    'kon_PN2','koff_PN2','kon_PC2','koff_PC2',...
    'alpha'};
if nargin == 0
    close all;
    %Ca values [start,end]
    ca = [0.5e-7,500e-7];
    %GParams
%Param test set 2: this set gives reasonable fits on SF, but at this state,
%gives low use-dependent slowing.
    Gparams = [
      5.1390896948824609E-7,
      56.494420229735589,
      1.7536414755306042,
      2.3857634183964078E-8,
      0.46120565450064932,
      0.95593875706040665,
      38.5079566561488,
      344.71689671856791,
      0.13587885545199183,
      36.790398429499618,
      59.626155300178226,
      386.10493999325354,
      0.62465189480021766,
      29.381428616059814
    ];% 
%     [6.4e-7,200,1.7,   1.5e-7,1.2,2.8,...
%         160,220, 0.5,30, 3,30,...280,230
%         1];%
%     Gparams = [5.5e-7,200,1.5,   2e-7,1,2,...
%         280,230, 3,33, 23,20,...
%         1];%
%Param test set 1: this set gave a large use-dependent increase and
%appropriate decay on SF, however, the fits to stopped flow increases were
%poor.
%     [12e-7,1000,1.6,   2.5e-7,2,2.7,...
%         150,220, 6,45, 40,20,...
%         1];%
    %time
    dtEig = 0.01e-3;%time steps in analytical sim
    time = [0,logspace(-4,1.5,1000)];%0:dtEig:16;%to 16sec
    close all;
elseif nominal(ca)==nominal('getparamlist')
    ftrace = paramList;
    return;
else
    plotOn = 0;
end

%% Simulations
%State list
stateList = compose('%1.0f',1:length(Gparams));
%{'G','N_{Ca}','N_F','N_FC_{Ca}','C_{Ca}','C_F','C_FN_{Ca}','N_{Ca}C_{Ca}','F'};
%states that add brightness
brightStates = [3,4,6,7,9]; 
brightRat = [1;1;1;1;1];
%Convert Ka to kon values
Gparams(1) = Gparams(2)/(Gparams(1)^Gparams(3));%konN
Gparams(4) = Gparams(5)/(Gparams(4)^Gparams(6));%konC
%Initialize states in incubatio buffer
G_init = solveGinit(ca(1),Gparams);
%Normalizing brightness to sat state
satState = solveGinit(1e-3,Gparams);
satState = sum(satState(brightStates).*brightRat);

%If start and end calcium equal, return vector
if ca(1)==ca(2)
    ftrace = repmat(...
        sum(G_init(brightStates).*brightRat)/satState,...
        1,length(time));
    return;
end
    
%Eigenspace solution to constant [Ca]; note that all of B is constant when
%using this solution
sysPost = real(eigSolve(ca(2),Gparams,G_init,time));

%Calculate the ftrace
ftrace = sum(bsxfun(@times,brightRat,sysPost(brightStates,:)),1)...
    /satState;


%% Plots for QC
if nargin==0
    %Sensor, full time course
    figure;
    subplot(2,1,1);
    plot(time,sysPost,'linewidth',2);%plot([(time_pre-time_pre(end))',time],[sysPre,sysPost]);
    xlabel('time (sec)');ylabel('state fraction')
    title({'WD_{Simple5} State evolution,',...
        ['from ',num2str(ca(1)*1e6,'%0.1f'),' to ',num2str(ca(2)*1e6,'%0.1f'),' \muM']});
    legend(stateList)
    set(gca,'xscale','log');
    
    %Plot the ftrace with thalf indicated
    subplot(2,1,2);hold on;
    [~,uniIdx] = unique(ftrace);
    halfF = (max(ftrace)-min(ftrace))/2 + min(ftrace);
    tPlot = time;
    tHalf = interp1(ftrace(uniIdx),tPlot(uniIdx),halfF);
    plot(time,ftrace);
    text(tHalf,halfF,['t_{half}=',num2str(tHalf)])
    xlabel('time (sec)');ylabel('Normalized F');
    title('Fluorescence change')
    set(gca,'xscale','log');
    plot(xlim,[halfF,halfF],'k--');
    
    %delete ftrace if main
    ftrace=[];
end
end

%% Functions
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

function solved = eigSolve(ca,Gparams,IC,time)
%Use SS calcium, system parameters, and initial conditions to solve
%linear homogenous system over specified time steps
Gmat = G_weightMat(ca,Gparams);
[V,D] = eig(Gmat);
E0 = V\IC;%project initial conditions onto eigen basis
%solution by E(t) = E(0)*exp(D*time);
Et = bsxfun(@times,E0,exp(diag(D)*time));
solved = V*Et;%project back into standard basis
end