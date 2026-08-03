function h = suppfigure11_code
%SUPPFIGURE11_CODE Plot the publication version of Supplementary Figure 11.
%
% All plotted values are loaded from the four packaged numeric files in
% this directory. No saved figure, rendered image, exploratory script, or
% external data directory is required.

close all

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(fullfile(repo_root, 'Utilities'), '-begin');

input_files = struct( ...
    'panel_A', fullfile(script_dir, ...
        'panel_A_high_history_example.mat'), ...
    'panel_B', fullfile(script_dir, ...
        'panel_B_epoch_error_bootstrap.csv'), ...
    'panel_C', fullfile(script_dir, ...
        'panel_C_history_200ms_bootstrap.csv'), ...
    'panel_D', fullfile(script_dir, ...
        'panel_D_quiescent_prediction_traces.csv'));
validateFiles(input_files);

loaded = load(input_files.panel_A, 'panel_A');
panel_A = loaded.panel_A;
panel_B = readtable(input_files.panel_B, 'TextType', 'string');
panel_C = readtable(input_files.panel_C, 'TextType', 'string');
panel_D = readtable(input_files.panel_D, 'TextType', 'string');

method_labels = ["Biophys SMC", "MLspike", "PGBAR"];
method_display_labels = ["Biophys_{SMC}", "MLspike", "PGBAR"];
method_colors = getMethodColors;

figure_size = [12.2 9.0];
h = figure('Color', 'w', 'Units', 'inches', ...
    'Position', [0.25 0.25 figure_size], ...
    'PaperUnits', 'inches', 'PaperSize', figure_size, ...
    'PaperPosition', [0 0 figure_size], ...
    'Renderer', 'painters', 'Toolbar', 'none');

%% Panel A: example high-spike history event
addPanelLetter(h, 'A', [0.012 0.945 0.03 0.03]);
panel_A_positions = [
    0.080 0.81500 0.235 0.105
    0.080 0.70375 0.235 0.105
    0.080 0.59250 0.235 0.105
    0.080 0.48125 0.235 0.105
    0.080 0.37000 0.235 0.105
    ];
plotPanelA(h, panel_A_positions, panel_A, ...
    method_labels, method_display_labels, method_colors);

%% Panel B: epoch-wise errors
addPanelLetter(h, 'B', [0.362 0.945 0.03 0.03]);
annotation(h, 'textbox', [0.400 0.940 0.550 0.028], ...
    'String', 'Errors versus epoch-wise spike count', ...
    'LineStyle', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'normal');

ax_B1 = axes(h, 'Position', [0.400 0.715 0.250 0.190]);
handles_B = plotEpochErrorBins( ...
    ax_B1, panel_B, method_labels, method_colors, ...
    "fp_per_epoch", 'False positives');
legend(ax_B1, handles_B, method_display_labels, ...
    'Location', 'northwest', 'Box', 'off', ...
    'FontName', 'Arial', 'FontSize', 10, 'Interpreter', 'tex');

ax_B2 = axes(h, 'Position', [0.700 0.715 0.250 0.190]);
plotEpochErrorBins(ax_B2, panel_B, method_labels, method_colors, ...
    "fn_per_epoch", 'False negatives');

%% Panel C: errors conditioned on the preceding 200 ms
addPanelLetter(h, 'C', [0.362 0.635 0.03 0.03]);
annotation(h, 'textbox', [0.400 0.625 0.550 0.028], ...
    'String', 'Spike history versus error type', ...
    'LineStyle', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'normal');

ax_C1 = axes(h, 'Position', [0.400 0.405 0.250 0.190]);
plotHistorySummary(ax_C1, panel_C, method_labels, method_colors, ...
    "fp_hazard_hz", {'False positives/', 'exposed second'}, ...
    'GT spikes in previous 200 ms');

ax_C2 = axes(h, 'Position', [0.700 0.405 0.250 0.190]);
plotHistorySummary(ax_C2, panel_C, method_labels, method_colors, ...
    "fn_fraction", 'False-negative fraction', ...
    'Prior GT spikes in previous 200 ms');
ylim(ax_C2, [0 1]);
yticks(ax_C2, [0 0.5 1]);

%% Panel D: quiescence-aligned MAP-event traces
addPanelLetter(h, 'D', [0.012 0.305 0.03 0.03]);
panel_D_positions = [
    0.050 0.055 0.280 0.225
    0.365 0.055 0.280 0.225
    0.680 0.055 0.280 0.225
    ];
plotQuiescentTraces(h, panel_D_positions, panel_D, ...
    method_labels, method_colors);

%% Export
saveFigureOutputs("supp_figure11", "suppfigure11", h);
end


function plotPanelA(figure_handle, positions, data, ...
        method_labels, method_display_labels, method_colors)
plot_window = double(data.plot_window_s);
trace_limits = [-0.12 2.02];
class_edges = [1.00 1.30 1.60 1.90];
fp_color = [0.82 0.12 0.12];

% Fluorescence
ax = axes(figure_handle, 'Position', positions(1, :));
hold(ax, 'on');
dff_rows = data.dff_time_s >= plot_window(1) & ...
    data.dff_time_s <= plot_window(2);
dff_time = double(data.dff_time_s(dff_rows));
dff = double(data.dff(dff_rows));
tail = dff_time >= 0.8 & dff_time <= 1.0;
if any(tail)
    baseline = median(dff(tail), 'omitnan');
else
    baseline = median(dff, 'omitnan');
end
dff = dff - baseline;
plot(ax, dff_time, dff, 'k', 'LineWidth', 1.1);
xlim(ax, plot_window);
finite_dff = dff(isfinite(dff));
dff_span = range(finite_dff);
if ~isfinite(dff_span) || dff_span <= 0
    dff_span = 1;
end
ylim(ax, [min(finite_dff) - 0.35 * dff_span, ...
    max(finite_dff) + 0.15 * dff_span]);
yl = ylim(ax);
dy = diff(yl);
plot(ax, plot_window, [0 0], ':', ...
    'Color', [0.3 0.3 0.3], 'LineWidth', 0.8);
history_y = yl(1) + 0.22 * dy;
plot(ax, [-data.prior_window_s 0], [history_y history_y], ...
    'Color', [0.68 0.68 0.68], 'LineWidth', 1.5);
text(ax, -data.prior_window_s, history_y, ...
    sprintf('%d spikes', data.prior_gt_spikes), ...
    'VerticalAlignment', 'bottom', 'Color', [0.45 0.45 0.45], ...
    'FontName', 'Arial', 'FontSize', 7);
text(ax, 0, history_y, 'Last spike', ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
    'Color', [0 0 0], 'FontName', 'Arial', 'FontSize', 7);
addScaleBars(ax, 0.2, niceScale(dff_span / 3));
addGroundTruthGuides(ax, data.gt_time_s, plot_window);
text(ax, -0.035, 0.5, 'Fluorescence', ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle', 'Color', [0 0 0], ...
    'FontName', 'Arial', 'FontSize', 10, ...
    'FontWeight', 'bold', 'Clipping', 'off');
title(ax, 'High spike activity history example', ...
    'FontName', 'Arial', 'FontWeight', 'normal', 'FontSize', 12);
hideAxisPreserveTitle(ax);

% Smoothed ground truth
ax = axes(figure_handle, 'Position', positions(2, :));
hold(ax, 'on');
gt_trace = smoothGroundTruth( ...
    dff_time, data.gt_time_s, data.trace_smoothing_sigma_s);
plot(ax, dff_time, gt_trace, 'k', 'LineWidth', 1.5);
xlim(ax, plot_window);
ylim(ax, trace_limits);
addGroundTruthGuides(ax, data.gt_time_s, plot_window);
trace_center = (0.5 - trace_limits(1)) / diff(trace_limits);
text(ax, -0.24, trace_center, {'Ground', 'truth'}, ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', 'Color', [0 0 0], ...
    'FontName', 'Arial', 'FontSize', 10, ...
    'FontWeight', 'bold', 'Clipping', 'off');
set(ax, 'Visible', 'off');

% Continuous predictions and discrete event classifications
for method_index = 1:numel(method_labels)
    ax = axes(figure_handle, ...
        'Position', positions(method_index + 2, :));
    hold(ax, 'on');
    method = data.methods(method_index);
    rows = method.time_s >= plot_window(1) & ...
        method.time_s <= plot_window(2);
    time = double(method.time_s(rows));
    trace = smoothAndNormalizeTrace( ...
        time, double(method.spike_prob(rows)), ...
        data.trace_smoothing_sigma_s);
    plot(ax, time, trace, ...
        'Color', method_colors(method_index, :), ...
        'LineWidth', 1.5);
    xlim(ax, plot_window);
    ylim(ax, trace_limits);
    addGroundTruthGuides(ax, data.gt_time_s, plot_window);
    for edge = class_edges
        plot(ax, plot_window, [edge edge], '--', ...
            'Color', method_colors(method_index, :) * 0.45 + 0.55, ...
            'LineWidth', 0.55);
    end
    drawEventTicks(ax, method.fn_time_s, ...
        plot_window, class_edges(1:2), [0.05 0.05 0.05]);
    drawEventTicks(ax, method.fp_time_s, ...
        plot_window, class_edges(2:3), fp_color);
    drawEventTicks(ax, method.tp_time_s, ...
        plot_window, class_edges(3:4), ...
        method_colors(method_index, :));

    text(ax, -0.24, trace_center, ...
        method_display_labels(method_index), ...
        'Units', 'normalized', 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'Color', method_colors(method_index, :), ...
        'FontName', 'Arial', 'FontSize', 10, ...
        'FontWeight', 'bold', 'Interpreter', 'tex', ...
        'Clipping', 'off');
    text(ax, 0.985, mean(class_edges(1:2)), 'FN', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'Color', [0.05 0.05 0.05], ...
        'FontName', 'Arial', 'FontSize', 6);
    text(ax, 0.985, mean(class_edges(2:3)), 'FP', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'Color', fp_color, 'FontName', 'Arial', 'FontSize', 6);
    text(ax, 0.985, mean(class_edges(3:4)), 'TP', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
        'Color', method_colors(method_index, :), ...
        'FontName', 'Arial', 'FontSize', 6);
    set(ax, 'Visible', 'off');
end
end


function handles = plotEpochErrorBins( ...
        ax, tbl, method_labels, colors, metric, y_label)
hold(ax, 'on');
handles = gobjects(numel(method_labels), 1);
method_offsets = [-0.05 0 0.05];
bin_centers = [];
upper_y = 0;
for method_index = 1:numel(method_labels)
    rows = tbl.metric == metric & ...
        tbl.method == method_labels(method_index);
    method_tbl = sortrows(tbl(rows, :), 'bin');
    x = double(method_tbl.x_estimate_gt_spikes);
    y = double(method_tbl.y_estimate);
    if isempty(bin_centers)
        bin_centers = x;
    end
    upper_y = max(upper_y, ...
        max(double(method_tbl.y_ci_upper), [], 'omitnan'));
    x_plot = x + method_offsets(method_index) .* localBinWidths(x);
    handles(method_index) = errorbar(ax, x_plot, y, ...
        y - double(method_tbl.y_ci_lower), ...
        double(method_tbl.y_ci_upper) - y, '-o', ...
        'Color', colors(method_index, :), 'LineWidth', 1.5, ...
        'MarkerFaceColor', 'w', 'MarkerSize', 4.5, 'CapSize', 0);
end
xlim(ax, [0 100]);
ylim(ax, [0 max(1, upper_y * 1.05)]);
xticks(ax, bin_centers);
xticklabels(ax, string(round(bin_centers)));
ax.XAxis.Exponent = 0;
xlabel(ax, 'Ground-truth spikes in epoch');
ylabel(ax, y_label);
styleAxis(ax, 7.5);
end


function plotHistorySummary( ...
        ax, tbl, method_labels, colors, metric, y_label, x_label)
hold(ax, 'on');
method_offsets = [-0.08 0 0.08];
upper_y = 0;
for method_index = 1:numel(method_labels)
    rows = tbl.metric == metric & ...
        tbl.method == method_labels(method_index);
    method_tbl = sortrows(tbl(rows, :), 'bin');
    estimate = double(method_tbl.estimate);
    upper_y = max(upper_y, ...
        max(double(method_tbl.ci_upper), [], 'omitnan'));
    errorbar(ax, double(method_tbl.bin) + method_offsets(method_index), ...
        estimate, estimate - double(method_tbl.ci_lower), ...
        double(method_tbl.ci_upper) - estimate, ...
        '-o', 'Color', colors(method_index, :), ...
        'LineWidth', 1.5, 'MarkerFaceColor', 'w', ...
        'MarkerSize', 4.5, 'CapSize', 0);
end
xlim(ax, [0.75 6.25]);
xticks(ax, 1:6);
xticklabels(ax, ["0", "1", "2", "3-4", "5-8", "9+"]);
xlabel(ax, x_label);
ylabel(ax, y_label);
ylim(ax, [0 max(1, upper_y * 1.05)]);
styleAxis(ax, 7.5);
end


function plotQuiescentTraces( ...
        figure_handle, positions, tbl, method_labels, method_colors)
display_window = [0.05 1];
display_rows = tbl.time_s >= display_window(1) & ...
    tbl.time_s <= display_window(2);
global_max = max( ...
    tbl.smoothed_mean_prediction_rate_hz(display_rows), ...
    [], 'omitnan');
canonical_bin_labels = ["1", "2-3", "4-5", "6+"];
for method_index = 1:numel(method_labels)
    ax = axes(figure_handle, 'Position', positions(method_index, :));
    hold(ax, 'on');
    method_rows = tbl.method == method_labels(method_index);
    bin_indices = unique(tbl.spike_bin(method_rows), 'stable');
    palette = makeMethodTints( ...
        method_colors(method_index, :), numel(bin_indices), 0.70);
    handles = gobjects(numel(bin_indices), 1);
    legend_labels = strings(numel(bin_indices), 1);
    for bin_index = 1:numel(bin_indices)
        rows = method_rows & ...
            tbl.spike_bin == bin_indices(bin_index) & display_rows;
        trace_tbl = sortrows(tbl(rows, :), 'time_s');
        handles(bin_index) = plot(ax, trace_tbl.time_s, ...
            trace_tbl.smoothed_mean_prediction_rate_hz, ...
            'Color', palette(bin_index, :), 'LineWidth', 1.6);
        legend_labels(bin_index) = ...
            canonical_bin_labels(bin_indices(bin_index)) + ...
            " (n=" + string(trace_tbl.n_events(1)) + ")";
    end
    xlim(ax, display_window);
    ylim(ax, [0 global_max * 1.08]);
    xlabel(ax, 'Time from last GT spike (s)');
    if method_index == 1
        ylabel(ax, 'Predicted MAP events/s');
    end
    if method_index == 1
        title_label = 'Biophys_{SMC}';
    else
        title_label = char(method_labels(method_index));
    end
    title(ax, title_label, 'Interpreter', 'tex', ...
        'FontName', 'Arial', 'FontWeight', 'normal', ...
        'Color', method_colors(method_index, :));
    legend(ax, handles, legend_labels, ...
        'Location', 'northeast', 'Box', 'off', 'FontSize', 6);
    styleAxis(ax, 7.5);
end
end


function trace = smoothGroundTruth(time, gt_times, sigma_s)
counts = zeros(size(time));
for gt_time = gt_times(:).'
    if gt_time < time(1) || gt_time > time(end)
        continue
    end
    [~, index] = min(abs(time - gt_time));
    counts(index) = counts(index) + 1;
end
trace = smoothAndNormalizeTrace(time, counts, sigma_s);
end


function normalized = smoothAndNormalizeTrace(time, values, sigma_s)
time = double(time(:));
values = double(values(:));
if isempty(time)
    normalized = values;
    return
end
dt = median(diff(time), 'omitnan');
window = max(3, 2 * ceil(3 * sigma_s / dt) + 1);
smoothed = smoothdata(values, 'gaussian', window);
finite = smoothed(isfinite(smoothed));
if isempty(finite) || max(finite) <= min(finite)
    normalized = zeros(size(smoothed));
else
    normalized = (smoothed - min(finite)) / ...
        (max(finite) - min(finite));
end
end


function addGroundTruthGuides(ax, gt_times, plot_window)
yl = ylim(ax);
gt_times = gt_times(gt_times >= plot_window(1) - 1e-10 & ...
    gt_times <= plot_window(2) + 1e-10);
for gt_time = gt_times(:).'
    if gt_time < -1e-8
        color = [179 179 179] / 255;
    else
        color = [0 0 0];
    end
    plot(ax, [gt_time gt_time], yl, ':', ...
        'Color', color, 'LineWidth', 0.8);
end
end


function drawEventTicks(ax, times, plot_window, band, color)
times = times(times >= plot_window(1) - 1e-10 & ...
    times <= plot_window(2) + 1e-10);
for time = times(:).'
    plot(ax, [time time], band, ...
        'Color', color, 'LineWidth', 0.9);
end
end


function addScaleBars(ax, x_length, y_length)
xl = xlim(ax);
yl = ylim(ax);
dx = diff(xl);
dy = diff(yl);
x1 = xl(2) - 0.08 * dx;
x0 = x1 - x_length;
y1 = yl(2) - 0.14 * dy;
y0 = y1 - y_length;
plot(ax, [x0 x1], [y1 y1], 'k', 'LineWidth', 1.2);
plot(ax, [x1 x1], [y0 y1], 'k', 'LineWidth', 1.2);
text(ax, mean([x0 x1]), y1 + 0.025 * dy, ...
    sprintf('%d ms', round(x_length * 1000)), ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontName', 'Arial', 'FontSize', 6.5);
text(ax, x1 + 0.018 * dx, mean([y0 y1]), ...
    sprintf('%.2g \\DeltaF/F', y_length), ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
    'FontName', 'Arial', 'FontSize', 6.5);
end


function value = niceScale(target)
if ~isfinite(target) || target <= 0
    value = 0.1;
    return
end
power = 10 ^ floor(log10(target));
scaled = target / power;
choices = [1 2 5 10];
[~, index] = min(abs(choices - scaled));
value = choices(index) * power;
end


function widths = localBinWidths(centers)
centers = double(centers(:));
if numel(centers) < 2
    widths = ones(size(centers));
    return
end
spacing = diff(centers);
widths = [spacing(1); ...
    0.5 * (spacing(1:end-1) + spacing(2:end)); spacing(end)];
end


function colors = makeMethodTints(base_color, n_colors, maximum_tint)
if n_colors == 1
    colors = base_color;
    return
end
tint = linspace(0, maximum_tint, n_colors).';
colors = base_color .* (1 - tint) + ones(n_colors, 3) .* tint;
end


function colors = getMethodColors
color_keys = {'biophys_{MC', 'MLspike', 'PGBAR'};
colors = nan(numel(color_keys), 3);
for index = 1:numel(color_keys)
    colors(index, :) = hexToRgb(pickGCaMPcolorsMS(color_keys{index}));
end
end


function rgb = hexToRgb(hex)
hex = erase(char(hex), '#');
rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), ...
    hex2dec(hex(5:6))] / 255;
end


function addPanelLetter(figure_handle, letter, position)
annotation(figure_handle, 'textbox', position, ...
    'String', letter, 'LineStyle', 'none', ...
    'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'normal', ...
    'VerticalAlignment', 'middle');
end


function hideAxisPreserveTitle(ax)
set(ax, 'Visible', 'off');
set(get(ax, 'Title'), 'Visible', 'on');
end


function styleAxis(ax, font_size)
set(ax, 'FontName', 'Arial', 'FontSize', font_size, ...
    'LineWidth', 1, 'TickDir', 'out', 'Box', 'off');
set(ax.XLabel, 'FontName', 'Arial', 'FontSize', 10, ...
    'FontWeight', 'normal');
set(ax.YLabel, 'FontName', 'Arial', 'FontSize', 10, ...
    'FontWeight', 'normal');
grid(ax, 'on');
ax.GridAlpha = 0.12;
ax.MinorGridAlpha = 0.08;
end


function validateFiles(files)
names = fieldnames(files);
for file_index = 1:numel(names)
    if ~isfile(files.(names{file_index}))
        error('suppfigure11_code:MissingInput', ...
            'Missing required input: %s', files.(names{file_index}));
    end
end
end
