function suppfigure9_B_code
%%%
% Plots of correlations as a function of filter width for CASCADE trained
% by jGCaMO8f data or Global_exc as in the indicated figure.
%%%

% Close any open plots
close all

% Collect data file directories
d = fileparts(mfilename("fullpath"));
load(fullfile(d,"..","figure4","correlation_tbl_jG8f.mat"),"tbl")

% Updated excitatory analyses use the jGCaMP8f table. Panel B uses raw,
% non-downsampled inference only.
tbl_panel = tbl(tbl.cell_type=="exc" & tbl.smoothing=="raw",:);

%% Summary plots
%Ordering of table entries
uniMethod = unique(tbl_panel.Method);
uniBins = unique(tbl_panel.Width);
% This was to handle tables that contain the jG8f datasets
uniMethod = {uniMethod};

for i_fig = 1:length(uniMethod)
    %Prep plots
    sizer = [3.5,4];
    f = figure;hold on;
    set(f,'Paperunits','inches',...
        'Papersize',sizer,...
        'Paperposition',[0,0,sizer],...
        'Units','inches',...
        'Position',[1,1,sizer]);
    hands = [];
    
    tiledlayout(1,1,"TileSpacing","compact");
    
    nexttile;hold on;
    method_names = strings(0);
    text_loc_y = [];

    for i_mod = 1:length(uniMethod{i_fig})
        this_method = uniMethod{i_fig}(i_mod);
        method_str = string(this_method);
        test = tbl_panel.Correlation(tbl_panel.Width==0.01 &...
            tbl_panel.Method==this_method);
        if isempty(test)
            continue;
        end
        %Getting mean and sem for each model
        this_means = arrayfun(@(x) mean(tbl_panel.Correlation(tbl_panel.Width==x &...
            tbl_panel.Method==this_method)), uniBins);
        
        this_sems = arrayfun(@(x) sem(tbl_panel.Correlation(tbl_panel.Width==x &...
            tbl_panel.Method==this_method)), uniBins);
        
        %Make the plot for this model
        shadedErrorBar(uniBins*1000,this_means,this_sems,...
            {'color',pickGCaMPcolorsMS(method_str),...
            'markerfacecolor',pickGCaMPcolorsMS(method_str),...
            'linewidth',1.5},1);
        %Make an off-screen plot that holds the patch version of the color for
        %each model
        h = patch([i_mod+199,i_mod+200,i_mod+200,i_mod+199],[0.6,0.6,1,1],'k','facecolor',pickGCaMPcolorsMS(method_str),'edgecolor',pickGCaMPcolorsMS(method_str));
        hands = [hands,h];
        method_names = [method_names,method_str];
        text_loc_y = [text_loc_y,this_means(end)];
    end
    ylabel({'Excitatory cells', 'Pearson correlation'})
    xlabel('Filter Width (ms)')
    set(gca,'xlim',[5,105],'xtick',0:20:100,'ylim',[gca().YLim(1),1],...
        'TickDir','out','LineWidth',1);
    grid on;

    
    grid on
    %Add on text label of each method
    [re_spaced,re_spaced_idx] = non_overlapped_text_position(...
        text_loc_y,diff(gca().YLim)*0.14);
    for i_text = 1:length(method_names)
        this_str = method_names(re_spaced_idx(i_text));
        this_str = regexprep(this_str, '_(\w+)', '_{$1}');
        text(uniBins(end)*1000+2,re_spaced(i_text),this_str,...
            'VerticalAlignment', 'middle','fontweight','bold', ...
            'Color',pickGCaMPcolorsMS(method_names(re_spaced_idx(i_text))),...
            'FontName','Arial');
    end%i_text
    

end

saveFigureOutputs("supp_figure9","suppfigure9_B");
