function outputPaths = saveFigureOutputs(figureDirectoryName,outputStem,figureHandles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save MATLAB figures below the repository's root output directory.
%
% Each figure is written as PNG, vector PDF, and editable MATLAB FIG. A
% single figure uses outputStem directly; multiple figures receive stable
% two-digit suffixes in figure-number order.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3 || isempty(figureHandles)
    figureHandles = findall(groot,'Type','figure');
end
figureHandles = figureHandles(isgraphics(figureHandles,'figure'));
if isempty(figureHandles)
    warning('saveFigureOutputs:noFigures','No figures were available to save.');
    outputPaths = strings(0,3);
    return;
end

[~,order] = sort([figureHandles.Number]);
figureHandles = figureHandles(order);

utilitiesDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(utilitiesDir);
outputDir = fullfile(repoRoot,'output',char(figureDirectoryName));
if ~isfolder(outputDir)
    mkdir(outputDir);
end

outputPaths = strings(numel(figureHandles),3);
for iFigure = 1:numel(figureHandles)
    if numel(figureHandles)==1
        thisStem = char(outputStem);
    else
        thisStem = sprintf('%s_%02d',char(outputStem),iFigure);
    end

    pngPath = fullfile(outputDir,[thisStem,'.png']);
    pdfPath = fullfile(outputDir,[thisStem,'.pdf']);
    figPath = fullfile(outputDir,[thisStem,'.fig']);
    drawnow;
    exportgraphics(figureHandles(iFigure),pngPath,'Resolution',300, ...
        'BackgroundColor','white');
    exportgraphics(figureHandles(iFigure),pdfPath,'ContentType','vector', ...
        'BackgroundColor','white');
    savefig(figureHandles(iFigure),figPath);
    outputPaths(iFigure,:) = string({pngPath,pdfPath,figPath});
end

fprintf('Saved %d figure(s) to %s\n',numel(figureHandles),outputDir);
end
