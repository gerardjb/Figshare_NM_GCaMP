function suppfigure2_code(mode)
% MODE="csv" (default) reads canonical source_data; MODE="original" retains extraction.
if nargin < 1, mode = "csv"; end
mode = lower(string(mode));
assert(ismember(mode,["csv","original"]),'suppfigure2_code:Mode','Use csv or original mode.');
useCsv = mode == "csv";
%%%
% Plots of EGTA BAPTA clamp comparison, data and simulations as in the
% indicated figure
%%%

% Close any open plots
close all

% Collect data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
sourceDataDir = fullfile(fileparts(fileparts(mfilename("fullpath"))),'source_data');
if useCsv
    savedCa = {readtable(fullfile(sourceDataDir,'SF1_c_saved_simulation.csv'),'TextType','string'), ...
        readtable(fullfile(sourceDataDir,'SF1_d_saved_simulation.csv'),'TextType','string')};
    savedOGB = {readtable(fullfile(sourceDataDir,'SF1_e_sim_saved_simulation.csv'),'TextType','string'), ...
        readtable(fullfile(sourceDataDir,'SF1_f_sim_saved_simulation.csv'),'TextType','string')};
    experimentalOGB = {'01_SF1_OnSummary20200711_On_37_I_-.csv','02_SF1_OnSummary20210129_On_37_K_-.csv'};
    experimentalGCaMP = {'03_SF1_OnSummary20200711_On_37_I_-.csv','04_SF1_OnSummary20210129_On_37_K_-.csv'};
end
% For OGB1 recordings
fnames = [fullfile(d,"OnSummary20200711_On 37 I - 0nM_OGB1.mat"),... BAPTA
    fullfile(d,"OnSummary20210129_On 37 K - 0nM_OGB1.mat")];% EGTA
% For jG8f recordings
f_gnames = [fullfile(d,"OnSummary20200711_On 37 I - 0nM_j2851.mat"),...
    fullfile(d,"OnSummary20210129_On 37 K - 0nM_jG8f.mat")];

% Shared set up
bType = {'EGTA','BAPTA'};
colors = flipud(linspecer(2));% first color for BAPTA, then EGTA
caConc = [5e-8,2.1e-7,5e-7,3e-6];% concentrations of total Ca in step buffer;note [buffer] 1.4e-3 M
kinParams = {[4.8e6,1],[5e8,100]};% [k_on, k_off] for each buffer (M^-1*s^-1, s^-1)
bTotParams = {[4e-3,4e-3],[1.5e-5,1.5e-3]};% buffere concentrations (M)

%For the plots
nrow = 2;
ncol = 4;
f = figure;hold on;set(gca,'tickdir','out');
f.Renderer = 'Painters';
sizerRaw = [7,3.5];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);
t = tiledlayout(nrow,ncol,'tilespacing','tight');
xend = 20;% xlim edge for the OGB1 and Ca_f plots

%% Run and plot simulations
%Hold Ca_f and time values
allTime = {};
allCa_f = {};
calSS = [];
%Make and plot OGB1 simulations, get Ca_f data
thiscol = 3;
for i = 1:numel(kinParams)
    %Initialize figure
    tileIndex = (i - 1) * ncol + thiscol;
    nexttile(tileIndex);hold on;
    %Simulation
    for ii = 1:length(caConc)
        %Calculate non-instantaneous clamp
        if useCsv
            target = caConc(ii)*1e6;
            qCa = savedCa{i}(abs(savedCa{i}.nominal_step_uM-target)<1e-10,:);
            qOGB = savedOGB{i}(abs(savedOGB{i}.nominal_step_uM-target)<1e-10,:);
            solid = qOGB(qOGB.line_style=="-",:);
            instant = qOGB(qOGB.line_style=="--",:);
            assert(~isempty(qCa) && ~isempty(solid) && ~isempty(instant), ...
                'suppfigure2_code:MissingCurve','Missing saved simulation curve.');
            time = solid.time_ms/1000;
            OGB_Ca = solid.normalized_OGB1_response;
            time_noEq = instant.time_ms/1000;
            OGB_Ca_noEq = instant.normalized_OGB1_response;
            Ca_f = qCa.free_calcium_uM/1e6;
        else
            [time,Ca_f,OGB_Ca] = BAPTA_OGB1sim(kinParams{i}(1),kinParams{i}(2),caConc(ii),bTotParams{i});
            %Calculate instantaneous clamp
            [time_noEq,OGB_Ca_noEq] = BAPTA_OGB1sim_NoEquil(Ca_f(end));
        end
        
        %Plot both
        plot(1000*time,OGB_Ca,'Color','k');
        plot(1000*time_noEq,OGB_Ca_noEq,'Color','k','linestyle','--');
        calSS = [calSS,caConc(ii)*1e6];
        if ii==length(caConc)
            text(2/3*xend,OGB_Ca(end),...
                [sprintf('%0.2f',caConc(ii)*1e6),' \muM'],...
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        else
            text(2/3*xend,OGB_Ca(end),...
                [sprintf('%0.2f',calSS(ii))],...,' \muM'
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        end
        
        %Pack out Ca_f variables for plot in next section
        allTime{i,ii} = time(1:length(Ca_f));
        allCa_f{i,ii} = Ca_f;
    end
    
    if i==1

        set(gca,'xticklabel',[]);
    else
        xlabel('time (ms)');
    end
    set(gca,'fontsize',12,'fontname','arial','xlim',[0,xend],'xtick',[0,xend/2,xend]);
    set(gca,'tickdir','out','xticklabelrotation',0);
end

%plot Ca_f simulations
thiscol = 1;
for j = 1:size(allTime,1)
    hLeg = [];
    hStr = {};
    tileIndex = (j - 1) * ncol + thiscol;
    nexttile(tileIndex);hold on;
    for jj = 1:size(allTime,2)
        h = plot(1000*allTime{j,jj},1e6*allCa_f{j,jj},'color','k');%/caConc(jj)
    end
    if j==1
        set(gca,'xticklabel',[]);
    else
        xlabel('time (ms)')
    end
    ylabel('[Ca]_{free} (\muM)')
    
    set(gca,'fontsize',13,'fontname','arial','yscale','log',...
        'xlim',[0,xend],'ylim',[0.01,1000],'ytick',[1,10,100,1000]);
    set(gca,'xtick',[0,xend/2,xend]);% 'yticklabel',axLabelExp2Pos,
    set(gca,'tickdir','out','xticklabelrotation',0);
    grid on;
end


%% Open and plot EGTA and BAPTA  OGB data
% Setup for OGB1 plots
thiscol = 2;
ca2plot = [2,4,5,7];%indices of the sample traces to show

for i = 1:length(bType)
    tileIndex = (i - 1) * ncol + thiscol;
    nexttile(tileIndex);hold on;
    if useCsv
        [outTrace,ca_hand] = readExperimentalCsv(fullfile(sourceDataDir,experimentalOGB{i}));
    else
        load(fnames(i));
    end
    plot(squeeze(1000*outTrace(:,1,ca2plot)),squeeze(outTrace(:,2,ca2plot)),'color','k');
    if i==1
        set(gca,'xticklabel',[])
    else
        xlabel('time (ms)')
    end
    for ii = 1:length(ca2plot)
        if ii==length(caConc)
            text(2/3*xend,mean(outTrace(end-10:end,2,ca2plot(ii))),...
                [sprintf('%0.2f',ca_hand(ca2plot(ii))/1000),' \muM'],...
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        else
            text(2/3*xend,mean(outTrace(end-10:end,2,ca2plot(ii))),...
                [sprintf('%0.2f',ca_hand(ca2plot(ii))/1000)],...,' \muM'
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        end
    end
    set(gca,'fontsize',12,'fontname','arial','xlim',[0,xend],'xtick',[0,xend/2,xend]);
    set(gca,'tickdir','out','xticklabelrotation',0);
end

saveFigureOutputs("supp_figure2","suppfigure2");

%% Open and plot EGTA and BAPTA jG8f data
% Set up for jG8f plots
thiscol = 4;
ca2plot = {[3,5,6,7],[2,3,4,5]};%indices of the sample traces to show
xend2 = 300;
text_pos = 4/5;
for i = 1:length(bType)
    tileIndex = (i - 1) * ncol + thiscol;
    nexttile(tileIndex);hold on;
    if useCsv
        [outTrace,ca_hand] = readExperimentalCsv(fullfile(sourceDataDir,experimentalGCaMP{i}));
    else
        load(f_gnames(i));
    end
    plot(squeeze(1000*outTrace(:,1,ca2plot{i})),squeeze(outTrace(:,2,ca2plot{i})),'color',pickGCaMPcolorsMS('jGCaMP8f'));
    if i==1
        set(gca,'xticklabel',[])
    else
        xlabel('time (ms)')
    end
    for ii = 1:length(ca2plot{i})
        plt_idx_end = find(1000*outTrace(:,1,ca2plot{i}(ii))<xend2,1,'last');
        if ii==length(caConc)
            text(text_pos*xend2,mean(outTrace(plt_idx_end-10:plt_idx_end,2,ca2plot{i}(ii))),...
                [sprintf('%0.2f',ca_hand(ca2plot{i}(ii))/1000),' \muM'],...
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        else
            text(text_pos*xend2,mean(outTrace(plt_idx_end-10:plt_idx_end,2,ca2plot{i}(ii))),...
                [sprintf('%0.2f',ca_hand(ca2plot{i}(ii))/1000)],...,' \muM'
                'color','k',...
                'horizontalalignment','left','verticalalignment','bottom');
        end
    end
    ylabel({'Normalized','fluorescence'})
    set(gca,'fontsize',12,'fontname','arial','xlim',[0,xend2],'xtick',[0,xend2/2,xend2],'ylim',[0,1]);
    set(gca,'tickdir','out','xticklabelrotation',0);
end

% Save the complete figure, including jGCaMP8f panels g/h.
saveFigureOutputs("supp_figure2","suppfigure2",f);
end

function [outTrace,ca_hand] = readExperimentalCsv(csvPath)
T = readtable(csvPath,'TextType','string');
indices = unique(T.source_trace_index,'stable');
lengths = arrayfun(@(index) nnz(T.source_trace_index==index),indices);
assert(all(lengths==lengths(1)),'suppfigure2_code:TraceLength','Stored trace lengths differ.');
outTrace = nan(lengths(1),2,max(indices));
ca_hand = nan(1,max(indices));
for index = indices(:)'
    q = T(T.source_trace_index==index,:);
    outTrace(:,1,index) = q.time_s;
    outTrace(:,2,index) = q.stored_normalized_fluorescence;
    ca_hand(index) = q.saved_calcium_nM(1);
end
end
