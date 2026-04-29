function h = plot_quiescent_event(results, eventIdx, varargin)
% plot_quiescent_event
%
% Plot a single quiescence-triggered decay event from the output of
% bin_quiescent_dff_by_spikecount.
%
% Usage:
%   plot_quiescent_event(results, 1);
%   plot_quiescent_event(results, 10, 'plotWindowSec', [-0.5 2]);
%   plot_quiescent_event(results, 3, 'preWindowSec', 0.1, 'spikeCountBinRelSec', [-0.2 -0.1]);
%
% Inputs:
%   - results  : struct returned by bin_quiescent_dff_by_spikecount
%   - eventIdx : 1-based index into results.events
%
% Name/value args:
%   - 'plotWindowSec'        : [tMin tMax] (sec) relative to trigger spike time t0
%   - 'preWindowSec'         : scalar (sec); used for spike_count_pre display/counting
%   - 'spikeCountBinRelSec'  : 1x2 (sec) relative to t0; used for spike_count_bin display/counting
%   - 'const'                : sensor name (e.g., 'jG8m'); parsed through GCaMPalias and
%                              used to choose the base bin color via pickGCaMPcolorsMS.
%   - 'figureHandle'         : existing figure handle (optional)
%   - 'axesHandle'           : existing axes handle (optional); if provided, plots into this axes
%                              (and ignores figureHandle/figure creation).

p = inputParser;
p.addParameter('plotWindowSec', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && numel(x) == 2 && all(isfinite(x))));
p.addParameter('preWindowSec', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0));
p.addParameter('spikeCountBinRelSec', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && numel(x) == 2 && all(isfinite(x))));
p.addParameter('const', 'jGCaMP8m', @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.addParameter('figureHandle', [], @(x) isempty(x) || ishghandle(x));
p.addParameter('axesHandle', [], @(x) isempty(x) || ishghandle(x));
p.parse(varargin{:});
opts = p.Results;

assert(isstruct(results) && isfield(results, 'events'), 'results must be a struct with field results.events');
assert(istable(results.events), 'results.events must be a table');
assert(isnumeric(eventIdx) && isscalar(eventIdx) && isfinite(eventIdx) && eventIdx >= 1, 'eventIdx must be a positive scalar');
eventIdx = round(eventIdx);
assert(eventIdx <= height(results.events), 'eventIdx out of range (1..%d)', height(results.events));

params = struct();
if isfield(results, 'params') && isstruct(results.params)
    params = results.params;
end

preWindowSec = opts.preWindowSec;
if isempty(preWindowSec)
    if isfield(params, 'preWindowSec')
        preWindowSec = params.preWindowSec;
    else
        preWindowSec = 0.1;
    end
end

spikeCountBinRelSec = opts.spikeCountBinRelSec;
if isempty(spikeCountBinRelSec)
    if isfield(params, 'spikeCountBinRelSec')
        spikeCountBinRelSec = params.spikeCountBinRelSec;
    else
        spikeCountBinRelSec = [-preWindowSec, 0];
    end
end
spikeCountBinRelSec = double(spikeCountBinRelSec(:)');
if spikeCountBinRelSec(1) > spikeCountBinRelSec(2)
    error('spikeCountBinRelSec must satisfy tStart <= tEnd');
end

analysisWindowSec = 1;
if isfield(params, 'analysisWindowSec'); analysisWindowSec = params.analysisWindowSec; end

evt = results.events(eventIdx, :);
filePath = eventTextValue(evt, 'file', '');
trialIdx = eventScalarValue(evt, 'trial', nan);
t0 = eventScalarValue(evt, 'event_time_s', nan);
nPre = eventScalarValue(evt, 'spike_count_pre', nan);
nBin = eventScalarValue(evt, 'spike_count_bin', nPre);

plotWindowSec = opts.plotWindowSec;
if isempty(plotWindowSec)
    left = min([-0.5, -preWindowSec - 0.05]);
    right = max([analysisWindowSec, spikeCountBinRelSec(2) + 0.05]);
    plotWindowSec = [left, right];
end
plotWindowSec = double(plotWindowSec(:)');

hasRaw = false;
tRelRaw = [];
yRaw = [];
spikesRel = [];
if ~isempty(filePath) && isfile(filePath) && isfinite(trialIdx) && isfinite(t0)
    try
        [time_stamps, dff, ap_times] = loadCellData(filePath);
        [time_stamps, dff] = coerceTrialsByTime(time_stamps, dff);
        nTrials = size(time_stamps, 1);
        if trialIdx >= 1 && trialIdx <= nTrials
            t = double(time_stamps(trialIdx, :));
            y = double(dff(trialIdx, :));
            spikes = spikesForTrial(ap_times, t, trialIdx, nTrials);
            spikesRel = spikes - t0;
            rawMask = (t >= (t0 + plotWindowSec(1))) & (t <= (t0 + plotWindowSec(2)));
            tRelRaw = t(rawMask) - t0;
            yRaw = y(rawMask);
            hasRaw = true;

            nPre = sum(spikes >= (t0 - preWindowSec) & spikes <= (t0 + eps(t0)));
            tStart = t0 + spikeCountBinRelSec(1);
            tEnd = t0 + spikeCountBinRelSec(2);
            nBin = sum(spikes >= tStart & spikes <= (tEnd + eps(tEnd)));
        end
    catch ME
        warning('plot_quiescent_event:rawLoadFailed', ...
            'Could not load raw event trace from %s (%s). Using packaged aligned trace only.', ...
            filePath, ME.message);
    end
end
if ~isfinite(nPre)
    nPre = 0;
end
if ~isfinite(nBin)
    nBin = nPre;
end

ax = opts.axesHandle;
fig = [];
if ~isempty(ax)
    if ~ishghandle(ax) || ~strcmp(get(ax, 'Type'), 'axes')
        error('axesHandle must be a valid axes handle.');
    end
    fig = ancestor(ax, 'figure');
    cla(ax);
    hold(ax, 'on');
    if ~isempty(fig)
        set(fig, 'Color', 'w');
    end
else
    fig = opts.figureHandle;
    if isempty(fig)
        fig = figure('Name', sprintf('Quiescent event %d', eventIdx));
    else
        figure(fig);
        clf(fig);
    end

    set(fig, 'Color', 'w');
    ax = axes('Parent', fig);
    hold(ax, 'on');
end

% Use baseline-subtracted aligned traces when available (matches binned plots).
baseline0 = eventScalarValue(evt, 'baseline', 0);
if ~isfinite(baseline0)
    baseline0 = 0;
end

hasAligned = isfield(results, 'tRel') && isfield(results, 'traces') && size(results.traces, 1) >= eventIdx;
peakRel = nan;
if ismember('peak_time_rel_s', results.events.Properties.VariableNames)
    peakRel = evt.peak_time_rel_s;
end

constParsed = parseSensorConst(opts.const);
[binLabel, traceColor] = spikeBinStyleFromCount(nPre, params, constParsed);

% Light raw trace (baseline-subtracted) for context.
if hasRaw
    plot(ax, tRelRaw, yRaw - baseline0, 'Color', traceColor, 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

% Aligned trace + fit
if hasAligned
    tRelAligned = double(results.tRel(:));
    if isfield(results, 'traces_bgnd_s') && size(results.traces_bgnd_s, 1) >= eventIdx
        yRelAligned = double(results.traces_bgnd_s(eventIdx, :))';
    else
        yRelAligned = double(results.traces(eventIdx, :))' - baseline0;
    end

    plot(ax, tRelAligned, yRelAligned, '-', 'Color', traceColor, 'LineWidth', 1.75, ...
        'DisplayName', sprintf('trace (%d spikes)', nPre));

    if isfinite(peakRel)
        fitMask = (tRelAligned >= peakRel) & (tRelAligned <= analysisWindowSec);
        yHatAbs = predictFitFromEvent(evt, params, tRelAligned(fitMask) - peakRel);
        if ~isempty(yHatAbs) && all(isfinite(yHatAbs))
            plot(ax, tRelAligned(fitMask), yHatAbs - baseline0, '-', 'Color', 'k', 'LineWidth', 2, ...
                'DisplayName', 'bi-exponential fit');
        end
    end
end

set(ax, 'XLim', plotWindowSec);

% Baseline and scale bar (match binned-plot style).
ensureYIncludesZero(ax);
xLen = min(0.5, 0.35 * limRange(plotWindowSec));
xl = get(ax, 'XLim');
line('Parent', ax, 'XData', xl, 'YData', [0 0], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2, 'HandleVisibility', 'off');

% Spikes drawn as short dashed vertical segments at the bottom of the plot.
yl = get(ax, 'YLim');
dy = limRange(yl);
y0 = yl(1)+ 0.24*dy;
y1 = yl(2)+ 0.05*dy;
yLen = round(dy/5,1);
ensureYRangeForScaleBar(ax, yLen);

spkMaskPlot = (spikesRel >= plotWindowSec(1)) & (spikesRel <= plotWindowSec(2));
spkTimes = spikesRel(spkMaskPlot);
hasTriggerLine = false;
if ~isempty(spkTimes)
    [minAbs, minIdx] = min(abs(spkTimes));
    triggerRel = nan;
    if isfinite(minAbs) && minAbs <= 1e-3
        triggerRel = spkTimes(minIdx);
    end

    for i = 1:numel(spkTimes)
        tr = spkTimes(i);
        if isfinite(triggerRel) && abs(tr - triggerRel) <= 1e-6
            c = [0.1 0.1 0.1];
            hasTriggerLine = true;
        elseif tr >= (-preWindowSec - 1e-12) && tr <= (0 + 1e-12)
            c = [0.7 0.7 0.7];
        else
            c = [0.1 0.1 0.1];
        end
        if i==numel(spkTimes)
            line('Parent', ax, 'XData', [tr tr], 'YData', [y0 y1], 'Color', c, 'LineStyle', '--', 'LineWidth', 0.8, 'DisplayName', 'trigger spike');
        elseif i==1
            line('Parent', ax, 'XData', [tr tr], 'YData', [y0 y1], 'Color', c, 'LineStyle', '--', 'LineWidth', 0.8, 'DisplayName', 'spikes in window');
        else
            line('Parent', ax, 'XData', [tr tr], 'YData', [y0 y1], 'Color', c, 'LineStyle', '--', 'LineWidth', 0.8, 'HandleVisibility', 'off');
        end
    end
end

% Always show the trigger spike at t0 (x=0) even if spike timestamps are slightly off.
if ~hasTriggerLine && plotWindowSec(1) <= 0 && plotWindowSec(2) >= 0
    line('Parent', ax, 'XData', [0 0], 'YData', [y0 y1], 'Color', [0.1 0.1 0.1], 'LineStyle', '--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

% Labels for spikes
text(xl(1),yl(1)+ 0.24*dy,{[num2str(nPre),' Spikes']},...
    HorizontalAlignment='left',...
    VerticalAlignment='top',...
    Color=[0.7,0.7,0.7])
text(0,yl(1)+ 0.24*dy,{'Last', 'spike'},...
    HorizontalAlignment='left',...
    VerticalAlignment='top')
% Marker for spike count window
plot([-preWindowSec,0],[yl(1)+ 0.24*dy,yl(1)+ 0.24*dy],color=[0.7,0.7,0.7],LineWidth=2)

% Legend things
%lg = legend(ax, 'Location', 'best');
%set(lg, 'Box', 'off', 'Interpreter', 'none');

tauF = nan;
tauS = nan;
if ismember('tau_fast_s', results.events.Properties.VariableNames); tauF = evt.tau_fast_s; end
if ismember('tau_slow_s', results.events.Properties.VariableNames); tauS = evt.tau_slow_s; end
if ~isfinite(tauF) && ismember('tau_s', results.events.Properties.VariableNames); tauF = evt.tau_s; end
if nPre>5;title('Janelia\it in vivo\rm\bf high activity example');else;title('Janelia\it in vivo\rm\bf low activity example');end
%title(sprintf('n=%d   \\tau_{fast}=%.3g s   \\tau_{slow}=%.3g s', nPre, tauF, tauS), 'Interpreter', 'tex');

addScaleBar(ax, xLen, yLen);
set(ax, 'Visible', 'off');
set(get(gca, 'Title'), 'Visible', 'on');

h = struct();
h.figure = fig;
h.axTrace = ax;
h.axSpikes = [];
h.ax = ax;

end

% -------------------------------------------------------------------------
% Helpers
% -------------------------------------------------------------------------
function value = eventScalarValue(evt, fieldName, defaultValue)
value = defaultValue;
if ~istable(evt) || ~ismember(fieldName, evt.Properties.VariableNames)
    return;
end
try
    raw = evt.(fieldName);
    if istable(raw)
        return;
    end
    if iscell(raw)
        raw = raw{1};
    end
    if isstring(raw)
        raw = str2double(raw(1));
    end
    raw = double(raw);
    if ~isempty(raw)
        value = raw(1);
    end
catch
    value = defaultValue;
end
end

function value = eventTextValue(evt, fieldName, defaultValue)
value = defaultValue;
if ~istable(evt) || ~ismember(fieldName, evt.Properties.VariableNames)
    return;
end
try
    raw = evt.(fieldName);
    if iscell(raw)
        raw = raw{1};
    elseif isstring(raw)
        raw = raw(1);
    end
    if isstring(raw)
        value = char(raw);
    elseif ischar(raw)
        value = raw;
    end
catch
    value = defaultValue;
end
end

function [time_stamps, dff, ap_times] = loadCellData(filePath)
S = load(filePath, 'time_stamps', 'dff', 'ap_times');
if ~isfield(S, 'time_stamps') || ~isfield(S, 'dff') || ~isfield(S, 'ap_times')
    error('Missing required variables in %s (need time_stamps, dff, ap_times)', filePath);
end
time_stamps = S.time_stamps;
dff = S.dff;
ap_times = S.ap_times;
end

function [time_stamps, dff] = coerceTrialsByTime(time_stamps, dff)
if ~isnumeric(time_stamps) || ~isnumeric(dff)
    error('time_stamps and dff must be numeric arrays.');
end
if isvector(time_stamps)
    time_stamps = time_stamps(:)';
end
if isvector(dff)
    dff = dff(:)';
end

if ~isequal(size(time_stamps), size(dff))
    if isequal(size(time_stamps'), size(dff))
        time_stamps = time_stamps';
    elseif isequal(size(time_stamps), size(dff'))
        dff = dff';
    else
        error('time_stamps and dff size mismatch: %s vs %s', mat2str(size(time_stamps)), mat2str(size(dff)));
    end
end
end

function spikes = spikesForTrial(ap_times, t, trialIdx, nTrials)
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
        spikes = cellfun(@(x) x(:), ap_times(:), 'UniformOutput', false);
        spikes = vertcat(spikes{:});
    end
elseif isnumeric(ap_times)
    if ismatrix(ap_times) && size(ap_times, 2) == 2 && all(isfinite(ap_times(:)))
        trialCol = ap_times(:, 1);
        timeCol = ap_times(:, 2);
        if all(mod(trialCol, 1) == 0) && all(trialCol >= 1) && all(trialCol <= nTrials)
            spikes = timeCol(trialCol == trialIdx);
        else
            spikes = ap_times(:);
        end
    else
        spikes = ap_times(:);
    end
else
    spikes = [];
end

spikes = spikes(isfinite(spikes) & spikes >= t0 & spikes <= t1);
spikes = sort(spikes(:));
end

function yHat = predictFitFromEvent(evt, params, tFit)
tFit = double(tFit(:));
if isempty(tFit)
    yHat = [];
    return;
end

baselineModel = 'constant';
decayModel = 'single';
if isfield(params, 'baselineModel'); baselineModel = lower(char(params.baselineModel)); end
if isfield(params, 'decayModel'); decayModel = lower(char(params.decayModel)); end

baseline = evt.baseline;
baselineSlope = 0;
if ismember('baseline_slope_per_s', evt.Properties.VariableNames)
    baselineSlope = evt.baseline_slope_per_s;
end
if ~isfinite(baselineSlope) || strcmp(baselineModel, 'constant')
    baselineSlope = 0;
end

if strcmp(decayModel, 'double')
    tauF = evt.tau_fast_s;
    tauS = evt.tau_slow_s;
    aF = evt.amp_fast;
    aS = evt.amp_slow;
    if any(~isfinite([baseline, baselineSlope, tauF, tauS, aF, aS])) || tauF <= 0 || tauS <= 0
        yHat = [];
        return;
    end
    yHat = baseline + baselineSlope * tFit + aF * exp(-tFit ./ tauF) + aS * exp(-tFit ./ tauS);
else
    tau = evt.tau_s;
    a = evt.amp;
    if any(~isfinite([baseline, baselineSlope, tau, a])) || tau <= 0
        yHat = [];
        return;
    end
    yHat = baseline + baselineSlope * tFit + a * exp(-tFit ./ tau);
end
end

function s = fitSummaryString(evt, params)
decayModel = 'single';
baselineModel = 'constant';
if isfield(params, 'decayModel'); decayModel = lower(char(params.decayModel)); end
if isfield(params, 'baselineModel'); baselineModel = lower(char(params.baselineModel)); end

r2 = nan;
if ismember('r2', evt.Properties.VariableNames); r2 = evt.r2; end

if strcmp(decayModel, 'double')
    s = sprintf('%s/%s  tauF=%.3g  tauS=%.3g  fracF=%.2f  R2=%.2f', ...
        decayModel, baselineModel, evt.tau_fast_s, evt.tau_slow_s, evt.frac_fast, r2);
else
    s = sprintf('%s/%s  tau=%.3g  R2=%.2f', decayModel, baselineModel, evt.tau_s, r2);
end
end

function [label, color] = spikeBinStyleFromCount(spikeCount, params, const)
% Match bin_quiescent_dff_by_spikecount color conventions:
% 1 spike: dark #9E0142, higher bins progressively lighter tints.
label = sprintf('%d', spikeCount);
if nargin < 3 || isempty(const)
    const = 'jGCaMP8m';
end
baseHex = pickGCaMPcolorsMS(const);
color = hex2rgb(baseHex);

binEdges = [];
if isstruct(params) && isfield(params, 'binEdges')
    binEdges = params.binEdges;
end
if isempty(binEdges) || ~isnumeric(binEdges)
    return;
end
binEdges = double(binEdges(:)');
binEdges = binEdges(isfinite(binEdges) & binEdges >= 0);
if isempty(binEdges)
    return;
end
if ~isinf(binEdges(end))
    binEdges(end+1) = inf;
end

lower = binEdges(1:end-1);
upper = binEdges(2:end);
nBins = numel(lower);
if nBins < 1 || ~isfinite(spikeCount)
    return;
end

binIdx = find(spikeCount >= lower & spikeCount < upper, 1, 'first');
if isempty(binIdx)
    binIdx = 1;
end
binIdx = min(max(1, binIdx), nBins);

lo = lower(binIdx);
hi = upper(binIdx);
if isfinite(hi)
    maxCount = hi - 1;
    if maxCount <= lo
        label = sprintf('%d', lo);
    else
        label = sprintf('%d-%d', lo, maxCount);
    end
else
    label = sprintf('%d+', lo);
end

pal = spikeBinColors(nBins, const);
color = pal(binIdx, :);
end

function colors = spikeBinColors(nBins, const)
if nargin < 2 || isempty(const)
    const = 'jGCaMP8m';
end
baseHex = pickGCaMPcolorsMS(const);
base = hex2rgb(baseHex);
if nBins <= 1
    colors = base;
    return;
end
t = linspace(0, 0.85, nBins)';
colors = base .* (1 - t) + ones(nBins, 3) .* t;
end

function constOut = parseSensorConst(constIn)
constOut = 'jGCaMP8m';
if nargin < 1 || isempty(constIn)
    return;
end
if isstring(constIn)
    constIn = char(constIn);
end
if ~ischar(constIn)
    return;
end
try
    constOut = GCaMPalias(constIn);
catch
    constOut = constIn;
end
end

function rgb = hex2rgb(hex)
hex = char(hex);
hex = strrep(hex, '#', '');
if numel(hex) ~= 6
    error('hex must be a 6-digit hex color like #9E0142');
end
r = hex2dec(hex(1:2));
g = hex2dec(hex(3:4));
b = hex2dec(hex(5:6));
rgb = [r g b] ./ 255;
end

function d = limRange(lim)
d = lim(2) - lim(1);
end

function ensureYIncludesZero(ax)
yl = get(ax, 'YLim');
if ~any(isfinite(yl))
    return;
end
if yl(1) > 0
    set(ax, 'YLim', [min(0, yl(1) - 0.1 * limRange(yl)), yl(2)]);
elseif yl(2) < 0
    set(ax, 'YLim', [yl(1), max(0, yl(2) + 0.1 * limRange(yl))]);
end
end

function ensureYRangeForScaleBar(ax, yLen)
yl = get(ax, 'YLim');
if ~any(isfinite(yl))
    return;
end
if limRange(yl) < (1.2 * yLen)
    pad = 0.1 * max(1e-6, yLen);
    set(ax, 'YLim', [min(yl(1), -pad), max(yl(2), yLen + pad)]);
end
end

function addScaleBar(ax, xLen, yLen)
% Draw an L-shaped scale bar in the upper-right of the current axes.
xl = get(ax, 'XLim');
yl = get(ax, 'YLim');
dx = limRange(xl);
dy = limRange(yl);
if dx <= 0 || dy <= 0
    return;
end

padX = 0.25 * dx;
padY = 0.2 * dy;
x1 = xl(2) - padX;
x0 = x1 - xLen;
y1 = yl(2) - padY;
y0 = y1 - yLen;

% Horizontal bar on top, vertical bar down from the right end.
line('Parent', ax, 'XData', [x0 x1], 'YData', [y1 y1], 'Color', 'k', 'LineWidth', 2,'HandleVisibility','off');
line('Parent', ax, 'XData', [x1 x1], 'YData', [y0 y1], 'Color', 'k', 'LineWidth', 2,'HandleVisibility','off');

text('Parent', ax, 'Position', [x0 + xLen/2, y1 + 0.04 * dy, 0], 'String', sprintf('%d ms', round(1000 * xLen)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Color', 'k', 'FontSize', 11, 'Interpreter', 'none', 'Clipping', 'off');
text('Parent', ax, 'Position', [x1 + 0.02 * dx, y0 + yLen/2, 0], 'String', sprintf('%.2g \\DeltaF/F', yLen), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
    'Color', 'k', 'FontSize', 11, 'Interpreter', 'tex', 'Clipping', 'off');
end
