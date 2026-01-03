function figure1_L_code
%%%
% Utility that fits a single spike response from the 8f bouton dataset.
% This impulse response function is then convolved with a Poisson spike
% train and compared to the actual bouton response to the same train.
%%%
close all

%% Get data
% Opening from current location
d = fileparts(mfilename("fullpath"));
load(fullfile(d,"..","Shared_data","gDbase.mat"));


targ = 6;%bouton to pick
offset = -gData(3).PoisGiov.tOffset;%
spikes = gData(3).PoisGiov.stim_time/1000;
spike_single = gData(3).PoisGiov.stim_time_single/1000;
t = gData(3).PoisGiov.poisson(:,1)+0.9*offset/2;
pois = mean(gData(3).PoisGiov.poisson(:,2:targ),2);
single = mean(gData(3).PoisGiov.single(:,2:targ),2);
% sel = [1:500,900:2000];%apply detrending to account for small baseline drifts
% detrend = fit(t(sel),single(sel),'poly3');
% single = single-detrend(t);
%truncate baseline
base = 0.05;%length of baseline period
pois = pois(t>=spikes(1)-base);
single=single(t>=spike_single-base);
t_pois=t(t>=spikes(1)-base)-spikes(1);
spikes=spikes-spikes(1);
t_single = t(t>=spike_single-base)-spike_single;
spike_single = 0;
% xlimits for the plots

%QC plot
QC_on = 0;
if QC_on
    figure;hold on;
    plot(t_single,single,t_pois,pois);
    cellfun(@(x) plot([x,x],ylim,'k--'),num2cell(spikes));
end

%% Fitting
%Param Initialization and bounding for biexponential 
inParams = [0.034,0.0013,0.06];
lb = [0.01,0.0008,0.01];
ub = [1,0.043,3];
%Set up fit
use_single = true;
if use_single
    t = t_single;%[t_single;t_pois+t_single(end)+base];%
    f = single;%[single;pois];%
    all_spike = spike_single;%[spike_single;spikes+t_single(end)+base];%
else
    t = [t_single;t_pois+t_single(end)+base];%
    f = [single;pois];%
    all_spike = [spike_single;spikes+t_single(end)+base];%
end
funfit = @(inParams,t) linear_kernel(inParams,all_spike,t);
options = optimoptions('lsqcurvefit',...
    'Display','iter-detailed',...
    'TypicalX',[0.1,0.01,1],...
    'Display','iter-detailed',...
    'MaxFunctionEvaluations',1000,...
    'UseParallel',false);
%Run fit
[outParams,resnorm,residuals] = lsqcurvefit(funfit,inParams,...
    t,f,...
    lb,ub,options);

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

%Simulations using linear kernel
single_hat = linear_kernel(outParams,spike_single,t_single);
pois_hat = linear_kernel(outParams,spikes,t_pois);

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
