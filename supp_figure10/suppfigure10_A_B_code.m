function suppfigure10_A_B_code
%%%
% Plots of model correlations between continuous predictions and ground
% truth convovled with progressivly larger Gaussian filters as in the
% indicated figure
%%%

% Close any open plots
close all

% Collect data files
d = fileparts(mfilename("fullpath"));
ds_pred = ["ForBiophys","ForMLspike","Biophys_CASCADE_exc",...
    "CASCADE_exc","ForENS2"];
meth_names = ["Biophys_{SMC}","MLspike","Biophys_{ML}",...
    "CASCADE","ENS^2"];
prefixes = ["biophysd","MLspiked","Cascaded","Cascaded","ens2d"];
% Sample cell
sample_files = ["jGCaMP8f_ANM471994_cell01.mat","jGCaMP8f_ANM478411_cell04.mat"];
% File for the matched/unmatched table
% Window for display
windows = {[108.6,110.2],[245.2,246.8]};

% Plot init and param stuff
sizer = [8.5,5];
text_x_pad_ratio = 0.15;%pad for bringing text out from figure
gt_wid = 0.4;%Width of ground truth line indicators
% Plot features to share across plots for spike predictions
yfrac_bottom = 4/5;
yfrac_top = 1;
tick_wid = 0.8;
filter_wid = 1;% this is the index of the filtered trace we'll use
class_size = 0.3;
class_edges = [1,1 + class_size,1 + 2*class_size,1 + 3* class_size];
class_types = ["false negatives","false positives","true positives"];
% For prediciton and ground truth plot limits
pred_ylim = [-0.02,class_edges(end)+0.2];
gt_ylim = [-0.02,class_edges(end)-0.2];
% Method and panel naming conventions
method_names = ["Biophys_{SMC}","MLspike","Biophys_{ML}","CASCADE","ENS^2"];
panel_names = ["High SNR example", "Low SNR example"];
% figure particulars
f = figure;%hold on;
set(f,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[1,1,sizer]);
% Initialize the container tiles and spacing
outer_tile = tiledlayout(1,length(windows),"TileSpacing","loose");
height_dff = 1;% relative height of dff trace
height = height_dff+length(method_names)+1;% full tile height

% Get table of pred-gt spike times and subset
load(fullfile(d,"matched_tbl_full.mat"),"T_low");
T = T_low(contains(T_low.cell,strtok(sample_files,'.')),:);%

% Windows placed per horizontal outer tile
for i_win = 1:length(windows)
    % Get sample cell's data
    load(fullfile(d,sample_files(i_win)),'time_stamps','dff','ap_times');
    epoch = 1;% selecting the epoch to show
    % Put into structure in case I need to retriweve it later (won't overwrite)
    data.time_stamps = time_stamps(epoch,:);%
    data.dff = dff(epoch,:);
    data.ap_times = ap_times;%

    % This window and plot spacing
    window = windows{i_win};
    text_x_pad = text_x_pad_ratio*(window(2)-window(1));% adjust text label location

    % Tile stuff for this column of plots
    til = tiledlayout(outer_tile,height,1,'tilespacing','none');
    til.Layout.Tile = i_win;
    
    % First plot DFF with spike times and scale bars
    nexttile(til);hold on;
    good_times = data.time_stamps>window(1) & data.time_stamps<window(2);
    good_aps = data.ap_times>window(1) & data.ap_times<window(2);
    plot(data.time_stamps(good_times),data.dff(good_times),'k','LineWidth',0.8);
    maxY = max(data.dff(good_times))*1.1;
    minY = min(data.dff(good_times));
    set(gca,'ylim',[minY,maxY],'xlim',window);
    arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.ap_times(good_aps));
    ax = gca;
    %Scale bars
    yspan = round((maxY-minY)/3,1);
    yText = [num2str(yspan),' \DeltaF/F'];
    xspan = round((window(2)-window(1))/8,1);
    xText = [num2str(xspan*1000),' ms'];
    makeTSscaleBar(ax,'xFrac',1,'yFrac',1,'yVal',yspan,'yText',yText,...
        'xVal',xspan,'xText',xText,...
        'lefty',0,'upsidedown',1);
    if i_win==1
        text(window(1)-text_x_pad_ratio,maxY*2/3,'Fluorescence',...
            'HorizontalAlignment','left','fontweight','bold','FontSize',10,'FontName','arial');
    end
    ax_bio=gca;ax_bio.YAxis.Visible = 'off';ax_bio.XAxis.Visible = 'off';

    % Loop over methods for prediction traces and spikes
    for i_meth = 1:length(method_names)
        % Load current method
        load(fullfile(d,ds_pred(i_meth),prefixes(i_meth)+"_"+sample_files(i_win)),...
            "smoothed_gt","smoothed_spike_prob","spike_time_estimates","time_stamps");

        % Get this method's color
        this_col = pickGCaMPcolorsMS(method_names(i_meth));
        
        % Get this window time
        good_times = time_stamps(epoch,:)>window(1) & time_stamps(epoch,:)<window(2);
        t = time_stamps(epoch,good_times);

        % Get the predicted true positive and false positive spikes for this window/method
        T_tp = T(T.method==meth_names(i_meth) & ...
                T.classification_outcome=="tp" & ...
                (T.pred_time>window(1) & T.pred_time<window(2)),:).pred_time;
        T_fp = T(T.method==meth_names(i_meth) & ...
                T.classification_outcome=="fp" & ...
                (T.pred_time>window(1) & T.pred_time<window(2)),:).pred_time;
        T_fn = T(T.method==meth_names(i_meth) & ...
                T.classification_outcome=="fn" & ...
                (T.gt_time>window(1) & T.gt_time<window(2)),:).gt_time;
        

        % If first time through add gt_traces
        if i_meth==1
            nexttile(til);hold on;
            % Add gt trace
            gt_trace = smoothed_gt(epoch,good_times,filter_wid);
            plot(t,contrastStretch(gt_trace),'k','linewidth',1.5);
            % Add text , gt spikes, and finish plot
            ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
            % Label first time through
            if i_win==1
                text(window(1)-text_x_pad_ratio,2*(ylims(2)-ylims(1))/3,{'Ground','truth'},...
                    'HorizontalAlignment','left','fontweight','bold',...
                    'FontSize',10,'FontName','arial');
            end
            ax_bio=gca;
            set(gca,'xlim',window,'box','off','ylim',gt_ylim);
            arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.ap_times(good_aps));
            ax=gca;ax.YAxis.Visible = 'off';ax.XAxis.Visible = 'off';

        end
        
        % Add the other methods prediction traces
        nexttile(til);hold on;
        pred_trace = smoothed_spike_prob(epoch,good_times,filter_wid);
        plot(t,contrastStretch(pred_trace),'color',this_col,'linewidth',1.5);
        ylims = get(gca,'ylim');yspan = ylims(2)-ylims(1);
        if i_win==1
            text(window(1)-text_x_pad_ratio,(ylims(2)-ylims(1))/2,method_names(i_meth),...
                'HorizontalAlignment','left','color',this_col,'fontweight','bold',...
                'FontSize',10,'FontName','arial');
        end
        ax=gca;
        set(gca,'xlim',window,'box','off','ylim',pred_ylim);
        arrayfun(@(x) plot([x,x],ylim,'k:','linewidth',gt_wid),data.ap_times(good_aps));
        % Add tp, fp, and fn spikes with dividers
        ylims = ylim;ybottom = yfrac_bottom*(ylims(2)-ylims(1));ytop = yfrac_top*(ylims(2)-ylims(1));
        arrayfun(@(y) plot(xlim,[y,y],'color',this_col,'linestyle','--'),class_edges);
        arrayfun(@(x) plot([x,x],class_edges(3:4),'color',this_col,'linewidth',tick_wid),T_tp);
        arrayfun(@(x) plot([x,x],class_edges(2:3),'color','r','linewidth',tick_wid),T_fp);
        arrayfun(@(x) plot([x,x],class_edges(1:2),'color','k','linewidth',tick_wid),T_fn);
        arrayfun(@(x,y,z) text(ax.XLim(2),mean([x,y]),z,...
            'horizontalalignment','left','verticalalignment','middle',...
            'FontSize',8,'FontName','arial'),...
            class_edges(1:3),class_edges(2:4),class_types);
        ax=gca;ax.YAxis.Visible = 'off';ax.XAxis.Visible = 'off';
        



    end % i_meth
    title(til,panel_names(i_win));

end % i_win
