function modelSelectionData = suppfigure13_A_B_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate supplementary figure 13 panels A and B from the compact jG8f
% model-selection intermediate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
addpath(fullfile(repoRoot,'Utilities'));

modelSelectionData = AccessFitFiles_Janelia( ...
    fullfile(scriptDir,'janelia_model_selection_data_jG8f.mat'), ...
    fullfile(scriptDir,'output'), ...
    'jGCaMP8f', ...
    'suppfigure13_A_B_global_best');

end
