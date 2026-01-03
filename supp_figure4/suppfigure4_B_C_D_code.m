function suppfigure4_B_C_D_code
%%%
% Plots of decay and biexponential fits as in indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,'..','Shared_data','stoppedFlowTraces.mat'),'processedTraces');
processedTraces = processedTraces{1};

% Plot setup
cmap = zeros(length(processedTraces),3);
ticklengths = [0.03,0.003];
refit = 1;

%% Raw trace plots
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


%% Fits and overlay plots
%Fitting functions and fit options
exp1 = @(t_off,tau,ss,x) ss*(1-exp(-(x-t_off)/tau));
exp2 = @(t_off,frac1,tau1,tau2,ss,x) ...
    ss*(1 - (frac1*exp(-(x-t_off)/tau1) + (1-frac1)*exp(-(x-t_off)/tau2)));
lb1 = [0.0005,0,0];lb2 = [0.0005,0,0,0,0];
ub1 = [0.001,10,1];ub2 = [0.001,1,10,10,1];
start1 = [0,0.05,0.5];start2 = [0,0.5,0.01,0.1,0.5];

%For plotting each vaiant's panel
goodTrace = {[2,4,5],[4,5,6],[4,5,6],[4,5,6]};
allTrace = {1:9,1:9,1:9,1:9};
xlim2s = [10,500,500,500];
    
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
        thisSS = mean(f(end-50:end));
        f_s = contrastStretch(f,[0,thisSS],[0,1]);
        t = processedTraces(j).time(:,allTrace{j}(i));
        
        %Finding points to fit and plot
        crit = 0.95;
        idxStart = find(t>0.003,1);
        idxCrit = find(smooth(f_s,25)>crit,1);
        
        %Only required if re-doing fits, else use saved ones
        if refit
            try
                %get the criterion fluorescence decrease for fit by smoothing
                start1(end) = thisSS;start2(end) = thisSS;
                ub1(end) = thisSS + 0.002*thisSS;ub2(end) = thisSS + 0.002*thisSS;
                lb1(end) = thisSS - 0.002*thisSS;lb2(end) = thisSS - 0.002*thisSS;
                fo1 = fitoptions('method','Nonlinearleastsquares',...
                'Lower',lb1,'Upper',ub1,'Startpoint',start1);
                fo2 = fitoptions('method','Nonlinearleastsquares',...
                    'Lower',lb2,'Upper',ub2,'Startpoint',start2);
                

                %Make a double and single exponential fit, then compare
                %Adjusted R-squared values
                [thisFit2,thisGof2] = fit(t(idxStart:idxCrit),f(idxStart:idxCrit),...
                    exp2,fo2);
                [thisFit1,thisGof1] = fit(t(idxStart:idxCrit),f(idxStart:idxCrit),...
                    exp1,fo1);
                if thisGof2.adjrsquare>thisGof1.adjrsquare+0.003*thisGof1.adjrsquare
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
            fHat_s = contrastStretch(processedTraces(j).fits{i}(t),...
                [0,processedTraces(j).fits{i}(t(end))],[0,1]);%
            plot(t(idxStart:5:idxCrit)*1000,1-f_s(idxStart:5:idxCrit),...
                'color',cmap(j,:));
            plot(t(1:idxCrit)*1000,1-fHat_s(1:idxCrit),...
                'color',[0.2,0.2,0.2,0.2],'linewidth',1.4);%[255/255,190/255,20/255]);%
            %add uM suffix for right-most concentration text
            if j==length(processedTraces) && ii==1
                concSuffix = '[Ca^{2+}] (\muM)';
            else
                concSuffix = '';
            end
            text(min(t(idxCrit)*1000,xlim2s(j)),...
                1-fHat_s(min(idxCrit,find(t*1000>xlim2s(j),1,'first')-1)),...
                [num2str(processedTraces(j).calcium(i)/1000,'%.2f'),concSuffix],...
                'horizontalalignment',horzAlign{ii},...
                'verticalalignment','bottom');
            ii = ii+1;
        end
    end
    
    set(gca,'yscale','log','tickdir','out','linewidth',1);
    set(gca,'ylim',[1-(crit+0.02),1],'xlim',[2,xlim2s(j)],...
        'xtick',[xlim2s(j)/2,xlim2s(j)],'YDir','reverse',...
        'ticklength',ticklengths)

    if j==1
        set(gca,'ytick',[1-crit,0.1,0.5,1],...
            'yticklabel',cellstr(string([1-crit,0.1,0.5,1]*100)));%
        ylabel('100 - %F_{max}')
    else
        set(gca,'yticklabel',[])
    end
    set(gca,'fontname','arial','fontsize',9)
    
end

xlabel(tH,'time (ms)')


%% Sample trace for demonstration of the analysis
%Functions for separating kinetic contributors
exp_fit1 = @(fitted,time) fitted.ss*fitted.frac1*(1-(exp(-(time-fitted.t_off)/fitted.tau1)));
exp_fit2 = @(fitted,time) fitted.ss*(1-fitted.frac1)*(1-(exp(-(time-fitted.t_off)/fitted.tau2)))+fitted.ss*fitted.frac1;

%Get and process a sample trace
sample_const = 4;
sample_trace = 5;
this_fit = processedTraces(sample_const).fits{sample_trace};
f = processedTraces(sample_const).traces(:,allTrace{sample_const}(sample_trace));
thisSS = mean(f(end-50:end));
f_s = contrastStretch(f,[0,thisSS],[0,1]);
t = processedTraces(sample_const).time(:,allTrace{sample_const}(sample_trace));
fHat_s = contrastStretch(this_fit(t),...
    [0,this_fit(t(end))],[0,1]);%
exp1 = exp_fit1(this_fit,t);
exp1_s = contrastStretch(exp1,...
    [0,this_fit(t(end))],[0,1]);%
exp2 = exp_fit2(this_fit,t);
exp2_s = contrastStretch(exp2,...
    [0,this_fit(t(end))],[0,1]);%

%Finding points to fit and plot
crit = 0.95;
crit_exp = 0.99;
idxStart = find(t>0.003,1);
idxCrit = find(smooth(f_s,25)>crit,1);
idxCrit_exp1 = find(exp1_s/this_fit.frac1>crit_exp,1);
xlim2s = [10,1000,500,500];

%plot
%formatting
fTrace_sample = figure;hold on;
sizerTrace_sample = [1.4,3];
set(fTrace_sample,'Paperunits','inches',...
    'Papersize',sizerTrace_sample,...
    'Paperposition',[0,0,sizerTrace_sample],...
    'Units','inches',...
    'Position',[2,2,sizerTrace_sample]);
show_linear = false;
if show_linear
    tH = tiledlayout(2,1);
    %placing linear plot
    nexttile;hold on;
    plot(t(t<0.5)*1000,f_s(t<0.5),'color',cmap(sample_const,:));
    plot(t(t<0.5)*1000,exp1_s(t<0.5),...
        'color',[0.2,0.2,0.2,0.8],'linewidth',1.4);
    plot(t(t<0.5)*1000,exp2_s(t<0.5),...
        'color',[0.8,0.8,0.8,0.8],'linewidth',1.4);
    %formatting linear plot
    set(gca,'tickdir','out','linewidth',1);
    set(gca,'xlim',[-10,xlim2s(sample_const)],...
        'xtick',[xlim2s(sample_const)/2,xlim2s(sample_const)],...
        'ticklength',ticklengths);
    %placing log plot
    nexttile;
end
hold on;
plot(t(idxStart:5:idxCrit)*1000,1-f_s(idxStart:5:idxCrit),...
    'color',cmap(sample_const,:));
plot(t(1:5:idxCrit)*1000,1-exp1_s(1:5:idxCrit),...
    'color',[0.1,0.1,0.1,0.9],'linewidth',2);
text(t(idxCrit_exp1)*1000,this_fit.frac1/2,{['\tau_{fast} = ',num2str(this_fit.tau1*1000,'%0.0f'), ' ms'],...
    ['proportion = ',num2str(this_fit.frac1,2)]},...
    'HorizontalAlignment','left');
plot(t(1:5:idxCrit)*1000,1-exp2_s(1:5:idxCrit),...
    'color',[0.8,0.8,0.8,0.9],'linewidth',2);
text(t(round(idxCrit_exp1))*1000,this_fit.frac1/5,['\tau_{slow} = ',num2str(this_fit.tau2*1000,'%0.0f'), ' ms'],...
     'color',[0.8,0.8,0.8,0.9],...
    'HorizontalAlignment','left');
%fomatting
set(gca,'yscale','log','tickdir','out','linewidth',1);
set(gca,'ylim',[1-(crit+0.02),1],'xlim',[-10,xlim2s(sample_const)],...
    'xtick',[xlim2s(sample_const)/2,xlim2s(sample_const)],'YDir','reverse',...
    'ticklength',ticklengths);
set(gca,'ytick',[1-crit,0.1,0.5,1],...
    'yticklabel',cellstr(string([1-crit,0.1,0.5,1]*100)));%
ylabel('100 - %F_{max}');
xlabel('Time (ms)');
title({'Sample exponential','analysis'});



%% Figure for component taus and magnitude

%Figure for exponential rise components
fSum = figure;hold on;
sizerSum = [7,2.2];
set(fSum,'Paperunits','inches',...
    'Papersize',sizerSum,...
    'Paperposition',[0,0,sizerSum],...
    'Units','inches',...
    'Position',[2,2,sizerSum]);

%Tiling of plot panels
tilePerPlot = 8;
nVertTiles = 8;
tspan = nVertTiles - 3;
bspan = nVertTiles - (tspan);
nHorzTiles = length(processedTraces)*tilePerPlot;
tH = tiledlayout(nVertTiles,nHorzTiles);
tileStarts = [1:tilePerPlot:length(processedTraces)*tilePerPlot];

%pack out
all_taus = {};
all_proportions1 = {};

for i = 1:length(processedTraces)
    
    %Separate nan from successful fits
    goodFits = find(~(cellfun(@isnumeric,processedTraces(i).fits(:))));%b/c isnumeric gets the NaNs
    betterFits = cellfun(@(x) x.ss>0.03,processedTraces(i).fits(goodFits));%because we don't want traces with less than 3% change
    theseFits = processedTraces(i).fits(goodFits(betterFits));
    ca = processedTraces(i).calcium(goodFits(betterFits));
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
    
    %pack out
    all_taus{i} = taus;
    all_proportions1{i} = proportions1;

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
        goodIdx = ~isnan(taus(ii,:));
        %Where to put the next panel
        thisAx = nexttile(tileStarts(i),[tspan,tilePerPlot-1]);hold on;
        tintAmp = 0.75;
        tint = (1 - cmap(i,:))*tintAmp*(ii-1);
        
        %Plotting concentrations in muM, time in ms
        plot(thisAx,ca(goodIdx)/1000,taus(ii,goodIdx)*1000,...
            'color',cmap(i,:)+tint,'markerfacecolor',cmap(i,:)+tint,...
            'linestyle',linStyles{ii},'marker',markers{ii},...
            'markersize',4);
        xtickangle(0)
        
        set(gca,'yscale','log','ylim',[0.7,1000],...
            'ytick',[1,10,100,1000],'yticklabel',[],...
            'tickdir','out','linewidth',1,'ticklength',ticklengths);
        %ylabel for left-most plot
        if i==1
            ylabel('\tau_{Rise} (ms)')
            set(gca,'yticklabel',cellstr(string([1,10,100,1000])));
        end
        set(gca,'xlim',[0.01,20],'xtick',[0.01,0.1,1,10],...
            'xticklabel',cellstr(string([])),...
            'xscale','log');
        
        %Plotting contribution of the fast process
        if ii==1
            thisAx = nexttile((nVertTiles-bspan)*nHorzTiles+tileStarts(i),...
                [bspan,tilePerPlot-1]);hold on;


            h = bar(repmat(log10(ca'/1000),1,2),cat(2,fracs{ii}'*100,(1-fracs{ii}')*100),...
                0.6,'stacked');
            h(1).FaceColor = cmap(i,:);h(1).EdgeColor = cmap(i,:);
            h(2).FaceColor = cmap(i,:) + (1-cmap(i,:))*tintAmp;h(2).EdgeColor = cmap(i,:) + (1-cmap(i,:))*tintAmp;
            set(gca,'ylim',[0,101],'ytick',[0,50,100],'yticklabel',[],...
                'xlim',log10([0.01,20]),'xtick',log10([0.01,0.1,1,10]),'xticklabel',cellstr(string([0.01,0.1,1,10])),...
                'tickdir','out','linewidth',1,'ticklength',ticklengths);
            xtickangle(0)
            if i==1
                %ylabel({'% Fluorescence from',['fast process (',char(9632),')']})
                ylabel({'% process', ['contribution']})
                set(gca,'yticklabel',cellstr(string([0,50,100])));
            end
            
        end
    end
    
    
    set(gca,'fontname','arial','fontsize',9)


    
end
xlabel(tH,'[Ca^{2+}] (\muM)')
