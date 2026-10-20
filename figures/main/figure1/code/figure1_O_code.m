function figure1_O_code
%%%
% Utility that fits a single spike response from the 8f bouton dataset.
% This impulse response function is then convolved with a Poisson spike
% train and compared to the actual bouton response in current Figure 1
% panel O.
%%%
close all

%% Get the reviewed observed and fitted display curves
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');
singleTable = readtable(fullfile(d,'60_O_single.csv'), ...
    'VariableNamingRule','preserve');
poissonTable = readtable(fullfile(d,'61_O_poisson.csv'), ...
    'VariableNamingRule','preserve');
t_single = singleTable.time_s;
single = singleTable.observed_dff;
single_hat = singleTable.predicted_dff;
t_pois = poissonTable.time_s;
pois = poissonTable.observed_dff;
pois_hat = poissonTable.predicted_dff;
spike_single = readmatrix(fullfile(d,'O_single_stimuli.csv'),'NumHeaderLines',1);
spikes = readmatrix(fullfile(d,'O_poisson_stimuli.csv'),'NumHeaderLines',1);

%QC plot
QC_on = 0;
if QC_on
    figure;hold on;
    plot(t_single,single,t_pois,pois);
    cellfun(@(x) plot([x,x],ylim,'k--'),num2cell(spikes));
end

%% Plots
% Setup and general plot settings parameters
f = figure;
sizerRaw = [4,2];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);
nRow = 1;
nCol = 3;
tl = tiledlayout(nRow,nCol,'tilespacing','compact');
cols = {pickGCaMPcolorsMS('jGCaMP8f'),'#C58B9F'};%light for multi-spike
xlims = {[t_pois(1),t_pois(end)/4],[t_pois(1),t_pois(end)]};
xval = 0.2;
yval = 0.1;

% Fit to single
hA1 = nexttile;hold on;
ylims = [-0.05,max(...
    [max(pois_hat)+0.1*max(pois_hat),...
    max(pois)+0.1*max(pois)])];
plot(t_single,single,'color',cols{1});
plot(t_single,single_hat,'color',[0.5,0.5,0.5,0.9],'linewidth',1.5)%
set(gca,'ylim',ylims,'xlim',xlims{1},...
    'YTick',[],'fontsize',10)
plot([spike_single,spike_single],ylim,'k--','LineWidth',0.4)
makeTSscaleBar(hA1,'xVal',xval,'xText',[num2str(xval*1000),' ms'],...
            'yVal',0,'yText','',...[num2str(yval),greek_char('Delta'),'F/F'],...
            'xfrac',0.3,'yfrac',0.7,...
            'lefty',0,'upsidedown',1,'fontsize',10);
axis off

% outParams on poisson train
hA2 = nexttile(2,[1,2]);hold on;
lims = [min(pois_hat),max(pois_hat),0,max(pois_hat)];
plot(t_pois,pois,'color',cols{2});
plot(t_pois,pois_hat,'color',[0.5,0.5,0.5,0.4],'linewidth',1.5)%
set(gca,'ylim',ylims,'xlim',[t_pois(1),t_pois(end)],...
    'YTick',[],'fontsize',10);
cellfun(@(x) plot([x,x],ylim,'k--','LineWidth',0.4),num2cell(spikes));
makeTSscaleBar(hA2,'xVal',xval,'xText',[num2str(xval*1000),' ms'],...
            'yVal',yval,'yText',[num2str(yval),greek_char('Delta'),'F/F'],...
            'xfrac',0.8,'yfrac',0.7,...
            'lefty',0,'upsidedown',1,'fontsize',10);
axis off
title(tl,'jGCaMP8f','color',cols{1},'fontsize',12)

saveFigureOutputs("figure1","figure1_O");
end
