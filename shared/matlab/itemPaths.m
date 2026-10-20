function paths = itemPaths(scriptPath,publicationId)
%ITEMPATHS Resolve code, input, source-data, and build locations for an item.

if nargin < 1 || isempty(scriptPath)
    scriptPath = mfilename('fullpath');
end
if nargin < 2
    publicationId = "";
end

paths.code = fileparts(char(scriptPath));
paths.item = fileparts(paths.code);
paths.inputs = fullfile(paths.item,'inputs');
paths.source_data = fullfile(paths.item,'source_data');
paths.root = projectRoot(paths.code);
paths.publication_id = string(publicationId);
paths.output = publicationOutputDir(publicationId,false);
end
