function tinted_rgb = tint_rgb(rgb, tint_factor)
%%%
% Function to apply a multiplicative tint to an input rgb triplet or hex
% code.
%
% Inputs:
%   -rgb - rgb triplet as vector or hexidecimal color code
%   -tint_factor - scalar factor
%
% Outputs:
%   -tinted_rgb - rgb triplet vector
%%%

% Handle inputs that are hexidecimal or 8 bit
if ~isnumeric(rgb)
    hex_pattern = '^#[0-9A-Fa-f]{3,6}$';
    is_hex_color = ~isempty(regexp(rgb,hex_pattern,'once'));
    if is_hex_color
        rgb = hex2rgb(rgb);
    else
        error('Provide either valid rgb triplet or hexidecimal of from #xxxxxx as first input');
    end
else
    is_RGB_triplet = size(rgb, 2) == 3 && all(rgb >= 0) && all(rgb <= 1);
    is_RGB_triplet_unscaled = size(rgb, 2) == 3 && all(rgb >= 0) && all(rgb <= 255);
    if is_RGB_triplet
    elseif is_RGB_triplet_unscaled
        rgb = rgb/255;
    else
        error('Provide either valid rgb triplet or hexidecimal of from #xxxxxx as first input');
    end
end

% Tints an RGB triplet by multiplying each component by the tint factor.
tinted_rgb = rgb * tint_factor;

% Ensure values stay within the [0, 1] range
tinted_rgb = max(0, min(1, tinted_rgb));
end