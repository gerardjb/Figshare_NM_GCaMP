function out = greek_char(input)
    % greekChar Converts the name of a Greek letter to its corresponding Unicode character.
    %
    % Input:
    %   input - A character vector or string representing the name of a Greek letter.
    %           Examples: 'Delta', "delta", 'alpha', "Gamma", etc.
    %
    % Output:
    %   out - A single character representing the corresponding Greek letter.
    %
    % Example:
    %   greekChar("Delta")  % Returns 'Δ'
    %   greekChar('alpha')  % Returns 'α'
    
    % Define a map from Greek letter names to their Unicode characters.
    % The map includes both lowercase and uppercase names.
    greekMap = containers.Map(...
        {'alpha', 'Alpha', 'beta', 'Beta', 'gamma', 'Gamma', 'delta', 'Delta', ...
         'epsilon', 'Epsilon', 'zeta', 'Zeta', 'eta', 'Eta', 'theta', 'Theta', ...
         'iota', 'Iota', 'kappa', 'Kappa', 'lambda', 'Lambda', 'mu', 'Mu', ...
         'nu', 'Nu', 'xi', 'Xi', 'omicron', 'Omicron', 'pi', 'Pi', ...
         'rho', 'Rho', 'sigma', 'Sigma', 'tau', 'Tau', 'upsilon', 'Upsilon', ...
         'phi', 'Phi', 'chi', 'Chi', 'psi', 'Psi', 'omega', 'Omega'},...
        {char(0x03B1), char(0x0391), char(0x03B2), char(0x0392), char(0x03B3), char(0x0393), ...
         char(0x03B4), char(0x0394), char(0x03B5), char(0x0395), char(0x03B6), char(0x0396), ...
         char(0x03B7), char(0x0397), char(0x03B8), char(0x0398), char(0x03B9), char(0x0399), ...
         char(0x03BA), char(0x039A), char(0x03BB), char(0x039B), char(0x03BC), char(0x039C), ...
         char(0x03BD), char(0x039D), char(0x03BE), char(0x039E), char(0x03BF), char(0x039F), ...
         char(0x03C0), char(0x03A0), char(0x03C1), char(0x03A1), char(0x03C3), char(0x03A3), ...
         char(0x03C4), char(0x03A4), char(0x03C5), char(0x03A5), char(0x03C6), char(0x03A6), ...
         char(0x03C7), char(0x03A7), char(0x03C8), char(0x03A8), char(0x03C9), char(0x03A9)});
    
    % Convert input to string for uniform processing
    if ischar(input)
        inputStr = string(input);
    elseif isstring(input)
        inputStr = input;
    else
        error('Input must be a character vector (char) or a string.');
    end
    
    % Check if the input name exists in the map
    if greekMap.isKey(inputStr)
        out = greekMap(inputStr);
    else
        error('Unknown Greek letter name: "%s". Please provide a valid Greek letter name.', inputStr);
    end
end
