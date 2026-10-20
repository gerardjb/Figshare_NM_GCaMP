function figure2CsvJ(sourceDataDir)
% Plot the published masks/components; use saved coefficient text metadata.
close all
meta=readtable(fullfile(sourceDataDir,'J_saved_annotation_metadata.csv'),'TextType','string');
names=["GCaMP6f","jGCaMP8f"];kinds=["observation","fast_component","slow_component"];
for i=1:2
    T=readtable(fullfile(sourceDataDir,"J_"+names(i)+"_plotted_curves.csv"),'TextType','string');
    m=meta(meta.indicator==names(i),:);
    f=figure;hold on;
    set(f,'PaperUnits','inches','PaperSize',[1.4,3],'PaperPosition',[0,0,1.4,3], ...
        'Units','inches','Position',[2,2,1.4,3]);
    colors={pickGCaMPcolorsMS(names(i)),[.1,.1,.1,.9],[.8,.8,.8,.9]};
    for j=1:3
        q=T(T.curve==kinds(j),:);width=1;if j>1,width=2;end
        plot(q.time_ms,q.one_minus_normalized_fluorescence,'Color',colors{j},'LineWidth',width);
    end
    fastString=['\tau_{fast} = ',sprintf('%.0f ms',m.tau_fast_ms)];
    if names(i)=="jGCaMP8f",fastString=['\tau_{fast} = ',sprintf('%.1f ms',m.tau_fast_ms)];end
    text(m.text_x_ms,m.fast_text_y,{fastString,sprintf('proportion = %.2g',m.fast_fraction)},'HorizontalAlignment','left');
    text(m.text_x_ms,m.slow_text_y,['\tau_{slow} = ',sprintf('%.0f ms',m.tau_slow_ms)], ...
        'Color',[.8,.8,.8,.9],'HorizontalAlignment','left');
    xmax=1000;if i==2,xmax=500;end
    set(gca,'YScale','log','YDir','reverse','TickDir','out','LineWidth',1, ...
        'YLim',[.03,1],'XLim',[-10,xmax],'XTick',[xmax/2,xmax], ...
        'YTick',[.05,.1,.5,1],'YTickLabel',{'5','10','50','100'},'TickLength',[.003,.03]);
    ylabel('100 - %F_{max}');xlabel('Time (ms)');title({'Sample exponential','analysis'});
end
saveFigureOutputs("figure2","figure2_J");
end
