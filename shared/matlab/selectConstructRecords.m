function selectedRecords = selectConstructRecords(records,desiredConstructs,callerName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select and order construct records by their explicit `const` names.
%
% This prevents legacy figures from silently changing when new constructs
% are appended to shared struct arrays.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3 || strlength(string(callerName))==0
    callerName = mfilename;
end
callerName = char(string(callerName));

if ~isstruct(records) || ~isfield(records,'const')
    error('selectConstructRecords:invalidInput', ...
        '%s requires a struct array with a const field.',callerName);
end

available = string({records.const});
desired = string(desiredConstructs(:)');
if isempty(desired)
    error('selectConstructRecords:emptySelection', ...
        '%s supplied no desired constructs.',callerName);
end
if numel(unique(desired)) ~= numel(desired)
    error('selectConstructRecords:duplicateRequest', ...
        '%s requested duplicate constructs.',callerName);
end

indices = zeros(size(desired));
for iConstruct = 1:numel(desired)
    matches = find(available==desired(iConstruct));
    if isempty(matches)
        error('selectConstructRecords:missingConstruct', ...
            '%s requires %s, but available constructs are: %s.', ...
            callerName,desired(iConstruct),strjoin(available,', '));
    elseif numel(matches)>1
        error('selectConstructRecords:duplicateConstruct', ...
            '%s found multiple records for %s.',callerName,desired(iConstruct));
    end
    indices(iConstruct) = matches;
end

selectedRecords = records(indices);
end
