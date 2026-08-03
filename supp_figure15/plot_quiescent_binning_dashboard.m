function h = plot_quiescent_binning_dashboard(results, varargin)
% plot_quiescent_binning_dashboard
%
% Compose a "dashboard" view for quiescent binning results:
%   - Left column (2x1): two example events selected from results.events
%   - Center column (1x1): mean traces (unnormalized + normalized)
%   - Right column (3x1): dot/box plots for tau_fast, tau_slow, frac_fast
% Column widths can be controlled by spanning an underlying tiledlayout grid.
%
% Usage:
%   h = plot_quiescent_binning_dashboard(results);
%   h = plot_quiescent_binning_dashboard(results, 'eventIdx', [1 21]);
%   h = plot_quiescent_binning_dashboard(results, 'const', 'jG8m');
%   h = plot_quiescent_binning_dashboard(results, 'columnWeights', [1 1 1]); % interpreted as [left center right]
%   h = plot_quiescent_binning_dashboard(results, 'columnWeights', [1 0.1 1 0.1 1]); % [left gutter center gutter right]
%   h = plot_quiescent_binning_dashboard(results, 'outputDir', pwd, 'outputStem', 'suppfigure15_A_B_C', 'saveOutput', true);
%
% Output:
%   h.figure, h.outerLayout, h.leftLayout, h.centerLayout, h.rightLayout
%   h.events (1xN struct array from plot_quiescent_event)
%   h.binned (struct from plot_quiescent_binning_results)
%   h.output (output directory, file paths, and stats table)

close all

p = inputParser;
p.addParameter('eventIdx', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(isfinite(x)) && all(x >= 1)));
p.addParameter('figureHandle', [], @(x) isempty(x) || ishghandle(x));
p.addParameter('plotParams', [], @(x) isempty(x) || isstruct(x));
p.addParameter('columnWeights', [1 0.1 1 0.1 1], @(x) isnumeric(x) && isvector(x) && (numel(x) == 3 || numel(x) == 5) && all(isfinite(x)) && all(x(:) >= 0));
p.addParameter('gutterWeight', 0.1, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
p.addParameter('columnResolution', 60, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 3);
p.addParameter('figSize', [7.5 3.5], @(x) isnumeric(x) && isvector(x));
p.addParameter('outputDir', pwd, @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.addParameter('outputStem', 'quiescent_binning_dashboard', @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.addParameter('saveOutput', false, @(x) islogical(x) && isscalar(x));
p.addParameter('const', 'jGCaMP8m', @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.parse(varargin{:});
opts = p.Results;

assert(isstruct(results) && isfield(results, 'events') && istable(results.events), 'results must contain results.events (table).');

eventIdx = round(opts.eventIdx(:)');
if isempty(eventIdx)
    eventIdx = selectDefaultEventIdx(results.events);
end
assert(numel(eventIdx) == 2, 'eventIdx must contain exactly 2 indices (for the left 2x1 tile).');
if any(~isfinite(eventIdx)) || any(eventIdx < 1)
    error('eventIdx must be positive finite indices.');
end
assert(max(eventIdx) <= height(results.events), 'eventIdx out of range (max=%d, nEvents=%d).', max(eventIdx), height(results.events));

plotParams = opts.plotParams;
if isempty(plotParams)
    plotParams = struct();
    if isfield(results, 'params') && isstruct(results.params)
        plotParams = results.params;
    end
end

constParsed = parseSensorConst(opts.const);
outputDir = char(string(opts.outputDir));
outputStem = char(string(opts.outputStem));

fig = opts.figureHandle;
if isempty(fig)
    fig = figure('Name', 'Quiescent binning dashboard');
    fig.Units = 'inches';
    fig.Position = [1,1,opts.figSize(1),opts.figSize(2)];
else
    figure(fig);
    clf(fig);
end
set(fig, 'Color', 'w');

colRes = max(3, round(opts.columnResolution));
colWeights = double(opts.columnWeights(:)');
if numel(colWeights) == 3
    g = double(opts.gutterWeight);
    colWeights = [colWeights(1) g colWeights(2) g colWeights(3)];
end
if numel(colWeights) ~= 5 || sum(colWeights) <= 0
    error('columnWeights must be a 1x3 or 1x5 vector with at least one positive entry.');
end
colSpans = computeSpans(colWeights, colRes);
if any(colSpans([1 3 5]) < 1)
    error('columnResolution too small to allocate all three columns (need >= 3).');
end

outer = tiledlayout(fig, 1, colRes, 'TileSpacing', 'loose', 'Padding', 'compact');

left = tiledlayout(outer, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
left.Layout.Tile = 1;
left.Layout.TileSpan = [1 colSpans(1)];

center = tiledlayout(outer, 1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
center.Layout.Tile = colSpans(1) + colSpans(2) + 1;
center.Layout.TileSpan = [1 colSpans(3)];

right = tiledlayout(outer, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
right.Layout.Tile = colSpans(1) + colSpans(2) + colSpans(3) + colSpans(4) + 1;
right.Layout.TileSpan = [1 colSpans(5)];

evtHandles = repmat(struct('figure', [], 'axTrace', [], 'axSpikes', [], 'ax', []), 1, numel(eventIdx));
for k = 1:numel(eventIdx)
    ax = nexttile(left, k);
    evtHandles(k) = plot_quiescent_event(results, eventIdx(k), 'axesHandle', ax, 'const', constParsed);
end

binnedHandles = plot_quiescent_binning_results(results, plotParams, ...
    'ParentMean', center, ...
    'ParentDots', right, ...
    'const', constParsed);

h = struct();
h.figure = fig;
h.outerLayout = outer;
h.leftLayout = left;
h.centerLayout = center;
h.rightLayout = right;
h.columnWeights = colWeights;
h.columnSpans = colSpans;
h.eventIdx = eventIdx;
h.events = evtHandles;
h.binned = binnedHandles;
h.output = struct( ...
    'dir', outputDir, ...
    'saveOutput', opts.saveOutput, ...
    'figurePath', '', ...
    'statsPath', '', ...
    'stats', compileDotPlotStatsOutput(binnedHandles));
h.output.stats.selectedEventIdx = eventIdx;
h.output.stats.selectedEventCriteria = ...
    'Top: lowest tau_fast among one-spike events. Bottom: highest tau_fast among events with at least eight spikes.';

% Add xlabel to the tau plots
h.rightLayout.XLabel.String = 'Spikes per bin';

fontname(gcf,'Arial');

if opts.saveOutput
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    h.output.figurePath = fullfile(outputDir, [outputStem,'.pdf']);
    h.output.statsPath = fullfile(outputDir, [outputStem,'_stats.mat']);
    exportgraphics(gcf, h.output.figurePath, 'Resolution', 300);
    stats = h.output.stats; %#ok<NASGU>
    save(h.output.statsPath, 'stats');
end
end

function statsOut = compileDotPlotStatsOutput(binnedHandles)
statsOut = struct();
if ~isstruct(binnedHandles) || ~isfield(binnedHandles, 'dots') || ...
        ~isstruct(binnedHandles.dots) || ~isfield(binnedHandles.dots, 'stats') || ...
        ~isstruct(binnedHandles.dots.stats)
    return;
end

statsStruct = binnedHandles.dots.stats;
statsOut.dotPlots = statsStruct;
statsOut.generatedAt = datetime('now');
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

function eventIdx = selectDefaultEventIdx(events)
if ~istable(events)
    eventIdx = [1, min(2, height(events))];
    return;
end

spikeCountField = '';
if ismember('spike_count_pre', events.Properties.VariableNames)
    spikeCountField = 'spike_count_pre';
elseif ismember('spike_count_bin', events.Properties.VariableNames)
    spikeCountField = 'spike_count_bin';
end
if isempty(spikeCountField)
    eventIdx = [1, min(2, height(events))];
    return;
end

tauField = '';
if ismember('tau_fast_s', events.Properties.VariableNames)
    tauField = 'tau_fast_s';
elseif ismember('tau_s', events.Properties.VariableNames)
    tauField = 'tau_s';
end
if isempty(tauField)
    eventIdx = [1, min(2, height(events))];
    return;
end

spikeCount = double(events.(spikeCountField));
tauFast = double(events.(tauField));

topCandidates = find(spikeCount == 1 & isfinite(tauFast));
if isempty(topCandidates)
    finiteOneSpike = find(isfinite(spikeCount) & isfinite(tauFast));
    if isempty(finiteOneSpike)
        eventIdx = [1, min(2, height(events))];
        return;
    end
    minSpikeCount = min(spikeCount(finiteOneSpike));
    topCandidates = finiteOneSpike(spikeCount(finiteOneSpike) == minSpikeCount);
end
[~,topRelIdx] = min(tauFast(topCandidates));
topIdx = topCandidates(topRelIdx);

bottomCandidates = find(spikeCount >= 8 & isfinite(tauFast));
if isempty(bottomCandidates)
    finiteHighSpike = find(isfinite(spikeCount) & isfinite(tauFast));
    maxSpikeCount = max(spikeCount(finiteHighSpike));
    bottomCandidates = finiteHighSpike(spikeCount(finiteHighSpike) == maxSpikeCount);
end
[~,bottomRelIdx] = max(tauFast(bottomCandidates));
bottomIdx = bottomCandidates(bottomRelIdx);

if topIdx == bottomIdx
    alternateCandidates = setdiff(find(isfinite(tauFast)), topIdx, 'stable');
    if ~isempty(alternateCandidates)
        [~,altRelIdx] = max(tauFast(alternateCandidates));
        bottomIdx = alternateCandidates(altRelIdx);
    end
end

eventIdx = [topIdx, bottomIdx];
end

function spans = computeSpans(weights, nCols)
weights = double(weights(:)');
weights(~isfinite(weights) | weights < 0) = 0;

active = weights > 0;
if ~any(active)
    weights = ones(size(weights));
    active = true(size(weights));
end

if sum(active) > nCols
    error('columnResolution=%d is too small for %d nonzero columnWeights entries.', nCols, sum(active));
end

wNorm = zeros(size(weights));
wNorm(active) = weights(active) ./ sum(weights(active));

raw = wNorm .* nCols;
base = zeros(size(weights));
base(active) = floor(raw(active));

% Ensure at least one column per active segment.
base(active & base < 1) = 1;
rem = nCols - sum(base);

frac = raw - floor(raw);
activeIdx = find(active);
[~, ordRel] = sort(frac(activeIdx), 'descend');
order = activeIdx(ordRel);

spans = base;
if rem > 0
    for k = 1:rem
        idx = order(mod(k-1, numel(order)) + 1);
        spans(idx) = spans(idx) + 1;
    end
elseif rem < 0
    % Remove columns from the largest spans (but keep >=1).
    [~, ordRel2] = sort(spans(activeIdx), 'descend');
    order2 = activeIdx(ordRel2);
    k = 1;
    while rem < 0 && k <= 1000
        for j = 1:numel(order2)
            idx = order2(j);
            if spans(idx) > 1
                spans(idx) = spans(idx) - 1;
                rem = rem + 1;
                if rem == 0
                    break;
                end
            end
        end
        k = k + 1;
        if all(spans(~active) == 0) && all(spans(active) == 1)
            break;
        end
    end
end

% Final guard: inactive segments are allowed to be 0, active segments must be >=1.
spans(~active) = 0;
spans(active & spans < 1) = 1;
delta = nCols - sum(spans);
if delta ~= 0
    idx = find(active, 1, 'last');
    if isempty(idx)
        idx = numel(spans);
    end
    spans(idx) = spans(idx) + delta;
end

end
