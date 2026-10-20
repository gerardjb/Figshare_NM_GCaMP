function figure2_K_L_code
%%%
% Plots of elongation and its comparison ot accessible slowing as shown in
% the refernced figure
%%%

% Close any open plots
close all

% Collect data files
d = fileparts(mfilename("fullpath"));
fname = fullfile(d,'10pulseData.mat');
fname2 = fullfile(d,'decay.mat');
fname3 = fullfile(d,'kineticContribution2.mat');

%% Elongation plot
load(fname);
consts = {'G6f','jG7f','jG8f'};
all = {[G6f,G6f(:,2)./G6f(:,1)],...
    [jG7f,jG7f(:,2)./jG7f(:,1)],...
    [jG8f,jG8f(:,2)./jG8f(:,1)]};

%All elongations together in one plot
colores = zeros(3,3);
for i = 1:3;colores(i,:) = hex2rgb(pickGCaMPcolorsMS(consts{i}));end
elongs = nancat(2,G6f(:,2)./G6f(:,1),jG7f(:,2)./jG7f(:,1),jG8f(:,2)./jG8f(:,1));
f =figure;
sizerRaw = [1.6,2.2];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

boxplot(elongs);
h = gca;
fixBoxplotAttributes(h,3,[0.66,0.66,0.66],0,1,'none')
for i = 1:size(elongs,2)
    dotPlot_xtr(elongs(:,i),i,0.05,0.05,colores(i,:));
end
set(gca,'xticklabel',{'G6f','jG7f','jG8f'},...
    'ylim',[0,5.5]);
xtickangle(45);
ylabel({'fold slowing','(1 to 10 pulse)'})
box off
set(gca,'tickdir','out','linewidth',1,'fontsize',10);

% One-way ANOVA with Tukey-Kramer post hoc tests for panel K.
elong_vals = elongs(:);
elong_groups = repelem(1:size(elongs,2),size(elongs,1))';
good_idx = ~isnan(elong_vals);
[p_anova,anova_tbl,anova_stats] = anova1(elong_vals(good_idx),elong_groups(good_idx),'off');
posthoc_tbl = multcompare(anova_stats,'Display','off','CType','tukey-kramer');
group_labels = {'G6f','jG7f','jG8f'};

yl = ylim;
text(0.03,0.97,sprintf('ANOVA p = %.3g',p_anova),...
    'Units','normalized','HorizontalAlignment','left',...
    'VerticalAlignment','top','FontName','arial','FontSize',8);

sig_rows = find(posthoc_tbl(:,6) < 0.05);
if ~isempty(sig_rows)
    ylim([yl(1),yl(2) + diff(yl)*0.25]);
    yl = ylim;
    y_base = yl(2) - diff(yl)*0.18;
    y_step = diff(yl)*0.08;
    for i_sig = 1:length(sig_rows)
        this_row = posthoc_tbl(sig_rows(i_sig),:);
        x1 = this_row(1);
        x2 = this_row(2);
        y = y_base + (i_sig-1)*y_step;
        plot([x1,x1,x2,x2],[y-0.08,y,y,y-0.08],'k-','LineWidth',1);
        text(mean([x1,x2]),y,p_to_sig_label(this_row(6)),...
            'HorizontalAlignment','center','VerticalAlignment','bottom',...
            'FontName','arial','FontSize',9);
    end
end

fprintf('Panel 2K one-way ANOVA on fold slowing\n');
fprintf('  p = %.4g\n',p_anova);
fprintf('  group means = [%s]\n',num2str(mean(elongs,1,'omitnan'),'%.4f '));
disp('  ANOVA table:');
disp(anova_tbl);
posthoc_out = table( ...
    string(group_labels(posthoc_tbl(:,1)))', ...
    string(group_labels(posthoc_tbl(:,2)))', ...
    posthoc_tbl(:,4), ...
    posthoc_tbl(:,3), ...
    posthoc_tbl(:,5), ...
    posthoc_tbl(:,6), ...
    'VariableNames',{'Group1','Group2','MeanDiff','LowerCI','UpperCI','PValue'});
disp('  Tukey-Kramer post hoc comparisons:');
disp(posthoc_out);

%% Elongation vs. accessible slowing
% Load other files
load(fname2)
load(fname3)

% Accessible slowing across the selected calcium conditions. Missing
% fitted components are omitted, not treated as zero contributions.
goodCa = ca>200 & ca<2000;
a_slow_values = cellfun(@(x,y) y(2,goodCa)./y(1,goodCa).*(1-x(goodCa)),...
    all_proportions1(2:end),all_taus(2:end),'UniformOutput',false);
a_slow_values = cellfun(@(x) x(isfinite(x)),a_slow_values,'UniformOutput',false);
elong_values = arrayfun(@(i) elongs(isfinite(elongs(:,i)),i),...
    1:size(elongs,2),'UniformOutput',false);
assert(~any(cellfun(@numel,a_slow_values)==0) && ~any(cellfun(@numel,elong_values)==0),...
    'Panel L requires finite values for every indicator.');

% OGB5N is the fixed reference (0,1), with no empirical interval.
a_slow = [0,cellfun(@median,a_slow_values)];
a_slow_q1 = [0,cellfun(@(x) prctile(x,25),a_slow_values)];
a_slow_q3 = [0,cellfun(@(x) prctile(x,75),a_slow_values)];
elongs_med = [1,cellfun(@median,elong_values)];
elong_q1 = [1,cellfun(@(x) prctile(x,25),elong_values)];
elong_q3 = [1,cellfun(@(x) prctile(x,75),elong_values)];

% Descriptive, unweighted regression of the four displayed indicator
% summaries, including the fixed OGB5N reference. IQRs describe spread
% across calcium conditions / boutons, not sampling variances of medians.
mdl = fitlm(a_slow(:),elongs_med(:));

% Figure setup
f = figure;hold on;set(gca,'tickdir','out');
sizerRaw = [2.8,2.4];
ticklengths = [0.04,0.02];
set(f,'Paperunits','inches',...
    'Papersize',sizerRaw,...
    'Paperposition',[0,0,sizerRaw],...
    'Units','inches',...
    'Position',[2,2,sizerRaw]);

% Arrange variables for plot
consts = {'OGB5N','G6f','jG7f','jG8f'};
elongs = [ones(size(elongs,1),1),elongs];
colores = [hex2rgb(pickGCaMPcolorsMS(consts{1}));...
    colores];

% Median markers and true Q1-Q3 endpoints (potentially asymmetric).
xends = [0,7];
nexttile;hold on
coef_ci = coefCI(mdl);
yfit = predict(mdl,xends');
plot(xends,yfit,'k--')
for i = 1:length(consts)
    plot([a_slow_q1(i),a_slow_q3(i)],[elongs_med(i),elongs_med(i)],...
        'color',colores(i,:),'LineWidth',1);
    plot([a_slow(i),a_slow(i)],[elong_q1(i),elong_q3(i)],...
        'color',colores(i,:),'LineWidth',1);
end
% Draw markers last so that the intervals do not obscure their centres.
for i = 1:length(consts)
    scatter(a_slow(i),elongs_med(i),25,colores(i,:),'filled',...
        'Clipping','off');
end
ylabel({'fold slowing','(1 to 10 pulse)'})
xlabel({'Accessible slowing','(\tau_{slow}/\tau_{fast} \times proportion_{slow})'})
set(gca,'XLim',xends,'YLim',[0,4.2],'XTick',[0,2,4,6,7],...
    'tickdir','out','ticklength',ticklengths,'LineWidth',1,...
    'FontName','arial','fontsize',10,'XTickLabelRotation',0);

fitStats = mdl.ModelFitVsNullModel;
stats_text = {sprintf('R^2 = %.3f',mdl.Rsquared.Ordinary),...
    sprintf('p = %.3g',fitStats.Pvalue),...
    sprintf('Slope 95%% CI [%.3f, %.3f]',coef_ci(2,1),coef_ci(2,2))};
text(0.97,0.03,stats_text,...
    'Units','normalized','HorizontalAlignment','right',...
    'VerticalAlignment','bottom','FontName','arial','FontSize',8);

fprintf('Panel 2L unweighted linear regression: fold slowing ~ accessible slowing\n');
fprintf('  Four indicator summaries, including the fixed OGB5N reference.\n');
fprintf('  n = %d indicator summaries\n',mdl.NumObservations);
fprintf('  slope = %.4f (95%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(2),coef_ci(2,1),coef_ci(2,2));
fprintf('  intercept = %.4f (95%% CI [%.4f, %.4f])\n',...
    mdl.Coefficients.Estimate(1),coef_ci(1,1),coef_ci(1,2));
fprintf('  R^2 = %.4f, adjusted R^2 = %.4f\n',...
    mdl.Rsquared.Ordinary,mdl.Rsquared.Adjusted);
fprintf('  model p = %.4g\n',fitStats.Pvalue);
panel_l_summary = table(string(consts(:)),a_slow(:),a_slow_q1(:),a_slow_q3(:),...
    elongs_med(:),elong_q1(:),elong_q3(:),[0;cellfun(@numel,a_slow_values(:))],...
    [0;cellfun(@numel,elong_values(:))],...
    'VariableNames',{'Indicator','XMedian','XQ1','XQ3','YMedian','YQ1','YQ3',...
    'NCalciumConditions','NBoutons'});
disp('  Panel L medians and quartile endpoints (reference counts are zero):');
disp(panel_l_summary);
saveFigureOutputs("figure2","figure2_K_L");
end

function out = p_to_sig_label(p)
if p < 0.001
    out = '***';
elseif p < 0.01
    out = '**';
elseif p < 0.05
    out = '*';
else
    out = 'ns';
end
end
