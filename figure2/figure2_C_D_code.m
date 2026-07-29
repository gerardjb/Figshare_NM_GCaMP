function figure2_C_D_code
%%%
% Plots of stopped flow rise for all variants as in indicated figure
%%%

% Close any open plots
close all

% Open file
d = fileparts(mfilename('fullpath'));
load(fullfile(d,"..","Shared_data","stoppedFlowTraces.mat"));
legacyConstructs = ["OGB1","GCaMP6f","jGCaMP7f","jGCaMP8f"];
processedTraces = cellfun( ...
    @(records) selectConstructRecords(records,legacyConstructs,mfilename), ...
    processedTraces,'UniformOutput',false);

% Hold on for off
xx = processedTraces;
processedTraces = processedTraces{1};

%% On kinetics trace plots
%Different xlimits to accomodate different probe speeds
xlim2s = [25,500,500,500];

%For raw traces
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [7,1.6];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);
ticklengths = [0.03,0.003];

%Tiling of plot panels
tilePerPlot = 8;
tH = tiledlayout(1,length(processedTraces)*tilePerPlot);
tileStarts = [1:tilePerPlot:length(processedTraces)*tilePerPlot];

for i = 1:length(processedTraces)
    cmap(i,:) = pickGCaMPcolorsMS(processedTraces(i).const);
    %Break out values for this variant
    pts = processedTraces(i).logSelectPts;
    t = processedTraces(i).time(pts,:)*1000;
    t(t<3) = nan;% remove values below the effective dead time
    F = processedTraces(i).traces(pts,:);
    F(t<3) = nan;
    ca = processedTraces(i).calcium;

    %Insert subplot, clip limit
    nexttile(tileStarts(i),[1,tilePerPlot-1]);%(1,length(processedTraces),i)
    plot(t,F,'color',cmap(i,:),'linewidth',0.5)
    set(gca,'xlim',[0,xlim2s(i)],'xtick',[0,xlim2s(i)/2,xlim2s(i)])
    box off;
    xtickangle(0);
    
    %Insert text
    currY = -inf;
    for ii = 1:size(F,2)
        thisY = mean(F(find(t(:,ii)<xlim2s(i),3,'last'),ii));
        if ii==size(F,2)&&i==length(processedTraces)
            text(xlim2s(i)+0.01*xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.1f'), ' \muM'],...
                'verticalalignment','middle');
        elseif ii==size(F,2)
            text(xlim2s(i)+0.01*xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.1f')],...
                'verticalalignment','middle');
        elseif abs(currY - thisY)<0.15
            continue;
        elseif ii==1
            text(xlim2s(i)+0.01*xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.0f')],...
                'verticalalignment','middle');
            currY = thisY;
        elseif thisY<0.85
            text(xlim2s(i)+0.01*xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.2f')],...
                'verticalalignment','middle');
            currY = thisY;
        end
        
    end
    %
    if i==1
        set(gca,'ytick',[0,0.5,1]);
        ylabel({'Normalized','fluorescence'})
    else
        set(gca,'ytick',[0,0.5,1],'yticklabel',[]);
    end
    set(gca,'fontname','arial','fontsize',9)
    set(gca,'tickdir','out','ticklength',ticklengths,'linewidth',1)
end

xlabel(tH,'time (ms)','fontname','arial');

%% Off kinetics trace plots
%Different xlimits to accomodate different probe speeds
xlim2s = [25,600,600,600];

% Put the processedTraces back to off
processedTraces = xx{2};

%For raw traces
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [7,1.6];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

%Tiling of plot panels
tilePerPlot = 8;
tH = tiledlayout(1,length(processedTraces)*tilePerPlot);
tileStarts = [1:tilePerPlot:length(processedTraces)*tilePerPlot];

for i = 1:length(processedTraces)
    cmap(i,:) = pickGCaMPcolorsMS(processedTraces(i).const);
    
    %Break out values for this variant
    pts = processedTraces(i).logSelectPts;
    t = processedTraces(i).time(pts,:)*1000;
    t(t<3) = nan;
    F = processedTraces(i).traces(pts,:);
    F(t<3) = nan;
    ca = processedTraces(i).calcium;
    if strcmp(processedTraces(i).const,'OGB1');prePts=100;else;prePts = 5;end%Number of points to display for baseline
    
    %Insert subplot, clip limit
    nexttile(tileStarts(i),[1,tilePerPlot-1]);%(1,length(processedTraces),i)
    plot(processedTraces(i).preTime(end-prePts:end)*1000,processedTraces(i).preTrace(end-prePts:end),...
        'color',cmap(i,:),'linewidth',0.5);
    hold on;
    plot(t,F,'color',cmap(i,:),'linewidth',0.5)
    set(gca,'xlim',[processedTraces(i).preTime(end-prePts)*1000,xlim2s(i)],'xtick',[0,xlim2s(i)/2,xlim2s(i)])
    box off;
    xtickangle(0);
    
    %Insert text
    currY = -inf;
    for ii = 1:size(F,2)
        thisY = mean(F(find(t(:,ii)<xlim2s(i),3,'last'),ii));
        if ii==size(F,2)&&i==length(processedTraces)
            text(xlim2s(i),thisY+0.13,...
                [num2str(ca(ii)/1000,'%0.2f'), ' \muM'],...
                'verticalalignment','middle');
        elseif ii==size(F,2)
            text(xlim2s(i),thisY+0.13,...
                [num2str(ca(ii)/1000,'%0.2f')],...
                'verticalalignment','middle');
        elseif abs(currY - thisY)<0.15
            continue;
        elseif ii==1
            text(xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.2f')],...
                'verticalalignment','middle');
            currY = thisY;
        elseif thisY<0.85
            text(xlim2s(i),thisY,...
                [num2str(ca(ii)/1000,'%0.2f')],...
                'verticalalignment','middle');
            currY = thisY;
        end
        
    end
    %
    if i==1
        set(gca,'ytick',[0,0.5,1]);
        ylabel({'Normalized','fluorescence'})
    else
        set(gca,'ytick',[0,0.5,1],'yticklabel',[]);
    end
    set(gca,'fontname','arial','fontsize',9)
    set(gca,'tickdir','out','ticklength',ticklengths,'linewidth',1)
end

xlabel(tH,'time (ms)','fontname','arial');

saveFigureOutputs("figure2","figure2_C_D");
