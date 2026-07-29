function figure2_G_H_I_code
%%%
% Plots of Hill analyses of stopped slow and its comparison to bouton
% kinetics as presented in the indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,'..','Shared_data','stoppedFlowTraces.mat'))
processedTraces = processedTraces{1};% get rising step traces
processedTraces = selectConstructRecords(processedTraces, ...
    ["OGB1","GCaMP6f","jGCaMP7f","jGCaMP8f"],mfilename);



%% Hill plots
%For Hill Plots
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [4.8,3.8];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

%General plot params
cmap = zeros(length(processedTraces),3);
ticklengths = [0.04,0.02];
tile_wide = 18;
tile_high = 2;
tile_starts = [1,2*floor(tile_wide/3),...
    tile_wide + ceil(tile_wide/2)+1, tile_wide + 1];
tile_size = {[1,2*floor(tile_wide/3)-1],[1,floor(tile_wide/3)+1]...
    [1,floor(tile_wide/2)-1],[1,floor(tile_wide/2)-1]};
tH = tiledlayout(tile_high,tile_wide,'tilespacing','loose');


targTime = [Inf,15];
ylabels = {'steady state','early'};
at0 = zeros(length(processedTraces),2);
atEnds = {};
atXlim = zeros(length(processedTraces),2);
colores = zeros(length(processedTraces),3);
consts = string();
Ts = {};%keeping sampling times for adding to the raw data plot
Ys = {};

%Fits, plots, and getting locations for text
for i = 1:length(processedTraces)
    consts(i) = processedTraces(i).const;
    colores(i,:) = hex2rgb(pickGCaMPcolorsMS(processedTraces(i).const));
    xplot = linspace(-1.4,0.3,50);
    ylims = [-2.6,2.6];
    pn = [1,2];
    t = processedTraces(i).time*1000;%to ms
    F = processedTraces(i).traces(:,3:end-1);
    ca = processedTraces(i).calcium(3:end-1)*10^-3;%to uM
    
    for ii = 1:length(targTime)
        goodT = find(t(:,1)<targTime(ii),3,'last');
        Ts{i,ii} = mean(t(goodT,1));
        Y = mean(F(goodT,:),1);Y(Y>0.999)=0.99;
        Ys{i,ii} = Y;
        fObj = polyfit(log10(ca),log10(Y./(1-Y)),pn(ii));
        nexttile(tile_starts(ii+2),tile_size{ii+2});hold on;
        plot(log10(ca),log10(Y./(1-Y)),...
            'markerfacecolor',colores(i,:),'MarkerEdgeColor',colores(i,:),...
            'marker','o','markersize',3,'linestyle','none');
        plot(xplot,polyval(fObj,xplot),'color',colores(i,:),...
            'linewidth',1);
        der = polyder(fObj);
        thisAt0 = polyval(der,0.1);
        at0(i,ii) = thisAt0;
        thisAtend = polyval(fObj,0.3);
        atXlim(i,ii) = thisAtend;
        %Get values at -0.5 and 0.5
        if pn(ii)==2
            theseEnds = [polyval(der,-0.2),polyval(der,0.4)];
            atEnds = [atEnds;theseEnds];
        end
        set(gca,'ylim',ylims);
        if i==1
            ylabel({ylabels{ii},...
                ['log(',char(952),'/(1-',char(952),'))']});
            xlabel(['log([Ca^{2+}]) (',char(956),'M)']);
        end
        set(gca,'fontsize',10,'fontname','arial',...
            'ticklength',ticklengths,'TickDir','out','LineWidth',1)
    end
    
end

%handle marginal text and labels
for i=1:length(targTime)
    nexttile(tile_starts(i+2),tile_size{i+2});
    [re_spaced,re_spaced_idx] = non_overlapped_text_position(...
            atXlim(:,i),diff(gca().YLim)*0.14);
    for i_text = 1:length(consts)
        text_name = num2str(at0(i_text,i),3);
        text(max(xlim),re_spaced(re_spaced_idx(i_text)),text_name,...
            'VerticalAlignment', 'middle','fontweight','bold', ...
            'Color',colores(i_text,:),...
            'FontName','Arial','FontSize',10);
    end%i_text
end
%xlabel(tH,['log([Ca^{2+}]) (',char(956),'M)'])
%ylabel(tH,['log(',char(952),'/(1-',char(952),'))'])

%% Raw log data and Hill v. PPR plots
% Hill v. PPR
% Load the PPR data
load(fullfile(d,'..','Shared_data','PPR.mat'))
c = {OGB5N_PPR,G6f_PPR,jG7f_PPR,jG8f_PPR};
pprs = cellfun(@(x) median(x(x(:,3)==1,2)),c);
iqrs = cellfun(@(x) quantile(x(x(:,3)==1,2),[0.25,0.75]),c,UniformOutput=false);
errs = cellfun(@(x) std(x(x(:,3)==1,2)),c);
xends = [1,3];

nexttile(tile_starts(2),tile_size{2});hold on;

%Add on the 
ax= scatter(at0(:,2)',pprs,25,colores,...
    'filled');
%Err for PPR - IQR of dist
cellfun(@(x,y) plot([at0(y,2),at0(y,2)],quantile(x(x(:,3)==1,2),[0.25,0.75])...
    ,'color',colores(y,:),'LineWidth',1),c,{1,2,3,4});
cellfun(@(x,y) plot(x,[pprs(y),pprs(y)],...
    'color',colores(y,:),'LineWidth',1),atEnds',{1,2,3,4});
mdl = fitlm(at0(:,2),pprs(:));
coef_ci = coefCI(mdl);
yfit = predict(mdl,xends');
plot(xends,yfit,'k--')
xlabel(['early Hill fit at 1',char(956),'M Ca^{2+}'])
ylabel({[char(916),'F/F normalized'], 'to single pulse'})
set(gca,'TickDir','out','LineWidth',1,'TickLength',ticklengths,...
    'fontname','arial','fontsize',10)

fitStats = mdl.ModelFitVsNullModel;
stats_text = {sprintf('R^2 = %.3f',mdl.Rsquared.Ordinary),...
    sprintf('p = %.3g',fitStats.Pvalue),...
    sprintf('Slope 95%% CI [%.3f, %.3f]',coef_ci(2,1),coef_ci(2,2))};
text(0.97,0.03,stats_text,...
    'Units','normalized','HorizontalAlignment','right',...
    'VerticalAlignment','bottom','FontName','arial','FontSize',8);

fprintf('Panel 2I linear regression: PPR ~ early Hill slope\n');
fprintf('  n = %d\n',mdl.NumObservations);
fprintf('  slope = %.4f (95%%%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(2),coef_ci(2,1),coef_ci(2,2));
fprintf('  intercept = %.4f (95%%%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(1),coef_ci(1,1),coef_ci(1,2));
fprintf('  R^2 = %.4f, adjusted R^2 = %.4f\n',...
    mdl.Rsquared.Ordinary,mdl.Rsquared.Adjusted);
fprintf('  model p = %.4g\n',fitStats.Pvalue);


% Raw log data plots
% Using 8f data as example
t = processedTraces(4).time*1000;%to ms
F = processedTraces(4).traces;
%Get the points where data is sampled for early and steady-state responses

% Plot data
nexttile(tile_starts(1),tile_size{1});hold on;
plot(t(2:end,:),F(2:end,:),'Color',colores(4,:),'linewidth',0.5);% drop point during dead time
% Setting plot aesthetic and scale (log to see both points together
set(gca,'xscale','log',...
    'tickdir','out','ticklength',ticklengths,'LineWidth',1,...
    'XTick',[1,10,100,1000,10000],'XTickLabel',compose('%.0f',[1,10,100,1000,10000]),...
    'xlim',[1,19000],'FontName','arial','fontsize',10,'XTickLabelRotation',0);
xlabel('Time (ms)');
ylabel({'Normalized','fluorescence'})
% Adding indicators of where early and steady state are sampled
sample_times = {'steady state','early'};
for i=1:2
    plot([Ts{4,i},Ts{4,i}],ylim,'k:');
    plot(Ts{4,i},Ys{4,i},'Marker','o','MarkerFaceColor',colores(4,:),'MarkerEdgeColor',colores(4,:),...
        'LineStyle','none','MarkerSize',3);
    text(Ts{4,i},max(ylim),sample_times{i},'FontName','arial','FontSize',10,...
        'VerticalAlignment','bottom','HorizontalAlignment','right');
end

saveFigureOutputs("figure2","figure2_G_H_I");
