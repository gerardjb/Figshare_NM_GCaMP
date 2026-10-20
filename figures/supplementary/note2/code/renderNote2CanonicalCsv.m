function figures = renderNote2CanonicalCsv(outputDirectory)
% Render the fixed nine families and their saved example curves.
% No RNG, kmeans, model evaluation, or fitting occurs on this path.
% Optional outputDirectory is solely for isolated adapter validation.
base=fileparts(mfilename('fullpath'));d=fullfile(base,'..','source_data');
fmt=jsondecode(fileread(fullfile(base,'note2_display_format.json')));
T=readtable(fullfile(d,'A_displayed_heatmap.csv'),'TextType','string','VariableNamingRule','preserve');
assert(height(T)==180 && isequal(T.display_row,(1:180)'), ...
    'Note2:heatmapRows','Expected the 180 published-display rows in order.');
assert(isequal(T.display_cluster,repelem((1:9)',20)), ...
    'Note2:heatmapClusters','Expected all nine published-display 20-row families.');
Z=T{:,4:end};assert(isequal(size(Z),[180,18]),'Note2:heatmapShape','Expected 18 displayed Z-score columns.');
figures=gobjects(1,4);
figures(1)=figure('Units','inches','Position',[1,1,7.5,3.5], ...
    'PaperUnits','inches','PaperSize',[7.5,3.5],'PaperPosition',[0,0,7.5,3.5]);
ax=axes(figures(1));imagesc(ax,Z,[-1,1]);colormap(ax,fmt.heatmap_colormap);
c=colorbar(ax);ylabel(c,'Z-score','FontName','arial','FontSize',10);
labels={'K-aN','k-offN','H-N','K-aC','k-offC','H-C', ...
    'k-onPN','k-offPN','k-onPC','k-offPC','k-onPN2','k-offPN2', ...
    'k-onPC2','k-offPC2','SF','PP','1-2-10','Pois'};
set(ax,'XTick',1:18,'XTickLabel',labels,'YTick',[], ...
    'FontName','arial','FontSize',10);hold(ax,'on');
for cluster=9:-1:1
    y=(cluster-1)*20+1.5;lw=0.8;if cluster==1;lw=1.8;end
    rectangle(ax,'Position',[0.5,y,14,19],'EdgeColor','k','LineWidth',lw);
    label=num2str(cluster);if cluster==1;label='Cluster 1';end
    weight='normal';if ismember(cluster,[1,5,9]);weight='bold';end
    text(ax,0,y,label,'HorizontalAlignment','right','VerticalAlignment','top', ...
        'FontName','arial','FontSize',10,'FontWeight',weight);
end
title(ax,'Parameter sets sorted by cluster, residuals','FontName','arial','FontSize',12);

panels={'B','C','D'};clusters=[1,5,9];
for p=1:3
    panel=panels{p};figures(p+1)=figure('Units','inches', ...
        'Position',[1,1,8,2.6],'PaperUnits','inches','PaperSize',[8,2.6], ...
        'PaperPosition',[0,0,8,2.6]);
    SF=readtable(fullfile(d,[panel,'_stopped_flow.csv']),'TextType','string');
    PP=readtable(fullfile(d,[panel,'_paired_pulse.csv']),'TextType','string');
    PO=readtable(fullfile(d,[panel,'_poisson.csv']),'TextType','string');
    events=readtable(fullfile(d,[panel,'_stimulus_times.csv']),'TextType','string');
    axesHandles=gobjects(1,6);
    for a=1:6
        style=fmt.examples(p).axes(a);ax=axes(figures(p+1),'Position',style.position);axesHandles(a)=ax;hold(ax,'on');
        switch a
            case {5,6}
                kinetic="off";if a==6;kinetic="on";end
                conditions=unique(SF.calcium_condition_nM(SF.kinetics==kinetic),'stable');
                curve=0;
                for trace=["observed","model"]
                    for condition=reshape(conditions,1,[])
                        select=SF.kinetics==kinetic & SF.trace_type==trace & SF.calcium_condition_nM==condition;
                        curve=curve+1;drawCurve(ax,SF.time_ms(select),SF.normalized_fluorescence(select),style.curve_styles(curve));
                    end
                end
                set(ax,'XTick',[0,200,400],'XTickLabelRotation',0,'YTick',[0,0.5,1],'TickDir','out','LineWidth',0.6);
                if a==6;set(ax,'XTickLabel',[]);end
            case {3,4}
                condition="paired pulse (10 ms interval)";if a==4;condition="single pulse";end
                trace=["observed","model"];
                for k=1:2
                    select=PP.condition==condition & PP.trace_type==trace(k);
                    drawCurve(ax,PP.time_from_last_stimulus_ms(select),PP.fluorescence_DeltaF_over_F(select),style.curve_styles(k));
                end
                select=events.experiment=="paired_pulse" & events.condition==condition;
                addEvents(ax,events.stimulus_time_ms(select),style.ylim);axis(ax,'off');
            otherwise
                % Zoom is the same measured/model Poisson data, with a narrower view.
                trace=["observed","model"];
                for k=1:2
                    select=PO.trace_type==trace(k);
                    drawCurve(ax,PO.time_from_first_stimulus_ms(select),PO.fluorescence_DeltaF_over_F(select),style.curve_styles(k));
                end
                select=events.experiment=="poisson";
                addEvents(ax,events.stimulus_time_ms(select),style.ylim);axis(ax,'off');
        end
        for k=1:(numel(style.decorations)*(a>4))
            h=style.decorations(k);plot(ax,h.x,h.y,'LineStyle',h.style,'LineWidth',h.width,'Color',h.color);
        end
        set(ax,'XLim',style.xlim,'YLim',style.ylim,'FontName','arial','FontSize',10);
        title(ax,style.title,'FontName','arial','FontSize',10);
        xlabel(ax,style.xlabel);ylabel(ax,style.ylabel);
    end
    % Scale-bar text is display formatting; values come from the existing artwork.
    makeTSscaleBar(axesHandles(4),'xFrac',0.68,'xval',100,'xtext','100 ms', ...
        'yFrac',0.90,'yVal',round(diff(fmt.examples(p).axes(4).ylim)/3,1), ...
        'yText',[num2str(round(diff(fmt.examples(p).axes(4).ylim)/3,1)),' ',char(916),'F/F'], ...
        'xPush',0.03,'lefty',0,'upsidedown',true,'linWidth',0.75,'fontSize',8);
    makeTSscaleBar(axesHandles(2),'xFrac',7/8,'yFrac',1/2,'yVal',0,'yText','', ...
        'xval',200,'xtext','200 ms','lefty',0,'upsidedown',true,'linWidth',0.75,'fontSize',8);
    makeTSscaleBar(axesHandles(1),'xFrac',6/7,'yFrac',0.88,'yVal',0.4,'yText',['0.4 ',char(916),'F/F'], ...
        'xval',100,'xtext','100 ms','lefty',0,'upsidedown',true,'linWidth',0.75,'fontSize',8);
    connectZoom(figures(p+1),axesHandles(2),axesHandles(1));
    label=['Cluster ',num2str(clusters(p))];if p==1;label=[label,' (Biophysical model)'];end
    titleColor=[0,0,0];if p==1;titleColor=fmt.examples(p).axes(1).curve_styles(2).color;end
    annotation(figures(p+1),'textbox',[0,0.86,1,0.13],'String',label,'Color',titleColor, ...
        'EdgeColor','none','HorizontalAlignment','center','FontName','arial', ...
        'FontSize',12,'FontWeight','bold');
end
if nargin>0 && ~isempty(outputDirectory)
    if ~isfolder(outputDirectory);mkdir(outputDirectory);end
    for k=1:4
        stem=fullfile(outputDirectory,sprintf('suppfigure5_%02d',k));
        exportgraphics(figures(k),[stem,'.pdf'],'ContentType','vector','BackgroundColor','white');
        exportgraphics(figures(k),[stem,'.png'],'Resolution',150,'BackgroundColor','white');
        savefig(figures(k),[stem,'.fig']);
    end
else
    saveFigureOutputs('supp_figure5','suppfigure5',figures);
end
end

function connectZoom(fig,p,z)
% Original reviewed zoom bracket, in normalized figure coordinates.
xp=p.Position(1)+([100,500]-p.XLim(1))/diff(p.XLim)*p.Position(3);
xz=z.Position(1)+([100,500]-z.XLim(1))/diff(z.XLim)*z.Position(3);
yp=p.Position(2)+(-0.05-p.YLim(1))/diff(p.YLim)*p.Position(4);
yz=z.Position(2)+(-0.05-z.YLim(1))/diff(z.YLim)*z.Position(4);
padY=0.01;padX=0.002;drop1=0.03;drop2=0.06;
annotation(fig,'line',xp,[yp-drop1,yp-drop1],'Color','k','LineWidth',3);
annotation(fig,'line',[xp(1)+padX,xp(1)+padX],[yp-padY,yp-drop1],'Color','k','LineWidth',3);
annotation(fig,'line',[xp(2)-padX,xp(2)-padX],[yp-drop1,yp-padY],'Color','k','LineWidth',3);
annotation(fig,'line',[mean(xp),mean(xp)],[yp-drop1-padY,yp-drop1-drop2],'Color','k','LineWidth',1.5,'LineStyle','--');
annotation(fig,'line',[mean(xp),mean(xz)],[yp-drop1-drop2,yz-drop1-drop2],'Color','k','LineWidth',1.5,'LineStyle','--');
annotation(fig,'line',[mean(xz),mean(xz)],[yz-drop1-drop2,yp-drop1-padY],'Color','k','LineWidth',1.5,'LineStyle','--');
annotation(fig,'line',xz,[yz-drop1,yz-drop1],'Color','k','LineWidth',3);
annotation(fig,'line',[xz(1)+padX,xz(1)+padX],[yz-padY,yz-drop1],'Color','k','LineWidth',3);
annotation(fig,'line',[xz(2)-padX,xz(2)-padX],[yz-drop1,yz-padY],'Color','k','LineWidth',3);
end

function drawCurve(ax,x,y,style)
assert(numel(x)>0 && numel(x)==numel(y),'Note2:emptyCurve','Missing or invalid canonical curve.');
plot(ax,x,y,'LineStyle',style.style,'LineWidth',style.width,'Color',style.color,'Tag','canonicalTrace');
end

function addEvents(ax,times,limits)
for time=reshape(times,1,[])
    plot(ax,[time,time],limits,'k:','LineWidth',0.4);
end
end
