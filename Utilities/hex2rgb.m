function rgb = hex2rgb(hex)
    % HEX2RGB Convert hex color string to RGB triplet
    %
    % rgb = hex2rgb(hex) converts a hexadecimal color code to an RGB triplet.
    % 
    % Input:
    %   hex - A string or character vector representing the hex color (e.g., '#FF5733' or 'FF5733')
    %
    % Output:
    %   rgb - A 1x3 vector containing RGB values scaled between 0 and 1

    % Remove the '#' character if present
    if startsWith(hex, '#')
        hex = hex(2:end);
    end
    
    % Validate the hex string length
    if numel(hex) ~= 6
        error('Hex color code must have exactly 6 characters.');
    end
    
    % Convert hex pairs to decimal
    r = sscanf(hex(1:2), '%2x') / 255;
    g = sscanf(hex(3:4), '%2x') / 255;
    b = sscanf(hex(5:6), '%2x') / 255;
    
    % Combine into an RGB triplet
    rgb = [r, g, b];
end
