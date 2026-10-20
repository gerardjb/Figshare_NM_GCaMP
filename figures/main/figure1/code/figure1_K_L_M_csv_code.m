function figure1_K_L_M_csv_code
% Plot Figure 1 K-M from the reviewed display/source-data CSVs.
close all
d = fullfile(fileparts(mfilename('fullpath')),'..','source_data');
raw=readtable(fullfile(d,'K_raw_examples.csv'),'VariableNamingRule','preserve');
aligned=readtable(fullfile(d,'K_aligned_examples.csv'),'VariableNamingRule','preserve');
fitted=readtable(fullfile(d,'K_fitted_examples.csv'),'VariableNamingRule','preserve');
spikes=readtable(fullfile(d,'K_spikes_examples.csv'),'VariableNamingRule','preserve');
events=readtable(fullfile(d,'M_finite_SNR_filtered_tau_events.csv'), ...
    'TextType','string','VariableNamingRule','preserve');
rng(0);

f=figure('Color','w'); sizeIn=[7.5,3.5];
set(f,'PaperUnits','inches','PaperSize',sizeIn,'PaperPosition',[0 0 sizeIn], ...
    'Units','inches','Position',[1 1 sizeIn]);
t=tiledlayout(f,2,5,'TileSpacing','compact','Padding','compact');
baseColor=hex2rgb(pickGCaMPcolorsMS('jGCaMP8f'));
exampleRows=unique(raw.source_event_row,'stable');

for iExample=1:numel(exampleRows)
    ax=nexttile(t,1+(iExample-1)*5,[1,2]); hold(ax,'on'); id=exampleRows(iExample);
    rr=raw.source_event_row==id; aa=aligned.source_event_row==id; ff=fitted.source_event_row==id;
    plot(ax,raw.time_s(rr),raw.baseline_subtracted_DeltaF_over_F(rr), ...
        'Color',[baseColor 0.35],'LineWidth',0.7);
    plot(ax,aligned.time_s(aa),aligned.aligned_DeltaF_over_F(aa), ...
        'Color',baseColor,'LineWidth',1.4);
    plot(ax,fitted.time_s(ff),fitted.fitted_DeltaF_over_F(ff),'k','LineWidth',1.5);
    ss=spikes.source_event_row==id; yl=ylim(ax); spikeTimes=spikes.spike_time_s(ss);
    for x=spikeTimes'
        if abs(x)<=1e-6
            plot(ax,[x x],yl,'k--','LineWidth',1.4);
        else
            plot(ax,[x x],yl,'--','Color',[0.7 0.7 0.7],'LineWidth',0.7);
        end
    end
    nPrior=sum(spikeTimes<0);
    text(ax,0.02,0.08,sprintf('%d Spikes',nPrior),'Units','normalized', ...
        'Color',[0.7 0.7 0.7],'HorizontalAlignment','left');
    text(ax,0,yl(1)+0.08*range(yl),{'Last','spike'}, ...
        'Color','k','HorizontalAlignment','left','VerticalAlignment','bottom');
    set(ax,'XLim',[-0.5 1],'Visible','off');
    if iExample==1, title(ax,'Janelia in vivo low activity example');
    else, title(ax,'Janelia in vivo high activity example'); end
    set(get(ax,'Title'),'Visible','on');
    addKScaleBar(ax,ternary(iExample==1,0.1,0.4));
end

binLabels=["1","2-3","4-5","6-8","9+"];
colors=baseColor+(1-baseColor).*linspace(0,0.85,numel(binLabels))';
for normalized=0:1
    ax=nexttile(t,3+normalized*5,[1,2]); hold(ax,'on');
    traceHandles=gobjects(numel(binLabels),1);
    for iBin=1:5
        meanTable=readtable(fullfile(d,sprintf('%02d_L_bin%d_mean_trace_bgnd_s.csv', ...
            35+4*iBin,iBin)),'VariableNamingRule','preserve');
        time=meanTable{:,2};
        inWindow=time>=0 & time<=1;
        time=time(inWindow); y=meanTable{inWindow,3};
        if normalized
            finiteY=y(isfinite(y));
            if isempty(finiteY)
                continue
            end
            lo=min(finiteY); hi=max(finiteY);
            if hi>lo, y=(y-lo)/(hi-lo); else, y=zeros(size(y)); end
        end
        traceHandles(iBin)=plot(ax,time,y,'Color',colors(iBin,:),'LineWidth',1.25);
    end
    line(ax,xlim(ax),[0 0],'Color','k','LineStyle',':');
    set(ax,'XLim',[0 1],'Visible','off');
    if normalized, title(ax,'Last-aligned normalized');
    else
        title(ax,'Last-aligned averages');
        lg=legend(ax,traceHandles,cellstr(binLabels),'Box','off','Location','east');
        lg.Title.String='Spike #'; lg.AutoUpdate='off';
    end
    set(get(ax,'Title'),'Visible','on');
    addLScaleBar(ax,normalized==0);
end

ax=nexttile(t,5,[2,1]); hold(ax,'on');
selected=events.selected_for_M==1 & isfinite(events.tau_fast_s);
for iBin=1:5
    rows=selected & events.bin_index==iBin;
    yAll=events.tau_fast_s(rows);
    if isempty(yAll), continue; end
    yScatter=yAll;
    stream=RandStream('mt19937ar','Seed',1+iBin+sum(double('tau_fast_s')));
    if numel(yScatter)>100
        order=randperm(stream,numel(yScatter)); yScatter=yScatter(order(1:100));
    end
    x=iBin+0.18*(rand(stream,size(yScatter))-0.5);
    scatter(ax,x,yScatter,10,colors(iBin,:),'filled', ...
        'MarkerEdgeColor','none','MarkerFaceAlpha',0.3);
    drawBoxSummary(ax,iBin,yAll,[0.7 0.7 0.7]);
end
set(ax,'XLim',[0.5 5.5],'XTick',1:5,'XTickLabel',binLabels, ...
    'YLim',[-0.005 0.2],'TickDir','out','LineWidth',1);
xlabel(ax,'Spikes'); ylabel(ax,'\tau_{fast} (s)');
set(findall(f,'Type','axes'),'FontName','Arial','FontSize',9, ...
    'TitleFontSizeMultiplier',1,'TitleFontWeight','normal');
saveFigureOutputs('figure1','figure1_K_L_M',f);
end

function drawBoxSummary(ax,x,y,gray)
q=prctile(y,[25 50 75]); iqrValue=q(3)-q(1);
inlier=y(y>=q(1)-1.5*iqrValue & y<=q(3)+1.5*iqrValue);
if isempty(inlier), inlier=y; end
whiskerLow=min(inlier); whiskerHigh=max(inlier); width=0.42;
line(ax,[x x],[whiskerLow q(1)],'Color',gray,'LineWidth',1.5);
line(ax,[x x],[q(3) whiskerHigh],'Color',gray,'LineWidth',1.5);
patch(ax,x+[-width -width width width]/2,[q(1) q(3) q(3) q(1)],'w', ...
    'EdgeColor',gray,'LineWidth',1.5,'FaceAlpha',0);
line(ax,x+[-width width]/2,[q(2) q(2)],'Color',gray,'LineWidth',1.5);
end

function addKScaleBar(ax,yLength)
yl=ylim(ax); x0=0.35; x1=0.85; y0=yl(2)-0.20*range(yl);
plot(ax,[x0 x1],[y0 y0],'k-','LineWidth',1.2,'HandleVisibility','off');
plot(ax,[x0 x0],[y0-yLength y0],'k-','LineWidth',1.2,'HandleVisibility','off');
text(ax,(x0+x1)/2,y0+0.04*range(yl),'500 ms', ...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8);
text(ax,x0-0.03,y0-yLength/2,sprintf('%.1f \\DeltaF/F',yLength), ...
    'HorizontalAlignment','right','VerticalAlignment','middle','Interpreter','tex','FontSize',8);
end

function addLScaleBar(ax,includeY)
yl=ylim(ax); x0=0.55; x1=0.90; y0=yl(2)-0.20*range(yl);
if includeY, x0=0.15; x1=0.50; end
plot(ax,[x0 x1],[y0 y0],'k-','LineWidth',1.2,'HandleVisibility','off');
text(ax,(x0+x1)/2,y0+0.04*range(yl),'350 ms', ...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8);
if includeY
    plot(ax,[x0 x0],[y0-0.2 y0],'k-','LineWidth',1.2,'HandleVisibility','off');
    text(ax,-0.05,y0-0.1,'0.2 \DeltaF/F','HorizontalAlignment','right', ...
        'VerticalAlignment','middle','Interpreter','tex','FontSize',8,'Clipping','off');
end
end

function out=ternary(condition,a,b)
if condition, out=a; else, out=b; end
end
