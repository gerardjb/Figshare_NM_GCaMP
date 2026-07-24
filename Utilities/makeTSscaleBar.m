function makeTSscaleBar(pHand, kwargs)
% makeTSscaleBar   Add an L‐shaped scale bar to a time‐series plot.
%
%   makeTSscaleBar(pHand, Name, Value, ...) adds a scale bar to the axes
%   specified by pHand. The scale bar always originates at a corner defined
%   by normalized coordinates (xFrac, yFrac) with respect to the axes limits.
%
%   Parameters:
%
%     'xFrac'             Normalized horizontal coordinate for the origin,
%                         between 0 and 1. 0 corresponds to the left edge,
%                         1 to the right edge. (Default: 0.67)
%     'yFrac'             Normalized vertical coordinate for the origin,
%                         between 0 and 1. 0 corresponds to the bottom edge,
%                         1 to the top edge. (Default: 0.67)
%
%     'xVal'              Length of the horizontal scale bar (in data units).
%                         (Default: 0)
%     'yVal'              Length of the vertical scale bar (in data units).
%                         (Default: 0)
%
%     'xText'             Label for the horizontal scale bar. (Default: "")
%     'yText'             Label for the vertical scale bar. (Default: "")
%
%     'xPush'             Fraction of the x-axis range to offset the y label.
%                         (Default: 0.02)
%     'yPush'             Fraction of the y-axis range to offset the x label.
%                         (Default: 0.02)
%
%     'color'             Color for the scale bar and text. (Default: 'k')
%     'linWidth'          Line width for the scale bar. (Default: 1.5)
%
%     'font'              Font name for the text. (Default: 'arial')
%     'fontSize'          Font size for the text. (Default: 10)
%
%     'lefty'             Logical flag. If true (default), the vertical bar
%                         is drawn on the left (i.e. the horizontal bar extends
%                         rightward from the origin). If false, the horizontal
%                         bar extends leftward.
%     'upsidedown'        Logical flag. If false (default), the vertical bar
%                         extends upward from the origin; if true, it extends downward.
%
% Example:
%   makeTSscaleBar(gca, 'xVal', 10, 'xText', "10 sec", 'yVal', 5, 'yText', "5 mV", ...
%                        'xFrac', 0.8, 'yFrac', 0.2, 'lefty', false, 'upsidedown', true);

    arguments
        pHand (1,1) matlab.graphics.axis.Axes
        kwargs.xFrac (1,1) double {mustBeGreaterThanOrEqual(kwargs.xFrac,0), mustBeLessThanOrEqual(kwargs.xFrac,1)} = 0.67
        kwargs.yFrac (1,1) double {mustBeGreaterThanOrEqual(kwargs.yFrac,0), mustBeLessThanOrEqual(kwargs.yFrac,1)} = 0.67
        kwargs.xVal (1,1) double = 0
        kwargs.yVal (1,1) double = 0
        kwargs.xText (1,:) string = ""
        kwargs.yText (1,:) string = ""
        kwargs.xPush (1,1) double = 0.02
        kwargs.yPush (1,1) double = 0.02
        kwargs.color = 'k'
        kwargs.linWidth (1,1) double = 1.5
        kwargs.font (1,:) char = 'arial'
        kwargs.fontSize (1,1) double = 10
        kwargs.lefty (1,1) logical = true
        kwargs.upsidedown (1,1) logical = false
    end

    % Compute the total axis ranges.
    xRange = diff(pHand.XLim);
    yRange = diff(pHand.YLim);

    % Determine the scale bar corner from normalized coordinates.
    xStart = pHand.XLim(1) + kwargs.xFrac * xRange;
    yStart = pHand.YLim(1) + kwargs.yFrac * yRange;

    % Decide horizontal extension based on 'lefty'
    if kwargs.lefty
        % Origin is on the left side of the horizontal bar: extend to the right.
        xEnd = xStart + kwargs.xVal;
    else
        % Origin is on the right side: extend to the left.
        xEnd = xStart - kwargs.xVal;
    end

    % Decide vertical extension based on 'upsidedown'
    if kwargs.upsidedown
        % Origin is at the top of the vertical bar: extend downward.
        yEnd = yStart - kwargs.yVal;
    else
        % Origin is at the bottom: extend upward.
        yEnd = yStart + kwargs.yVal;
    end

    % Draw the scale bar as one polyline so the two segments share an exact
    % corner even after vector export or rasterization.
    hold(pHand, 'on');
    plot(pHand, [xEnd, xStart, xStart], [yStart, yStart, yEnd], ...
        'Color', kwargs.color, 'LineWidth', kwargs.linWidth);

    % Compute label offsets in data units.
    xOffset = xRange * kwargs.xPush;
    yOffset = yRange * kwargs.yPush;

    % --- Place the horizontal (x) label ---
    % The x label is centered along the horizontal segment.
    xLabelX = (xStart + xEnd) / 2;
    % For vertical placement, choose below the horizontal segment if the vertical bar extends upward,
    % and above it if the vertical bar extends downward.
    if kwargs.upsidedown
        xLabelY = yStart + yOffset;  % Place above.
        verticalAlignmentX = 'bottom';
    else
        xLabelY = yStart - yOffset;  % Place below.
        verticalAlignmentX = 'top';
    end

    % --- Place the vertical (y) label ---
    % The y label is centered along the vertical segment.
    yLabelY = (yStart + yEnd) / 2;
    % For horizontal placement, choose to the left of the vertical segment if the horizontal bar extends rightward,
    % and to the right if it extends leftward.
    if kwargs.lefty
        yLabelX = xStart - xOffset;  % Place to the left.
        horizontalAlignmentY = 'right';
    else
        yLabelX = xStart + xOffset;  % Place to the right.
        horizontalAlignmentY = 'left';
    end

    % Add the text labels.
    text(pHand, xLabelX, xLabelY, kwargs.xText, ...
         'FontName', kwargs.font, 'FontSize', kwargs.fontSize, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', verticalAlignmentX);
    text(pHand, yLabelX, yLabelY, kwargs.yText, ...
         'FontName', kwargs.font, 'FontSize', kwargs.fontSize, ...
         'HorizontalAlignment', horizontalAlignmentY, 'VerticalAlignment', 'middle');
end
