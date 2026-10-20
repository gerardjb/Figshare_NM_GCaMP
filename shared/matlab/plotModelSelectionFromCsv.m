function f = plotModelSelectionFromCsv(sourceDir,curveFile,observedFile,fitFile,spikeFile,construct,figureDirectoryName,outputStem)
% Plot stopped-flow and Janelia best-fit displays from reviewed CSV streams.
sf = readtable(fullfile(sourceDir,curveFile),'VariableNamingRule','preserve');
obs = readtable(fullfile(sourceDir,observedFile),'VariableNamingRule','preserve');
fit = readtable(fullfile(sourceDir,fitFile),'VariableNamingRule','preserve');
spikes = readtable(fullfile(sourceDir,spikeFile),'VariableNamingRule','preserve');

f = figure('Name','Janelia global best fit','Color','w');
sizeCm = [19.17,6.74];
set(f,'PaperUnits','centimeters','PaperPosition',[0,0,sizeCm], ...
    'PaperSize',sizeCm,'Units','centimeters','Position',[5,5,sizeCm]);
tlo = tiledlayout(f,1,4,'TileSpacing','compact','Padding','compact');
dataCol = hex2rgb(pickGCaMPcolorsMS(construct));
modelCol = hex2rgb('#009E73');
kinetics = {'(on kinetics)','(off kinetics)'};

sfAxes = gobjects(2,1);
for direction = 1:2
    ax = nexttile(tlo,direction); sfAxes(direction)=ax; hold(ax,'on');
    rowsDirection = sf.direction_index==direction;
    conditions = unique(sf.calcium_condition_index(rowsDirection),'stable');
    for iCondition = 1:numel(conditions)
        rows = rowsDirection & sf.calcium_condition_index==conditions(iCondition);
        plot(ax,sf.time_ms(rows),sf.observed_normalized_fluorescence(rows), ...
            'Color',dataCol,'LineWidth',1);
        plot(ax,sf.time_ms(rows),sf.fitted_normalized_fluorescence(rows), ...
            'Color',[modelCol,0.3],'LineWidth',2);
    end
    xlabel(ax,'time (ms)'); ylabel(ax,{'Normalized F',kinetics{direction}});
    set(ax,'XLim',[0 500],'XTick',[0 250 500],'TickDir','out','LineWidth',1);
end
title(sfAxes(1),'Stopped flow fits','FontWeight','bold');

ax = nexttile(tlo,3,[1 2]); hold(ax,'on');
plot(ax,obs.time_s,obs.observed_DeltaF_over_F,'Color',dataCol,'LineWidth',1);
plot(ax,fit.time_s,fit.fitted_DeltaF_over_F,'Color',[modelCol,0.3],'LineWidth',2);
xlabel(ax,'time (s)'); ylabel(ax,'\DeltaF/F');
title(ax,sprintf('Janelia fit (%s)',construct));
axis(ax,'tight'); yl=ylim(ax);
for iSpike=1:height(spikes)
    plot(ax,repmat(spikes.spike_time_s(iSpike),1,2),yl,'k--');
end
ylim(ax,yl); set(ax,'TickDir','out','LineWidth',1);

saveFigureOutputs(figureDirectoryName,outputStem,f);
end
