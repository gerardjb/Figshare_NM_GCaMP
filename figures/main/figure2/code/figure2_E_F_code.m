function figure2_E_F_code(mode)
% CSV mode is the fast canonical plotting route; original mode retains extraction.
if nargin < 1, mode="csv"; end
mode=lower(string(mode));
assert(ismember(mode,["csv","original"]),'Figure2:Mode','Use csv or original mode.');
useCsv=mode=="csv";
sourceDataDir=fullfile(fileparts(fileparts(mfilename('fullpath'))),'source_data');
%%%
% Plots comparing bouton and stopped flow rise as in indicated figure
%%%

% Close any open plots
close all

% Collect data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
sf_fs = {'OnSummary20210129_On 37 I+ - 0nM_G6f.mat',...
    'OnSummary20210129_On 37 I+ - 0nM_jG7f.mat',...
    'OnSummary20210129_On 37 I+ - 0nM_jG8f.mat'};

% Settings for the different constructs
consts = ["GCaMP6f","jGCaMP7f","jGCaMP8f"];
colores = {};
for i = 1:length(consts)
    colores{i} = pickGCaMPcolorsMS(consts(i));
end

%% Stopped flow rise times panel 2E
% Extracting the half rise times from the stopped-flow analysis files
tRises = [];
for i = 1:length(sf_fs)
    if useCsv
        files={'02_EF_G6f_rise.csv','03_EF_jG7f_rise.csv','04_EF_jG8f_rise.csv'};
        q=readtable(fullfile(sourceDataDir,files{i}));
        ca=q.calcium_nM;this_out=q.half_rise_s;
    else
        load(fullfile(d,sf_fs{i}),'t_50out','ca');
        this_out=t_50out(:,2);
    end
    this_out(ca<40) = nan;
    tRises = [tRises,this_out];
    
    if i==3 && ~useCsv
        ca = ca(2:end);% Strip 0
    end
end


% Set up figure
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [2,1.8];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

% 
ax= plot(ca/1000,tRises*1000,'marker','o','markersize',3,'MarkerFaceColor', 'auto');
set(ax,{'color'},colores',{'markerfacecolor'},colores');
set(gca,'xscale','log','yscale','log',...
    'xtick',[0.1,1,10],'xticklabel',{'0.1','1','10'},...
    'xlim',[0.05,15],'ylim',[1,1000],...
    'ytick',[1,10,100,1000],'yticklabel',{'1','10','100','1000'})
goodCas = [150,1000]; % Selecting the 
ylims = get(gca,'ylim');
p = patch([goodCas(1),goodCas(1),goodCas(2),goodCas(2)]/1000,...
    [ylims(1),ylims(2),ylims(2),ylims(1)],...
    [0.5,0.5,0.5],'facealpha',0.2,'edgecolor','none');
text(min(xlim),ylims(2),[char(916),'Ca^{2+} range'],...
    'Interpreter','tex',...
    'horizontalalignment','left','verticalalignment','bottom','FontName','arial');
xlabel(['free [Ca^{2+}] (',char(956),'M)'], 'Interpreter', 'tex', 'FontName', 'Arial')
ylabel({'stopped flow','half rise (ms)'})
set(gca,'LineWidth',1,'TickLength',[0.04,0.02],...
    'FontName','arial','FontSize',10)

%% Plotting Stopped flow rise vs. bouton rise times panel 2F

if useCsv
    q=readtable(fullfile(sourceDataDir,'01_F_bouton_rise.csv'),'TextType','string');
    rises=arrayfun(@(name) q.bouton_10_90_rise(q.indicator==name),consts,'UniformOutput',false);
else
    load(fullfile(d,'boutonRiseTimes.mat'));
end

%For linear fit to rise times
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [2,2];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);
goodCa = ca>150&ca<1000;
meanRiseSF = mean(tRises(goodCa,:))*1000;
meanRiseB = cellfun(@mean,rises);
rgb_colores = cell2mat(cellfun(@hex2rgb,colores,'UniformOutput',0)');
scatter(meanRiseSF,meanRiseB,15,rgb_colores,...
    'filled');
mdl = fitlm(meanRiseSF(:),meanRiseB(:));
coef_ci = coefCI(mdl);
xfit = [0,200]; if useCsv, xfit=[0,250]; end
yfit = predict(mdl,xfit');
plot(xfit,yfit,'k--')

%Add error bars
errSF = sem(tRises(goodCa,:)*1000);errB = cellfun(@sem,rises);
for i = 1:length(consts)
    plot([meanRiseSF(i)-errSF(i),meanRiseSF(i)+errSF(i)],...
        [meanRiseB(i),meanRiseB(i)],...
        'color',colores{i},'linewidth',1);
    plot([meanRiseSF(i),meanRiseSF(i)],...
        [meanRiseB(i)-errB(i),meanRiseB(i)+errB(i)],...
        'color',colores{i},'linewidth',1);
end
ylabel({'Bouton 10-90%', 'rise (ms)'})
xlabel('Stopped flow half rise (ms)')
set(gca,'LineWidth',1,'FontName','arial','FontSize',10,...
    'TickLength',[0.03,0.003],'ylim',[0,25],'xlim',xfit);

% Report the linear regression statistics for panel 2F.
fitStats = mdl.ModelFitVsNullModel;
stats_text = {sprintf('R^2 = %.3f',mdl.Rsquared.Ordinary),...
    sprintf('p = %.3g',fitStats.Pvalue),...
    sprintf('Slope 95%% CI [%.3f, %.3f]',coef_ci(2,1),coef_ci(2,2))};
text(0.97,0.03,stats_text,...
    'Units','normalized','HorizontalAlignment','right',...
    'VerticalAlignment','bottom','FontName','arial','FontSize',8);

fprintf('Panel 2F linear regression: bouton rise ~ stopped-flow rise\n');
fprintf('  n = %d\n',mdl.NumObservations);
fprintf('  slope = %.4f ms/ms (95%%%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(2),coef_ci(2,1),coef_ci(2,2));
fprintf('  intercept = %.4f ms (95%%%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(1),coef_ci(1,1),coef_ci(1,2));
fprintf('  R^2 = %.4f, adjusted R^2 = %.4f\n',...
    mdl.Rsquared.Ordinary,mdl.Rsquared.Adjusted);
fprintf('  model p = %.4g\n',fitStats.Pvalue);

saveFigureOutputs("figure2","figure2_E_F");
