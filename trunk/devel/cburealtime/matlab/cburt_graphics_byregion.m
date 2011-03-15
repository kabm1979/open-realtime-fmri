function [cburt]=cburt_graphics_byregion(cburt,seriesnum,imgnum)

figure(17); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:By region'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')

prefix='';
B=cburt.incoming.series(seriesnum).model.betas(cburt.incoming.series(seriesnum).model.X.columnofinterest(cburt.incoming.series(seriesnum).model.whichX),:);
if (size(B,1)>0)
    barh(B');

    title('Estimated betas')

    nmes=[];
    for i=1:length(cburt.rois)
        nmes{i}=cburt.rois(i).name;
    end;
    set(gca,'YTick',[1:length(cburt.rois)]);
    set(gca,'Yticklabel',nmes);
    drawnow;
else
    clf;
end;