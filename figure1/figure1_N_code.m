function figure1_N_code
%%%
% Utility that fits a single spike response from the 6f bouton dataset as
% in current Figure 1 panel N.
% This kernel in the convolved with pairs of spikes
% with low ISI and compared to the actual bouton response to the same train.
%%%
close all;

%% Get Data
% Opening from current location
d = fileparts(mfilename("fullpath"));
load(fullfile(d,"..","Shared_data","gDbase.mat"));

idx_to_show = [1,2,3];
targ = 6;%bouton to pick
offset = gData(1).PPRtraces.tOffset*1000;%in ms, 1 = G6f
%offset = 0;
ISIs = gData(1).PPRtraces.ISI;
spikes = [0,arrayfun(@(x) [0,x],ISIs(idx_to_show(2:end)),'UniformOutput',false)];
t = gData(1).PPRtraces.Data{1}(:,1) - offset;
baseline = -50;
traces = arrayfun(@(x) gData(1).PPRtraces.Data{x}(t>=baseline,targ),idx_to_show,'UniformOutput',false);
t = t(t>=baseline);

%% Fitting
% Param Initialization and bounding for biexponential 
inParams = [74,83,0.06];
lb = [10,0.8,0.01];
ub = [1000,43,3];

% Set up fit
funfit = @(inParams,t) linear_kernel(inParams,spikes{1},t);
options = optimoptions('lsqcurvefit',...
    'Display','iter-detailed',...
    'TypicalX',[0.1,0.01,1],...
    'Display','iter-detailed',...
    'MaxFunctionEvaluations',1000,...
    'UseParallel',false);

%Run fit
[outParams,resnorm,residuals] = lsqcurvefit(funfit,inParams,...
    t,traces{1},...
    lb,ub,options);


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

%Simulations using linear kernel
hats = cellfun(@(x) linear_kernel(outParams,x,t),spikes,'UniformOutput',false);

%Plots
for i = 1:length(idx_to_show)
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
