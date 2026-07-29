function figure2_J_code
%%%
% Plots of the biexponential nature of GCaMP stopped flow response as
% presented in the indicated figure
%%%

% Close any open plots
close all

% Open data files
d = fileparts(mfilename("fullpath"));
load(fullfile(d,'..','Shared_data','stoppedFlowTraces.mat'),'processedTraces')
processedTraces = processedTraces{1};% get rise traces

%% Sample G6f and 8f traces for demonstration of biexponential analysis
% Functions for separating kinetic contributors
exp_fit1 = @(fitted,time) fitted.ss*fitted.frac1*(1-(exp(-(time-fitted.t_off)/fitted.tau1)));
exp_fit2 = @(fitted,time) fitted.ss*(1-fitted.frac1)*(1-(exp(-(time-fitted.t_off)/fitted.tau2)))+fitted.ss*fitted.frac1;

% Loop over sample traces to plot
sample_const = [2,4];% indices of 6f and 8f
sample_trace = [5,5];% chosen sample traces for each indicator
allTrace = {1:9,1:9,1:9,1:9};% vestigial

for i = 1:length(sample_const)

    % Process sample trace
    const = processedTraces(sample_const(i)).const;
    this_fit = processedTraces(sample_const(i)).fits{sample_trace(i)};
    this_gof = processedTraces(sample_const(i)).gofs{sample_trace(i)};
    f = processedTraces(sample_const(i)).traces(:,allTrace{sample_const(i)}(sample_trace(i)));
    thisSS = mean(f(end-50:end));
    f_s = contrastStretch(f,[0,thisSS],[0,1]);
    t = processedTraces(sample_const(i)).time(:,allTrace{sample_const(i)}(sample_trace(i)));
    fHat_s = contrastStretch(this_fit(t),...
        [0,this_fit(t(end))],[0,1]);%
    exp1 = exp_fit1(this_fit,t);
    exp1_s = contrastStretch(exp1,...
        [0,this_fit(t(end))],[0,1]);%
    exp2 = exp_fit2(this_fit,t);
    exp2_s = contrastStretch(exp2,...
        [0,this_fit(t(end))],[0,1]);%
    
    %Finding points to fit and plot
    crit = 0.95;
    crit_exp = 0.99;
    idxStart = find(t>0.003,1);
    idxCrit = find(smooth(f_s,25)>crit,1);
    idxCrit_exp1 = find(exp1_s/this_fit.frac1>crit_exp,1);
    xlim2s = [10,1000,500,500];

    % plot
    % formatting
    fTrace_sample = figure;hold on;
    sizerTrace_sample = [1.4,3];
    set(fTrace_sample,'Paperunits','inches',...
        'Papersize',sizerTrace_sample,...
        'Paperposition',[0,0,sizerTrace_sample],...
        'Units','inches',...
        'Position',[2,2,sizerTrace_sample]);
    ticklengths = [0.003,0.03];
    
    % plot
    plot(t(idxStart:5:idxCrit)*1000,1-f_s(idxStart:5:idxCrit),...
        'color',pickGCaMPcolorsMS(const));
    plot(t(1:5:idxCrit)*1000,1-exp1_s(1:5:idxCrit),...
        'color',[0.1,0.1,0.1,0.9],'linewidth',2);
    text(t(idxCrit_exp1)*1000,this_fit.frac1/2,{['\tau_{fast} = ',num2str(this_fit.tau1*1000,'%0.0f'), ' ms'],...
        ['proportion = ',num2str(this_fit.frac1,2)]},...
        'HorizontalAlignment','left');
    plot(t(1:5:idxCrit)*1000,1-exp2_s(1:5:idxCrit),...
        'color',[0.8,0.8,0.8,0.9],'linewidth',2);
    text(t(round(idxCrit_exp1))*1000,this_fit.frac1/5,['\tau_{slow} = ',num2str(this_fit.tau2*1000,'%0.0f'), ' ms'],...
         'color',[0.8,0.8,0.8,0.9],...
        'HorizontalAlignment','left');

    if iscell(this_gof) && numel(this_gof) >= 2
        gof_text = {sprintf('mono adj. R^2 = %.3f',this_gof{1}.adjrsquare),...
            sprintf('bi adj. R^2 = %.3f',this_gof{2}.adjrsquare)};
        text(0.97,0.03,gof_text,...
            'Units','normalized','HorizontalAlignment','right',...
            'VerticalAlignment','bottom','FontName','arial','FontSize',8);

        fprintf('Panel 2J sample fit for %s trace %d\n',const,sample_trace(i));
        fprintf('  chosen model = %s\n',class(this_fit));
        fprintf('  monoexp: adj R^2 = %.4f, RMSE = %.4g\n',...
            this_gof{1}.adjrsquare,this_gof{1}.rmse);
        fprintf('  biexp:   adj R^2 = %.4f, RMSE = %.4g\n',...
            this_gof{2}.adjrsquare,this_gof{2}.rmse);
        fprintf('  delta adj R^2 = %.4f\n',...
            this_gof{2}.adjrsquare - this_gof{1}.adjrsquare);
    end

    %fomatting axis
    set(gca,'yscale','log','tickdir','out','linewidth',1);
    set(gca,'ylim',[1-(crit+0.02),1],'xlim',[-10,xlim2s(sample_const(i))],...
        'xtick',[xlim2s(sample_const(i))/2,xlim2s(sample_const(i))],'YDir','reverse',...
        'ticklength',ticklengths);
    set(gca,'ytick',[1-crit,0.1,0.5,1],...
        'yticklabel',cellstr(string([1-crit,0.1,0.5,1]*100)));%
    ylabel('100 - %F_{max}');
    xlabel('Time (ms)');
    title({'Sample exponential','analysis'});
end

saveFigureOutputs("figure2","figure2_J");
