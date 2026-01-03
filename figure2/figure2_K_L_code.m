function figure2_K_L_code
%%%
% Plots of elongation and its comparison ot accessible slowing as shown in
% the refernced figure
%%%

% Close any open plots
close all

% Collect data files
d = fileparts(mfilename("fullpath"));
fname = fullfile(d,'10pulseData.mat');
fname2 = fullfile(d,'decay.mat');
fname3 = fullfile(d,'kineticContribution2.mat');

%% Elongation plot
load(fname);
consts = {'G6f','jG7f','jG8f'};
all = {[G6f,G6f(:,2)./G6f(:,1)],...
    [jG7f,jG7f(:,2)./jG7f(:,1)],...
    [jG8f,jG8f(:,2)./jG8f(:,1)]};

%All elongations together in one plot
colores = zeros(3,3);
for i = 1:3;colores(i,:) = hex2rgb(pickGCaMPcolorsMS(consts{i}));end
elongs = nancat(2,G6f(:,2)./G6f(:,1),jG7f(:,2)./jG7f(:,1),jG8f(:,2)./jG8f(:,1));
f =figure;
sizerRaw = [1.6,2.2];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

boxplot(elongs);
h = gca;
fixBoxplotAttributes(h,3,[0.66,0.66,0.66],0,1,'none')
for i = 1:size(elongs,2)
    dotPlot_xtr(elongs(:,i),i,0.05,0.05,colores(i,:));
end
set(gca,'xticklabel',{'G6f','jG7f','jG8f'},...
    'ylim',[0,5.5]);
xtickangle(45);
ylabel({'fold slowing','(1 to 10 pulse)'})
box off
set(gca,'tickdir','out','linewidth',1,'fontsize',10);

%% Elongation vs. accessible slowing
% Load other files
load(fname2)
load(fname3)

%Calculate the contribution of components
%Percent fast + something about decay (sf? bouton?) vs. Elongation scatter
goodCa = ca>200 & ca<2000;
a_slow = [0,cellfun(@(x,y) nansum(y(2,goodCa)./y(1,goodCa).*[1-x(goodCa)]),all_proportions1(2:end),all_taus(2:end))/sum(goodCa)];
a_slow_iqr = [0,cellfun(@(x,y) iqr(y(2,goodCa)./y(1,goodCa).*[1-x(goodCa)]),all_proportions1(2:end),all_taus(2:end))/sum(goodCa)];
elongs_med = [1,nanmedian(elongs,1)];
elong_iqr = [0,iqr(elongs,1)];
weights = 1./(a_slow_iqr.^2 + elong_iqr.^2);
weights(1) = 1;

mdl = fitlm(a_slow,elongs_med,'Weights',weights);

% Figure setup
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [2.1,2.4];
ticklengths = [0.04,0.02];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

% Arrange variables for plot
consts = {'OGB5N','G6f','jG7f','jG8f'};
elongs = [ones(size(elongs,1),1),elongs];
colores = [hex2rgb(pickGCaMPcolorsMS(consts{1}));...
    colores];

%right tile, rise contribution v. slowing
xends = [0,6];
nexttile;hold on
for i = 1:length(consts)
    scatter(a_slow(i),elongs_med(i),...
        25,hex2rgb(pickGCaMPcolorsMS(consts{i})),'filled');
end
% Err for Accessible slowing - IQR of dist
arrayfun(@(y) plot([a_slow(y)-a_slow_iqr(y)/2,a_slow(y)+a_slow_iqr(y)/2],[elongs_med(y),elongs_med(y)],...
    'color',colores(y,:),'LineWidth',1),[1,2,3,4]);
% Err for fold slowing - IQR of dist
arrayfun(@(x) plot([a_slow(x),a_slow(x)],[elongs_med(x)-elong_iqr(x)/2,elongs_med(x)+elong_iqr(x)/2],...
    'color',colores(x,:),'LineWidth',1),[1,2,3,4]);
fCoeff = polyfit(a_slow,elongs_med,1);
plot(xends,polyval(fCoeff,xends),'k--')
ylabel({'fold slowing','(1 to 10 pulse)'})
xlabel({'Accessible slowing','(\tau_{slow}/\tau_{fast} * proportion_{slow})'})
set(gca,'YLim',[0,3.8],...
    'tickdir','out','ticklength',ticklengths,'LineWidth',1,...
    'FontName','arial','fontsize',10,'XTickLabelRotation',0);