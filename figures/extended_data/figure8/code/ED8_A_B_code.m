function modelSelectionData = ED8_A_B_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate Extended Data Figure 8 panels A and B from the compact jG8f
% model-selection intermediate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
sourceDir = fullfile(scriptDir,'..','source_data');
plotModelSelectionFromCsv(sourceDir, ...
    'A_stopped_flow_bestfit_curves.csv','B_Janelia_observed.csv', ...
    'B_Janelia_fitted.csv','B_Janelia_ground_truth_spikes.csv', ...
    'jGCaMP8f','extended_data/figure8','ED8_A_B_global_best');
modelSelectionData = struct('source','reviewed source_data CSVs');

end
