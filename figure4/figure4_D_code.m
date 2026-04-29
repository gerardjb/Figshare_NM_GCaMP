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
load(fullfile(d,"correlation_tbl_jG8f.mat"),"tbl")

% Panel D compares raw, non-downsampled inference for both cell classes.
tbl_panel = tbl(tbl.smoothing=="raw" & (tbl.cell_type=="exc" | tbl.cell_type=="inh"),:);

% Save the panel D mixed-effects statistics used for downstream reporting.
panelDStats = build_panel_D_stats(tbl_panel);
save(fullfile(d,"figure4_D_lme_stats.mat"),"panelDStats","-v7.3")

%% Summary plots
%Ordering of table entries
uniCell_types = unique(tbl_panel.cell_type);
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
    
    tiledlayout(2,1,"TileSpacing","compact");
    
    for i_cell = 1:length(uniCell_types)
        nexttile;hold on;
        method_names = strings(0);
        text_loc_y = [];

        for i_mod = 1:length(uniMethod{i_fig})
            this_method = uniMethod{i_fig}(i_mod);
            method_str = string(this_method);
            test = tbl_panel.Correlation(tbl_panel.Width==0.01 &...
                tbl_panel.Method==this_method & ...
                tbl_panel.cell_type==uniCell_types(i_cell));
            if isempty(test)
                continue;
            end
            %Getting mean and sem for each model
            this_means = arrayfun(@(x) mean(tbl_panel.Correlation(tbl_panel.Width==x &...
                tbl_panel.Method==this_method & ...
                tbl_panel.cell_type==uniCell_types(i_cell))),uniBins);
            
            this_sems = arrayfun(@(x) sem(tbl_panel.Correlation(tbl_panel.Width==x &...
                tbl_panel.Method==this_method & ...
                tbl_panel.cell_type==uniCell_types(i_cell))),uniBins);
            
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
        for i_text = 1:length(method_names)
            this_str = method_names(re_spaced_idx(i_text));
            this_str = regexprep(this_str, '_(\w+)', '_{$1}');
            text(uniBins(end)*1000+2,re_spaced(i_text),this_str,...
                'VerticalAlignment', 'middle','fontweight','bold', ...
                'Color',pickGCaMPcolorsMS(method_names(re_spaced_idx(i_text))),...
                'FontName','Arial');
        end%i_text
    end

end

end

function panelDStats = build_panel_D_stats(tbl_panel)
panelDStats = struct();
panelDStats.source_file = "correlation_tbl_jG8f.mat";
panelDStats.generated_by = mfilename;
panelDStats.generated_on = string(datetime("now"));
panelDStats.response_variable = "Z";
panelDStats.response_transform = "Fisher Z transform of correlation";
panelDStats.formula = "Z ~ Method*Width + (1|SubjectID)";
panelDStats.dummy_var_coding = "reference";
panelDStats.df_method = "Satterthwaite";
panelDStats.reference_methods = ["Biophys_SMC","Biophys_ML"];
panelDStats.comparison_methods = ["CASCADE","ENS^2","MLspike"];
panelDStats.smoothing = "raw";
panelDStats.cell_types = unique(tbl_panel.cell_type);
panelDStats.methods = unique(tbl_panel.Method);
panelDStats.bin_widths = sort(unique(tbl_panel.Width));
panelDStats.n_rows = height(tbl_panel);
panelDStats.n_subjects = numel(unique(string(tbl_panel.Cell)+"_"+string(tbl_panel.Epoch)));
panelDStats.summary = summarize_panel_D_table(tbl_panel);

cell_stats = cell(numel(panelDStats.cell_types),1);
for i_cell = 1:numel(panelDStats.cell_types)
    cell_type = panelDStats.cell_types(i_cell);
    T = tbl_panel(tbl_panel.cell_type==cell_type,:);
    T.SubjectID = categorical(string(T.Cell)+"_"+string(T.Epoch));
    T.Method = categorical(T.Method);
    T.Width = categorical(T.Width);
    T.Z = atanh(T.Correlation);

    this_stats = struct();
    this_stats.cell_type = cell_type;
    this_stats.n_rows = height(T);
    this_stats.n_subjects = numel(categories(T.SubjectID));
    this_stats.methods = categories(T.Method);
    this_stats.width_levels = categories(T.Width);
    this_stats.lme_by_reference = {};

    for i_ref = 1:numel(panelDStats.reference_methods)
        ref_method = panelDStats.reference_methods(i_ref);
        if ~ismember(ref_method,categories(T.Method))
            continue;
        end

        T_ref = T;
        current_order = string(categories(T_ref.Method));
        new_order = [ref_method; current_order(current_order~=ref_method)];
        T_ref.Method = reordercats(T_ref.Method,cellstr(new_order));

        lme = fitlme(T_ref,panelDStats.formula,"DummyVarCoding",panelDStats.dummy_var_coding);
        [beta,~,beta_stats] = fixedEffects(lme);

        ref_stats = struct();
        ref_stats.reference_method = ref_method;
        ref_stats.lme = lme;
        ref_stats.coefficient_names = string(lme.CoefficientNames);
        ref_stats.fixed_effect_estimates = beta;
        ref_stats.fixed_effect_stats = beta_stats;
        ref_stats.coefficients = lme.Coefficients;
        ref_stats.model_criteria = lme.ModelCriterion;
        ref_stats.log_likelihood = lme.LogLikelihood;
        ref_stats.residual_df = lme.DFE;
        ref_stats.mse = lme.MSE;
        ref_stats.residual_sd = sqrt(lme.MSE);
        ref_stats.anova = anova(lme,"DFMethod",panelDStats.df_method);
        ref_stats.random_effects = randomEffects(lme);
        ref_stats.covariance_parameters = covarianceParameters(lme);
        ref_stats.comparison_tests = build_reference_tests(lme,ref_method,panelDStats.comparison_methods);

        this_stats.lme_by_reference{end+1} = ref_stats;
    end

    cell_stats{i_cell} = this_stats;
end

panelDStats.by_cell_type = cell_stats;
end

function summary_tbl = summarize_panel_D_table(tbl_panel)
G = groupsummary(tbl_panel,["cell_type","Method","Width"],["mean","std"],"Correlation");
group_labels = findgroups(tbl_panel(:,["cell_type","Method","Width"]));
group_n = splitapply(@numel,tbl_panel.Correlation,group_labels);
subject_ids = string(tbl_panel.Cell)+"_"+string(tbl_panel.Epoch);
group_subjects = splitapply(@(x) numel(unique(x)),subject_ids,group_labels);
G.N = group_n;
G.NSubjects = group_subjects;
G.SEMCorrelation = G.std_Correlation ./ sqrt(G.N);
summary_tbl = G;
end

function comparison_tests = build_reference_tests(lme,ref_method,comparison_methods)
coef_names = string(lme.CoefficientNames);
comparison_tests = repmat(struct(),numel(comparison_methods),1);
width_levels = get_width_levels_from_coefficients(coef_names);

for i_cmp = 1:numel(comparison_methods)
    cmp_method = comparison_methods(i_cmp);
    comparison_tests(i_cmp).reference_method = ref_method;
    comparison_tests(i_cmp).comparison_method = cmp_method;

    main_term = "Method_" + cmp_method;
    interaction_term = "Method_" + cmp_method + ":Width_";

    L_main = double(coef_names == main_term);
    L_interaction = double(startsWith(coef_names,interaction_term));
    L_any = double((coef_names == main_term) | startsWith(coef_names,interaction_term));

    comparison_tests(i_cmp).main_effect = run_coef_test(lme,L_main);
    comparison_tests(i_cmp).interaction = run_coef_test(lme,L_interaction);
    comparison_tests(i_cmp).overall_method_difference = run_coef_test(lme,L_any);
    comparison_tests(i_cmp).average_across_widths = ...
        build_average_across_widths_summary(lme,cmp_method,width_levels);
end
end

function across_width_summary = build_average_across_widths_summary(lme,cmp_method,width_levels)
coef_names = string(lme.CoefficientNames);
beta = lme.Coefficients.Estimate;
predicted_differences = nan(numel(width_levels),1);

for i_width = 1:numel(width_levels)
    width_label = width_levels(i_width);
    predicted_differences(i_width) = ...
        get_method_difference_at_width(coef_names,beta,cmp_method,width_label);
end

H_average = build_average_width_contrast(coef_names,cmp_method,numel(width_levels));
[p,F,df1,df2] = coefTest(lme,H_average);
contrast_estimate = H_average * beta;
residual_sd = sqrt(lme.MSE);
mean_difference = mean(predicted_differences,"omitnan");

across_width_summary = struct();
across_width_summary.width_labels = width_levels;
across_width_summary.predicted_difference_by_width = predicted_differences;
across_width_summary.mean_predicted_difference = mean_difference;
across_width_summary.mean_absolute_predicted_difference = mean(abs(predicted_differences),"omitnan");
across_width_summary.contrast_weights = H_average;
across_width_summary.contrast_estimate = contrast_estimate;
across_width_summary.p = p;
across_width_summary.F = F;
across_width_summary.df1 = df1;
across_width_summary.df2 = df2;
across_width_summary.residual_sd = residual_sd;
across_width_summary.effect_size = contrast_estimate / residual_sd;
across_width_summary.effect_size_type = "model-based standardized mean difference across widths";
across_width_summary.effect_size_direction = "Positive values indicate larger Fisher-Z correlation than the reference method.";
end

function diff_at_width = get_method_difference_at_width(coef_names,beta,cmp_method,width_label)
main_term = "Method_" + cmp_method;
diff_at_width = 0;

main_idx = find(coef_names == main_term,1);
if ~isempty(main_idx)
    diff_at_width = diff_at_width + beta(main_idx);
end

if width_label == "0.01"
    return;
end

interaction_term = "Method_" + cmp_method + ":Width_" + width_label;
interaction_idx = find(coef_names == interaction_term,1);
if ~isempty(interaction_idx)
    diff_at_width = diff_at_width + beta(interaction_idx);
end
end

function width_levels = get_width_levels_from_coefficients(coef_names)
width_levels = "0.01";
width_tokens = extractAfter(coef_names(startsWith(coef_names,"Width_")),"Width_");
if ~isempty(width_tokens)
    width_levels = [width_levels; width_tokens(:)];
end
width_levels = unique(width_levels,"stable");
end

function H_average = build_average_width_contrast(coef_names,cmp_method,n_widths)
main_term = "Method_" + cmp_method;
interaction_term = "Method_" + cmp_method + ":Width_";
H_average = zeros(1,numel(coef_names));
H_average(coef_names == main_term) = 1;
H_average(startsWith(coef_names,interaction_term)) = 1 / n_widths;
end

function test_stats = run_coef_test(lme,L)
test_stats = struct("n_terms",nnz(L),"coefficient_mask",logical(L));
if nnz(L)==0
    test_stats.p = NaN;
    test_stats.F = NaN;
    test_stats.df1 = NaN;
    test_stats.df2 = NaN;
    return;
end

[p,F,df1,df2] = coefTest(lme,reshape(L,1,[]));
test_stats.p = p;
test_stats.F = F;
test_stats.df1 = df1;
test_stats.df2 = df2;
end

