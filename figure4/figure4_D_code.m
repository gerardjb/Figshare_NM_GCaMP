function figure4_D_code
%%%
% Plots of model correlations between continuous predictions and ground
% truth convovled with progressivly larger Gaussian filters as in the
% indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,"correlation_analysis_tbl.mat"),"tbl_out")

%% Summary plots
%Ordering of table entries
uniCell_types = unique(tbl_out.("Cell type"));
uniModel = unique(tbl_out.Model);
uniBins = unique(tbl_out.("Bin width"));
% This was to handle tables that contain the jG8f datasets
uniModel = {uniModel};

for i_fig = 1:length(uniModel)
    %Prep plots
    sizer = [3.5,4];
    f = figure;hold on;
    set(f,'Paperunits','inches',...
        'Papersize',sizer,...
        'Paperposition',[0,0,sizer],...
        'Units','inches',...
        'Position',[1,1,sizer]);
    hands = [];
    
    tiledlayout(2,1,"TileSpacing","compact");
    
    for i_cell = 1:length(uniCell_types)
        nexttile;hold on;
        model_names = [];
        text_loc_y = [];

        for i_mod = 1:length(uniModel{i_fig})
            test = tbl_out.("Correlation")(tbl_out.("Bin width")==0.01 &...
                tbl_out.Model==uniModel{i_fig}(i_mod) & ...
                tbl_out.("Cell type")==uniCell_types(i_cell));
            if isempty(test)
                continue;
            end
            %Getting mean and sem for each model
            this_means = arrayfun(@(x) mean(tbl_out.("Correlation")(tbl_out.("Bin width")==x &...
                tbl_out.Model==uniModel{i_fig}(i_mod) & ...
                tbl_out.("Cell type")==uniCell_types(i_cell))),uniBins);
            
            this_sems = arrayfun(@(x) sem(tbl_out.("Correlation")(tbl_out.("Bin width")==x &...
                tbl_out.Model==uniModel{i_fig}(i_mod) & ...
                tbl_out.("Cell type")==uniCell_types(i_cell))),uniBins);
            
            %Make the plot for this model
            shadedErrorBar(uniBins*1000,this_means,this_sems,...
                {'color',pickGCaMPcolorsMS(uniModel{i_fig}(i_mod)),...
                'markerfacecolor',pickGCaMPcolorsMS(uniModel{i_fig}(i_mod)),...
                'linewidth',1.5},1);
            %Make an off-screen plot that holds the patch version of the color for
            %each model
            h = patch([i_mod+199,i_mod+200,i_mod+200,i_mod+199],[0.6,0.6,1,1],'k','facecolor',pickGCaMPcolorsMS(uniModel{i_fig}(i_mod)),'edgecolor',pickGCaMPcolorsMS(uniModel{i_fig}(i_mod)));
            hands = [hands,h];
            model_names = [model_names,uniModel{i_fig}(i_mod)];
            text_loc_y = [text_loc_y,this_means(end)];
        end
        if uniCell_types(i_cell) == "exc"
            %h = legend(hands,model_names,'location','southeast');h.Box = 'off';
            %title(h,'Method');
            ylabel({'Excitatory cells', 'Pearson correlation'})
            xlabel('Filter Width (ms)')
            set(gca,'xlim',[5,105],'xtick',0:20:100,'ylim',[gca().YLim(1),1],...
                'TickDir','out','LineWidth',1);
            grid on;
        else
            ylabel({'Inhibitory cells', 'Pearson correlation'})
            xlabel('Filter Width (ms)')
            set(gca,'xlim',[5,105],'xtick',0:20:100,'ylim',[gca().YLim(1),1],...
                'TickDir','out','LineWidth',1);
        end
        
        grid on
        %Add on text label of each method
        [re_spaced,re_spaced_idx] = non_overlapped_text_position(...
            text_loc_y,diff(gca().YLim)*0.14);
        for i_text = 1:length(model_names)
            this_str = model_names(re_spaced_idx(i_text));
            this_str = regexprep(this_str, '_(\w+)', '_{$1}');
            text(uniBins(end)*1000+2,re_spaced(i_text),this_str,...
                'VerticalAlignment', 'middle','fontweight','bold', ...
                'Color',pickGCaMPcolorsMS(model_names(re_spaced_idx(i_text))),...
                'FontName','Arial');
        end%i_text
    end

end

