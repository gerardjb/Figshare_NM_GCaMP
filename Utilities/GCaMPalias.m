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
elseif ismember(alias,{'Biophys_{SMC}','Biophys_SMC'})
    GCaMP = 'biophys_{MC';
elseif ismember(alias,{'Biophys_{ML}','Biophys_ML'})
    GCaMP = 'biophys_{NN';
elseif ismember(alias,{'CASCADE'})
    GCaMP = 'CASCADE__';
else
    GCaMP = alias;
end