function suppfigure10_C_to_F_code
%%%
% Plots of model correlations between continuous predictions and ground
% truth convovled with progressivly larger Gaussian filters as in the
% indicated figure
%%%

% Close any open plots
close all

% Collect data files
d = fileparts(mfilename("fullpath"));
unmatched_file = 'pred_and_gt_spk_tbl.mat';
matched_file = 'matched_tbl_full.mat';
janelia_summary_file = '8fCellTableSummary.csv';

% Load tables
janelia_tbl = readtable(fullfile(d,janelia_summary_file));
load(fullfile(d,unmatched_file),"spike_pred_tbl");
matched_data = load(fullfile(d,matched_file),"tbl");
T_low = matched_data.tbl(matched_data.tbl.cost==0.01,:);
T_high = matched_data.tbl(matched_data.tbl.cost==0.1,:);

% Map source method labels to the manuscript naming convention.
source_method_names = ["Biophys_CASCADE_exc","CASCADE_exc","ForBiophys",...
    "ForENS2","ForMLspike","pgbar"];
display_method_names = ["Biophys_{ML}","CASCADE","Biophys_{SMC}",...
    "ENS^2","MLspike","PGBAR"];
spike_pred_tbl.method = replace(string(spike_pred_tbl.method),...
    source_method_names,display_method_names);
T_low.method = replace(string(T_low.method),...
    source_method_names,display_method_names);
T_high.method = replace(string(T_high.method),...
    source_method_names,display_method_names);

% Prep the tables for updated method names, etc.
% Janelia
janelia_tbl.CellNumber = janelia_tbl.CellNumber+1;% matlab indexing
janelia_tbl.cell = strcat("_",janelia_tbl.Sensor,"_ANM",num2str(janelia_tbl.SubjectID),"_cell0",num2str(janelia_tbl.CellNumber));% cell naming
% unmatched table
T_unmatched = spike_pred_tbl;

%% Set tables for epoch, bias, and uncertainty values
% unmatched
T_unmatched.cell_epoch = strcat(T_unmatched.cell,"_",num2str(T_unmatched.trial));
T_unmatched.bias = T_unmatched.time_to_nearest_gt;
T_unmatched.uncertainty = abs(T_unmatched.bias);

% matched
T_high.cell_epoch = strcat(T_high.cell,"_",num2str(T_high.trial));
T_high.bias = T_high.pred_time-T_high.gt_time;
T_high.uncertainty = abs(T_high.bias);


%% Break the matched_diffs down for F1-score metrics
% Prep table
T_low.cell_epoch = strcat(T_low.cell,"_",num2str(T_low.trial));
T_low_g = unstack(groupsummary(T_low,["method","cell_epoch","classification_outcome"]),...do grouping stats
    "GroupCount","classification_outcome");% and unstack for easeier comparison
T_low_g(:,["fn","fp","tp"]) = fillmissing(T_low_g(:,["fn","fp","tp"]),'constant',0);% handle nan
% Get f1-scores
T_low_g.recall = T_low_g.tp./(T_low_g.tp + T_low_g.fn);
T_low_g.precision = T_low_g.tp./(T_low_g.tp + T_low_g.fp);
T_low_g.accuracy = T_low_g.tp./(T_low_g.tp + T_low_g.fp + T_low_g.fn);
T_low_g.f1 = harmmean([T_low_g.precision,T_low_g.recall],2);

%% Prepping plots 
% Compare SNR and f-score metrics
% prep table
T_low_g.BaseID = regexprep(T_low_g.cell_epoch, {'_ \d+$','_\d+$'}, '');% for matching to janelia table
[found, loc] = ismember(T_low_g.BaseID, janelia_tbl.cell);sum(found)
T_low_g.medianSNR = janelia_tbl.MedianActionPotentialSignal_to_noiseRatio(loc);

% Loop over methods for plotting effects of SNR on discrete predictions
uni_meth = ["Biophys_{SMC}","PGBAR","MLspike",...
    "Biophys_{ML}","CASCADE","ENS^2"];%unique(T_low_g.method);
method_colors = ["#009E73","#4A4A4A","#0072B2",...
    "#007755","#F3AE14","#A6780C"];
metrics = ["precision","recall","f1"];
f = figure;
sizer = [8.5,5];
set(f,'Paperunits','inches',...
    'Papersize',sizer,...
    'Paperposition',[0,0,sizer],...
    'Units','inches',...
    'Position',[1,1,sizer]);
outter_tile1 = tiledlayout(4,1,"TileSpacing","loose");% for rows
xlabel(outter_tile1,'Normalized signal-to-noise')
col_tile1 = tiledlayout(outter_tile1,1,length(uni_meth),"TileSpacing","compact");% For columns

for i_meth = 1:length(uni_meth)
    % Prep for this row of spike analyses
    col_tile1.Layout.Tile = 1;
    ylabel(col_tile1,{'Imputed spike','statistics'});
    nexttile(col_tile1);

    % Mask methods data and make donut plots
    mask=T_low_g.method==uni_meth(i_meth);
    tps = sum(T_low_g.tp(mask));
    fps = sum(T_low_g.fp(mask));
    fns = sum(T_low_g.fn(mask));
    disp(strcat(uni_meth(i_meth)," ",num2str(tps+fps)));
    do = donutchart(categorical(T_low.classification_outcome(T_low.method==uni_meth(i_meth))),...
        "Labels",["fn","fp","tp"]);
    title(do,{'','',''});
    
    %donut has no proper title properties, so placed manually as text
    c_ax = gca;
    if i_meth == 1
        tile_1_height = c_ax.Position(4);
        tile_1_bottom = c_ax.Position(2);
    else
        this_tile_height = c_ax.Position(4);
    end

    tile_position = [c_ax.Position(1),tile_1_bottom,c_ax.Position(3),tile_1_height];
    
    axOverlay = axes('Position', tile_position, ...
        'Visible', 'off', ...
        'Color', 'none');
    text(axOverlay, 0.5, 1.95, {uni_meth(i_meth), [num2str(tps+fps),'(tp+fp)/'], [num2str(5817),'(gt)']}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ... 
        'Color', hex2rgb(char(method_colors(i_meth))), ...
        'FontWeight', 'bold', ...
        'FontSize', 10);
end

for i_metric = 1:length(metrics)
    % Prep this row of tiles
    col_tile2 = tiledlayout(outter_tile1,1,length(uni_meth));% For columns
    col_tile2.Layout.Tile = i_metric+1;
    ylabel(col_tile2,metrics(i_metric));

    for i_meth = 1:length(uni_meth)
        % Mask method's data and do regression
        mask=T_low_g.method==uni_meth(i_meth);
        mdl_x = T_low_g.medianSNR(mask)/max(T_low_g.medianSNR(mask));
        x_range = [min(mdl_x),max(mdl_x)];
        mdl_y = T_low_g.(metrics(i_metric))(mask);
        mdl = fitlm(mdl_x,mdl_y);

        % Calculate KDE and prep for the marginal plot
        [f_meth,x_meth] = ksdensity(T_low_g.(metrics(i_metric))(mask));
        f_patch = [f_meth./max(f_meth),zeros(size(f_meth))];
        x_patch = [x_meth,flipud(x_meth)];

        % Get boxplot data
        q1 = quantile(mdl_y,0.25);
        q2 = quantile(mdl_y,0.5);
        q3 = quantile(mdl_y,0.75);
        lower_whisker = max(min(mdl_y),q1 - 1.5*(q3 - q1));
        upper_whisker = min(max(mdl_y),q3 + 1.5*(q3 - q1));
        
        % Tile stuff for this column of plots
        til = tiledlayout(col_tile2,1,3,'tilespacing','none');
        til.Layout.Tile = i_meth;
        
        % insert scatter/regression to left 2 tiles
        nexttile(til,[1,2]);hold on;
        scatter(mdl_x,mdl_y,...
            5,hex2rgb(char(method_colors(i_meth))));
        plot(x_range,...
            mdl.Coefficients.Estimate(1)+mdl.Coefficients.Estimate(2)*x_range,...
            'k','LineWidth',1);
        text_str = {['R^2 = ',num2str(mdl.Rsquared.Ordinary,2)],...
            ['p = ',num2str(mdl.Coefficients.pValue(2),2)]};
        text(1,0,text_str,'FontSize',8,'FontName','arial',...
            'HorizontalAlignment','right','VerticalAlignment','bottom');
        set(gca,'ylim',[0,1],'xlim',[0,1],'TickDir','out','LineWidth',1);
        box off;

        % insert raincloud-like plot to last 1
        nexttile(til,[1,1]);hold on;
        patch(f_patch,x_patch,hex2rgb(char(method_colors(i_meth))));
        % and add the boxplot
        wid = -0.2;bot = -0.1;mid = bot + wid/2;top = bot + wid;
        box_x = [bot,top,top,bot];box_y = [q1,q1,q3,q3];
        patch(box_x,box_y,hex2rgb(char(method_colors(i_meth))),'EdgeColor','k');
        plot([mid,mid],[lower_whisker,q1],'k','LineWidth',1);
        plot([mid,mid],[q3,upper_whisker],'k','LineWidth',1);
        plot([bot,top],[q2,q2],'w','LineWidth',1.3);
        set(gca,'ylim',[0,1],'xlim',[top-0.3,1]);
        axis off;
    
    end % i_meth

end % i_metric
