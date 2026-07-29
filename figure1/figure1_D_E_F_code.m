function figure1_D_E_F_code
%%%
% Plots of single spike responses presented in the indicated figure
%%%

% Close any open plots
close all

% Open data file
load("figure1_D_E_F_data.mat")

% Loop variables
plot_name = ["DFF","SNR","Rise_log"];
panel_name = ["D","E","F"];
const_names = ["GCaMP6f","jGCaMP7f","jGCaMP8f","OGB-5N"];

% 
for i_panel = 1:numel(panel_name)
    % Initialize boxplot variables
    g = [];x = [];

    % Open plot panel
    figure('Name',panel_name(i_panel));hold on;

    % Get currennt structure and contents
    currentStruct = eval(plot_name(i_panel));
    these_consts = fieldnames(currentStruct);

    % Arrange data for boxplots and plot points
    for i_const = 1:length(these_consts)
        these_pts = currentStruct.(these_consts{i_const})(:,2);
        n_pts = length(these_pts);
        x = [x;these_pts];
        g = [g;repmat(const_names(i_const),n_pts,1)];
        plot(i_const+0.2*randn(n_pts,1),these_pts,...
            'LineStyle','none','Marker','o');
    end

    % Add boxplots
    boxplot(x,g,"Positions",1:length(these_consts),"BoxStyle","outline");
    
    % Labels
    ylabel(plot_name(i_panel));
    title("Panel "+panel_name(i_panel))
end

saveFigureOutputs("figure1","figure1_D_E_F");
