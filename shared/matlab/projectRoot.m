function root = projectRoot(startPath)
%PROJECTROOT Locate the repository root without relying on the working directory.

if nargin < 1 || isempty(startPath)
    startPath = mfilename('fullpath');
end

candidate = char(startPath);
if isfile(candidate)
    candidate = fileparts(candidate);
end

while true
    if isfile(fullfile(candidate,'pyproject.toml')) && ...
            isfolder(fullfile(candidate,'figures')) && ...
            isfolder(fullfile(candidate,'shared'))
        root = candidate;
        return
    end
    parent = fileparts(candidate);
    if strcmp(parent,candidate)
        error('projectRoot:notFound', ...
            'Could not locate the repository root from %s.',startPath);
    end
    candidate = parent;
end
end
