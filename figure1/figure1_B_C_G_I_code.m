function figure1_B_C_G_I_code
%%%
% Plots of single spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,"figure1_C_G_data.mat"),"OGB5N");
load(fullfile(d,"..","Shared_data","gDbase.mat"),"gData");

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