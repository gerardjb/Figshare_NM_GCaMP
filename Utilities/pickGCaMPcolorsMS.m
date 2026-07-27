function cmap = pickGCaMPcolorsMS(consts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%pickGCaMPcolors
%Joey Broussard
%12/21/2023
%PNI
%
%Summary: Maps a set of GCaMP varinats from a specified library to a
%particular color. Useful for returning colormaps across analyses for a
%given set of GCaMP variants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Setting the library
GCaMPlib = {'blank',...
    'black',...
    'CASCADE__',...
    'slow',...
    'biophys_{MC',...
    'fast',...
    'MLspike',...
    'jGCaMP7f',...
    'jGCaMP8f',...
    'GCaMP6f',...
    'ENS',...
    'biophys_{NN',...
    'CASCADE_{jG8f}',...
    'jGCaMP8m',...
    'PGBAR'};

%Convert nominal to cell

if ~iscell(consts)||~ischar(consts)%If names passed in as nominal, change to str
    consts = cellstr(consts);
end
nConst = length(consts);
%Handle aliases
for iConst = 1:nConst
    consts{iConst} = GCaMPalias(consts{iConst});
    % Map the current manuscript display labels to the historical keys used
    % by this color library.
    if any(strcmpi(consts{iConst},{'Biophys_{SMC}','Biophys_SMC'}))
        consts{iConst} = 'biophys_{MC';
    elseif any(strcmpi(consts{iConst},{'Biophys_{ML}','Biophys_ML'}))
        consts{iConst} = 'biophys_{NN';
    elseif strcmpi(consts{iConst},'CASCADE')
        consts{iConst} = 'CASCADE__';
    end
end
%% Make the mapping
%If on list, pass back the corresponding color
fullMap = {'#808080',...neutral gray
    '#000000',...k
    '#F3AE14',...(CASCADE) light orange
    '#56B4E9',...(current slow fluorescence), light blue
    '#009E73',...(current model fluorescence), dark green
    '#C1BB6E',...(current fast pathway), dark yellow
    '#0072B2',...(MLspike)
    '#CC5F09',...(jGCaMP7f pressentations), dark orange
    '#9E0142',...(jGCaMP8f presentations), dark red
    '#0F1C79',...(GCaMP6f presentations)
    '#A6780C',...%(ENS^2)
    '#007755',...%(biophys_NN)
    '#FFCC29',...%(Cascade trained with 8f),...
    '#53338B',...% first try for 8m
    '#4A4A4A'};% PGBAR

lib_idx = arrayfun(@(x) contains(consts,x,'IgnoreCase',true),GCaMPlib);
if any(lib_idx)
    cmap = fullMap{lib_idx};
else %Make anything passed in that isn't on the list be gray
    cmap = fullMap{1};
end

