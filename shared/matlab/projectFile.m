function pathOut = projectFile(varargin)
%PROJECTFILE Return an absolute path below the repository root.

pathOut = fullfile(projectRoot(),varargin{:});
end
