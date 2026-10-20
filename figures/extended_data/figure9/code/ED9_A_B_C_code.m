function h = ED9_A_B_C_code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate Extended Data Figure 9 panels A-C from the packaged quiescent
% binning results.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scriptDir = fileparts(mfilename('fullpath'));
inputDir = fullfile(scriptDir,'..','inputs');
repoRoot = projectRoot(scriptDir);
addpath(scriptDir);
addpath(fullfile(repoRoot,'shared','matlab'));

dataFile = fullfile(inputDir,'decay_v_spikeNum.mat');
if ~isfile(dataFile)
    error('Required data file not found: %s',dataFile);
end

loaded = load(dataFile,'results');
if ~isfield(loaded,'results')
    error('Data file does not contain a results structure: %s',dataFile);
end

h = plot_quiescent_binning_dashboard(loaded.results, ...
    'const','jG8m', ...
    'outputDir',publicationOutputDir('extended_data/figure9',true), ...
    'outputStem','ED9_A_B_C_quiescent_binning_dashboard', ...
    'saveOutput',true);

end
