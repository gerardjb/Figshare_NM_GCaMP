function figure4B_C_code
%%%
% Plots of sample continuous and discrete spike predicitons of the tested
% approaches as in the indicated figure
%%%

% Close any open plots
close all

% Collect data file directories
d = fullfile(fileparts(mfilename("fullpath")),'..','source_data');


%-- Data handling --
% Cell types
cell_types = ["exc","inh"];
cell_title = {'Excitatory','Inhibitory'};

%-- Figure setups --
%Flags
add_spikes = true;%For including discrete spike count

%General
sizer = [8.5,5.5];
text_x_pad_ratio = 0.41;%pad for bringing text out from figure
pad_bottom = 0.02;%For plot spacing - otherwise bottom of trace gets clipped
gt_wid = 0.4;%Width of ground truth line indicators

%Plot init (B and C)
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
outer_tile = tiledlayout(1,2,"TileSpacing","compact");
outer_tile.OuterPosition = [0.11,0,0.85,1];
exc_method_axes = gobjects(6,1);

% Loop over cell types for plots
for j = fliplr(1:length(cell_types))
    
    
    cell_type = cell_types(j);

    if cell_type == "exc"
        %For excitatory
        cell = 'jGCaMP8f_ANM478349_cell01';
        sel = 4;% epoch showm
        %Part of the data to plot
        p_window = [89.9,94.5];
        panel_prefix = "Figure4B";
    else
        %For inhibitory
        cell = 'jGCaMP8f_ANM478342_cell04';
        sel = 1;
        %Part of the data to plot
        p_window = [86.5,91.3];%
        panel_prefix = "Figure4C";
    end

    % Load the registered Source Data streams used by the workbook.
    fluorescence = readtable(fullfile(d,panel_prefix + ...
        "_fluorescence_ground_truth.csv"),'TextType','string');
    gt_events = readtable(fullfile(d,panel_prefix + ...
        "_ground_truth_spike_events.csv"),'TextType','string');
    displayed_correlations = readtable(fullfile(d,panel_prefix + ...
        "_displayed_correlations.csv"),'TextType','string');
    data.fluo_time = fluorescence.time_s;
    data.fluo_mean = fluorescence.fluorescence_DeltaF_F;
    data.ground_truth = fluorescence.ground_truth_display_normalized;
    data.events_AP = gt_events.spike_time_s;
    
    %Set up plot
    model_names = {{'Biophys_{SMC}'},{'PGBAR'},{'MLspike'},{'Biophys_{ML}'},...
        {'CASCADE'},{'ENS^2'}};
    sig1 = 0.02;%
    sig2 = sig1;%
    colores = {'#009E73','#4A4A4A','#0072B2','#007755',...
        '#F3AE14','#A6780C'};% can also pull these with pickGCaMP
    
    % text_x_pad = text_x_pad_ratio*(p_window(2)-p_window(1));
    
    h_dff = 2;% set height for the dff plot
    height = h_dff+length(model_names)+1;% bottom blank for spacing
    til = tiledlayout(outer_tile,height,1,'tilespacing','none');
    til.Layout.Tile = j;
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
    makeTSscaleBar(ax,'xFrac',1,'yFrac',1,'yVal',yspan,'yText',yText,...
        'xVal',xspan,'xText',xText,...
        'lefty',0,'upsidedown',1);
    if j==1
        text(p_window(1)-text_x_pad_ratio,maxY*2/3,'Fluorescence',...
            'fontweight','bold');
    end
    
    % Ground-truth curve exactly as exported to the registered Source Data.
    nexttile(til);hold on;
    plot(data.fluo_time(good_times),data.ground_truth(good_times),'k','linewidth',1.5);
    ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
    if j==1
        text(p_window(1)-text_x_pad_ratio,2*(ylims(2)-ylims(1))/3,{'Ground','truth'},...
         'fontweight','bold');
    end
    ax_bio=gca;ax_bio.YAxis.Visible = 'off';ax_bio.XAxis.Visible = 'off';
    set(gca,'xlim',p_window,'box','off','ylim',[ylims(1)-yspan*pad_bottom,ylims(2)*(1+pad_top)]);
    arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.events_AP(good_aps));
    
    %Plot features to share across plots
    %For spike predictions
    yfrac_bottom = 4/5;
    yfrac_top = 1;
    tick_wid = 0.6;
    
    method_keys = ["BiophysSMC","PGBAR","MLspike",...
        "BiophysML","CASCADE","ENS2"];
    for i = 1:length(model_names)
        prediction = readtable(fullfile(d,panel_prefix + "_" + ...
            method_keys(i) + "_prediction.csv"),'TextType','string');
        time = prediction.time_s;
        pred_display = prediction.display_normalized_prediction;
        good_times = time>p_window(1)&time<p_window(2);
        nexttile(til);hold on;
        plot(time(good_times),pred_display(good_times),...
            'color',colores{i},'linewidth',1.5);
        ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
        if j==1
            text(p_window(1)-text_x_pad_ratio,2*(ylims(2)-ylims(1))/3,model_names{i},...
                'color',colores{i},'fontweight','bold');
        end
        ax=gca;ax.YAxis.Visible = 'off';ax.XAxis.Visible = 'off';
        if j==1
            exc_method_axes(i) = ax;
        end
        set(gca,'xlim',p_window,'box','off','ylim',[ylims(1)-yspan*pad_bottom,ylims(2)*1.3]);
        arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.events_AP(good_aps));
        % Add the exact exported event ticks.
        if add_spikes
            if panel_prefix=="Figure4C" && method_keys(i)=="ENS2"
                event_file = fullfile(d, ...
                    "Figure4C_ENS2_displayed_ticks_inherited_from_CASCADE.csv");
            else
                event_file = fullfile(d,panel_prefix + "_" + ...
                    method_keys(i) + "_predicted_spike_events.csv");
            end
            events = readtable(event_file,'TextType','string');
            spike_time_estimates = events.spike_time_s;
            good_spike_ests = spike_time_estimates(spike_time_estimates>=p_window(1) & spike_time_estimates<=p_window(2));
            ylims = ylim;ybottom = yfrac_bottom*(ylims(2)-ylims(1));ytop = yfrac_top*(ylims(2)-ylims(1));
            arrayfun(@(x) plot([x,x],[ybottom,ytop],'color',colores{i},'linewidth',tick_wid),good_spike_ests);
        end
        % Add the correlation value exported with the displayed panel.
        corr_row = displayed_correlations.method==method_keys(i);
        pred_corr = displayed_correlations.full_epoch_prediction_ground_truth_r(corr_row);
        xlims = xlim; x_span = xlims(2)-xlims(1); 
        text(xlims(2) - x_span*0.05,(ylims(2)-ylims(1))/2,...
            ['r = ',num2str(pred_corr(1),'%0.2f')],...
            'color',colores{i},'fontweight','bold');
    end
    title(til,[cell_title{j},' cell sample'])
end%j

drawnow;
group_label_axes = axes(f,'Position',[0,0,1,1],'Visible','off', ...
    'XLim',[0,1],'YLim',[0,1],'HitTest','off','HandleVisibility','off');
add_method_group_bracket(f,group_label_axes,exc_method_axes(1:3),"Unsupervised methods");
add_method_group_bracket(f,group_label_axes,exc_method_axes(4:6),"Supervised methods");

saveFigureOutputs("figure4","figure4_B_C",f);
end

function add_method_group_bracket(fig_handle,label_axes,method_axes,label_text)
% Add a square bracket and rotated group label using finalized axes geometry.
fig_pixels = getpixelposition(fig_handle);
positions = zeros(numel(method_axes),4);
for i_ax = 1:numel(method_axes)
    ax_pixels = getpixelposition(method_axes(i_ax),true);
    positions(i_ax,:) = [ ...
        ax_pixels(1)/fig_pixels(3),ax_pixels(2)/fig_pixels(4), ...
        ax_pixels(3)/fig_pixels(3),ax_pixels(4)/fig_pixels(4)];
end

group_padding = 0.004;
group_bottom = min(positions(:,2)) + group_padding;
group_top = max(positions(:,2)+positions(:,4)) - group_padding;
bracket_x = 0.175;% centered within the reserved left annotation margin
tick_length = 0.012;

annotation(fig_handle,'line',[bracket_x,bracket_x], ...
    [group_bottom,group_top],'Color','k','LineWidth',1.5);
annotation(fig_handle,'line',[bracket_x,bracket_x+tick_length], ...
    [group_top,group_top],'Color','k','LineWidth',1.5);
annotation(fig_handle,'line',[bracket_x,bracket_x+tick_length], ...
    [group_bottom,group_bottom],'Color','k','LineWidth',1.5);
text(label_axes,bracket_x-0.035,mean([group_bottom,group_top]), ...
    cellstr(split(label_text)),'Rotation',90, ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontWeight','normal','FontName','Arial','FontSize',10);
end
