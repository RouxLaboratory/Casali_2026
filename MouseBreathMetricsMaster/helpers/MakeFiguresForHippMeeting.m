cd('C:\Users\gcasali\Desktop\TimeLockedCells\Piriform\sws\'); % Piriform
BrainRegion = 'PIR'; % PIR or HPC ;

fig_list = dir('*.fig');
n_figs= numel(fig_list);
for iFig = 1 : n_figs ;
close all;
uiopen([ fig_list(iFig).name],1);
Ts=EqualBinning([-500,500],10);
figure(1);
delete(subplot(6,2,[3:12]));
s1=subplot(6,2,1);yyaxis left;;
d1= [s1.Children(1).XData;s1.Children(1).YData]';
d2= [s1.Children(2).XData;s1.Children(2).YData]';
d3= [s1.Children(3).XData;s1.Children(3).YData]';;
figure(1);s2=subplot(6,2,2);yyaxis left; %SmoothedM = s2.Children.CData;
n_cycles =round(max(s2.YLim));
FigTitle = [ fig_list(iFig).name(1:end-4) '_New_Simplified_'];
%FigTitle( 1: strfind(FigTitle,'_Cell_'))
TitleName = FigTitle( 13: strfind(FigTitle,['_' BrainRegion '_'])-1)

figure(2);clf;
FaceAlphaValue = 0.9;
s =scatter([d1(:,1);d2(:,1);d3(:,1)],[d1(:,2);d2(:,2);d3(:,2)],'MarkerEdgeAlpha',FaceAlphaValue,'MarkerFaceAlpha',FaceAlphaValue, 'MarkerFaceColor',rgb('Black'),'MarkerEdgeColor',rgb('Black'),'SizeData',s1.Children(1).SizeData); % 'CData',[s1.Children(1).CData];
axis square;ylim([0,n_cycles]);
set(gca,'YTick',[],'XTick',[-500,0,500]);
xlabel('Time (ms)') ;
ylabel('Sorted cycles');
set(gca,'FontSize',30) ;

FaceAlphaValue = 1.0;
figure(3);clf;hold on ;
s =scatter([d1(:,1)],[d1(:,2);],'MarkerEdgeAlpha',FaceAlphaValue,'MarkerFaceAlpha',FaceAlphaValue, 'MarkerFaceColor',s1.Children(1).MarkerFaceColor,'MarkerEdgeColor',s1.Children(1).MarkerEdgeColor,'SizeData',s1.Children(1).SizeData) ;%'CData',[s1.Children(1).CData]
s =scatter([d2(:,1)],[d2(:,2);],'MarkerEdgeAlpha',FaceAlphaValue,'MarkerFaceAlpha',FaceAlphaValue,'MarkerEdgeColor',s1.Children(2).MarkerEdgeColor,'MarkerEdgeColor',s1.Children(2).MarkerEdgeColor,'SizeData',s1.Children(2).SizeData) ;%'CData',[s1.Children(2).CData]
s =scatter([d3(:,1)],[d3(:,2);],'MarkerEdgeAlpha',FaceAlphaValue,'MarkerFaceAlpha',FaceAlphaValue,'MarkerEdgeColor',s1.Children(3).MarkerEdgeColor,'MarkerEdgeColor',s1.Children(3).MarkerEdgeColor,'SizeData',s1.Children(3).SizeData) ;%'CData',[s1.Children(3).CData]
axis square;ylim([0,n_cycles]);
set(gca,'YTick',[],'XTick',[-500,0,500]);
xlabel('Time (ms)') ;
ylabel('Sorted cycles');
set(gca,'FontSize',30) ;

figure(4);clf;
SmoothingWindow = [1000,3 ] ;
f = fspecial( 'gauss',[SmoothingWindow(1)*2,SmoothingWindow(2)],[SmoothingWindow(1) ]);
m = DensityMap([d1(:,1);d2(:,1);d3(:,1)],[d1(:,2);d2(:,2);d3(:,2)], [-500,0.0;500,n_cycles],[10,1],0 ); 
SmoothedM = imfilter(m,f,'replicate');
imagesc(Ts, [], SmoothedM);caxis([prctile(SmoothedM(:),[2,97])]);set(gca,'YDir','normal');
set(gca,'YTick',[],'XTick',[-500,0,500]); 
ylabel('Sorted cycles');set(gca,'YDir','normal');
yyaxis right
plot(Ts, nanmean(SmoothedM),'Color','k','LineWidth',3); 
ylabel('F.R. (Hz)');
axis square ;
set(gca,'YTick',[FindExtremesOfArray( get(gca,'YLim'))]);
xlabel('Time (ms)') ;
set(gca,'FontSize',30) ;
title('');axis square ; 

figure(5);clf;
Smoothedz = imfilter(zscore(SmoothedM,[],2),f,'replicate');
imagesc(Ts, [], Smoothedz);caxis([-1,1]*3);
[p,i]=max(nanmean(Smoothedz,1));
set(gca,'YTick',[],'XTick',sort([Ts(i), -500,0,500])); 
ylabel('Sorted cycles');set(gca,'YDir','normal');
yyaxis right
plot(Ts, nanmean(Smoothedz),'Color','k','LineWidth',3); 

axis square ;
ylim([-1,1]*ceil(abs(max(ylim()))));
ylabel('');;set(gca,'YTick',[]);
%ylabel('F.R. (z-score)');set(gca,'YTick',[get(gca,'YLim')]);
ZScoreYlim = get(gca,'YLim');
xlabel('Time (ms)') ;
set(gca,'FontSize',30) ;
title('');axis square



figure(2);set(gca,'XTick',sort([Ts(i), -500,0,500])); 
yyaxis right
%p=plot(Ts, nanmean(m),'Color','r','LineWidth',3); 
%ylim([0, max(get(gca,'YLim'))]);
p=plot(Ts, nanmean(Smoothedz),'Color','r','LineWidth',3); 
ylabel('');
axis square ;
ylim(ZScoreYlim);
set(gca,'YTick',[],'Visible','on','YColor','k');
set(p,'Visible','off');
hold on 
line([0,0],ylim(),'Color','r','LineWidth',2,'LineStyle','--')
title(TitleName);
SAVE_Figure(figure(2),[FigTitle 'RawRater'],'png','portrait');%close(figure(2));

figure(3);set(gca,'XTick',sort([Ts(i), -500,0,500])); 
yyaxis right
plot(Ts, nanmean(Smoothedz),'Color','k','LineWidth',3); 
axis square ;
ylim(ZScoreYlim);
%ylabel('F.R. (z-score)');set(gca,'YTick',[get(gca,'YLim')],'YColor','k');
ylabel('');set(gca,'YTick',[],'YColor','k');
line([0,0],ylim(),'Color','k','LineWidth',2,'LineStyle','--');
title(TitleName);
SAVE_Figure(figure(3),[FigTitle 'ColouredRater'],'png','portrait');%close(figure(3));

figure(4);set(gca,'XTick',sort([Ts(i), -500,0,500])); 
line([0,0],ylim(),'Color','k','LineWidth',2,'LineStyle','--');
title(TitleName);
SAVE_Figure(figure(4),[FigTitle 'RateMap'],'png','portrait');%close(figure(4));

figure(5);set(gca,'XTick',sort([Ts(i), -500,0,500])); 
line([0,0],ylim(),'Color','k','LineWidth',2,'LineStyle','--');
title(TitleName);
SAVE_Figure(figure(5),[FigTitle 'RateZScore'],'png','portrait');%close(figure(5));
%SAVE_Figure(figure(5),[FigTitle 'RateZScore'],'pdf','portrait');%close(figure(5));

close all;

end
cd('C:\Users\gcasali\Desktop\TimeLockedCells');