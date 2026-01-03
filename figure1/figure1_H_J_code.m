function figure1_H_J_code
%%%
% Plots of paired spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Open data file
load("figure1_H_J_data.mat")

% Loop variables
plot_name = ["PPR","spike_1_10"];
panel_name = ["H","J"];
const_namesH = ["OGB-5N","GCaMP6f","jGCaMP7f","jGCaMP8f"];
const_structH = ["OGB5N","G6f","jG7f","jG8f"];
spike_intervals = {["10","100"],["10","20","50","100"]};

%% Panel H plots
for i_constH = 1:numel(const_namesH)
    % Initialize boxplot variables
    g = [];x = [];

    % Open plot panel
    figure('Name',panel_name(1));hold on;

    % Arrange data for boxplots and plot points
    % Only two points for OGB5N data
    if i_constH ==1; this_s_int = spike_intervals{1};else;this_s_int = spike_intervals{2};end

    % Looping over 
    for i_int = 1:length(this_s_int)
        
        these_pts = PPR.(const_structH(i_constH))(:,i_int);
        n_pts = length(these_pts);
        x = [x;these_pts];
        g = [g;repmat(this_s_int(i_int),n_pts,1)];
        plot(i_int+0.2*randn(n_pts,1),these_pts,...
            'LineStyle','none','Marker','o');
    end

    % Add boxplots
    boxplot(x,g,"Positions",1:length(this_s_int),"BoxStyle","outline");
    
    % Labels
    ylabel(plot_name(1));
    title("Panel "+panel_name(1)+" "+const_namesH(i_constH))
end

%% Panel J plots
% Loop variables
offset_x = [-0.1,0,0.1];
consts = ["G6f","jG7f","jG8f"];

% Figure formatting
figure;hold on;
sizer = [3.6,5.5];
set(gcf,'Units','centimeters','paperunits','centimeters',...
    'papersize',sizer,'paperposition',[0,0,sizer],...
    'Position',[4,4,sizer]);


% Panel J plots
for i_const = 1:length(consts)
    % plot individual strip plots
    arrayfun(@(i) ...
        plot(i+offset_x(i_const),spike_1_10.(consts(i_const))(:,i),...
        'color',pickGCaMPcolorsMS(consts(i_const)),'marker','.'),...
        1:2);

    % Add error bar plot
    errorbar((1:2)+offset_x(i_const),...
        mean(spike_1_10.(consts(i_const)),1),sem(spike_1_10.(consts(i_const)),1),...
        'Color',pickGCaMPcolorsMS(consts(i_const)),'CapSize',0,'LineWidth',1);

end
% Finalizing
title("Panel I")
set(gca,'tickdir','out','ticklength',[0.05,0.03],...
    'ylim',[0,230],'ytick',[0,100,200],...
    'xtick',[1,2],'xlim',[0.8,2.2],'xticklabels',["1 pulse","10 pulse"],...
    'linewidth',1,'XTickLabelRotation',60,'fontsize',10,'FontName','arial')
