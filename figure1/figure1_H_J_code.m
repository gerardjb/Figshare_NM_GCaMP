function figure1_H_J_code
%%%
% Plots of paired spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Locate this figure directory so the function can run from any working dir
d = fileparts(mfilename("fullpath"));

% Open data file
dataFile = fullfile(d,"figure1_H_J_data.mat");
load(dataFile)

% Loop variables
panel_name = ["H","J"];

%% Panel H plots
fH = plot_panel_H(PPR);
set(fH,'Name',panel_name(1));
title(findobj(fH,'Type','axes'),"Panel "+panel_name(1))

%% Panel J plots
% Loop variables
offset_x = [-0.1,0,0.1];
consts = ["G6f","jG7f","jG8f"];

% Figure formatting
figure;hold on;
sizer = [3.6,5.5];
set(gcf,'Units','centimeters','paperunits','centimeters',...
    'papersize',sizer,'paperposition',[0,0,sizer],...
    'Position',[4,4,sizer]);


% Panel J plots
for i_const = 1:length(consts)
    % plot individual strip plots
    arrayfun(@(i) ...
        plot(i+offset_x(i_const),spike_1_10.(consts(i_const))(:,i),...
        'color',pickGCaMPcolorsMS(consts(i_const)),'marker','.'),...
        1:2);

    % Add error bar plot
    errorbar((1:2)+offset_x(i_const),...
        mean(spike_1_10.(consts(i_const)),1),sem(spike_1_10.(consts(i_const)),1),...
        'Color',pickGCaMPcolorsMS(consts(i_const)),'CapSize',0,'LineWidth',1);

end
% Finalizing
title("Panel J")
set(gca,'tickdir','out','ticklength',[0.05,0.03],...
    'ylim',[0,230],'ytick',[0,100,200],...
    'xtick',[1,2],'xlim',[0.8,2.2],'xticklabels',["1 pulse","10 pulse"],...
    'linewidth',1,'XTickLabelRotation',60,'fontsize',10,'FontName','arial')
saveFigureOutputs("figure1","figure1_H_J");
end

function f = plot_panel_H(PPR)
% Plot paired-pulse response values across sensors on one shared x-axis.

% ISIs used in the paper figure.
isiAll = [10 20 50 100];
xAll = log10(isiAll);
sensorOffset = 0.05;

% Map dataset keys to display labels and colors.
sensorKeys = {'OGB5N','G6f','jG7f','jG8f'};
sensorLabels = {'OGB-5N','GCaMP6f','jGCaMP7f','jGCaMP8f'};
sensorHex = { ...
    '#808080', ...
    pickGCaMPcolorsMS('GCaMP6f'), ...
    pickGCaMPcolorsMS('jGCaMP7f'), ...
    pickGCaMPcolorsMS('jGCaMP8f')};
sensorRgb = cell2mat(cellfun(@hex2rgb, sensorHex(:), 'UniformOutput', false));

present = isfield(PPR, sensorKeys);
sensorKeys = sensorKeys(present);
sensorLabels = sensorLabels(present);
sensorRgb = sensorRgb(present,:);
nSensors = numel(sensorKeys);
if nSensors > 1
    sensorDx = linspace(-sensorOffset, sensorOffset, nSensors);
else
    sensorDx = 0;
end

f = figure('Color','w','Units','centimeters','Position',[2,2,6,5],...
    'PaperUnits','centimeters','PaperPosition',[0,0,6,5]);
ax = axes(f);
hold(ax,'on');

% Reference line: linear response (PPR=1).
hRef = yline(ax,1,':','Color',[0.5 0.5 0.5],'LineWidth',1.5);
hRef.HandleVisibility = 'off';

rng(0); % deterministic jitter
hSummary = gobjects(0);
hSummaryLabels = {};
for iS = 1:nSensors
    key = sensorKeys{iS};
    vals = PPR.(key);
    if ~isnumeric(vals) || isempty(vals)
        continue;
    end

    nIsi = size(vals,2);
    if nIsi == 4
        isi = isiAll;
    elseif nIsi == 2
        isi = [10 100];
    else
        error('Unexpected PPR.%s column count %d; expected 2 or 4.', key, nIsi);
    end
    x = log10(isi(:))' + sensorDx(iS);

    med = nan(1,nIsi);
    lo = nan(1,nIsi);
    hi = nan(1,nIsi);

    for j = 1:nIsi
        y = vals(:,j);
        y = y(isfinite(y));
        if isempty(y)
            continue;
        end

        xj = x(j) + 0.01*randn(size(y)); % small jitter in log10-space
        scatter(ax, xj, y, 22, 'filled', ...
            'MarkerFaceColor', sensorRgb(iS,:), ...
            'MarkerFaceAlpha', 0.35, ...
            'MarkerEdgeColor', 'none', ...
            'HandleVisibility', 'off');

        med(j) = median(y);
        q = prctile(y,[25 75]);
        lo(j) = med(j) - q(1);
        hi(j) = q(2) - med(j);
    end

    good = isfinite(med);
    if any(good)
        legendLabel = sprintf('\\color[rgb]{%.3f %.3f %.3f}%s', ...
            sensorRgb(iS,1), sensorRgb(iS,2), sensorRgb(iS,3), sensorLabels{iS});
        h = errorbar(ax, x(good), med(good), lo(good), hi(good), '-o', ...
            'Color', sensorRgb(iS,:), ...
            'MarkerFaceColor', sensorRgb(iS,:), ...
            'MarkerEdgeColor', [0.9,0.9,0.9], ...
            'LineWidth', 2, ...
            'CapSize', 0, ...
            'DisplayName', legendLabel);
        hSummary(end+1) = h;
        hSummaryLabels{end+1} = legendLabel;
    end
end

ax.XTick = xAll;
ax.XTickLabel = string(isiAll);
ax.XLim = [min(xAll)-0.08, max(xAll)+0.08];
ax.TickDir = 'out';
ax.LineWidth = 1.5;
ax.FontSize = 10;
ax.FontName = 'Arial';

xlabel(ax,'Paired-pulse interval (ms)');
ylabel(ax,{'\DeltaF/F normalized', 'to single pulse'});
ylim(ax,[0,4.5]);

if ~isempty(hSummary)
    lgd = legend(ax, hSummary, hSummaryLabels, ...
        'Location','northoutside', ...
        'Orientation','horizontal', ...
        'Box','off');
    lgd.Interpreter = 'tex';
    lgd.FontSize = 8;
    lgd.NumColumns = 2;
end
end
