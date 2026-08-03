function h = suppfigure15_A_B_C_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate supplementary figure 15 panels A-C from the packaged quiescent
% binning results.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
addpath(scriptDir);
addpath(fullfile(repoRoot,'Utilities'));

dataFile = fullfile(scriptDir,'decay_v_spikeNum.mat');
if ~isfile(dataFile)
    error('Required data file not found: %s',dataFile);
end

loaded = load(dataFile,'results');
if ~isfield(loaded,'results')
    error('Data file does not contain a results structure: %s',dataFile);
end

h = plot_quiescent_binning_dashboard(loaded.results, ...
    'const','jG8m', ...
    'outputDir',fullfile(repoRoot,'output','supp_figure15'), ...
    'outputStem','suppfigure15_A_B_C_quiescent_binning_dashboard', ...
    'saveOutput',true);

end
