function figure1_N_code
%%%
% Utility that fits a single spike response from the 6f bouton dataset as
% in current Figure 1 panel N.
% This kernel in the convolved with pairs of spikes
% with low ISI and compared to the actual bouton response to the same train.
%%%
close all;

%% Get the reviewed observed and fitted display curves
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');
curveFiles = ["57_N_condition1.csv","58_N_condition2.csv", ...
    "59_N_condition3.csv"];
stimFiles = ["N_condition1_stimuli.csv","N_condition2_stimuli.csv", ...
    "N_condition3_stimuli.csv"];
curves = arrayfun(@(name) {readtable(fullfile(d,name), ...
    'VariableNamingRule','preserve')},curveFiles);
spikes = arrayfun(@(name) {readmatrix(fullfile(d,name), ...
    'NumHeaderLines',1)},stimFiles);
traces = cellfun(@(x) x.observed_dff,curves,'UniformOutput',false);
hats = cellfun(@(x) x.predicted_dff,curves,'UniformOutput',false);
t = curves{1}.time_ms;


%% Plots
% Setup and general plot settings parameters
f = figure;
sizerRaw = [3.6,2];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);
nRow = 1;
nCol = 3;
tl = tiledlayout(nRow,nCol,'tilespacing','loose');
cols = {pickGCaMPcolorsMS('GCaMP6f'),'#9DA1C3','#9DA1C3'};%light for multi-spike
fit_cols = {[0.3,0.3,0.3,0.9],[0.3,0.3,0.3,0.4],[0.3,0.3,0.3,0.4]};
%xlims = {[t_pois(1),t_pois(end)/4],[t_pois(1),t_pois(end)]};
xval = 100;
yval = 0.1;
ylims = [-0.1,max(cellfun(@max,traces))*1.05];

%Plots
for i = 1:numel(curves)
    h = nexttile;hold on
    plot(t,traces{i},'color',cols{i});
    plot(t,hats{i},'color',fit_cols{i},'linewidth',1.5);
    set(gca,'ylim',ylims,...
        'YTick',[],'fontsize',10);
    arrayfun(@(x) plot([x,x],ylim,'k--'),spikes{i});
    if i==1
        makeTSscaleBar(h,'xVal',xval,'xText',[num2str(xval),' ms'],...
            'yVal',yval,'yText',[num2str(yval),greek_char('Delta'),'F/F'],...
            'xfrac',0.3,'yfrac',0.5,...
            'lefty',0,'upsidedown',1,'fontsize',10);
    end
    axis off
end

title(tl,'GCaMP6f','color',cols{1},'fontsize',12)

saveFigureOutputs("figure1","figure1_N");
end
