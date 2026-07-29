function suppfigure4_F_G_H_code
%%%
% Plots of decay and biexponential fits as in indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,'..','Shared_data','stoppedFlowTraces.mat'),'processedTraces');
processedTraces = processedTraces{2};
processedTraces = selectConstructRecords(processedTraces, ...
    ["OGB1","GCaMP6f","jGCaMP7f","jGCaMP8f"],mfilename);

%% Raw trace plots
%Different xlimits to accomodate different probe speeds
ticklengths = [0.03,0.003];
xlim2s = [25,600,600,600];
refit = 1;

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
    cmap(i,:) = hex2rgb(pickGCaMPcolorsMS(processedTraces(i).const));
    
    %Break out values for this variant
    pts = processedTraces(i).logSelectPts;
    t = processedTraces(i).time(pts,:)*1000;
    t(t<3) = nan;
    F = processedTraces(i).traces(pts,:);
    F(t<3) = nan;
    ca = processedTraces(i).calcium;
    if strcmp(processedTraces(i).const,'OGB1');prePts=100;else;prePts = 5;end%Number of points to display for baseline
    
    %Insert subplot, clip limit
    nexttile(tileStarts(i),[1,tilePerPlot-1]);%
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


%% Fits and overlay plots
%Fitting functions and fit options
exp1 = @(t_off,tau,ss,x) ss*(exp(-(x-t_off)/tau));
exp2 = @(t_off,frac1,tau1,tau2,ss,x) ...
    ss*(frac1*exp(-(x-t_off)/tau1) + (1-frac1)*exp(-(x-t_off)/tau2));
lb1 = [0.0002,0,0.999];lb2 = [0.0005,0,0,0,0];
ub1 = [0.001,10,1.001];ub2 = [0.001,1,10,10,1];
start1 = [0.0005,0.05,1];start2 = [0.0005,0.99,0.01,0.2,1];

%For plotting each vaiant's panel
goodTrace = {[1,2],[1,2],[1,2],[1,2]};
allTrace = {1:2,1:2,1:2,1:2};
xlim2s = [15,600,600,600];
    
%Figure for traces with fits overlaid
fTrace = figure;hold on;
sizerTrace = [7,1.6];
set(fTrace,'Paperunits','inches',...
    'Papersize',sizerTrace,...
    'Paperposition',[0,0,sizerTrace],...
    'Units','inches',...
    'Position',[2,2,sizerTrace]);  

%Tiling of plot panels
tilePerPlot = 8;
tH = tiledlayout(1,length(processedTraces)*tilePerPlot);
tileStarts = [1:tilePerPlot:length(processedTraces)*tilePerPlot];

for j = 1:length(processedTraces)
    
    %For spacing of text labels
    horzAlign = {'center','center','center'};
    ii = 1;
    
    %Where to put the next panel
    nexttile(tileStarts(j),[1,tilePerPlot-1]);hold on;
    
    %Processing traces for log display and biexponential fit overlay
    for i = 1:length(allTrace{j})
        %get and stretch trace
        f = processedTraces(j).traces(:,allTrace{j}(i));
        thisSS = 1;%mean(f(1:3));
        f_s = contrastStretch(f,[mean(f(end-50:end)),thisSS],[0,1]);
        t = processedTraces(j).time(:,allTrace{j}(i));
        
        %Finding points to fit and plot
        crit = 0.01;
        idxStart = find(t>0.003,1);
        idxCrit = find(smooth(f_s,100)<crit,1);
        
        %Only required if re-doing fits, else use saved ones
        if refit
            try
                %get the criterion fluorescence decrease for fit by smoothing
                start1(end) = thisSS;start2(end) = thisSS;
                fo1 = fitoptions('method','Nonlinearleastsquares',...
                    'Lower',lb1,'Upper',ub1,'Startpoint',start1);
                fo2 = fitoptions('method','Nonlinearleastsquares',...
                    'Lower',lb2,'Upper',ub2,'Startpoint',start2);
                

                %Make a double and single exponential fit, then compare
                %Adjusted R-squared values
                [thisFit2,thisGof2] = fit(t(idxStart:idxCrit),f_s(idxStart:idxCrit),...
                    exp2,fo2);
                [thisFit1,thisGof1] = fit(t(idxStart:idxCrit),f_s(idxStart:idxCrit),...
                    exp1,fo1);
                if thisGof2.adjrsquare>thisGof1.adjrsquare+0.0008*thisGof1.adjrsquare
                    thisFit = thisFit2;
                else
                    thisFit = thisFit1;
                end
                thisGof = {thisGof1,thisGof2};
                
            catch
                %if fit fails (like on flat trace) input nan
                thisFit = NaN;thisGof = NaN;
            end
            
            %f_s = contrastStretch(f_s,[0,1],[0,1]);
            processedTraces(j).fits{i} = thisFit;
            processedTraces(j).gofs{i} = thisGof;
        end

        %Make trace with overlay plot
        if ismember(i,goodTrace{j})
            fHat_s = thisFit(t);
            plot(t(idxStart:10:idxCrit)*1000,f_s(idxStart:10:idxCrit),...
                'color',cmap(j,:));
            plot(t(1:idxCrit)*1000,fHat_s(1:idxCrit),...
                'color',[0.2,0.2,0.2,0.2],'linewidth',1.4);%[255/255,190/255,20/255]);%
            %add uM suffix for right-most concentration text
            if j==length(processedTraces) && ii==1
                concSuffix = '[Ca^{2+}] (\muM)';
            else
                concSuffix = '';
            end
            text(min(t(idxCrit)*1000,xlim2s(j)),...
                1-(ii-1)*0.8,...
                [num2str(processedTraces(j).calcium(i)/1000,'%.2f'),concSuffix],...
                'horizontalalignment',horzAlign{ii},...
                'verticalalignment','bottom');
            ii = ii+1;
        end
    end
    
    set(gca,'yscale','log','tickdir','out','linewidth',1);
    set(gca,'ylim',[(crit-0.004),1],'xlim',[2,xlim2s(j)],...
        'xtick',[xlim2s(j)/2,xlim2s(j)],...
        'ticklength',ticklengths)

    if j==1
        set(gca,'ytick',[crit,0.1,0.5,1],...
            'yticklabel',cellstr(string([crit,0.1,0.5,1]*100)));%
        ylabel('%F_{max}')
    else
        set(gca,'yticklabel',[])
    end
    set(gca,'fontname','arial','fontsize',9)
    

end

xlabel(tH,'time (ms)')


%% Figure for component taus and magnitude

%Figure for exponential rise components
fSum = figure;hold on;
sizerSum = [7,2.2];
set(fSum,'Paperunits','inches',...
    'Papersize',sizerSum,...
    'Paperposition',[0,0,sizerSum],...
    'Units','inches',...
    'Position',[2,2,sizerSum]);
xlims = [0.75,2.25];

%Tiling of plot panels
tilePerPlot = 8;
nVertTiles = 8;
tspan = nVertTiles - 3;
bspan = nVertTiles - (tspan);
nHorzTiles = length(processedTraces)*tilePerPlot;
tH = tiledlayout(nVertTiles,nHorzTiles);
tileStarts = [1:tilePerPlot:length(processedTraces)*tilePerPlot];

% %Variable to hold percent fluorescence contributions
% fGroupBar = zeros(length(processedTraces(1).calcium),...calcium step
%     length(processedTraces),...construct
%     2);%percent contribution

for i = 1:length(processedTraces)
    
    %Separate nan from successful fits
    theseFits = processedTraces(i).fits;
    ca = processedTraces(i).calcium;
    exp1Fits = cellfun(@(x) ismember('tau',fieldnames(x)),...
        theseFits);
    exp2Fits = ~exp1Fits;
    
    %Get data and error bars
    taus = nan(2,length(theseFits));
    proportions1 = zeros(1,length(theseFits));
    for ii = 1:length(theseFits)
        if ismember('tau',fieldnames(theseFits{ii}))
            taus(2,ii) = theseFits{ii}.tau;
            proportions1(ii) = 0;
        elseif ismember('tau1',fieldnames(theseFits{ii}))
            taus(:,ii) = [theseFits{ii}.tau1;theseFits{ii}.tau2];
            proportions1(ii) = theseFits{ii}.frac1;
        end
    end
    
    %Make the plots for each variant
    
    markers = {'^','o'};
    linStyles = {'-','-'};
    fracs = {proportions1,1-proportions1};
    
    %Correct the ordering for OGB1
    if strcmp('OGB1',processedTraces(i).const)
        taus = taus([2,1],:);
        fracs = fracs([2,1]);
    end
    
    for ii =1:2
        %Where to put the next panel
        thisAx = nexttile(tileStarts(i),[tspan,tilePerPlot-1]);hold on;
        %Colors for the plot
        tintAmp = 0.75;
        tint = (1 - cmap(i,:))*tintAmp*(ii-1);
        
        
        %Plotting concentrations in muM, time in ms
        plot(thisAx,[1,2],taus(ii,:)*1000,...
            'color',cmap(i,:)+tint,'markerfacecolor',cmap(i,:)+tint,...
            'linestyle',linStyles{ii},'marker',markers{ii},...
            'markersize',4);
        xtickangle(0)
        
        set(gca,'yscale','log','ylim',[2,1500],...
            'ytick',[10,100,1000],'yticklabel',[10,100,1000],...
            'tickdir','out','linewidth',1,'ticklength',ticklengths);
        %ylabel for left-most plot
        if i==1
            ylabel('\tau_{Decay} (ms)')
            set(gca,'yticklabel',cellstr(string([10,100,1000])));
            
        end
        set(gca,'xlim',xlims,'xtick',[1,2],...
            'xticklabel',cellstr(string([])),...
            'xscale','linear');
        
        %Getting contribution of fast and slow process for this variant
        if ii==1
            thisAx = nexttile((nVertTiles-bspan)*nHorzTiles+tileStarts(i),...
                [bspan,tilePerPlot-1]);hold on;


            h = bar(repmat([1;2],1,2),cat(2,fracs{ii}'*100,(1-fracs{ii}')*100),...
                0.1,'stacked');
            h(1).FaceColor = cmap(i,:);h(1).EdgeColor = cmap(i,:);
            h(2).FaceColor = cmap(i,:) + (1-cmap(i,:))*tintAmp;h(2).EdgeColor = cmap(i,:) + (1-cmap(i,:))*tintAmp;
            set(gca,'ylim',[0,101],'ytick',[0,50,100],'yticklabel',[],...
                'xlim',xlims,'xtick',[1,2],'xticklabel',cellstr(string(ca/1000)),...
                'tickdir','out','linewidth',1,'ticklength',ticklengths);
            xtickangle(0)
            if i==1
                ylabel({'% process', ['contribution']})
                set(gca,'yticklabel',cellstr(string([0,50,100])));
            end    
        end
    end
    
    
    set(gca,'fontname','arial','fontsize',9)


    
end
xlabel(tH,'[Ca^{2+}] (\muM)')

saveFigureOutputs("supp_figure4","suppfigure4_F_G_H");
