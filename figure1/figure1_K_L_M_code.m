function figure1_K_L_M_code
%%%
% Plots the quiescent-event examples, last-aligned averages, and fast tau
% summary shown in current Figure 1 panels K, L, and M.
%%%

close all

%% Get Data
d = fileparts(mfilename("fullpath"));
S = load(fullfile(d,"figure1_K_L_M_data.mat"),"results");
results = S.results;

% Defaults used for the displayed panels.
eventIdx = [1 21];
const = 'jGCaMP8f';
traceWindow = [0 1];
figSize = [7.5 3.5];
columnWeights = [1 0.1 1 0.1 1];
columnResolution = 60;

assert(isstruct(results) && isfield(results,'events') && istable(results.events), ...
    'figure1_K_L_M_data.mat must contain results.events as a table.');
assert(max(eventIdx) <= height(results.events), ...
    'eventIdx out of range (max=%d, nEvents=%d).', max(eventIdx), height(results.events));

%% Figure Layout
f = figure('Name','Figure 1 K-L-M','Color','w');
set(f,'Units','inches','Position',[1,1,figSize]);

colSpans = computeSpans(columnWeights,columnResolution);
outer = tiledlayout(f,1,columnResolution,'TileSpacing','loose','Padding','compact');

tileK = tiledlayout(outer,2,1,'TileSpacing','compact','Padding','compact');
tileK.Layout.Tile = 1;
tileK.Layout.TileSpan = [1 colSpans(1)];

tileL = tiledlayout(outer,2,1,'TileSpacing','compact','Padding','compact');
tileL.Layout.Tile = colSpans(1) + colSpans(2) + 1;
tileL.Layout.TileSpan = [1 colSpans(3)];

tileM = tiledlayout(outer,1,1,'TileSpacing','compact','Padding','compact');
tileM.Layout.Tile = colSpans(1) + colSpans(2) + colSpans(3) + colSpans(4) + 1;
tileM.Layout.TileSpan = [1 colSpans(5)];

%% Panel K: Example Events
for k = 1:numel(eventIdx)
    ax = nexttile(tileK,k);
    plot_event_panel(results,eventIdx(k),ax,const);
end

%% Panel L: Binned Last-Aligned Averages
colors = colorsForBins(results,const);
plot_mean_trace_panels(results,colors,tileL,traceWindow);

%% Panel M: Fast Tau Summary
axM = nexttile(tileM,1);
plot_tau_fast_panel(results,colors,axM);
xlabel(tileM,'Spikes');

setFigureFont(f,'Arial');
end

function plot_event_panel(results,eventIdx,ax,const)
params = results.params;
evt = results.events(eventIdx,:);

preWindowSec = getFieldWithDefault(params,'preWindowSec',0.1);
spikeCountBinRelSec = getFieldWithDefault(params,'spikeCountBinRelSec',[-preWindowSec 0]);
analysisWindowSec = getFieldWithDefault(params,'analysisWindowSec',1);

filePath = evt.file{1};
trialIdx = evt.trial;
t0 = evt.event_time_s;

[time_stamps,dff,ap_times] = loadCellData(filePath);
[time_stamps,dff] = coerceTrialsByTime(time_stamps,dff);
nTrials = size(time_stamps,1);
assert(trialIdx >= 1 && trialIdx <= nTrials, ...
    'Event trial index %d out of range for %s', trialIdx, filePath);

t = double(time_stamps(trialIdx,:));
y = double(dff(trialIdx,:));
spikes = spikesForTrial(ap_times,t,trialIdx,nTrials);
spikesRel = spikes - t0;
nPre = sum(spikes >= (t0 - preWindowSec) & spikes <= (t0 + eps(t0)));

plotWindowSec = [min([-0.5, -preWindowSec - 0.05]), ...
    max([analysisWindowSec, spikeCountBinRelSec(2) + 0.05])];
rawMask = (t >= (t0 + plotWindowSec(1))) & (t <= (t0 + plotWindowSec(2)));
tRelRaw = t(rawMask) - t0;
yRaw = y(rawMask);

cla(ax);
hold(ax,'on');

baseline0 = evt.baseline;
if ~isfinite(baseline0)
    baseline0 = 0;
end
[~, traceColor] = spikeBinStyleFromCount(nPre,params,const);

plot(ax,tRelRaw,yRaw-baseline0,'Color',traceColor,'LineWidth',0.5,'HandleVisibility','off');

hasAligned = isfield(results,'tRel') && isfield(results,'traces') && size(results.traces,1) >= eventIdx;
peakRel = nan;
if ismember('peak_time_rel_s',results.events.Properties.VariableNames)
    peakRel = evt.peak_time_rel_s;
end

if hasAligned
    tRelAligned = double(results.tRel(:));
    if isfield(results,'traces_bgnd_s') && size(results.traces_bgnd_s,1) >= eventIdx
        yRelAligned = double(results.traces_bgnd_s(eventIdx,:))';
    else
        yRelAligned = double(results.traces(eventIdx,:))' - baseline0;
    end

    plot(ax,tRelAligned,yRelAligned,'-','Color',traceColor,'LineWidth',1.75);

    if isfinite(peakRel)
        fitMask = (tRelAligned >= peakRel) & (tRelAligned <= analysisWindowSec);
        yHatAbs = predictFitFromEvent(evt,params,tRelAligned(fitMask)-peakRel);
        if ~isempty(yHatAbs) && all(isfinite(yHatAbs))
            plot(ax,tRelAligned(fitMask),yHatAbs-baseline0,'-','Color','k','LineWidth',2);
        end
    end
end

set(ax,'XLim',plotWindowSec);
ensureYIncludesZero(ax);
xl = get(ax,'XLim');
yl = get(ax,'YLim');
dy = limRange(yl);
xLen = min(0.5,0.35*limRange(plotWindowSec));
y0 = yl(1) + 0.24*dy;
y1 = yl(2) + 0.05*dy;
yLen = round(dy/5,1);
ensureYRangeForScaleBar(ax,yLen);

line(ax,xl,[0 0],'Color','k','LineStyle',':','LineWidth',2,'HandleVisibility','off');

spkMaskPlot = (spikesRel >= plotWindowSec(1)) & (spikesRel <= plotWindowSec(2));
spkTimes = spikesRel(spkMaskPlot);
hasTriggerLine = false;
if ~isempty(spkTimes)
    [minAbs,minIdx] = min(abs(spkTimes));
    triggerRel = nan;
    if isfinite(minAbs) && minAbs <= 1e-3
        triggerRel = spkTimes(minIdx);
    end

    for i = 1:numel(spkTimes)
        tr = spkTimes(i);
        if isfinite(triggerRel) && abs(tr-triggerRel) <= 1e-6
            c = [0.1 0.1 0.1];
            hasTriggerLine = true;
        elseif tr >= (-preWindowSec - 1e-12) && tr <= (0 + 1e-12)
            c = [0.7 0.7 0.7];
        else
            c = [0.1 0.1 0.1];
        end
        line(ax,[tr tr],[y0 y1],'Color',c,'LineStyle','--','LineWidth',0.8,'HandleVisibility','off');
    end
end

if ~hasTriggerLine && plotWindowSec(1) <= 0 && plotWindowSec(2) >= 0
    line(ax,[0 0],[y0 y1],'Color',[0.1 0.1 0.1],'LineStyle','--','LineWidth',1.5,'HandleVisibility','off');
end

yl = get(ax,'YLim');
dy = limRange(yl);
text(ax,xl(1),yl(1)+0.24*dy,sprintf('%d Spikes',numel(spkTimes)), ...
    'HorizontalAlignment','left','VerticalAlignment','top','Color',[0.7 0.7 0.7]);
text(ax,0,yl(1)+0.24*dy,{'Last','spike'}, ...
    'HorizontalAlignment','left','VerticalAlignment','top','Color','k');
plot(ax,[-preWindowSec 0],[yl(1)+0.24*dy yl(1)+0.24*dy], ...
    'Color',[0.7 0.7 0.7],'LineWidth',2);

if nPre > 5
    title(ax,'Janelia \it in vivo\rm\bf high activity example','Interpreter','tex');
else
    title(ax,'Janelia \it in vivo\rm\bf low activity example','Interpreter','tex');
end

addScaleBar(ax,xLen,yLen);
set(ax,'Visible','off');
set(get(ax,'Title'),'Visible','on');
end

function plot_mean_trace_panels(results,colors,parent,traceWindow)
if ~isfield(results,'tRel') || isempty(results.tRel)
    return;
end

xlRef = traceWindow;
xLen = min(0.5,0.35*limRange(xlRef));
yLen = 0.2;

axTop = nexttile(parent,1);
cla(axTop);
hold(axTop,'on');
lineHandles = gobjects(0);
lineLabels = {};
for i = 1:numel(results.bins)
    b = results.bins(i);
    if b.n < 1
        continue;
    end
    windowIdx = b.tRel >= traceWindow(1) & b.tRel <= traceWindow(2);
    t = b.tRel(windowIdx)';
    if isfield(b,'mean_trace_bgnd_s')
        mu = b.mean_trace_bgnd_s(windowIdx)';
    else
        mu = b.mean_trace(windowIdx)';
    end
    if ~any(isfinite(mu))
        continue;
    end
    lineHandles(end+1) = plot(axTop,t,mu,'Color',colors(i,:),'LineWidth',1.5); %#ok<AGROW>
    lineLabels{end+1} = b.label; %#ok<AGROW>
end
set(axTop,'XLim',xlRef,'TickDir','out','LineWidth',1);
ensureYIncludesZero(axTop);
line(axTop,xlRef,[0 0],'Color','k','LineStyle',':','LineWidth',2);
set(axTop,'Visible','off');
ensureYRangeForScaleBar(axTop,yLen);
addScaleBar(axTop,xLen,yLen);
title(axTop,'Last-aligned averages');
set(get(axTop,'Title'),'Visible','on');
if ~isempty(lineHandles)
    lg = legend(axTop,lineHandles,lineLabels,'Location','southeast','Box','off','Interpreter','none');
    lg.Title.String = 'Spike #';
    lg.Visible = 'on';
end

axBot = nexttile(parent,2);
cla(axBot);
hold(axBot,'on');
for i = 1:numel(results.bins)
    b = results.bins(i);
    if b.n < 1
        continue;
    end
    windowIdx = b.tRel >= traceWindow(1) & b.tRel <= traceWindow(2);
    t = b.tRel(windowIdx)';
    if isfield(b,'mean_trace_bgnd_s')
        mu = b.mean_trace_bgnd_s(windowIdx)';
    else
        mu = b.mean_trace(windowIdx)';
    end
    muFinite = mu(isfinite(mu));
    if isempty(muFinite)
        continue;
    end
    muMin = min(muFinite);
    muMax = max(muFinite);
    if isfinite(muMin) && isfinite(muMax) && muMax > muMin
        mu = contrastStretchLocal(mu,[muMin muMax],[0 1]);
    else
        mu = zeros(size(mu));
    end
    plot(axBot,t,mu,'Color',colors(i,:),'LineWidth',1.5);
end
set(axBot,'XLim',xlRef,'TickDir','out','LineWidth',1);
ensureYIncludesZero(axBot);
line(axBot,xlRef,[0 0],'Color','k','LineStyle',':','LineWidth',2);
set(axBot,'Visible','off');
addScaleBarX(axBot,xLen);
title(axBot,'Last-aligned normalized');
set(get(axBot,'Title'),'Visible','on');
end

function plot_tau_fast_panel(results,colors,ax)
plotParams = results.params;
fieldName = 'tau_fast_s';
labels = {results.bins.label};
gray = [0.7 0.7 0.7];

snrMin = getFieldWithDefault(plotParams,'plotSNRMin',5);
snrMax = getFieldWithDefault(plotParams,'plotSNRMax',inf);
maxScatter = max(0,round(getFieldWithDefault(plotParams,'plotMaxScatterPerBin',100)));
scatterFrac = max(0,min(1,getFieldWithDefault(plotParams,'plotScatterFrac',1)));
seed = max(0,round(getFieldWithDefault(plotParams,'plotScatterSeed',1)));
jitterW = getFieldWithDefault(plotParams,'plotJitterWidth',0.18);

cla(ax);
hold(ax,'on');
for i = 1:numel(results.bins)
    b = results.bins(i);
    if isempty(b.events) || ~ismember(fieldName,b.events.Properties.VariableNames)
        continue;
    end
    yAll = filteredEventValues(b.events,fieldName,snrMin,snrMax);
    if isempty(yAll)
        continue;
    end

    yScatter = yAll;
    n = numel(yScatter);
    nKeep = n;
    if scatterFrac < 1
        nKeep = min(nKeep,max(1,round(scatterFrac*n)));
    end
    if isfinite(maxScatter)
        nKeep = min(nKeep,maxScatter);
    end

    stream = RandStream('mt19937ar','Seed',seed+i+sum(double(fieldName)));
    if nKeep < n
        perm = randperm(stream,n);
        yScatter = yScatter(perm(1:nKeep));
    end
    x = i + jitterW*(rand(stream,numel(yScatter),1)-0.5);
    s = scatter(ax,x,yScatter,10,colors(i,:),'filled','MarkerEdgeColor','none');
    try
        s.MarkerFaceAlpha = 0.3;
    end

    drawBoxSummary(ax,i,yAll,gray);
end

set(ax,'TickDir','out','LineWidth',1,'Box','off', ...
    'XLim',[0.5 numel(results.bins)+0.5], ...
    'XTick',1:numel(results.bins), ...
    'XTickLabel',labels, ...
    'YLim',[-0.005 0.25]);
ylabel(ax,'\tau_{fast} (s)');
end

function y = filteredEventValues(events,fieldName,snrMin,snrMax)
y = double(events.(fieldName));
mask = isfinite(y);
hasSnr = ismember('snr',events.Properties.VariableNames) && isnumeric(events.snr);
if hasSnr
    snr = double(events.snr);
    mask = mask & isfinite(snr) & snr >= snrMin & snr <= snrMax;
end
y = y(mask);
end

function drawBoxSummary(ax,x,y,gray)
q = prctile(y,[25 50 75]);
iqrVal = q(3)-q(1);
loFence = q(1)-1.5*iqrVal;
hiFence = q(3)+1.5*iqrVal;
inlier = y(y >= loFence & y <= hiFence);
if isempty(inlier)
    inlier = y;
end
whLo = min(inlier);
whHi = max(inlier);
w = 0.42;
line(ax,[x x],[whLo q(1)],'Color',gray,'LineWidth',1.5);
line(ax,[x x],[q(3) whHi],'Color',gray,'LineWidth',1.5);
patch(ax,x+[-w -w w w]/2,[q(1) q(3) q(3) q(1)],'w', ...
    'EdgeColor',gray,'LineWidth',1.5,'FaceAlpha',0);
line(ax,x+[-w w]/2,[q(2) q(2)],'Color',gray,'LineWidth',1.5);
end

function [time_stamps,dff,ap_times] = loadCellData(filePath)
S = load(filePath,'time_stamps','dff','ap_times');
if ~isfield(S,'time_stamps') || ~isfield(S,'dff') || ~isfield(S,'ap_times')
    error('Missing required variables in %s (need time_stamps, dff, ap_times)',filePath);
end
time_stamps = S.time_stamps;
dff = S.dff;
ap_times = S.ap_times;
end

function [time_stamps,dff] = coerceTrialsByTime(time_stamps,dff)
if isvector(time_stamps)
    time_stamps = time_stamps(:)';
end
if isvector(dff)
    dff = dff(:)';
end

if ~isequal(size(time_stamps),size(dff))
    if isequal(size(time_stamps'),size(dff))
        time_stamps = time_stamps';
    elseif isequal(size(time_stamps),size(dff'))
        dff = dff';
    else
        error('time_stamps and dff size mismatch: %s vs %s',mat2str(size(time_stamps)),mat2str(size(dff)));
    end
end
end

function spikes = spikesForTrial(ap_times,t,trialIdx,nTrials)
spikes = [];
if isempty(ap_times) || isempty(t)
    return;
end

t0 = min(t);
t1 = max(t);
if iscell(ap_times)
    if numel(ap_times) == nTrials
        spikes = ap_times{trialIdx};
        spikes = spikes(:);
    else
        spikes = cellfun(@(x) x(:),ap_times(:),'UniformOutput',false);
        spikes = vertcat(spikes{:});
    end
elseif isnumeric(ap_times)
    if ismatrix(ap_times) && size(ap_times,2) == 2 && all(isfinite(ap_times(:)))
        trialCol = ap_times(:,1);
        timeCol = ap_times(:,2);
        if all(mod(trialCol,1) == 0) && all(trialCol >= 1) && all(trialCol <= nTrials)
            spikes = timeCol(trialCol == trialIdx);
        else
            spikes = ap_times(:);
        end
    else
        spikes = ap_times(:);
    end
end
spikes = spikes(isfinite(spikes) & spikes >= t0 & spikes <= t1);
spikes = sort(spikes(:));
end

function yHat = predictFitFromEvent(evt,params,tFit)
tFit = double(tFit(:));
if isempty(tFit)
    yHat = [];
    return;
end

baselineModel = lower(char(getFieldWithDefault(params,'baselineModel','constant')));
decayModel = lower(char(getFieldWithDefault(params,'decayModel','single')));

baseline = evt.baseline;
baselineSlope = 0;
if ismember('baseline_slope_per_s',evt.Properties.VariableNames)
    baselineSlope = evt.baseline_slope_per_s;
end
if ~isfinite(baselineSlope) || strcmp(baselineModel,'constant')
    baselineSlope = 0;
end

if strcmp(decayModel,'double')
    tauF = evt.tau_fast_s;
    tauS = evt.tau_slow_s;
    aF = evt.amp_fast;
    aS = evt.amp_slow;
    if any(~isfinite([baseline baselineSlope tauF tauS aF aS])) || tauF <= 0 || tauS <= 0
        yHat = [];
        return;
    end
    yHat = baseline + baselineSlope*tFit + aF*exp(-tFit./tauF) + aS*exp(-tFit./tauS);
else
    tau = evt.tau_s;
    a = evt.amp;
    if any(~isfinite([baseline baselineSlope tau a])) || tau <= 0
        yHat = [];
        return;
    end
    yHat = baseline + baselineSlope*tFit + a*exp(-tFit./tau);
end
end

function [label,color] = spikeBinStyleFromCount(spikeCount,params,const)
label = sprintf('%d',spikeCount);
baseHex = pickGCaMPcolorsMS(const);
color = hex2rgb(baseHex);

binEdges = getFieldWithDefault(params,'binEdges',[]);
if isempty(binEdges) || ~isnumeric(binEdges)
    return;
end
binEdges = double(binEdges(:)');
if ~isinf(binEdges(end))
    binEdges(end+1) = inf;
end

lower = binEdges(1:end-1);
upper = binEdges(2:end);
nBins = numel(lower);
binIdx = find(spikeCount >= lower & spikeCount < upper,1,'first');
if isempty(binIdx)
    binIdx = 1;
end
binIdx = min(max(1,binIdx),nBins);

lo = lower(binIdx);
hi = upper(binIdx);
if isfinite(hi)
    maxCount = hi - 1;
    if maxCount <= lo
        label = sprintf('%d',lo);
    else
        label = sprintf('%d-%d',lo,maxCount);
    end
else
    label = sprintf('%d+',lo);
end

pal = spikeBinColors(nBins,const);
color = pal(binIdx,:);
end

function colors = colorsForBins(results,const)
labelsThis = {results.bins.label};
labelsAll = labelsThis;
if isfield(results,'params') && isfield(results.params,'binEdges')
    [~,labelsAll] = assignSpikeCountBins([],results.params.binEdges);
end

pal = spikeBinColors(numel(labelsAll),const);
colors = nan(numel(labelsThis),3);
for i = 1:numel(labelsThis)
    idx = find(strcmp(labelsAll,labelsThis{i}),1,'first');
    if isempty(idx)
        idx = i;
    end
    idx = min(max(1,idx),size(pal,1));
    colors(i,:) = pal(idx,:);
end
end

function [binIdx,binLabels] = assignSpikeCountBins(spikeCounts,binEdges)
binEdges = binEdges(:)';
if isempty(binEdges) || ~isinf(binEdges(end))
    error('binEdges must end with inf');
end
lower = binEdges(1:end-1);
upper = binEdges(2:end);
binIdx = nan(size(spikeCounts));
binLabels = cell(numel(lower),1);
for i = 1:numel(lower)
    lo = lower(i);
    hi = upper(i);
    if isfinite(hi)
        binIdx(spikeCounts >= lo & spikeCounts < hi) = i;
        maxCount = hi - 1;
        if maxCount <= lo
            binLabels{i} = sprintf('%d',lo);
        else
            binLabels{i} = sprintf('%d-%d',lo,maxCount);
        end
    else
        binIdx(spikeCounts >= lo) = i;
        binLabels{i} = sprintf('%d+',lo);
    end
end
end

function colors = spikeBinColors(nBins,const)
base = hex2rgb(pickGCaMPcolorsMS(const));
if nBins <= 1
    colors = base;
    return;
end
t = linspace(0,0.85,nBins)';
colors = base.*(1-t) + ones(nBins,3).*t;
end

function spans = computeSpans(weights,nCols)
weights = double(weights(:)');
weights(~isfinite(weights) | weights < 0) = 0;
active = weights > 0;
if ~any(active)
    weights = ones(size(weights));
    active = true(size(weights));
end
if sum(active) > nCols
    error('columnResolution=%d is too small for %d nonzero columnWeights entries.',nCols,sum(active));
end

wNorm = zeros(size(weights));
wNorm(active) = weights(active)./sum(weights(active));
raw = wNorm.*nCols;
spans = zeros(size(weights));
spans(active) = floor(raw(active));
spans(active & spans < 1) = 1;
rem = nCols - sum(spans);
frac = raw - floor(raw);
activeIdx = find(active);
[~,ordRel] = sort(frac(activeIdx),'descend');
order = activeIdx(ordRel);

if rem > 0
    for k = 1:rem
        idx = order(mod(k-1,numel(order))+1);
        spans(idx) = spans(idx) + 1;
    end
elseif rem < 0
    [~,ordRel2] = sort(spans(activeIdx),'descend');
    order2 = activeIdx(ordRel2);
    while rem < 0
        changed = false;
        for j = 1:numel(order2)
            idx = order2(j);
            if spans(idx) > 1
                spans(idx) = spans(idx) - 1;
                rem = rem + 1;
                changed = true;
                if rem == 0
                    break;
                end
            end
        end
        if ~changed
            break;
        end
    end
end
spans(~active) = 0;
delta = nCols - sum(spans);
if delta ~= 0
    idx = find(active,1,'last');
    spans(idx) = spans(idx) + delta;
end
end

function out = contrastStretchLocal(x,inRange,outRange)
out = (x-inRange(1))./(inRange(2)-inRange(1));
out = out.*(outRange(2)-outRange(1)) + outRange(1);
end

function rgb = hex2rgb(hex)
hex = char(hex);
hex = strrep(hex,'#','');
if numel(hex) ~= 6
    error('hex must be a 6-digit hex color like #9E0142');
end
rgb = [hex2dec(hex(1:2)) hex2dec(hex(3:4)) hex2dec(hex(5:6))]./255;
end

function v = getFieldWithDefault(s,fieldName,defaultVal)
v = defaultVal;
if isstruct(s) && isfield(s,fieldName)
    v = s.(fieldName);
end
end

function ensureYIncludesZero(ax)
yl = get(ax,'YLim');
if yl(1) > 0
    set(ax,'YLim',[min(0,yl(1)-0.1*limRange(yl)),yl(2)]);
elseif yl(2) < 0
    set(ax,'YLim',[yl(1),max(0,yl(2)+0.1*limRange(yl))]);
end
end

function ensureYRangeForScaleBar(ax,yLen)
yl = get(ax,'YLim');
if limRange(yl) < 1.2*yLen
    pad = 0.1*max(1e-6,yLen);
    set(ax,'YLim',[min(yl(1),-pad),max(yl(2),yLen+pad)]);
end
end

function addScaleBar(ax,xLen,yLen)
xl = get(ax,'XLim');
yl = get(ax,'YLim');
dx = limRange(xl);
dy = limRange(yl);
if dx <= 0 || dy <= 0
    return;
end
padX = 0.25*dx;
padY = 0.2*dy;
x1 = xl(2)-padX;
x0 = x1-xLen;
y1 = yl(2)-padY;
y0 = y1-yLen;
line(ax,[x0 x1],[y1 y1],'Color','k','LineWidth',2,'HandleVisibility','off');
line(ax,[x1 x1],[y0 y1],'Color','k','LineWidth',2,'HandleVisibility','off');
text(ax,x0+xLen/2,y1+0.04*dy,sprintf('%d ms',round(1000*xLen)), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',11,'Interpreter','none','Clipping','off');
text(ax,x1+0.02*dx,y0+yLen/2,sprintf('%.2g \\DeltaF/F',yLen), ...
    'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',11,'Interpreter','tex','Clipping','off');
end

function addScaleBarX(ax,xLen)
xl = get(ax,'XLim');
yl = get(ax,'YLim');
dx = limRange(xl);
dy = limRange(yl);
if dx <= 0 || dy <= 0
    return;
end
padX = 0.2*dx;
padY = 0.12*dy;
x1 = xl(2)-padX;
x0 = x1-xLen;
y1 = yl(2)-padY;
line(ax,[x0 x1],[y1 y1],'Color','k','LineWidth',2);
text(ax,x0+xLen/2,y1+0.04*dy,sprintf('%d ms',round(1000*xLen)), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',11,'Interpreter','none','Clipping','off');
end

function d = limRange(lim)
d = lim(2)-lim(1);
end

function setFigureFont(fig,fontName)
objs = findall(fig,'-property','FontName');
for i = 1:numel(objs)
    try
        objs(i).FontName = fontName;
    end
end
end
