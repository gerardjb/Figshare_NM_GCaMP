function modelSelectionData = suppfigure14_A_B_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate supplementary figure 14 panels A and B from the compact jG8f
% model-selection intermediate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
addpath(fullfile(repoRoot,'Utilities'));

modelSelectionData = AccessFitFiles_Janelia( ...
    fullfile(scriptDir,'janelia_model_selection_data_jG8f.mat'), ...
    fullfile(repoRoot,'output','supp_figure14'), ...
    'jGCaMP8f', ...
    'suppfigure14_A_B_global_best');

end
