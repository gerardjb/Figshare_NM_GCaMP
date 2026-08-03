function modelSelectionData = suppfigure15_D_E_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate supplementary figure 15 panels D and E from the compact jG8m
% model-selection intermediate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
addpath(fullfile(repoRoot,'Utilities'));

modelSelectionData = AccessFitFiles_Janelia( ...
    fullfile(scriptDir,'janelia_model_selection_data_jG8m.mat'), ...
    fullfile(repoRoot,'output','supp_figure15'), ...
    'jGCaMP8m', ...
    'suppfigure15_D_E_global_best', ...
    [22,6.8]);

end
