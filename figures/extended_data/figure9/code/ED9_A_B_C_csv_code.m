function h = ED9_A_B_C_csv_code
% Render ED9 A-C directly from the reviewed source-data CSVs.
close all
sourceDir = fullfile(fileparts(mfilename('fullpath')),'..','source_data');
raw = readtable(fullfile(sourceDir,'A_raw_example_traces.csv'),'VariableNamingRule','preserve');
aligned = readtable(fullfile(sourceDir,'A_aligned_example_traces.csv'),'VariableNamingRule','preserve');
fitted = readtable(fullfile(sourceDir,'A_fitted_example_traces.csv'),'VariableNamingRule','preserve');
spikes = readtable(fullfile(sourceDir,'A_example_spikes.csv'),'VariableNamingRule','preserve');
means = readtable(fullfile(sourceDir,'01_Mean_decay_traces.csv'),'TextType','string','VariableNamingRule','preserve');
events = readtable(fullfile(sourceDir,'C_stored_event_parameters.csv'),'VariableNamingRule','preserve');

h = figure('Color','w'); sizeIn=[8.2,3.4];
set(h,'PaperUnits','inches','PaperSize',sizeIn,'PaperPosition',[0,0,sizeIn], ...
    'Units','inches','Position',[1,1,sizeIn]);
t = tiledlayout(h,6,12,'TileSpacing','compact','Padding','compact');
purple = hex2rgb(pickGCaMPcolorsMS('jGCaMP8m'));

exampleRows = unique(raw.source_event_row,'stable');
for iExample=1:numel(exampleRows)
    ax=nexttile(t,(iExample-1)*3*12+1,[3,4]); hold(ax,'on');
    id=exampleRows(iExample);
    rr=raw.source_event_row==id; aa=aligned.source_event_row==id; ff=fitted.source_event_row==id;
    plot(ax,raw.time_s(rr),raw.baseline_subtracted_DeltaF_over_F(rr), ...
        'Color',[0.75 0.75 0.75],'LineWidth',1);
    plot(ax,aligned.time_s(aa),aligned.aligned_DeltaF_over_F(aa), ...
        'Color',purple,'LineWidth',1.2);
    plot(ax,fitted.time_s(ff),fitted.fitted_DeltaF_over_F(ff),'k','LineWidth',1.5);
    ss=spikes.source_event_row==id; yl=ylim(ax);
    for x=spikes.spike_time_s(ss)'; plot(ax,[x x],yl,'k:','LineWidth',0.7); end
    set(ax,'TickDir','out','LineWidth',1); xlabel(ax,'time (s)'); ylabel(ax,'\DeltaF/F');
    if iExample==1, title(ax,'Quiescent-event examples'); end
end

binLabels=["1","2-3","4-5","6-8","9+"];
% Match the published spike-bin key: one spike is darkest and successive
% higher-count bins are progressively lighter.
colors=purple+(1-purple).*linspace(0,0.85,numel(binLabels))';
for normalized=0:1
    ax=nexttile(t,1+normalized*3*12+4,[3,4]); hold(ax,'on');
    for iBin=1:numel(binLabels)
        rows=means.spike_bin==binLabels(iBin);
        if normalized
            y=means.normalized_mean_dff(rows);
        else
            y=means.mean_dff(rows);
        end
        plot(ax,means.time_s(rows),y,'Color',colors(iBin,:),'LineWidth',1.3);
    end
    line(ax,xlim(ax),[0 0],'Color','k','LineStyle',':');
    set(ax,'TickDir','out','LineWidth',1); xlabel(ax,'time (s)');
    ylabel(ax,ternary(normalized,'Normalized \DeltaF/F','\DeltaF/F'));
    if normalized==0, title(ax,'Last-aligned averages'); legend(ax,binLabels,'Box','off'); end
end

metrics={'tau_fast_s','tau_slow_s','frac_fast'};
yLabels={'\tau_{fast} (s)','\tau_{slow} (s)','fast fraction'};
yLimits={[-0.005 0.25],[-0.05 2.5],[0 1]};
for iMetric=1:3
    ax=nexttile(t,9+(iMetric-1)*24,[2,4]); hold(ax,'on');
    % Match the published results.bins membership: bins were constructed from
    % the number of spikes in the pre-event window, not the wider bin count.
    group=binIndex(events.spike_count_pre);
    assert(isequal(accumarray(group(group>0),1,[5,1])',[1342 1193 442 266 102]), ...
        'ED9:binMembership','Canonical event-bin membership has changed.');
    values=events.(metrics{iMetric});
    % The published dot/box routine applies results.params.plotSNRMin=5 and
    % plotSNRMax=Inf before both the scatter and the box summary.
    good=isfinite(values)&isfinite(events.snr)&events.snr>=5&group>0;
    for iBin=1:numel(binLabels)
        y=values(good&group==iBin);
        stream=RandStream('mt19937ar','Seed',1+iBin+sum(double(metrics{iMetric})));
        if numel(y)>100
            order=randperm(stream,numel(y)); y=y(order(1:100));
        end
        x=iBin+0.18*(rand(stream,numel(y),1)-0.5);
        scatter(ax,x,y,10,colors(iBin,:),'filled','MarkerEdgeColor','none', ...
            'MarkerFaceAlpha',0.3);
    end
    boxplot(ax,values(good),group(good),'Labels',cellstr(binLabels), ...
        'Colors',[0.7 0.7 0.7],'Symbol','');
    set(findobj(ax,'Tag','Box'),'LineWidth',1.5);
    set(findobj(ax,'Tag','Median'),'LineWidth',1.5,'Color',[0.7 0.7 0.7]);
    ylim(ax,yLimits{iMetric}); ylabel(ax,yLabels{iMetric});
    set(ax,'TickDir','out','LineWidth',1);
    if iMetric==3, xlabel(ax,'Spikes per bin'); end
end

set(findall(h,'Type','axes'),'FontName','Arial','FontSize',9);
saveFigureOutputs('extended_data/figure9','ED9_A_B_C_quiescent_binning_dashboard',h);
end

function idx=binIndex(counts)
idx=zeros(size(counts)); idx(counts==1)=1; idx(counts>=2&counts<=3)=2;
idx(counts>=4&counts<=5)=3; idx(counts>=6&counts<=8)=4; idx(counts>=9)=5;
end

function out=ternary(condition,a,b)
if condition, out=a; else, out=b; end
end
