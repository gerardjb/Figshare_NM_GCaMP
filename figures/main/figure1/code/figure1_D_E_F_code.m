function figure1_D_E_F_code
%%%
% Plots of single spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Read the reviewed publication values used by the source-data workbook.
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');

% Loop variables
plot_name = ["DFF","SNR","Rise_log"];
panel_name = ["D","E","F"];
csv_name = ["01_Panel_D_points.csv","02_Panel_E_points.csv", ...
    "03_Panel_F_points.csv"];
const_names = ["GCaMP6f","jGCaMP7f","jGCaMP8f","OGB-5N"];
indicator_keys = ["G6f","jG7f","jG8f","O5N"];
% Published construct identity colors; white blending reproduces pale dots.
indicatorColors = [hex2rgb('#0F1C79');hex2rgb('#CC5F09'); ...
    hex2rgb('#9E0142');hex2rgb('#808080')];
displayLabels = ["6f","j7f","j8f","OGB-5N"];


% 
for i_panel = 1:numel(panel_name)
    % Initialize boxplot variables
    g = [];x = [];

    % Open plot panel
    fig=figure('Name',panel_name(i_panel),'Color','w'); hold on;
    set(fig,'PaperUnits','centimeters','PaperSize',[3.5 5.1], ...
        'PaperPosition',[0 0 3.5 5.1],'Units','centimeters', ...
        'Position',[3 3 3.5 5.1]);

    panelTable = readtable(fullfile(d,csv_name(i_panel)), ...
        'TextType','string','VariableNamingRule','preserve');
    present = arrayfun(@(key) any(panelTable.indicator==key),indicator_keys);
    presentIndices = find(present);

    % Arrange data for boxplots and plot points
    for i_present = 1:numel(presentIndices)
        i_const = presentIndices(i_present);
        rows = panelTable.indicator==indicator_keys(i_const);
        these_pts = panelTable.plotted_value(rows);
        these_x = panelTable.stored_x_coordinate(rows)+0.5;
        n_pts = length(these_pts);
        x = [x;these_pts];
        g = [g;repmat(i_present,n_pts,1)];
        plot(these_x,these_pts,...
            'LineStyle','none','Marker','o','MarkerSize',2.2, ...
            'Color',0.5*indicatorColors(i_const,:)+0.5, ...
            'MarkerFaceColor',0.5*indicatorColors(i_const,:)+0.5, ...
            'MarkerEdgeColor','none');
    end

    % Add boxplots
    boxplot(x,g,"Positions",1:numel(presentIndices),"BoxStyle","outline", ...
        "Labels",cellstr(displayLabels(present)),"Colors",[0.65 0.65 0.65], ...
        "Symbol",'');
    set(findobj(gca,'Tag','Box'),'LineWidth',0.75);
    set(findobj(gca,'Tag','Median'),'LineWidth',0.75,'Color',[0.65 0.65 0.65]);
    set(findobj(gca,'Tag','Whisker'),'LineWidth',0.75,'LineStyle','-');
    set(findobj(gca,'Tag','Upper Whisker'),'LineWidth',0.75,'LineStyle','-');
    set(findobj(gca,'Tag','Lower Whisker'),'LineWidth',0.75,'LineStyle','-');
    set(findobj(gca,'Tag','Upper Adjacent Value'),'Visible','off');
    set(findobj(gca,'Tag','Lower Adjacent Value'),'Visible','off');
    set(gca,'FontName','Arial','FontSize',7,'LineWidth',0.75, ...
        'TickDir','out','Box','off','XTickLabelRotation',45);
    
    % Presentation only: preserve canonical points and log10(ms) coordinates.
    switch panel_name(i_panel)
        case "D"
            ylabel('Peak \DeltaF/F'); ylim([0 3.45]); yticks(0:3);
            brackets=[1 2 2.45;2 4 2.45;1 3 2.80;3 4 2.80;1 4 3.15;2 3 2.15];
            bracketLabels={'n.s.','n.s.','**','n.s.','n.s.','**'};
        case "E"
            ylabel('SNR'); ylim([0 20]); yticks(0:5:15);
            brackets=[1 3 18.1;1 2 16.0;2 3 16.0];
            bracketLabels={'***','n.s.','***'};
        case "F"
            ylabel('Bouton 10-90% rise (ms)'); ylim([-1.15 3.25]);
            set(gca,'YTick',[-1 0 1 2], ...
                'YTickLabel',{'0.1','1','10','100'});
            brackets=[1 2 1.982828096512 1.849028427109 2.247483275041 1.5; ...
                2 4 1.982828096512 1.849028427109 2.134186312138 3.0; ...
                1 3 2.404516980356 2.270681839142 2.571199018140 2.0; ...
                3 4 2.404516980356 2.270681839142 2.676408408238 3.5; ...
                1 4 2.838230807977 2.704395666764 3.024386869755 2.5; ...
                2 3 1.678089772058 1.544290102655 1.826645714651 2.5];
            bracketLabels={'n.s.','***','***','n.s.','***','***'};
    end
    for iBracket=1:size(brackets,1)
        addPublishedBracket(gca,brackets(iBracket,:),bracketLabels{iBracket});
    end
end

saveFigureOutputs("figure1","figure1_D_E_F");

end

function addPublishedBracket(ax,row,label)
% Fixed displayed labels used by the published figure.
yl=ylim(ax);span=diff(yl);cap=0.025*span;
if numel(row)>=6
    plot(ax,[row(1) row(1) row(2) row(2)], ...
        [row(4) row(3) row(3) row(4)], ...
        'Color',[0.1 0.1 0.1],'LineWidth',0.75,'Clipping','off');
    text(ax,row(6),row(5),label,'FontName','Arial','FontSize',7, ...
        'HorizontalAlignment','center','VerticalAlignment','top', ...
        'Interpreter','none','Clipping','off');
    return;
end
plot(ax,[row(1) row(1) row(2) row(2)], ...
    [row(3)-cap row(3) row(3) row(3)-cap], ...
    'Color',[0.1 0.1 0.1],'LineWidth',0.75,'Clipping','off');
text(ax,mean(row(1:2)),row(3)+0.008*span,label, ...
    'FontName','Arial','FontSize',7,'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','Interpreter','none','Clipping','off');
end
