function figure3_B_code
%%%
% Figure 3 stopped flow fits for GCaMP6f, jGCaMP7f, and jGCaMP8f based on
% the bipohysical model specific to each variant.
%         
%%%

% Close any open plots
close all

% Collect data files
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');
model_param_stub = ["G6f_simple6","jG7f_simple6","jG8f_simple6"];
csvConst = ["GCaMP6f","jGCaMP7f","jGCaMP8f"];

%Set model color
fCol = [validatecolor(pickGCaMPcolorsMS('biophys_{MC')),0.4];

%% Plots of model fit overlaid to data
%setting plot things
sizer = [5.2,3.4];
f = figure;hold on;
set(f,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[1,1,sizer]);

%Outter tiledlayout
tile_outer = tiledlayout(1,3,"TileSpacing","loose");

for j = 1:length(model_param_stub)   

    %Making name for output .mat file
    const = strtok(model_param_stub(j),'_');

    %Set up plot tiles
    sWid = 1;bWid = 0;%width of each plot
    height = 10;
    til = tiledlayout(tile_outer,height,sWid+bWid,'tilespacing','tight');
    til.Layout.Tile = j;
    
    %Get, prep, and plot data with fits for SF
    kinetics = ["rise","decay"];
    for i = 1:numel(kinetics)
        csvFile = fullfile(d,"Figure3_C_"+csvConst(j)+"_"+kinetics(i)+"_stoppedflow.csv");
        [Time,datasets,thisNormfit] = readStoppedFlowCSV(csvFile);

        %Add SF overlay plot to tile
        nexttile(til,height/2*(sWid+bWid)*(i-1)+1,[height/2,sWid]);hold on;
        set(gca,'tickdir','out','linewidth',1,'TickLength',[0.02,0.02]);
        plot(Time,datasets,...
            'linestyle','-','Color',pickGCaMPcolorsMS(const),'linewidth',1);
        plot(Time,thisNormfit,...
            'color',[fCol],'linewidth',2)
        if i==1
            set(gca,'xticklabels',[])
            %title({'Stopped flow'});
        end
        set(gca,'xlim',[0,400],'xtick',[0,200,400],...
            'ytick',[0,0.5,1],'ylim',[0.0,1.01],...
            'fontname','arial','fontsize',10)
    end
    
    title(til,GCaMPalias(const),'Color',pickGCaMPcolorsMS(const),'FontSize',10,'FontName','arial')
    
    
end%j
ylabel(tile_outer,'Normalized fluorescence','fontname','arial','fontsize',10)
xlabel(tile_outer,'Time (ms)','fontname','arial','fontsize',10)
title(tile_outer,'Model fits (--) to stopped flow','fontname','arial','fontsize',12);

saveFigureOutputs("figure3","figure3_B");
end

function [time,observed,model] = readStoppedFlowCSV(csvFile)
% These are the canonical plotted curves, not a new model fit.
tbl = readtable(csvFile,'VariableNamingRule','preserve');
traceIDs = unique(tbl.trace_index,'stable');
time = []; observed = []; model = [];
for k = 1:numel(traceIDs)
    rows = sortrows(tbl(tbl.trace_index==traceIDs(k),:),'time_ms');
    if k==1
        time = rows.time_ms;
        observed = nan(height(rows),numel(traceIDs));
        model = observed;
    else
        assert(isequaln(time,rows.time_ms),'Stopped-flow CSV trace time grids differ.');
    end
    observed(:,k) = rows.observed_normalized_fluorescence;
    model(:,k) = rows.model_normalized_fluorescence;
end
end
