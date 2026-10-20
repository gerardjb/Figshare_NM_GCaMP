function suppfigure9_A_code(mode)
% MODE="csv" (default) renders exact saved display values; "original" reruns extraction.
if nargin < 1, mode = "csv"; end
mode = lower(string(mode));
if mode == "csv"
    renderSavedCsv();
elseif mode == "original"
    renderOriginal();
else
    error('suppfigure9_A_code:Mode','Use csv or original mode.');
end
end

function renderOriginal()
%%%
% Plots comparing correlations of CASCADE trained on the jGCaMP8f dataset
% or original Global_exc dataset compared to ground truth as in the
% indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fullfile(fileparts(mfilename("fullpath")),'..','inputs');

%-- Data handling --
% Cell types
cell_title = {'Excitatory'};

%-- Figure setups --
%Flags
add_spikes = true;%For including discrete spike count

%General
sizer = [4,4];
text_x_pad_ratio = 0.15;%pad for bringing text out from figure
pad_bottom = 0.02;%For plot spacing - otherwise bottom of trace gets clipped
gt_wid = 0.4;%Width of ground truth line indicators

%Plot init (A)
if add_spikes
    pad_top = 0.3;%For giving enough head room to put spike predictions
else
    pad_top = 0.1;
end
f = figure;%hold on;
set(f,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[1,1,sizer]);
outer_tile = tiledlayout(1,1,"TileSpacing","compact");


%For excitatory
cell = 'jGCaMP8f_ANM478349_cell01';
sel = 4;% epoch showm
%Part of the data to plot
p_window = [89.9,94.5];
model_files = {fullfile(d,['ForBiophys\biophysd_',cell]),...
    fullfile(d,'CASCADE_exc',['Cascaded_',cell]),...
    fullfile(d,'CASCADE_jGCaMP8f_exc',['Cascaded_',cell]),...
    };


%Get this cell's data
file = fullfile(d,[cell,'.mat']);
load(file,'time_stamps','dff','ap_times')

%Get data
data.start_time = time_stamps(sel,1);
data.fluo_time = time_stamps(sel,:) - data.start_time;
data.fluo_mean = dff(sel,:);
data.events_AP = ap_times - data.start_time;

%Set up plot
model_names = {{'Biophys_{SMC}'},{'CASCADE'},{'CASCADE_{jG8f}'}};
sig1 = 0.02;%
sig2 = sig1;%
colores = {'#009E73','#F3AE14','#FFCC29'};% can also pull these with pickGCaMP

h_dff = 2;% set height for the dff plot
height = h_dff+length(model_names)+1;% bottom blank for spacing
til = tiledlayout(outer_tile,height,1,'tilespacing','none');
til.Layout.Tile = 1;
nexttile(til);
hold on;

%Add the fluorescence data
good_times = data.fluo_time>p_window(1)&data.fluo_time<p_window(2);
good_aps = data.events_AP>p_window(1)&data.events_AP<p_window(2);
plot(data.fluo_time(good_times),data.fluo_mean(good_times),'k','LineWidth',0.8);
maxY = max(data.fluo_mean(good_times))*1.1;
minY = min(data.fluo_mean(good_times));
set(gca,'ylim',[minY,maxY],'xlim',p_window,'box','off');
arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.events_AP(good_aps));
ax=gca;ax.YAxis.Visible = 'off';ax.XAxis.Visible = 'off';
ax.Clipping = 'off';

%Scale bars
yspan = round((maxY-minY)/3,1);
yText = [num2str(yspan),' \DeltaF/F'];
xspan = round((p_window(2)-p_window(1))/8,1);
xText = [num2str(xspan),' s'];
makeTSscaleBar(ax,'xFrac',7/8,'yFrac',2/3,'yVal',yspan,'yText',yText,...
    'xVal',xspan,'xText',xText,...
    'lefty',0,'upsidedown',1);
text(p_window(1)-text_x_pad_ratio,maxY*2/3,'Fluorescence',...
    'fontweight','bold');

%And with the binned spike counts
cts = histc(data.events_AP,data.fluo_time);

%Now apply a few gaussian filters of specified width to the binned cts
dt = mean(diff(data.fluo_time));
filtered2 = gaussfilt(data.fluo_time(:),cts(:),sig2);
nexttile(til);hold on;
plot(data.fluo_time(good_times),contrastStretch(filtered2(good_times)),'k','linewidth',1.5);
ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
text(p_window(1)-text_x_pad_ratio,2*(ylims(2)-ylims(1))/3,{'Ground','truth'},...
 'fontweight','bold');

ax_bio=gca;ax_bio.YAxis.Visible = 'off';ax_bio.XAxis.Visible = 'off';
set(gca,'xlim',p_window,'box','off','ylim',[ylims(1)-yspan*pad_bottom,ylims(2)*(1+pad_top)]);
arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.events_AP(good_aps));

%Plot features to share across plots
%For spike predictions
yfrac_bottom = 4/5;
yfrac_top = 1;
tick_wid = 0.6;
%Handle SMC outputs separately
load(model_files{1});
%t_start = data.fluo_time(t_ends{sel}(1));
time = time_stamps(sel,:) - data.start_time;%inferences{sel}.time + t_start;
good_times = time>p_window(1)&time<p_window(2);
filt_time = data.fluo_time>=time(1) & data.fluo_time<=time(end);
%Get times where biophys inference available
filtered1 = gaussfilt(data.fluo_time(filt_time),cts(filt_time),sig2);


%Now nexttile;hold on;open the corresponding Cascade fits, plot, and do correlations
for i = 2:length(model_names)
    load(model_files{i});
    time = time_stamps(sel,:) - time_stamps(sel,1);
    if length(time)~=length(data.fluo_time)
        spike_prob = interp1(time,spike_prob',data.fluo_time)';
        time = data.fluo_time;
        %filtered1 = interp1(data.fluo_time(:),filtered1,time);
    end
    time = time(filt_time);
    %good_times = time>p_window(1)&time<p_window(2);
    nexttile(til);hold on;
    spike_prob = spike_prob(sel,filt_time);
    spike_prob(isnan(spike_prob))=0;
    pred_filt = gaussfilt(time,spike_prob,sig1);
    plot(time(good_times),contrastStretch(pred_filt(good_times)),'color',colores{i},'linewidth',1.5);
    ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
    text(p_window(1)-text_x_pad_ratio,2*(ylims(2)-ylims(1))/3,model_names{i},...
        'color',colores{i},'fontweight','bold');
    ax=gca;ax.YAxis.Visible = 'off';ax.XAxis.Visible = 'off';
    set(gca,'xlim',p_window,'box','off','ylim',[ylims(1)-yspan*pad_bottom,ylims(2)*1.3]);
    arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.events_AP(good_aps));
    %add predicted spikes
    if add_spikes
        spike_time_estimates = spike_time_estimates - data.start_time;
        good_spike_ests = spike_time_estimates(spike_time_estimates>=p_window(1) & spike_time_estimates<=p_window(2));
        ylims = ylim;ybottom = yfrac_bottom*(ylims(2)-ylims(1));ytop = yfrac_top*(ylims(2)-ylims(1));
        arrayfun(@(x) plot([x,x],[ybottom,ytop],'color',colores{i},'linewidth',tick_wid),good_spike_ests);
    end
    %Add correlation to gt
    pred_corr = corrcoef(pred_filt,filtered1,'rows','complete');
    text(p_window(2),(ylims(2)-ylims(1))/2,['r = ',num2str(pred_corr(1,2),'%0.2f')],...
        'color',colores{i},'fontweight','bold');
end
title(til,[cell_title{1},' cell sample'])

saveFigureOutputs("supp_figure9","suppfigure9_A");

end


function renderSavedCsv()
close all
sourceDataDir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'source_data');
T = readtable(fullfile(sourceDataDir,'SF3_A_saved_displayed_traces.csv'),'TextType','string');
E = readtable(fullfile(sourceDataDir,'SF3_A_saved_event_ticks.csv'),'TextType','string');
roles = ["fluorescence","ground_truth","CASCADE_Global_exc","CASCADE_jGCaMP8f"];
colors = {'k','k','#F3AE14','#FFCC29'};
labels = {'Fluorescence',{'Ground','truth'},'CASCADE','CASCADE_{jG8f}'};
limits = [-0.00315121328,1.60383177; -0.02,1.3; -0.02,1.3; -0.02,1.3];
p_window = [89.9,94.5];
f = figure;
set(f,'PaperUnits','inches','PaperSize',[4,4],'PaperPosition',[0,0,4,4], ...
    'Units','inches','Position',[1,1,4,4]);
outer_tile = tiledlayout(1,1,'TileSpacing','compact');
til = tiledlayout(outer_tile,6,1,'TileSpacing','none'); til.Layout.Tile=1;
gt = E(E.event_kind=="ground_truth",:);
for i=1:4
    ax = nexttile(til); hold(ax,'on');
    q = T(T.trace_role==roles(i),:);
    width=1.5; if i==1, width=0.8; end
    plot(ax,q.time_s,q.displayed_value,'Color',colors{i},'LineWidth',width);
    set(ax,'XLim',p_window,'YLim',limits(i,:),'Box','off');
    for j=1:height(gt)
        plot(ax,[gt.event_time_s(j),gt.event_time_s(j)],limits(i,:), ...
            'k:','LineWidth',0.4);
    end
    ax.YAxis.Visible='off'; ax.XAxis.Visible='off';
    ax.Clipping='off';
    if i==1
        % Reference figure and native time scale both specify a 0.6 s horizontal bar.
        makeTSscaleBar(ax,'xFrac',7/8,'yFrac',2/3,'yVal',0.5, ...
            'yText','0.5 \DeltaF/F','xVal',0.6,'xText','0.6 s', ...
            'lefty',0,'upsidedown',1);
        yLabel=limits(i,2)*2/3;
    else
        yLabel=2/3; % Exact saved text coordinate before axis padding.
    end
    text(ax,p_window(1)-0.15,yLabel,labels{i},'Color',colors{i},'FontWeight','bold');
    if i>=3
        ticks = E(E.trace_role==roles(i) & E.event_kind=="predicted",:);
        for j=1:height(ticks)
            plot(ax,[ticks.event_time_s(j),ticks.event_time_s(j)], ...
                [ticks.display_tick_bottom(j),ticks.display_tick_top(j)], ...
                'Color',colors{i},'LineWidth',0.6);
        end
        rLabels=["r = 0.87","r = 0.84"];
        text(ax,p_window(2),diff(limits(i,:))/2,rLabels(i-2), ...
            'Color',colors{i},'FontWeight','bold');
    end
end
title(til,'Excitatory cell sample');
saveFigureOutputs("supp_figure9","suppfigure9_A",f);
end
