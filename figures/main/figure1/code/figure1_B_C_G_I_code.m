function figure1_B_C_G_I_code
%%%
% Plots of single spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Reconstruct the compact plotting structures from the reviewed CSV streams
% that also feed the source-data workbook.
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');
constructs = ["GCaMP6f","jGCaMP7f","jGCaMP8f"];
prefixes = ["G6f","jG7f","jG8f"];
bFiles = ["06_B_G6f_trials.csv","17_B_jG7f_trials.csv", ...
    "20_B_jG8f_trials.csv"];
cMeanFiles = ["07_C_G6f_mean.csv","18_C_jG7f_mean.csv", ...
    "21_C_jG8f_mean.csv"];
cSemFiles = ["08_C_G6f_SEM_polygon.csv","19_C_jG7f_SEM_polygon.csv", ...
    "22_C_jG8f_SEM_polygon.csv"];
gData = struct([]);
for iConstruct = 1:numel(constructs)
    gData(iConstruct).const = char(constructs(iConstruct));
    trials = readtable(fullfile(d,bFiles(iConstruct)), ...
        'VariableNamingRule','preserve');
    gData(iConstruct).single_traces.trial_time = trials{:,2};
    gData(iConstruct).single_traces.trial_traces = trials{:,3:end};
    avg = readtable(fullfile(d,cMeanFiles(iConstruct)), ...
        'VariableNamingRule','preserve');
    semPoly = readtable(fullfile(d,cSemFiles(iConstruct)), ...
        'VariableNamingRule','preserve');
    gData(iConstruct).single_pop_avg.pop_avg_time = avg{:,2};
    gData(iConstruct).single_pop_avg.pop_avg = avg{:,3};
    gData(iConstruct).single_pop_avg.sem_patch = [semPoly{:,2},semPoly{:,3}];
end

ogbObserved = readtable(fullfile(d,'31_C_OGB5N_observed.csv'), ...
    'VariableNamingRule','preserve');
ogbFit = readtable(fullfile(d,'32_C_OGB5N_fit.csv'), ...
    'VariableNamingRule','preserve');
OGB5N.single_pop_avg.time_trace = ogbObserved{:,2};
OGB5N.single_pop_avg.dff = ogbObserved{:,3};
OGB5N.single_pop_avg.time_fit = ogbFit{:,2};
OGB5N.singl_pop_avg.dff_hat = ogbFit{:,3};

% Paired-pulse demonstrations.
gPrefixes = ["G6f","jG8f"];
gIndices = [1,3];
gBases = [9,23];
for iDemo = 1:2
    idx = gIndices(iDemo);
    base = gBases(iDemo);
    singleStim = readCurve(fullfile(d,sprintf('%02d_G_%s_single_stim.csv',base,gPrefixes(iDemo))));
    ppStim = readCurve(fullfile(d,sprintf('%02d_G_%s_PP_stim.csv',base+1,gPrefixes(iDemo))));
    singleFit = readCurve(fullfile(d,sprintf('%02d_G_%s_single_fit.csv',base+2,gPrefixes(iDemo))));
    ppFit = readCurve(fullfile(d,sprintf('%02d_G_%s_PP_fit.csv',base+3,gPrefixes(iDemo))));
    gData(idx).PPR_demo.time_trace = singleStim(:,1);
    gData(idx).PPR_demo.single_stim = singleStim(:,2);
    gData(idx).PPR_demo.PP_stim = ppStim(:,2);
    gData(idx).PPR_demo.time_fit = singleFit(:,1);
    gData(idx).PPR_demo.single_fit = singleFit(:,2);
    gData(idx).PPR_demo.PP_fit = ppFit(:,2);
end
ogbNames = ["33_G_OGB5N_single_stim.csv","34_G_OGB5N_PP_stim.csv", ...
    "35_G_OGB5N_single_fit.csv","36_G_OGB5N_PP_fit.csv"];
ogbCurves = arrayfun(@(name) {readCurve(fullfile(d,name))},ogbNames);
OGB5N.PPR_demo.time_trace = ogbCurves{1}(:,1);
OGB5N.PPR_demo.single_stim = ogbCurves{1}(:,2);
OGB5N.PPR_demo.PP_stim = ogbCurves{2}(:,2);
OGB5N.PPR_demo.time_fit = ogbCurves{3}(:,1);
OGB5N.PPR_demo.single_fit = ogbCurves{3}(:,2);
OGB5N.PPR_demo.PP_fit = ogbCurves{4}(:,2);

% One- versus ten-spike demonstrations.
iBases = [13,27];
for iDemo = 1:2
    idx = gIndices(iDemo);
    p = gPrefixes(iDemo);
    base = iBases(iDemo);
    unSingle = readCurve(fullfile(d,sprintf('%02d_I_%s_unno_single.csv',base,p)));
    unTen = readCurve(fullfile(d,sprintf('%02d_I_%s_unno_ten_stim.csv',base+1,p)));
    normSingle = readCurve(fullfile(d,sprintf('%02d_I_%s_norm_single.csv',base+2,p)));
    normTen = readCurve(fullfile(d,sprintf('%02d_I_%s_norm_ten_stim.csv',base+3,p)));
    gData(idx).traces1_2_10.demo.time_trace = unSingle(:,1);
    gData(idx).traces1_2_10.demo.time_aligned = normTen(:,1);
    gData(idx).traces1_2_10.demo.unnormalized.single = unSingle(:,2);
    gData(idx).traces1_2_10.demo.unnormalized.ten_stim = unTen(:,2);
    gData(idx).traces1_2_10.demo.normalized.single = normSingle(:,2);
    gData(idx).traces1_2_10.demo.normalized.ten_stim = normTen(:,2);
end

%% Plots for panels B and C
% Panel B
figure("Name","Figure 1 B");
for i = 1:length(gData)
    % Loop for each construct's sample bouton with individual traces
    subplot(3,1,i);hold on
    col = hex2rgb(pickGCaMPcolorsMS(gData(i).const));
    plot(gData(i).single_traces.trial_time,gData(i).single_traces.trial_traces,...
        'Color',[col,0.1],'LineWidth',0.5);
    plot(gData(i).single_traces.trial_time,mean(gData(i).single_traces.trial_traces,2),...
        'Color',col,'LineWidth',1.3)
    set(gca,'ylim',[-0.75,1.75],'xlim',[-50,300])
    plot([0,0],ylim,'k--');
    title(gData(i).const,'Color',col)
end
set(gcf,"units","inches","position",[1,1,1.5,3])

% Panel C
figure("Name","Figure 1 C");hold on;
%Loop for OGB5N first, then GCaMPs
for i=1:4
    if i==1
        % For OGB5N show mean trace with fit
        plot(OGB5N.single_pop_avg.time_trace,...
            OGB5N.single_pop_avg.dff,'Color',[0.7,0.7,0.7]);
        plot(OGB5N.single_pop_avg.time_fit,...
            OGB5N.singl_pop_avg.dff_hat,'Color',[0.5,0.5,0.5]);
        
    else
        % For GCaMPs, show mean trace and sem
        fill(gData(i-1).single_pop_avg.sem_patch(:,2),gData(i-1).single_pop_avg.sem_patch(:,1),...
            hex2rgb(pickGCaMPcolorsMS(gData(i-1).const)),"facealpha",0.2,"EdgeColor","none");
        plot(gData(i-1).single_pop_avg.pop_avg_time,gData(i-1).single_pop_avg.pop_avg ,...
            'Color',pickGCaMPcolorsMS(gData(i-1).const));
        
    end
end

%% Plots for panel G
figure("Name","Figure 1 G");
tiledlayout(2,2)
const_names = ["OGB5N","GCaMP6f","jGCaMP8f"];
const_idx = [nan,1,3];
for i=1:length(gData)
    nexttile;hold on;
    if i==1
        % Note different time base for OGB5N
        plot(OGB5N.PPR_demo.time_trace,OGB5N.PPR_demo.single_stim,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(OGB5N.PPR_demo.time_trace,OGB5N.PPR_demo.PP_stim,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(OGB5N.PPR_demo.time_fit,OGB5N.PPR_demo.single_fit,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(OGB5N.PPR_demo.time_fit,OGB5N.PPR_demo.PP_fit,'Color',pickGCaMPcolorsMS(const_names(i)));
        title(const_names(i),"Color",pickGCaMPcolorsMS(const_names(i)))

    else
        % Plots for the GCaMP variants
        plot(gData(const_idx(i)).PPR_demo.time_trace,gData(const_idx(i)).PPR_demo.single_stim,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(gData(const_idx(i)).PPR_demo.time_trace,gData(const_idx(i)).PPR_demo.PP_stim,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(gData(const_idx(i)).PPR_demo.time_fit,gData(const_idx(i)).PPR_demo.single_fit,'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(gData(const_idx(i)).PPR_demo.time_fit,gData(const_idx(i)).PPR_demo.PP_fit,'Color',pickGCaMPcolorsMS(const_names(i)));
        title(const_names(i),"Color",pickGCaMPcolorsMS(const_names(i)))
    end
end

%% Plots for panel I
figure("Name","Figure 1 I");
tiledlayout(2,2)
const_names = ["GCaMP6f","jGCaMP8f"];
trace_types = ["unnormalized","normalized"];
const_idx = [1,3];
% Loop over GCaMP variants
for i = 1:2
    % And normalization type
    for ii = 1:2
        nexttile;hold on;
        % Whether to align by last spike or not
        if ii==1
            time_a = gData(const_idx(i)).traces1_2_10.demo.time_trace;
        else
            time_a = gData(const_idx(i)).traces1_2_10.demo.time_aligned;
        end
        plot(gData(const_idx(i)).traces1_2_10.demo.time_trace,...
            gData(const_idx(i)).traces1_2_10.demo.(trace_types(ii)).single,...
            'Color',pickGCaMPcolorsMS(const_names(i)));
        plot(time_a,...
            gData(const_idx(i)).traces1_2_10.demo.(trace_types(ii)).ten_stim,...
            'Color',hex2rgb(pickGCaMPcolorsMS(const_names(i)))+0.35);
    end
end

saveFigureOutputs("figure1","figure1_B_C_G_I");
end

function xy = readCurve(path)
t = readtable(path,'VariableNamingRule','preserve');
xy = t{:,2:3};
end
