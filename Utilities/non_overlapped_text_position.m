function [spaced_pos,spaced_idx] = non_overlapped_text_position(text_pos_in,min_space)
%%
%Utility to adjust the coordinate spacing, of a vector, esp. for putting
%labels at the ends of lines on a plot.
%
%   Inputs:
%       -text_pos_in - vector of positions
%       -min_space - minimum spacing between values
%
%   Outputs:
%       -spaced_pos - vector of respaced positions
%       -spaced_idx - rank ordering of the positions
%%

%sort the positions
[spaced_pos, spaced_idx] = sort(text_pos_in(:));

%Flip so that we're top to bottom
spaced_pos = flipud(spaced_pos);
spaced_idx = flipud(spaced_idx);

%Make those under-spaced be regularly-spaced
for i = 2:length(text_pos_in)
    if spaced_pos(i-1)-spaced_pos(i)<min_space
        spaced_pos(i) = spaced_pos(i-1) - min_space;
    end
end