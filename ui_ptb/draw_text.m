function [nx, ny, textbounds] = draw_text(win, text, x, y, color, varargin)
%DRAW_TEXT CJK-safe wrapper around DrawFormattedText.
%   Converts char text to double() so PTB can render CJK characters.
%   Accepts the same positional arguments as DrawFormattedText.

if ischar(text)
    text = double(text);
end

[nx, ny, textbounds] = DrawFormattedText(win, text, x, y, color, varargin{:});
end
