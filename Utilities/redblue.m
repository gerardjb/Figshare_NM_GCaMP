function c = redblue(m)
%REDBLUE    Shades of red and blue color map
%   REDBLUE(M), is an M-by-3 matrix that defines a colormap.
%   The colors begin with bright blue, range through shades of
%   blue to white, and then through shades of red to bright red.
%   REDBLUE, by itself, is the same length as the current figure's
%   colormap. If no figure exists, MATLAB creates one.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(redblue)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.
%   Adam Auton, 9th October 2009
if nargin < 1 %When you just want the colormap to override current same step version
    m = size(get(gcf,'colormap'),1);
    cl = get(gca,'clim');%getting the climits
    if (mod(m,2) == 0) && cl(1)<0 && cl(2)>0
        % From [0 0 1] to [1 1 1], then [1 1 1] to [1 0 0];
        bRat = cl(2)/(cl(2)-cl(1));%ratio of red to blue length
        rRat = abs(cl(1))/(cl(2)-cl(1));
        m1 = floor(m*rRat);
        m2 = ceil(m*bRat);
        r = (0:m1-1)'/max(m1-1,1);
        g = r;
        b = fliplr((0:m2-1))'/max(m2-1,1);
        r = [r; ones(m2,1)];
        g = [g; b];
        b = [ones(m1,1); b];
    elseif ~(mod(m,2) == 0) && cl(1)<0 && cl(2)>0
        % From [0 0 1] to [1 1 1] to [1 0 0];
        bRat = cl(2)/(cl(2)-cl(1));%ratio of red to blue length
        rRat = abs(cl(1))/(cl(2)-cl(1));
        m1 = floor(m*rRat);
        m2 = floor(m*bRat)-1;
        r = (0:m1-1)'/max(m1,1);
        g = r;
        b = fliplr((0:m2-1))'/max(m2,1);
        r = [r; ones(m2 + 1,1)];
        g = [g; 1; b];
        b = [ones(m1 + 1,1); b];
    elseif (mod(m,2) == 0)
        % From [0 0 1] to [1 1 1], then [1 1 1] to [1 0 0];
        m1 = m*0.5;
        r = (0:m1-1)'/max(m1-1,1);
        g = r;
        r = [r; ones(m1,1)];
        g = [g; flipud(g)];
        b = flipud(r);
    else
        % From [0 0 1] to [1 1 1] to [1 0 0];
        m1 = floor(m*0.5);
        r = (0:m1-1)'/max(m1,1);
        g = r;
        r = [r; ones(m1+1,1)];
        g = [g; 1; flipud(g)];
        b = flipud(r);
    end

else %if you want to make an arbitrary evenly spaced red-blue map
    if (mod(m,2) == 0)
        % From [0 0 1] to [1 1 1], then [1 1 1] to [1 0 0];
        m1 = m*0.5;
        r = (0:m1-1)'/max(m1-1,1);
        g = r;
        r = [r; ones(m1,1)];
        g = [g; flipud(g)];
        b = flipud(r);
    else
        % From [0 0 1] to [1 1 1] to [1 0 0];
        m1 = floor(m*0.5);
        r = (0:m1-1)'/max(m1,1);
        g = r;
        r = [r; ones(m1+1,1)];
        g = [g; 1; flipud(g)];
        b = flipud(r);
    end
end

c = [r g b]; 