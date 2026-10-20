function modelSelectionData = ED9_D_E_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate Extended Data Figure 9 panels D and E from the compact jG8m
% model-selection intermediate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
sourceDir = fullfile(scriptDir,'..','source_data');
plotModelSelectionFromCsv(sourceDir, ...
    'D_stopped_flow_bestfit_curves.csv','E_Janelia_observed.csv', ...
    'E_Janelia_fitted.csv','E_Janelia_ground_truth_spikes.csv', ...
    'jGCaMP8m','extended_data/figure9','ED9_D_E_global_best');
modelSelectionData = struct('source','reviewed source_data CSVs');

end
