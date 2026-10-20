function suppfigure1_E_to_G_code(mode)
%%%
% Plots of saturation vs elongation controls for jGCaMP8f 1-2-10 protocol,
% intended as an addendum below supp figure 1 panels A-D.
%
% This script-style function runs with defaults (no inputs) and generates a
% 2x4 tiled layout showing supra-linear and saturating exemplars plus
% summary scatters, using the linear kernel + biexponential decay workflow.
%%%

% Default publication path consumes fixed published-display CSVs, without refitting.
if nargin < 1 || ~strcmpi(string(mode),"original")
    renderNote1CanonicalCsv("E_G");
    return
end

close all

% Open data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');
load(projectFile('shared','inputs','gDbase.mat'));

% Get data for specific construct (consistent with other supp_figure1 code)
const = 'jG8f';
constIdx = nominal({gData.const})==GCaMPalias(const);

Data = gData(constIdx).traces1_2_10.Data;
ts = gData(constIdx).traces1_2_10.ts;
structType = gData(constIdx).traces1_2_10.structType;

% Generate the panels (defaults: supra exemplar idx=9, saturating idx=5)
qcKernelSaturationElongation(Data,ts,[], ...
    'structType',structType, ...
    'constColor',const, ...
    'addScaleBars',true);

% Match figure export conventions
ff = gcf;
sizer = [8.5,4.2];
set(ff,'Paperunits','inches', ...
    'Papersize',sizer, ...
    'Paperposition',[0,0,sizer], ...
    'Units','inches', ...
    'Position',[4,2,sizer]);

saveFigureOutputs("supp_figure1","suppfigure1_E_to_G",ff);
end
