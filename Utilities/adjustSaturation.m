function outputColor = adjustSaturation(inputColor, saturationFactor)
%%%
% adjustSaturation Adjusts the saturation of a color.
%
% Supports input formats:
%   - Hexadecimal string (e.g., '#FF00FF' or 'FF00FF')
%   - 1x3 RGB vector scaled [0, 255]
%   - 1x3 RGB vector scaled [0, 1]
%
% Syntax:
%   outputColor = adjustSaturation(inputColor, saturationFactor)
%
% Inputs:
%   inputColor      - Color input in one of the supported formats.
%                     Examples:
%                       '#FF00FF', 'FF00FF', [255, 0, 255], [1, 0, 1]
%
%   saturationFactor - Scalar specifying saturation adjustment.
%                      >1  : Increase saturation
%                      =1  : No change
%                      <1  : Decrease saturation
%
% Output:
%   outputColor     - Adjusted color in the same format as inputColor.
%
% Example:
%   % Increase saturation of a hex color
%   newColor = adjustSaturation('#FF00FF', 1.5);
%
%   % Decrease saturation of an 8-bit RGB
%   newColor = adjustSaturation([255, 0, 255], 0.5);
%
%   % Increase saturation of a normalized RGB
%   newColor = adjustSaturation([1, 0, 1], 2);
%%%

%% Input Validation and Conversion
% Handle inputs that are hexidecimal or 8 bit
if ~isnumeric(inputColor)
    hex_pattern = '^#[0-9A-Fa-f]{3,6}$';
    is_hex_color = ~isempty(regexp(inputColor,hex_pattern,'once'));
    if is_hex_color
        inputColor = hex2rgb(inputColor);
    else
        error('Provide either valid rgb triplet or hexidecimal of from #xxxxxx as first input');
    end
else
    is_RGB_triplet = size(inputColor, 2) == 3 && all(inputColor >= 0) && all(inputColor <= 1);
    is_RGB_triplet_unscaled = size(inputColor, 2) == 3 && all(inputColor >= 0) && all(inputColor <= 255);
    if is_RGB_triplet
    elseif is_RGB_triplet_unscaled
        inputColor = inputColor/255;
    else
        error('Provide either valid rgb triplet or hexidecimal of from #xxxxxx as first input');
    end
end

%% Validate saturationFactor
if ~isscalar(saturationFactor) || ~isnumeric(saturationFactor) || saturationFactor < 0
    error('saturationFactor must be a non-negative scalar.');
end

%% Adjust Saturation

% Convert RGB to HSV
hsv = rgb2hsv(inputColor);

% Adjust the Saturation component
hsv(2) = hsv(2) * saturationFactor;

% Clamp the Saturation to [0, 1]
hsv(2) = min(max(hsv(2), 0), 1);

% Convert back to RGB
outputColor = hsv2rgb(hsv);


end