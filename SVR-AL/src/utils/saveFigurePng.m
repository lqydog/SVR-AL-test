function saveFigurePng(fig, pngPath, dpi)
%SAVEFIGUREPNG Save a MATLAB figure to a PNG file (headless-safe).
%
% Usage:
%   saveFigurePng(fig, pngPath)
%   saveFigurePng(fig, pngPath, dpi)
%
% Notes:
% - Ensures parent folder exists.
% - Prefers exportgraphics (R2021b+), falls back to saveas.

if nargin < 3 || isempty(dpi)
    dpi = 150;
end

if ~isgraphics(fig, 'figure')
    error("saveFigurePng:InvalidFigure", "Input must be a figure handle.");
end

pngPath = string(pngPath);
if strlength(pngPath) == 0
    error("saveFigurePng:InvalidPath", "pngPath must be non-empty.");
end

parent = fileparts(pngPath);
if strlength(string(parent)) > 0 && ~isfolder(parent)
    mkdir(parent);
end

try
    exportgraphics(fig, pngPath, "Resolution", dpi);
catch
    saveas(fig, pngPath);
end
end

