function out = contrastStretch(in,range_in,range_out)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Joey Broussard
%PNI
%10/1/2019
%
% This function takes an input of arbitrary dimension and stretches the
% values to lie along a new range.
%
% Inputs:
%   in - value to be cast into a new range
%   range_in - duplex specifying the low and high limit of the original
%       range. Default = [min,max]
%   range_out - duplex specifying the low and high limit of the new range
%       Default = [0,1]
% Outputs:
%   out - value after casting into new range
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Handle input cases
if nargin == 1
    range_in = [min(in),max(in)];
    range_out = [0,1];
elseif nargin == 2
    range_out = [0,1];
end

%Contrast stretching the input
out = (in - range_in(1))*...%(input-low_out)*...
    (range_out(2) - range_out(1))/(range_in(2) - range_in(1)) +...
    range_out(1);