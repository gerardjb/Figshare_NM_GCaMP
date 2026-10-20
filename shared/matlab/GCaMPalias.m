function GCaMP = GCaMPalias(alias)
%Converts a GCaMP variant alias to its full standard name
if ismember(alias,{'G6f'})
    GCaMP = 'GCaMP6f';
elseif ismember(alias,{'G6s'})
    GCaMP = 'GCaMP6s';
elseif ismember(alias,{'jG7f'})
    GCaMP = 'jGCaMP7f';
elseif ismember(alias,{'jG7s'})
    GCaMP = 'jGCaMP7s';
elseif ismember(alias,{'jG8f','j2851'})
    GCaMP = 'jGCaMP8f';
elseif ismember(alias,{'jG8m','j2874'})
    GCaMP = 'jGCaMP8m';
elseif ismember(alias,{'jG8s','j2859'})
    GCaMP = 'jGCaMP8s';
elseif ismember(alias,{'OGB1','OGB'})
    GCaMP = 'OGB1';
else
    % If already a canonical name (or an unknown label), pass through unchanged.
    GCaMP = alias;
end
