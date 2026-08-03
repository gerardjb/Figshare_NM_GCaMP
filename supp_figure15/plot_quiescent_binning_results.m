function h = plot_quiescent_binning_results(results, plotParams, varargin)
% plot_quiescent_binning_results
%
% Plot mean traces and dot/box summaries for the output of
% bin_quiescent_dff_by_spikecount.
%
% Usage:
%   h = plot_quiescent_binning_results(results);
%   h = plot_quiescent_binning_results(results, results.params);
%   h = plot_quiescent_binning_results(results, [], 'ParentMean', tCenter, 'ParentDots', tRight);
%
% Name/value args:
%   - 'ParentMean' : [] (default) or a graphics container (figure/panel/tiledlayout) to host the
%     mean-traces tiledlayout (2x1).
%   - 'MeanTile'   : if ParentMean is a tiledlayout, which tile to place the mean-traces layout in (default 1).
%   - 'ParentDots' : [] (default) or a tiledlayout/figure/panel to host the 3 dot/box plots.
%   - 'const'      : sensor name (e.g., 'jG8m'); parsed through GCaMPalias and
%                    used to choose the base bin color via pickGCaMPcolorsMS.
%
% Output:
%   h.mean.figure, h.mean.layout, h.mean.axTop, h.mean.axBottom, h.mean.legend
%   h.dots.figures (1x3, empty if embedded), h.dots.axes (1x3)
%   h.colors (per-bin RGB)

p = inputParser;
p.addParameter('ParentMean', [], @(x) isempty(x) || ishghandle(x) || isa(x, 'matlab.graphics.layout.TiledChartLayout'));
p.addParameter('MeanTile', 1, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1);
p.addParameter('ParentDots', [], @(x) isempty(x) || ishghandle(x) || isa(x, 'matlab.graphics.layout.TiledChartLayout'));
p.addParameter('traceWindow', [0, 1], @(x) isnumeric(x) && isvector(x));
p.addParameter('tau_ylims', {[-0.005,0.25],[-0.05,2.5],[0,1]}, @(x) iscell(x) && numel(x)==3);
p.addParameter('const', 'jGCaMP8m', @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.parse(varargin{:});
opts = p.Results;

if nargin < 2 || isempty(plotParams) || ~isstruct(plotParams)
    plotParams = struct();
    if isstruct(results) && isfield(results, 'params') && isstruct(results.params)
        plotParams = results.params;
    end
end

h = struct();
h.mean = struct('figure', [], 'layout', [], 'axTop', [], 'axBottom', [], 'legend', []);
h.dots = struct('figures', [], 'axes', []);

if ~isstruct(results) || ~isfield(results, 'bins') || isempty(results.bins)
    return;
end

constParsed = parseSensorConst(opts.const);
colors = colorsForBins(results, constParsed);
h.colors = colors;

% ---- Mean traces: unnormalized (top) + normalized (bottom) ----
[h.mean.figure, h.mean.layout, h.mean.axTop, h.mean.axBottom, h.mean.legend] = plotMeanTraces(results, colors, plotParams, opts.ParentMean, opts.MeanTile, opts.traceWindow);

% ---- Dot plots: points + gray boxplot ----
h.dots = plotDotPlots(results, colors, plotParams, opts.ParentDots, opts.tau_ylims);
end

function [fig, tlo, axTop, axBot, lg] = plotMeanTraces(results, colors, plotParams, parentMean, meanTile, traceWindow)
fig = [];
tlo = [];
axTop = [];
axBot = [];
lg = [];

if nargin < 4
    parentMean = [];
end
if nargin < 5
    meanTile = 1;
end

if isempty(parentMean)
    fig = figure('Name', 'Binned dF/F decays');
    set(fig, 'Color', 'w');
    tlo = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
else
    if isa(parentMean, 'matlab.graphics.layout.TiledChartLayout')
        tlo = tiledlayout(parentMean, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
        tlo.Layout.Tile = max(1, round(meanTile));
        fig = ancestor(tlo, 'figure');
    else
        fig = ancestor(parentMean, 'figure');
        tlo = tiledlayout(parentMean, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    end
    if ~isempty(fig)
        set(fig, 'Color', 'w');
    end
end

if ~isfield(results, 'tRel') || isempty(results.tRel)
    return;
end

xlRef = [traceWindow(1), traceWindow(2)];
xLen = min(0.5, 0.35 * limRange(xlRef));
yLen = 0.2;

% Top: unnormalized traces + legend
axTop = nexttile(tlo, 1);
cla(axTop);
hold(axTop, 'on');
lineHandles = gobjects(0);
lineLabels = {};
for i = 1:numel(results.bins)
    b = results.bins(i);
    if b.n < 1
        continue;
    end
    window_idxs = b.tRel>=traceWindow(1) & b.tRel<=traceWindow(2);
    t = b.tRel(window_idxs)';
    if isfield(b, 'mean_trace_bgnd_s')
        mu = b.mean_trace_bgnd_s(window_idxs)';
    else
        mu = b.mean_trace(window_idxs)';
    end
    if ~any(isfinite(mu))
        continue;
    end
    lineHandles(end+1) = plot(axTop, t, mu, 'Color', colors(i, :), 'LineWidth', 1.5, 'DisplayName', b.label); %#ok<AGROW>
    lineLabels{end+1} = b.label;
end

set(axTop, 'TickDir', 'out', 'LineWidth', 1);
set(axTop, 'XLim', xlRef);
ensureYIncludesZero(axTop);
xl = get(axTop, 'XLim');
line('Parent', axTop, 'XData', xl, 'YData', [0 0], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);
set(axTop, 'Visible', 'off');
ensureYRangeForScaleBar(axTop, yLen);
addScaleBar(axTop, xLen, yLen);

if ~isempty(lineHandles)
    lg = legend(axTop, lineHandles, lineLabels);
    set(lg, 'Box', 'off', 'Interpreter', 'none', 'Location', 'southeast', ...
        'Visible', 'on', 'FontSize', 7, 'NumColumns', 2);
    % A short two-column legend preserves the reference figure's upper-right
    % placement without extending through the trace baseline.
    try
        lg.ItemTokenSize = [9, 3];
    catch
    end
    lg.Title.String = 'Spike #';
    lg.Title.FontSize = 8;
    drawnow;
    try
        % Pin the legend above the nearly flat trace tails and below the
        % scale annotation rather than letting MATLAB stretch it downward.
        lg.Units = 'normalized';
        legendPos = lg.Position;
        legendPos(1) = axTop.Position(1) + axTop.Position(3) - legendPos(3) - 0.01;
        legendPos(2) = axTop.Position(2) + 0.120;
        lg.Position = legendPos;
    catch
    end
    
end

title(axTop,'Trigger-aligned average \DeltaF/F')
set(get(gca, 'Title'), 'Visible', 'on');

% Bottom: normalized traces (0..1); x-only scale bar
axBot = nexttile(tlo, 2);
cla(axBot);
hold(axBot, 'on');
for i = 1:numel(results.bins)
    b = results.bins(i);
    if b.n < 1
        continue;
    end
    window_idxs = b.tRel>=traceWindow(1) & b.tRel<=traceWindow(2);
    t = b.tRel(window_idxs)';
    if isfield(b, 'mean_trace_bgnd_s')
        mu = b.mean_trace_bgnd_s(window_idxs)';
    else
        mu = b.mean_trace(window_idxs)';
    end
    muFinite = mu(isfinite(mu));
    if isempty(muFinite)
        continue;
    end
    muMin = min(muFinite);
    muMax = max(muFinite);
    if isfinite(muMin) && isfinite(muMax) && (muMax > muMin)
        mu = contrastStretch(mu, [muMin muMax], [0, 1]);
    else
        mu = zeros(size(mu));
    end
    plot(axBot, t, mu, 'Color', colors(i, :), 'LineWidth', 1.5);
end

set(axBot, 'TickDir', 'out', 'LineWidth', 1);
set(axBot, 'XLim', xlRef);
ensureYIncludesZero(axBot);
xl = get(axBot, 'XLim');
line('Parent', axBot, 'XData', xl, 'YData', [0 0], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);
set(axBot, 'Visible', 'off');
addScaleBarX(axBot, xLen);

title(axBot,'Trigger-aligned normalized \DeltaF/F')
set(get(gca, 'Title'), 'Visible', 'on');

end

function out = plotDotPlots(results, colors, plotParams, parentDots, tau_ylims)
out = struct('figures', [], 'axes', [], 'stats', struct());

fields = {'tau_fast_s', 'tau_slow_s', 'frac_fast'};
yLabs = {'\tau_{fast} (s)', '\tau_{slow} (s)', 'fastFrac'};
figNames = {'Tau_{fast} by spike count', 'Tau_{slow} by spike count', 'fastFrac by spike count'};

axList = gobjects(1, 3);
figList = gobjects(1, 3);
statsStruct = struct();

if isempty(parentDots)
    for k = 1:3
        [figList(k), axList(k), statsThis] = plotDotBoxByBin(results, colors, fields{k}, yLabs{k}, plotParams, 'FigureName', figNames{k});
        statsStruct.(fields{k}) = splitTrendStats(statsThis);
        % Adjust the ylims to taste
        set(gca,ylim=tau_ylims{k});
    end
else
    if isa(parentDots, 'matlab.graphics.layout.TiledChartLayout')
        for k = 1:3
            axList(k) = nexttile(parentDots, k);
            [~, axList(k), statsThis] = plotDotBoxByBin(results, colors, fields{k}, yLabs{k}, plotParams, 'Axes', axList(k));
            statsStruct.(fields{k}) = splitTrendStats(statsThis);
            % Adjust the ylims to taste
            set(gca,ylim=tau_ylims{k});
        end
    else
        fig = ancestor(parentDots, 'figure');
        if ~isempty(fig)
            set(fig, 'Color', 'w');
        end
        tlo = tiledlayout(parentDots, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
        for k = 1:3
            axList(k) = nexttile(tlo, k);
            [~, axList(k), statsThis] = plotDotBoxByBin(results, colors, fields{k}, yLabs{k}, plotParams, 'Axes', axList(k));
            statsStruct.(fields{k}) = splitTrendStats(statsThis);
            % Adjust the ylims to taste
            set(gca,ylim=tau_ylims{k});
        end
    end
end

out.figures = figList;
out.axes = axList;
out.stats = statsStruct;
end

function [fig, ax, stats] = plotDotBoxByBin(results, colors, fieldName, yLab, plotParams, varargin)
p = inputParser;
p.addParameter('Axes', [], @(x) isempty(x) || ishghandle(x));
p.addParameter('FigureName', '', @(s) ischar(s) || (isstring(s) && isscalar(s)));
p.parse(varargin{:});
opts = p.Results;

fig = [];
ax = opts.Axes;
stats = emptyTrendStats();

if isempty(results.bins) || ~ismember(fieldName, results.events.Properties.VariableNames)
    return;
end

if isempty(ax) || ~ishghandle(ax)
    fig = figure('Name', char(opts.FigureName));
    set(fig, 'Color', 'w');
    ax = gca;
else
    fig = ancestor(ax, 'figure');
end

cla(ax);
axes(ax);

labels = {results.bins.label};
gray = [0.7, 0.7, 0.7];

snrMin = getFieldWithDefault(plotParams, 'plotSNRMin', 5);
snrMax = getFieldWithDefault(plotParams, 'plotSNRMax', inf);
maxScatter = getFieldWithDefault(plotParams, 'plotMaxScatterPerBin', 100);
scatterFrac = getFieldWithDefault(plotParams, 'plotScatterFrac', 1);
seed = getFieldWithDefault(plotParams, 'plotScatterSeed', 1);
jitterW = getFieldWithDefault(plotParams, 'plotJitterWidth', 0.18);
maxScatter = max(0, round(maxScatter));
scatterFrac = max(0, min(1, scatterFrac));
seed = max(0, round(seed));


hold(ax, 'on');
for i = 1:numel(results.bins)
    b = results.bins(i);
    if isempty(b.events) || ~ismember(fieldName, b.events.Properties.VariableNames)
        continue;
    end
    y = double(b.events.(fieldName));
    mask = isfinite(y);

    hasSnr = ismember('snr', b.events.Properties.VariableNames) && isnumeric(b.events.snr);
    applySnr = ~(isinf(snrMin) && snrMin < 0 && isinf(snrMax) && snrMax > 0);
    if applySnr && hasSnr
        snr = double(b.events.snr);
        mask = mask & isfinite(snr) & (snr >= snrMin) & (snr <= snrMax);
    end
    y = y(mask);
    if isempty(y)
        continue;
    end

    % Subsample for scatter display (boxplot uses all).
    n = numel(y);
    nKeep = n;
    if scatterFrac < 1
        nKeep = min(nKeep, max(1, round(scatterFrac * n)));
    end
    if isfinite(maxScatter)
        nKeep = min(nKeep, maxScatter);
    end
    if nKeep == 0
        continue;
    end

    seedThis = seed + i + sum(double(fieldName));
    stream = RandStream('mt19937ar', 'Seed', max(0, round(seedThis)));
    if nKeep < n
        perm = randperm(stream, n);
        keepIdx = perm(1:nKeep);
        y = y(keepIdx);
    end

    x = i + jitterW * (rand(stream, numel(y), 1) - 0.5);
    try
        s = scatter(ax, x, y, 10, colors(i, :), 'filled', 'MarkerEdgeColor', 'none');
        s.MarkerFaceAlpha = 0.3;
    catch
        c = colors(i, :) * 0.6 + 0.4 * [1 1 1];
        scatter(ax, x, y, 18, c, 'filled', 'MarkerEdgeColor', 'none');
    end

end

% Boxplots
allY = [];
allG = [];
for i = 1:numel(results.bins)
    b = results.bins(i);
    if isempty(b.events) || ~ismember(fieldName, b.events.Properties.VariableNames)
        continue;
    end
    y = double(b.events.(fieldName));
    mask = isfinite(y);

    hasSnr = ismember('snr', b.events.Properties.VariableNames) && isnumeric(b.events.snr);
    applySnr = ~(isinf(snrMin) && snrMin < 0 && isinf(snrMax) && snrMax > 0);
    if applySnr && hasSnr
        snr = double(b.events.snr);
        mask = mask & isfinite(snr) & (snr >= snrMin) & (snr <= snrMax);
    end

    y = y(mask);
    allY = [allY; y(:)];
    allG = [allG; i * ones(numel(y), 1)];
end
if isempty(allY)
    return;
end

stats = computeTrendStats(results.events, fieldName, snrMin, snrMax);

boxplot(allY, allG, 'Labels', labels, 'Colors', gray, 'Symbol', '');
set(findobj(ax, 'Tag', 'Box'), 'LineWidth', 1.5, 'LineStyle', '-');
set(findobj(ax, 'Tag', 'Median'), 'LineWidth', 1.5, 'Color', gray, 'LineStyle', '-');
set(findobj(ax, 'Tag', 'Whisker'), 'LineWidth', 1.5, 'Color', gray, 'LineStyle', '-');
set(findobj(ax, 'Tag', 'Upper Whisker'), 'LineWidth', 1.5, 'Color', gray, 'LineStyle', '-');
set(findobj(ax, 'Tag', 'Lower Whisker'), 'LineWidth', 1.5, 'Color', gray, 'LineStyle', '-');

% Remove whisker caps.
set(findobj(ax, 'Tag', 'Upper Adjacent Value'), 'Visible', 'off');
set(findobj(ax, 'Tag', 'Lower Adjacent Value'), 'Visible', 'off');

set(ax, 'TickDir', 'out', 'LineWidth', 1, 'Box', 'off');
ylabel(ax, yLab);
% Keep the statistics in the returned/saved output without obscuring the
% compact supplementary-figure panels with an on-axes text overlay.
end

function stats = computeTrendStats(events, fieldName, snrMin, snrMax)
stats = emptyTrendStats();

required = {'spike_count_pre', fieldName};
if ~all(ismember(required, events.Properties.VariableNames))
    return;
end

x = double(events.spike_count_pre);
y = double(events.(fieldName));
mask = isfinite(x) & isfinite(y);

hasSnr = ismember('snr', events.Properties.VariableNames) && isnumeric(events.snr);
applySnr = ~(isinf(snrMin) && snrMin < 0 && isinf(snrMax) && snrMax > 0);
if applySnr && hasSnr
    snr = double(events.snr);
    mask = mask & isfinite(snr) & (snr >= snrMin) & (snr <= snrMax);
end

if nnz(mask) < 3
    return;
end

x = x(mask);
y = y(mask);
stats.n = numel(y);

try
    [stats.rho, stats.pSpearman] = corr(x, y, 'type', 'Spearman', 'rows', 'complete');
catch
end

requiredLME = {'file', 'trial', 'cell'};
if ~all(ismember(requiredLME, events.Properties.VariableNames))
    return;
end

fileId = events.file(mask);
trialId = events.trial(mask);
cellId = events.cell(mask);

trialKey = makeNestedGroupKey(fileId, trialId);
cellKey = makeNestedGroupKey(trialKey, cellId);

useLogResponse = startsWith(fieldName, 'tau_', 'IgnoreCase', true) && all(y > 0);
if useLogResponse
    response = log(y);
    responseName = 'log_y';
else
    response = y;
    responseName = 'y';
end

try
    tbl = table(response, x, categorical(trialKey), categorical(cellKey), ...
        'VariableNames', {responseName, 'spike_count_pre', 'trial_key', 'cell_key'});
catch
    return;
end

keep = isfinite(tbl.(responseName)) & isfinite(tbl.spike_count_pre) & ...
    ~isundefined(tbl.trial_key) & ~isundefined(tbl.cell_key);
tbl = tbl(keep, :);
if height(tbl) < 4 || numel(unique(tbl.spike_count_pre)) < 2
    return;
end

try
    randomTerms = strings(0, 1);
    usedRandomSlope = false;
    if numel(categories(tbl.trial_key)) >= 2
        randomTerms(end+1, 1) = "(1 + spike_count_pre|trial_key)";
        usedRandomSlope = true;
    end
    if numel(categories(tbl.cell_key)) >= 2
        randomTerms(end+1, 1) = "(1|cell_key)";
    end
    if isempty(randomTerms)
        return;
    end
    formula = sprintf('%s ~ spike_count_pre + %s', responseName, strjoin(cellstr(randomTerms), ' + '));
    try
        lme = fitlme(tbl, formula);
    catch
        % Fall back to intercept-only trial effects if the random-slope fit is singular or fails.
        randomTerms = strings(0, 1);
        usedRandomSlope = false;
        if numel(categories(tbl.trial_key)) >= 2
            randomTerms(end+1, 1) = "(1|trial_key)";
        end
        if numel(categories(tbl.cell_key)) >= 2
            randomTerms(end+1, 1) = "(1|cell_key)";
        end
        if isempty(randomTerms)
            return;
        end
        formula = sprintf('%s ~ spike_count_pre + %s', responseName, strjoin(cellstr(randomTerms), ' + '));
        lme = fitlme(tbl, formula);
    end
    coefTbl = lme.Coefficients;
    idx = strcmp(coefTbl.Name, 'spike_count_pre');
    if any(idx)
        stats.beta = coefTbl.Estimate(idx);
        H = zeros(1, height(coefTbl));
        H(idx) = 1;
        [stats.pLME, stats.FLME, stats.DF1LME, stats.DF2LME] = ...
            coefTest(lme, H, 0, 'DFMethod', 'satterthwaite');
        stats.lmeFormula = string(formula);
        if usedRandomSlope
            stats.lmeDescription = "Nested LME with trial-level random slope on spike_count_pre and random intercept for cell nested within trial; Satterthwaite F-test on the fixed effect spike_count_pre.";
        else
            stats.lmeDescription = "Nested LME with random intercepts for trial and cell nested within trial; Satterthwaite F-test on the fixed effect spike_count_pre.";
        end
        stats.hasLME = true;
    end
catch
end
end

function stats = emptyTrendStats()
stats = struct( ...
    'rho', nan, ...
    'pSpearman', nan, ...
    'beta', nan, ...
    'pLME', nan, ...
    'FLME', nan, ...
    'DF1LME', nan, ...
    'DF2LME', nan, ...
    'lmeFormula', "", ...
    'lmeDescription', "", ...
    'n', 0, ...
    'hasLME', false);
end

function out = splitTrendStats(stats)
out = struct();
out.stats = struct( ...
    'rho', stats.rho, ...
    'pSpearman', stats.pSpearman, ...
    'n', stats.n);
out.lme = struct( ...
    'beta', stats.beta, ...
    'p', stats.pLME, ...
    'F', stats.FLME, ...
    'DF1', stats.DF1LME, ...
    'DF2', stats.DF2LME, ...
    'formula', stats.lmeFormula, ...
    'description', stats.lmeDescription, ...
    'hasFit', stats.hasLME);
end

function key = makeNestedGroupKey(varargin)
n = numel(varargin{1});
parts = strings(n, nargin);
for j = 1:nargin
    v = varargin{j};
    if iscategorical(v)
        s = string(v);
    elseif isstring(v)
        s = v;
    elseif iscellstr(v)
        s = string(v);
    elseif iscell(v)
        try
            s = string(v);
        catch
            s = repmat("<missing>", numel(v), 1);
        end
    elseif isnumeric(v) || islogical(v)
        s = string(v);
    else
        try
            s = string(v);
        catch
            s = repmat("<missing>", numel(v), 1);
        end
    end
    s(ismissing(s)) = "<missing>";
    parts(:, j) = s(:);
end

key = parts(:, 1);
for j = 2:nargin
    key = key + "|" + parts(:, j);
end
end

function annotateTrendStats(ax, stats)
if isempty(ax) || ~ishghandle(ax) || stats.n < 3
    return;
end

lines = {
    sprintf('Spearman \\rho = %s, p = %s', formatStatValue(stats.rho), formatPValue(stats.pSpearman))
    };

if stats.hasLME
    lines{end+1} = sprintf('Nested LME \\beta = %s', formatStatValue(stats.beta));
    lines{end+1} = sprintf('Satt. F(%s, %s) = %s, p = %s', ...
        formatDFValue(stats.DF1LME), formatDFValue(stats.DF2LME), ...
        formatStatValue(stats.FLME), formatPValue(stats.pLME));
end

lines{end+1} = sprintf('n = %d', stats.n);

text(ax, 0.97, 0.97, lines, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 8, ...
    'Color', [0.25 0.25 0.25], ...
    'BackgroundColor', 'w', ...
    'Margin', 4, ...
    'Clipping', 'on');
end

function txt = formatPValue(p)
if ~isfinite(p)
    txt = 'nan';
elseif p < 1e-3
    txt = sprintf('%.1e', p);
else
    txt = sprintf('%.3f', p);
end
end

function txt = formatStatValue(x)
if ~isfinite(x)
    txt = 'nan';
else
    txt = sprintf('%.3f', x);
end
end

function txt = formatDFValue(x)
if ~isfinite(x)
    txt = 'inf';
elseif abs(x - round(x)) < 1e-8
    txt = sprintf('%d', round(x));
else
    txt = sprintf('%.1f', x);
end
end

function colors = colorsForBins(results, const)
% Assign bin colors by spike-count bin label, so colors remain consistent
% even if some bins are empty (e.g., no "1 spike" events).
if ~isfield(results, 'bins') || isempty(results.bins)
    colors = zeros(0, 3);
    return;
end

labelsThis = {results.bins.label};
colors = nan(numel(labelsThis), 3);

labelsAll = labelsThis;
if isfield(results, 'params') && isstruct(results.params) && isfield(results.params, 'binEdges')
    try
        [~, labelsAll] = assignSpikeCountBins([], results.params.binEdges);
    catch
        labelsAll = labelsThis;
    end
end

pal = spikeBinColors(numel(labelsAll), const);
for i = 1:numel(labelsThis)
    idx = find(strcmp(labelsAll, labelsThis{i}), 1, 'first');
    if isempty(idx)
        idx = i;
    end
    idx = min(max(1, idx), size(pal, 1));
    colors(i, :) = pal(idx, :);
end
end

function [binIdx, binLabels] = assignSpikeCountBins(spikeCounts, binEdges)
binEdges = binEdges(:)';
if isempty(binEdges) || ~isinf(binEdges(end))
    error('binEdges must end with inf');
end
lower = binEdges(1:end-1);
upper = binEdges(2:end);

binIdx = nan(size(spikeCounts));
binLabels = cell(numel(lower), 1);
for i = 1:numel(lower)
    lo = lower(i);
    hi = upper(i);
    if isfinite(hi)
        binIdx(spikeCounts >= lo & spikeCounts < hi) = i;
        maxCount = hi - 1;
        if maxCount <= lo
            binLabels{i} = sprintf('%d', lo);
        else
            binLabels{i} = sprintf('%d-%d', lo, maxCount);
        end
    else
        binIdx(spikeCounts >= lo) = i;
        binLabels{i} = sprintf('%d+', lo);
    end
end
end

function colors = spikeBinColors(nBins, const)
% 1 spike: dark #9E0142, higher bins progressively lighter tints.
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

function addScaleBar(ax, xLen, yLen)
% Draw an L-shaped scale bar in the upper-right of the current axes.
xl = get(ax, 'XLim');
yl = get(ax, 'YLim');
dx = limRange(xl);
dy = limRange(yl);
if dx <= 0 || dy <= 0
    return;
end

padX = 0.20 * dx;
% Leave a deliberate gap below the title and above the compact legend.
padY = 0.14 * dy;
x1 = xl(2) - padX;
x0 = x1 - xLen;
y1 = yl(2) - padY;
y0 = y1 - yLen;

% Horizontal bar on top, vertical bar down from the right end.
line('Parent', ax, 'XData', [x0 x1], 'YData', [y1 y1], 'Color', 'k', 'LineWidth', 2);
line('Parent', ax, 'XData', [x1 x1], 'YData', [y0 y1], 'Color', 'k', 'LineWidth', 2);

text('Parent', ax, 'Position', [x0 + xLen/2, y1 + 0.025 * dy, 0], 'String', sprintf('%d ms', round(1000 * xLen)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Color', 'k', 'FontSize', 11, 'Interpreter', 'none', 'Clipping', 'off');
text('Parent', ax, 'Position', [x1 + 0.02 * dx, y0 + yLen/2, 0], 'String', sprintf('%.2g \\DeltaF/F', yLen), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
    'Color', 'k', 'FontSize', 11, 'Interpreter', 'tex', 'Clipping', 'off');
end

function addScaleBarX(ax, xLen)
% Draw only a horizontal scale bar (upper-right), for normalized traces.
xl = get(ax, 'XLim');
yl = get(ax, 'YLim');
dx = limRange(xl);
dy = limRange(yl);
if dx <= 0 || dy <= 0
    return;
end

padX = 0.2 * dx;
% Keep the bar and its label visibly separated from the subplot title.
padY = 0.14 * dy;
x1 = xl(2) - padX;
x0 = x1 - xLen;
y1 = yl(2) - padY;

line('Parent', ax, 'XData', [x0 x1], 'YData', [y1 y1], 'Color', 'k', 'LineWidth', 2);
text('Parent', ax, 'Position', [x0 + xLen/2, y1 + 0.025 * dy, 0], 'String', sprintf('%d ms', round(1000 * xLen)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Color', 'k', 'FontSize', 11, 'Interpreter', 'none', 'Clipping', 'off');
end

function d = limRange(lim)
d = lim(2) - lim(1);
end

function v = getFieldWithDefault(s, fieldName, defaultVal)
v = defaultVal;
if isempty(s) || ~isstruct(s) || ~isfield(s, fieldName)
    return;
end
try
    v = s.(fieldName);
catch
    v = defaultVal;
end
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
