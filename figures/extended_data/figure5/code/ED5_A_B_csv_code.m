function ED5_A_B_csv_code
%% Plot high- and low-SNR examples from the reviewed source-data CSVs.
close all

sourceDir = fullfile(fileparts(mfilename("fullpath")),'..','source_data');
panelKeys = ["A","B"];
panelTitles = ["High SNR example","Low SNR example"];
methodKeys = ["Biophys_SMC","PGBAR","MLspike","Biophys_ML","CASCADE","ENS2"];
methodLabels = ["Biophys_{SMC}","PGBAR","MLspike","Biophys_{ML}","CASCADE","ENS^2"];

f = figure('Color','w');
sizer = [8.5,5];
set(f,'PaperUnits','inches','PaperSize',sizer,'PaperPosition',[0,0,sizer], ...
    'Units','inches','Position',[1,1,sizer]);
outer = tiledlayout(f,1,2,'TileSpacing','loose','Padding','compact');

for iPanel = 1:2
    key = panelKeys(iPanel);
    fluorescence = readtable(fullfile(sourceDir,key+"_fluorescence.csv"), ...
        'TextType','string','VariableNamingRule','preserve');
    gtCurve = readtable(fullfile(sourceDir,key+"_ground_truth_curve.csv"), ...
        'TextType','string','VariableNamingRule','preserve');
    predictions = readtable(fullfile(sourceDir,key+"_prediction_curves.csv"), ...
        'TextType','string','VariableNamingRule','preserve');
    gtEvents = readtable(fullfile(sourceDir,key+"_ground_truth_events.csv"), ...
        'TextType','string','VariableNamingRule','preserve');
    classified = readtable(fullfile(sourceDir,key+"_plotted_classified_events.csv"), ...
        'TextType','string','VariableNamingRule','preserve');

    window = [min(fluorescence.time_s),max(fluorescence.time_s)];
    pad = 0.15*diff(window);
    inner = tiledlayout(outer,8,1,'TileSpacing','none','Padding','compact');
    inner.Layout.Tile = iPanel;
    title(inner,panelTitles(iPanel),'FontName','Arial');

    ax = nexttile(inner); hold(ax,'on');
    plot(ax,fluorescence.time_s,fluorescence.fluorescence_dff,'k','LineWidth',0.8);
    addEventLines(ax,gtEvents.spike_time_s,[0 0 0],':',0.4);
    set(ax,'XLim',window,'Visible','off');
    if iPanel==1
        text(ax,window(1)-pad,mean(ylim(ax)),'Fluorescence','FontWeight','bold', ...
            'HorizontalAlignment','left','FontName','Arial','Clipping','off');
    end
    yspan = round(diff(ylim(ax))/3,1);
    makeTSscaleBar(ax,'xFrac',1,'yFrac',1,'yVal',yspan, ...
        'yText',[num2str(yspan),' \DeltaF/F'],'xVal',0.2,'xText','200 ms', ...
        'lefty',0,'upsidedown',1);

    ax = nexttile(inner); hold(ax,'on');
    plot(ax,gtCurve.time_s,gtCurve.display_normalized_ground_truth,'k','LineWidth',1.5);
    addEventLines(ax,gtEvents.spike_time_s,[0 0 0],':',0.4);
    set(ax,'XLim',window,'YLim',[-0.02 1.7],'Visible','off');
    if iPanel==1
        text(ax,window(1)-pad,0.8,{'Ground','truth'},'FontWeight','bold', ...
            'HorizontalAlignment','left','FontName','Arial','Clipping','off');
    end

    for iMethod = 1:numel(methodKeys)
        ax = nexttile(inner); hold(ax,'on');
        methodRows = predictions.method==methodKeys(iMethod);
        color = pickGCaMPcolorsMS(methodLabels(iMethod));
        plot(ax,predictions.time_s(methodRows), ...
            predictions.display_normalized_probability(methodRows), ...
            'Color',color,'LineWidth',1.5);
        addEventLines(ax,gtEvents.spike_time_s,[0 0 0],':',0.4);
        set(ax,'XLim',window,'YLim',[-0.02 2.1],'Visible','off');
        if iPanel==1
            text(ax,window(1)-pad,0.8,methodLabels(iMethod), ...
                'Color',color,'FontWeight','bold','HorizontalAlignment','left', ...
                'FontName','Arial','Interpreter','tex','Clipping','off');
        end

        outcomes = ["fn","fp","tp"];
        levels = [1.05 1.35;1.35 1.65;1.65 1.95];
        outcomeColors = {[0 0 0],[1 0 0],hex2rgb(color)};
        for iOutcome = 1:3
            rows = classified.method==methodKeys(iMethod) & ...
                classified.classification==outcomes(iOutcome);
            times = classified.event_time_s(rows);
            for iEvent = 1:numel(times)
                plot(ax,[times(iEvent),times(iEvent)],levels(iOutcome,:), ...
                    'Color',outcomeColors{iOutcome},'LineWidth',0.8);
            end
        end
    end
end

set(findall(f,'Type','axes'),'FontName','Arial','FontSize',10);
saveFigureOutputs("extended_data/figure5","ED5_A_B",f);
end

function addEventLines(ax,times,color,style,width)
yl = ylim(ax);
for i = 1:numel(times)
    plot(ax,[times(i),times(i)],yl,'Color',color,'LineStyle',style, ...
        'LineWidth',width,'HandleVisibility','off');
end
end
