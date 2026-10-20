function modelSelectionData = AccessFitFiles_Janelia(intermediateFile,outputDir,construct,outputStem,figureSizeCm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AccessFitFiles_Janelia
%
% Load a compact intermediate file for a Janelia parameter comparison, then
% plot only the parameter set with the global minimum
% combined stopped-flow + Janelia score.
%
% Inputs:
%   intermediateFile:
%       single MAT file containing only the model-selection summary and the
%       best-fit traces needed for plotting.
%   outputDir: plot output directory.
%   construct: plotting construct, e.g. 'jGCaMP8f' or 'jGCaMP8m'.
%   outputStem: base filename for PNG/PDF outputs.
%   figureSizeCm: optional [width height] override; defaults to [19.17 6.74].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = projectRoot(scriptDir);
matlabUtilities = fullfile(repoRoot,'shared','matlab');
if ~contains(path,matlabUtilities)
    addpath(matlabUtilities);
end

if nargin < 1 || isempty(intermediateFile)
    error('An intermediate model-selection MAT file is required.');
end
if nargin < 2 || isempty(outputDir)
    outputDir = fullfile(scriptDir,'output');
end
if nargin < 3
    construct = '';
end
if nargin < 4 || isempty(outputStem)
    outputStem = 'janelia_global_best_fit';
end
if nargin < 5 || isempty(figureSizeCm)
    figureSizeCm = [19.17,6.74];
end

if ~isfolder(outputDir); mkdir(outputDir); end

sharedDataDir = fullfile(repoRoot,'shared','inputs');
sfDataFile = fullfile(sharedDataDir,'stoppedFlowTraces.mat');
gdbFile = fullfile(sharedDataDir,'gDbase.mat');

if ~isfile(intermediateFile)
    error('Intermediate file not found: %s',intermediateFile);
end
loaded = load(intermediateFile,'modelSelectionData');
modelSelectionData = loaded.modelSelectionData;
modelSelectionData = validateModelSelectionData(modelSelectionData);

if ~isfile(sfDataFile)
    error('Shared stopped-flow data not found: %s',sfDataFile);
end
if ~isfile(gdbFile)
    error('Shared GCaMP database not found: %s',gdbFile);
end

load(sfDataFile,'processedTraces');
load(gdbFile,'gData');

plotBestFit(modelSelectionData,processedTraces,gData,outputDir,construct,outputStem,figureSizeCm);

fprintf('Selected %s with combined score %.6g. Outputs saved to %s\n', ...
    modelSelectionData.bestFit.sourceFileName, ...
    modelSelectionData.bestFit.combinedScore, ...
    outputDir);

end

function modelSelectionData = validateModelSelectionData(modelSelectionData)
requiredFields = {'combinedScore','output_params_all','janelia_params_all','bestFit'};
for iField = 1:numel(requiredFields)
    if ~isfield(modelSelectionData,requiredFields{iField})
        error('modelSelectionData is missing required field "%s".',requiredFields{iField});
    end
end
combinedScore = modelSelectionData.combinedScore(:);
[~,globalBestIdx] = min(combinedScore);
modelSelectionData.bestIdx = globalBestIdx;

bestFit = modelSelectionData.bestFit;
requiredBestFields = {'sourceFileName','const','output_params','janelia_params', ...
    'combinedScore','normfit','tJanelia','dff_hatJanelia'};
for iField = 1:numel(requiredBestFields)
    if ~isfield(bestFit,requiredBestFields{iField})
        error('modelSelectionData.bestFit is missing required field "%s".',requiredBestFields{iField});
    end
end

if isfield(modelSelectionData,'fname_list')
    fnameList = string(modelSelectionData.fname_list(:));
    expectedName = fnameList(globalBestIdx);
    if expectedName ~= string(bestFit.sourceFileName)
        error('Stored bestFit (%s) does not match global minimum combinedScore row (%s).', ...
            string(bestFit.sourceFileName),expectedName);
    end
end
end

function plotBestFit(modelSelectionData,processedTraces,gData,outputDir,construct,outputStem,figureSizeCm)
bestFit = modelSelectionData.bestFit;
if nargin < 5 || isempty(construct)
    const = char(bestFit.const);
else
    const = char(construct);
end

f = figure('Name','Janelia global best fit', ...
    'PaperUnits','centimeters', ...
    'PaperPosition',[0,0,figureSizeCm], ...
    'PaperSize',figureSizeCm, ...
    'Units','centimeters', ...
    'Position',[5,5,figureSizeCm]);
tlo = tiledlayout(1,4,'TileSpacing','compact','Padding','compact');

dataHex = pickGCaMPcolorsMS(const);
dataCol = hex2rgb(dataHex);
modelCol = hex2rgb('#009E73');
kinType = {'(on kinetics)','(off kinetics)'};
goodFits = {1:9,10:11};

axSF = gobjects(2,1);
for sfIdx = 1:2
    ax = nexttile(tlo,sfIdx);
    axSF(sfIdx) = ax;
    hold(ax,'on');
    set(ax,'tickdir','out','linewidth',1);
    thisConst = strcmp(GCaMPalias(const),{processedTraces{1}.const});
    if sfIdx == 2
        plotStoppedFlowTile(ax,processedTraces,thisConst,bestFit.normfit,sfIdx,goodFits,dataCol,modelCol);
    else
        plotStoppedFlowTile(ax,processedTraces,thisConst,bestFit.normfit,sfIdx,goodFits,dataCol,modelCol);
    end
    xlabel(ax,'time (ms)');
    ylabel(ax,{'Normalized F',kinType{sfIdx}});
    set(ax,'xlim',[0,500],'xtick',[0,250,500]);
end
addGroupTitleOverAxes(f,axSF,'Stopped flow fits');

axJ = nexttile(tlo,3,[1 2]);
hold(axJ,'on');
set(axJ,'tickdir','out','linewidth',1);
constIdx = find(strcmp({gData.const},GCaMPalias(const)),1,'first');
if isempty(constIdx)
    error('Janelia const %s not found in gData.',GCaMPalias(const));
end
jd = gData(constIdx).Janelia_data(1);
tJ = double(jd.time(:));
normFJ = double(jd.normF(:));
plot(axJ,tJ,normFJ,'Color',dataCol,'LineWidth',1);
plot(axJ,bestFit.tJanelia,bestFit.dff_hatJanelia,'Color',[modelCol,0.3],'LineWidth',2);
xlabel(axJ,'time (s)');
ylabel(axJ,'\DeltaF/F');
title(axJ,sprintf('Janelia fit (%s)',const));
axis(axJ,'tight');
spikes = gData(constIdx).Janelia_data.gt_spikes;
yl = ylim(axJ);
arrayfun(@(x) plot(axJ,[x,x],yl,'k--'),spikes);
ylim(axJ,yl);

saveas(f,fullfile(outputDir,[outputStem,'.png']));
saveas(f,fullfile(outputDir,[outputStem,'.pdf']));
end

function plotStoppedFlowTile(ax,processedTraces,thisConst,normfit,sfIdx,goodFits,dataCol,modelCol)
fitAlpha = 0.3;
fitLineWidth = 2;
dataLineWidth = 1;

Time = processedTraces{sfIdx}(thisConst).time(processedTraces{sfIdx}(thisConst).logSelectPts,:);
datasets = processedTraces{sfIdx}(thisConst).traces(processedTraces{sfIdx}(thisConst).logSelectPts,:);
normfit = normfit(:);

try
    thisNormfit = reshape(normfit,[],11);
    thisNormfit = thisNormfit(:,goodFits{sfIdx});
    if sfIdx == 2
        Time = Time(:,1);
        datasets = datasets(:,1);
        thisNormfit = thisNormfit(:,1);
    end
    plot(ax,Time*1000,datasets,'linestyle','-','Color',dataCol,'linewidth',dataLineWidth);
    plot(ax,Time*1000,thisNormfit,'Color',[modelCol,fitAlpha],'linewidth',fitLineWidth);
catch
    plot(ax,Time*1000,datasets,'linestyle','-','Color',dataCol,'linewidth',dataLineWidth);
end
end

function rgb = hex2rgb(hex)
if isstring(hex); hex = char(hex); end
if isempty(hex)
    rgb = [0.5,0.5,0.5];
    return;
end
if hex(1) == '#'
    hex = hex(2:end);
end
r = hex2dec(hex(1:2));
g = hex2dec(hex(3:4));
b = hex2dec(hex(5:6));
rgb = double([r,g,b]) ./ 255;
end

function addGroupTitleOverAxes(figHandle,axArray,titleText)
axArray = axArray(isgraphics(axArray));
if isempty(axArray)
    return;
end
origUnits = get(axArray,'Units');
if iscell(origUnits); origUnits = string(origUnits); else; origUnits = string({origUnits}); end
for i = 1:numel(axArray)
    axArray(i).Units = 'normalized';
end
positions = reshape([axArray.Position],4,[])';
xLeft = min(positions(:,1));
xRight = max(positions(:,1) + positions(:,3));
yTop = max(positions(:,2) + positions(:,4));
boxHeight = 0.05;
y = min(yTop + 0.01,0.98 - boxHeight);
annotation(figHandle,'textbox',[xLeft,y,(xRight - xLeft),boxHeight], ...
    'String',titleText, ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom', ...
    'FontWeight','bold');
for i = 1:numel(axArray)
    axArray(i).Units = char(origUnits(i));
end
end
