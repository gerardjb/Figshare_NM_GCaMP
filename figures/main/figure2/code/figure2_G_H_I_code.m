function figure2_G_H_I_code(mode)
% CSV mode is the fast canonical plotting route; original mode retains extraction.
if nargin < 1, mode="csv"; end
mode=lower(string(mode));
assert(ismember(mode,["csv","original"]),'Figure2:Mode','Use csv or original mode.');
useCsv=mode=="csv";
sourceDataDir=fullfile(fileparts(fileparts(mfilename('fullpath'))),'source_data');
%%%
% Plots of Hill analyses of stopped slow and its comparison to bouton
% kinetics as presented in the indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
if useCsv
    processedTraces=figure2CsvInputs('rise',sourceDataDir);
    sampleFiles={'09_GH_OGB1_samples.csv','11_GH_GCaMP6f_samples.csv', ...
        '13_GH_jGCaMP7f_samples.csv','15_GH_jGCaMP8f_samples.csv'};
else
load(projectFile('shared','inputs','stoppedFlowTraces.mat'))
processedTraces = processedTraces{1};% get rising step traces
processedTraces = selectConstructRecords(processedTraces, ...
    ["OGB1","GCaMP6f","jGCaMP7f","jGCaMP8f"],mfilename);
end



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
    if useCsv
        sampleTable=readtable(fullfile(sourceDataDir,sampleFiles{i}),'TextType','string');
    else
    t = processedTraces(i).time*1000;%to ms
    F = processedTraces(i).traces(:,3:end-1);
    ca = processedTraces(i).calcium(3:end-1)*10^-3;%to uM
    end
    
    for ii = 1:length(targTime)
        if useCsv
            phases=["steady","early"];
            q=sampleTable(sampleTable.sampling_phase==phases(ii),:);
            ca=unique(q.calcium,'stable')'*1e-3;
            Y=arrayfun(@(calcium) mean(q.normalized_fluorescence(abs(q.calcium-calcium)<1e-8)),ca*1000);
            Ts{i,ii}=mean(unique(q.time));
            Y(Y>0.999)=0.99;
        else
        goodT = find(t(:,1)<targTime(ii),3,'last');
        Ts{i,ii} = mean(t(goodT,1));
        Y = mean(F(goodT,:),1);Y(Y>0.999)=0.99;
        end
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
% Load the packaged 10 ms values derived from the canonical PPR struct in
% Figure 1. The original-input extraction workflow reads
% figure1_H_J_data.mat; this plotting path consumes its tracked CSV export.
pprFile = projectFile('figures','main','figure2','source_data', ...
    '07_I_PPR_inputs.csv');
pprTable = readtable(pprFile,'TextType','string');
sensorKeys = ["OGB5N","G6f","jG7f","jG8f"];
selectedForI = lower(string(pprTable.selected_for_I))=="true";
c = cell(1,numel(sensorKeys));
for iSensor = 1:numel(sensorKeys)
    mask = pprTable.indicator==sensorKeys(iSensor) & ...
        selectedForI;
    values = pprTable.normalized_second_response(mask);
    c{iSensor} = values(isfinite(values));
end
if useCsv
    [hillMeans,hillHalfRange]=figure2CsvInputs('early_hill_summary',sourceDataDir);
    at0(:,2)=hillMeans(:);
end
pprs = cellfun(@median,c);
iqrs = cellfun(@(x) quantile(x,[0.25,0.75]),c,UniformOutput=false);
errs = cellfun(@std,c);
xends = [1,3];

nexttile(tile_starts(2),tile_size{2});hold on;

%Add on the 
ax= scatter(at0(:,2)',pprs,25,colores,...
    'filled');
%Err for PPR - IQR of dist
cellfun(@(x,y) plot([at0(y,2),at0(y,2)],quantile(x,[0.25,0.75])...
    ,'color',colores(y,:),'LineWidth',1),c,{1,2,3,4});
if useCsv
    for iSensor=1:4
        plot(at0(iSensor,2)+[-1,1]*hillHalfRange(iSensor),[pprs(iSensor),pprs(iSensor)], ...
            'Color',colores(iSensor,:),'LineWidth',1);
    end
else
cellfun(@(x,y) plot(x,[pprs(y),pprs(y)],...
    'color',colores(y,:),'LineWidth',1),atEnds',{1,2,3,4});
end
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
if ~useCsv
text(0.97,0.03,stats_text,...
    'Units','normalized','HorizontalAlignment','right',...
    'VerticalAlignment','bottom','FontName','arial','FontSize',8);
end % Reference panel I has no extra statistics textbox.

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
if useCsv
    raw=readtable(fullfile(sourceDataDir,'G_saved_full_jGCaMP8f_rise.csv'));
    columns=unique(raw.calcium_column_index,'stable');
    nr=nnz(raw.calcium_column_index==columns(1));
    t=zeros(nr,numel(columns));F=t;
    for ic=1:numel(columns)
        q=raw(raw.calcium_column_index==columns(ic),:);
        t(:,ic)=q.time_ms;F(:,ic)=q.normalized_fluorescence;
    end
else
t = processedTraces(4).time*1000;%to ms
F = processedTraces(4).traces;
end
%Get the points where data is sampled for early and steady-state responses

% Plot data
nexttile(tile_starts(1),tile_size{1});hold on;
if useCsv
    plot(t,F,'Color',colores(4,:),'linewidth',0.5); % CSV already excludes source first point.
else
    plot(t(2:end,:),F(2:end,:),'Color',colores(4,:),'linewidth',0.5);
end
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
