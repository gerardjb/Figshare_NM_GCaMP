function results = qcKernelSaturationElongation(Data,ts,idx,varargin)
%%%
% Figure-style QC panels for saturation vs elongation in 1-2-10 data.
%
% Creates a 2x4 tiledlayout suitable for embedding under `supp_figure1`:
%   Row 1: supra-linear exemplar (default idx 9)
%   Row 2: saturating exemplar (default idx 5)
%   Col 1: single-spike trace + linear-kernel fit
%   Col 2: ten-spike trace + linear-kernel prediction (from single fit)
%   Col 3: "Final pulse aligned" normalized amplitude (kinetics)
%   Col 4: summary scatter plots (by structure type)
%
% Inputs:
%   Data - cell array where Data{i} is [T x Ncond] dF/F matrix (1/2/10 conds)
%   ts   - cell array where ts{i} is [T x Ncond] time matrix (seconds)
%   idx  - vector of indices to include in the summary scatters (use [] for all)
%
% Name/value options:
%   'condCols'        - [single two ten] columns in Data{i} (default [1 2 3])
%   'spikes'          - spike times per condition (default {0,[0 0.01],0:0.01:0.09})
%   'baselineWindow'  - [t0 t1] seconds for baseline subtraction (default [-0.05 0])
%   'xlimRaw'         - x-limits for raw overlays (default [-0.05 0.6])
%   'xlimAligned'     - x-limits for aligned/normalized decays (default [-0.05 0.8])
%   'smoothN'         - movmean window samples for display (default 9)
%   'showTwoSpike'    - true/false include 2-spike in aligned panel (default false)
%   'exemplarSupraIdx'- index for supra-linear exemplar (default 9)
%   'exemplarSatIdx'  - index for saturating exemplar (default 5)
%   'structType'      - cellstr/string/categorical per index (e.g. 'bouton','somata')
%   'constColor'      - construct key for pickGCaMPcolorsMS (default 'jG8f')
%
% Output:
%   results - struct array (one per idx) with kernel params + metrics
%%%

p = inputParser;
p.addParameter('condCols',[1 2 3],@(x) isnumeric(x) && numel(x)==3);
p.addParameter('spikes',{0,[0 0.01],0:0.01:0.09},@(x) iscell(x) && numel(x)>=3);
p.addParameter('baselineWindow',[-0.05 0],@(x) isnumeric(x) && numel(x)==2);
p.addParameter('xlimRaw',[-0.05 0.6],@(x) isnumeric(x) && numel(x)==2);
p.addParameter('xlimAligned',[-0.05 0.8],@(x) isnumeric(x) && numel(x)==2);
p.addParameter('smoothN',9,@(x) isnumeric(x) && isscalar(x) && x>=1);
p.addParameter('showTwoSpike',false,@(x) islogical(x) && isscalar(x));
p.addParameter('exemplarSupraIdx',9,@(x) isnumeric(x) && isscalar(x) && x>=1);
p.addParameter('exemplarSatIdx',5,@(x) isnumeric(x) && isscalar(x) && x>=1);
p.addParameter('structType',[],@(x) iscell(x) || isstring(x) || iscategorical(x) || isempty(x));
p.addParameter('constColor','jG8f',@(x) ischar(x) || isstring(x));
p.addParameter('addScaleBars',true,@(x) islogical(x) && isscalar(x));
p.addParameter('scaleBarRawX',0.1,@(x) isnumeric(x) && isscalar(x) && x>0);
p.addParameter('scaleBarRawY',0.1,@(x) isnumeric(x) && isscalar(x) && x>=0);
p.addParameter('scaleBarNormX',0.1,@(x) isnumeric(x) && isscalar(x) && x>0);
p.addParameter('scaleBarNormY',0.2,@(x) isnumeric(x) && isscalar(x) && x>0);
p.parse(varargin{:});
opt = p.Results;

if ~exist('lsqcurvefit','file')
    error('qcKernelSaturationElongation:MissingToolbox','lsqcurvefit not found (Optimization Toolbox required).');
end
if ~exist('linear_kernel','file')
    error('qcKernelSaturationElongation:MissingDependency','linear_kernel.m not found on path.');
end
if ~exist('fitDecayForGCaMPcell2','file')
    error('qcKernelSaturationElongation:MissingDependency','fitDecayForGCaMPcell2.m not found on path.');
end
if ~exist('pickGCaMPcolorsMS','file')
    error('qcKernelSaturationElongation:MissingDependency','pickGCaMPcolorsMS.m not found on path.');
end
if ~exist('hex2rgb','file')
    error('qcKernelSaturationElongation:MissingDependency','hex2rgb.m not found on path.');
end
if ~exist('tint_rgb','file') || ~exist('adjustSaturation','file')
    error('qcKernelSaturationElongation:MissingDependency','tint_rgb.m / adjustSaturation.m not found on path.');
end
if opt.addScaleBars && ~exist('makeTSscaleBar','file')
    error('qcKernelSaturationElongation:MissingDependency','makeTSscaleBar.m not found on path.');
end

if isempty(idx)
    idx = 1:numel(Data);
end
idx = idx(:)';

if ~isempty(opt.structType) && numel(opt.structType) ~= numel(Data)
    error('qcKernelSaturationElongation:BadStructTypeSize','structType must match numel(Data).');
end

constCol = hex2rgb(pickGCaMPcolorsMS(opt.constColor));
cmap = [ ...
    constCol; ...
    adjustSaturation((tint_rgb(constCol,1.25)),0.3); ...
    adjustSaturation((tint_rgb(constCol,1.55)),0.15) ...
    ];
fitCol = [0.35,0.35,0.35,0.85];
predCol = [0.35,0.35,0.35,0.55];

results = repmat(struct( ...
    'idx',nan, ...
    'structType',"", ...
    'kernelParams',nan(1,3), ...
    'resnorm',nan, ...
    'peakSingle',nan, ...
    'peakTenObs',nan, ...
    'peakTenPred',nan, ...
    'saturation',nan, ...
    'tauFastSingle',nan, ...
    'tauFastTenObs',nan, ...
    'tauFastTenPred',nan, ...
    'elongationObs_overSingle',nan, ...
    'elongationPred_overSingle',nan ...
    ),1,numel(idx));

% ---- Compute metrics for all idx (for scatters)
cols = opt.condCols;
spikes1 = opt.spikes{1};
spikes2 = opt.spikes{2};
spikes10 = opt.spikes{3};

for r = 1:numel(idx)
    ii = idx(r);
    [t1,t2,t10,f1,f2,f10] = getTraces(Data,ts,ii,cols,opt.baselineWindow);
    [outParams,resnorm] = fitKernelToSingle(t1,f1,spikes1);
    f10hat = linear_kernel(outParams,spikes10,t10);

    peakObs10 = max(f10);
    peakPred10 = max(f10hat);
    saturation = peakObs10 ./ max(peakPred10,eps);

    tau1 = fitTauFast(t1,f1);
    tau10 = fitTauFast(t10,f10);
    tau10p = fitTauFast(t10,f10hat);

    results(r).idx = ii;
    if isempty(opt.structType)
        results(r).structType = "";
    else
        results(r).structType = string(opt.structType(ii));
    end
    results(r).kernelParams = outParams;
    results(r).resnorm = resnorm;
    results(r).peakSingle = max(f1);
    results(r).peakTenObs = peakObs10;
    results(r).peakTenPred = peakPred10;
    results(r).saturation = saturation;
    results(r).tauFastSingle = tau1;
    results(r).tauFastTenObs = tau10;
    results(r).tauFastTenPred = tau10p;
    results(r).elongationObs_overSingle = tau10 / max(tau1,eps);
    results(r).elongationPred_overSingle = tau10p / max(tau1,eps);
end

% ---- Figure layout (2x4) with exemplars + scatters
ff = figure('Name','Kernel saturation vs elongation (supp panel draft)');
outer = tiledlayout(ff,2,4,'TileSpacing','compact','Padding','compact');

[yLim1RawShared,yLim10RawShared] = sharedRawYLim(Data,ts,[opt.exemplarSupraIdx,opt.exemplarSatIdx], ...
    cols,opt,spikes1,spikes10);

plotExemplarRow(outer,1,opt.exemplarSupraIdx,'Linear kernel supra-linear example', ...
    Data,ts,cols,opt,spikes1,spikes2,spikes10,cmap,fitCol,predCol,true,yLim1RawShared,yLim10RawShared);
plotExemplarRow(outer,2,opt.exemplarSatIdx,'Linear kernel saturating example', ...
    Data,ts,cols,opt,spikes1,spikes2,spikes10,cmap,fitCol,predCol,false,yLim1RawShared,yLim10RawShared);

% Scatter: tau_fast vs saturation
axTop = nexttile(outer,4);
hold(axTop,'on');
plotSummaryScatter(axTop,results,'saturation','tauFastTenObs',opt.structType,1000,true);
ylabel(axTop,'\tau_{fast} (ms)');
xlabel(axTop,'Saturation (obs/pred peak)');
styleScatterAxis(axTop);

lgd = legend(axTop,'Location','eastoutside');
lgd.Box = 'off';
title(lgd,'Structure');

% Scatter: tau_fast(data) / tau_fast(pred) vs saturation
axBot = nexttile(outer,8);
hold(axBot,'on');
tauRatio = arrayfun(@(r) r.tauFastTenObs / max(r.tauFastTenPred,eps), results);
plotSummaryScatter(axBot,results,'saturation',tauRatio,opt.structType,1,false);
ylabel(axBot,'\tau_{fast} (data/pred)');
xlabel(axBot,'Saturation (obs/pred peak)');
styleScatterAxis(axBot);

linkaxes([axTop,axBot],'x');
drawnow;
axBot.Position = axTop.Position;

end

function plotExemplarRow(outer,rowIdx,ii,rowTitle,Data,ts,cols,opt,spikes1,spikes2,spikes10,cmap,fitCol,predCol,addScaleBars,forceYLim1,forceYLim10)
if ii < 1 || ii > numel(Data)
    error('qcKernelSaturationElongation:BadExemplarIdx','Exemplar idx %d out of range.',ii);
end

left = tiledlayout(outer,1,2,'TileSpacing','compact','Padding','compact');
left.Layout.Tile = 1 + (rowIdx-1)*4;
left.Layout.TileSpan = [1 2];
title(left,rowTitle,'FontWeight','normal');

[t1,t2,t10,f1,f2,f10] = getTraces(Data,ts,ii,cols,opt.baselineWindow);
[outParams,~] = fitKernelToSingle(t1,f1,spikes1);
f1hat = linear_kernel(outParams,spikes1,t1);
f10hat = linear_kernel(outParams,spikes10,t10);

ax1 = nexttile(left,1); hold(ax1,'on');
plot(ax1,t1,smoothdata(f1,'movmean',opt.smoothN),'Color',cmap(1,:),'LineWidth',1);
plot(ax1,t1,f1hat,'Color',fitCol,'LineWidth',1.2);
xlim(ax1,opt.xlimRaw);
styleTraceAxis(ax1);
if ~isempty(forceYLim1)
    ylim(ax1,forceYLim1);
end
y = ylim(ax1);
plot(ax1,[0,0],y,'k--','LineWidth',0.4);
if opt.addScaleBars && addScaleBars
    makeTSscaleBar(ax1,'xVal',opt.scaleBarRawX,'xText',[num2str(opt.scaleBarRawX*1000),' ms'], ...
        'yVal',opt.scaleBarRawY,'yText',[num2str(opt.scaleBarRawY),' ',greek_char('Delta'),'F/F'], ...
        'xfrac',0.35,'yfrac',0.75,'lefty',0,'upsidedown',1,'fontsize',10);
end

ax2 = nexttile(left,2); hold(ax2,'on');
plot(ax2,t10,smoothdata(f10,'movmean',opt.smoothN),'Color',cmap(3,:),'LineWidth',1);
plot(ax2,t10,f10hat,'Color',fitCol,'LineWidth',1.2);
xlim(ax2,opt.xlimRaw);
styleTraceAxis(ax2);
if ~isempty(forceYLim10)
    ylim(ax2,forceYLim10);
end
y = ylim(ax2);
plot(ax2,[0,0],y,'k--','LineWidth',0.4);
if opt.addScaleBars && addScaleBars
    makeTSscaleBar(ax2,'xVal',opt.scaleBarRawX,'xText',[num2str(opt.scaleBarRawX*1000),' ms'], ...
        'yVal',opt.scaleBarRawY,'yText',[num2str(opt.scaleBarRawY),' ',greek_char('Delta'),'F/F'], ...
        'xfrac',0.35,'yfrac',0.75,'lefty',0,'upsidedown',1,'fontsize',10);
end

ax3 = nexttile(outer,3 + (rowIdx-1)*4); hold(ax3,'on');
[t1a,f1n] = alignAndNormalize(t1,f1,max(spikes1),opt.smoothN);
[t2a,f2n] = alignAndNormalize(t2,f2,max(spikes2),opt.smoothN);
[t10a,f10n] = alignAndNormalize(t10,f10,max(spikes10),opt.smoothN);
[~,f10pn] = alignAndNormalize(t10,f10hat,max(spikes10),1);

plot(ax3,t1a,f1n,'Color',cmap(1,:),'LineWidth',1);
if opt.showTwoSpike
    plot(ax3,t2a,f2n,'Color',cmap(2,:),'LineWidth',1);
end
plot(ax3,t10a,f10n,'Color',cmap(3,:),'LineWidth',1.2);
plot(ax3,t10a,f10pn,'Color',predCol,'LineWidth',1.1);
xlim(ax3,opt.xlimAligned);
ylim(ax3,[-0.05,1.05]);
styleTraceAxis(ax3);
y = ylim(ax3);
plot(ax3,[0,0],y,'k--','LineWidth',0.4);
title(ax3,{'Final pulse aligned','normalized amplitude'},'FontWeight','normal');
if opt.addScaleBars && addScaleBars
    makeTSscaleBar(ax3,'xVal',opt.scaleBarNormX,'xText',[num2str(opt.scaleBarNormX*1000),' ms'], ...
        'yVal',0,'yText',"", ...
        'xfrac',0.35,'yfrac',0.75,'lefty',0,'upsidedown',1,'fontsize',10);
end
end

function [tAligned,fNorm] = alignAndNormalize(t,f,lastSpike,smoothN)
tAligned = t - lastSpike;
fDisp = f;
if smoothN > 1
    fDisp = smoothdata(fDisp,'movmean',smoothN);
end
pk = max(fDisp);
if pk <= 0 || ~isfinite(pk)
    fNorm = fDisp*nan;
else
    fNorm = fDisp ./ pk;
end
end

function tauFast = fitTauFast(t,f)
[model,~,~] = fitDecayForGCaMPcell2(t,f);
if isempty(model)
    tauFast = nan;
    return;
end
b = model.b;
d = model.d;
rates = [b,d];
rates = rates(isfinite(rates) & rates~=0);
if isempty(rates)
    tauFast = nan;
    return;
end
tauFast = 1/max(abs(rates));
end

function fOut = baselineSubtract(t,f,bw)
mask = t>=bw(1) & t<=bw(2);
if ~any(mask)
    mask = t < 0;
end
if ~any(mask)
    base = f(1);
else
    base = mean(f(mask),'omitnan');
end
fOut = f - base;
end

function [yLim1Raw,yLim10Raw] = sharedRawYLim(Data,ts,exemplarIdx,cols,opt,spikes1,spikes10)
vals1 = [];
vals10 = [];
for k = 1:numel(exemplarIdx)
    ii = exemplarIdx(k);
    [t1,~,t10,f1,~,f10] = getTraces(Data,ts,ii,cols,opt.baselineWindow);
    [outParams,~] = fitKernelToSingle(t1,f1,spikes1);
    f1hat = linear_kernel(outParams,spikes1,t1);
    f10hat = linear_kernel(outParams,spikes10,t10);

    mask1 = t1>=opt.xlimRaw(1) & t1<=opt.xlimRaw(2);
    mask10 = t10>=opt.xlimRaw(1) & t10<=opt.xlimRaw(2);
    vals1 = [vals1; f1(mask1); f1hat(mask1)]; %#ok<AGROW>
    vals10 = [vals10; f10(mask10); f10hat(mask10)]; %#ok<AGROW>
end
yLim1Raw = paddedLim(vals1);
yLim10Raw = paddedLim(vals10);
end

function lim = paddedLim(v)
v = v(isfinite(v));
if isempty(v)
    lim = [-0.1, 0.1];
    return;
end
vmin = min(v);
vmax = max(v);
span = vmax - vmin;
if span <= 0
    span = max(abs(vmax),1) * 0.1;
end
pad = 0.05 * span;
lim = [vmin-pad, vmax+pad];
end

function [t1,t2,t10,f1,f2,f10] = getTraces(Data,ts,ii,cols,bw)
thisData = Data{ii};
thisTs = ts{ii};
t1 = thisTs(:,cols(1));
t2 = thisTs(:,cols(2));
t10 = thisTs(:,cols(3));
f1 = baselineSubtract(t1,thisData(:,cols(1)),bw);
f2 = baselineSubtract(t2,thisData(:,cols(2)),bw);
f10 = baselineSubtract(t10,thisData(:,cols(3)),bw);
end

function [outParams,resnorm] = fitKernelToSingle(t1,f1,spikes1)
Fm0 = max(f1);
inParams = [0.05,0.002,max(Fm0,eps)];
lb = [0.001,0.0001,0];
ub = [2,0.2,inf];
funfit = @(params,t) linear_kernel(params,spikes1,t);
options = optimoptions('lsqcurvefit', ...
    'Display','off', ...
    'TypicalX',[0.1,0.01,1], ...
    'MaxFunctionEvaluations',1000, ...
    'UseParallel',false);
[outParams,resnorm] = lsqcurvefit(funfit,inParams,t1,f1,lb,ub,options);
end

function styleTraceAxis(ax)
ax.YAxis.Visible = 'off';
ax.XAxis.Visible = 'off';
ax.Box = 'off';
ax.LineWidth = 1;
ax.TickDir = 'out';
ax.Clipping = 'on';
ax.FontName = 'Arial';
ax.FontSize = 10;
end

function styleScatterAxis(ax)
ax.Box = 'off';
ax.LineWidth = 1;
ax.TickDir = 'out';
grid(ax,'on');
ax.FontName = 'Arial';
ax.FontSize = 10;
end

function plotSummaryScatter(ax,results,xField,yFieldOrVector,structType,yScale,addDisplayName)
if nargin < 6 || isempty(yScale)
    yScale = 1;
end
if nargin < 7
    addDisplayName = true;
end
if ischar(yFieldOrVector) || isstring(yFieldOrVector)
    y = arrayfun(@(r) r.(yFieldOrVector), results);
else
    y = yFieldOrVector;
end
x = arrayfun(@(r) r.(xField), results);

if isempty(structType)
    scatter(ax,x,yScale*y,18,'k','filled','MarkerFaceAlpha',0.6);
    return;
end

types = string({results.structType});
[labels] = labelForStructType(types);
uni = unique(labels);
for i = 1:numel(uni)
    sel = labels == uni(i);
    marker = markerForLabel(uni(i));
    if addDisplayName
        scatter(ax,x(sel),yScale*y(sel),22,'k',marker, ...
            'MarkerFaceColor','none','LineWidth',1,'DisplayName',char(uni(i)));
    else
        scatter(ax,x(sel),yScale*y(sel),22,'k',marker, ...
            'MarkerFaceColor','none','LineWidth',1);
    end
end
end

function labels = labelForStructType(types)
labels = strings(size(types));
for i = 1:numel(types)
    t = lower(strtrim(types(i)));
    if contains(t,'bout')
        labels(i) = "Bouton";
    elseif contains(t,'soma')
        labels(i) = "Somata";
    else
        labels(i) = "Other";
    end
end
end

function marker = markerForLabel(label)
switch string(label)
    case "Bouton"
        marker = 'o';
    case "Somata"
        marker = '^';
    otherwise
        marker = 's';
end
end
