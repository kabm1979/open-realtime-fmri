function [cburt]=cburt_graphics_incoming(cburt,seriesnum,imgnum)

figure(12); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:Incoming data'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')
subplot(411);
if (isfield(cburt.options,'graphics_incoming') && strcmp(cburt.options.graphics_incoming,'imagesc'))
    
    % djm: try raw if filtered doesn't exist
    try imagesc(cburt.incoming.series(seriesnum).timeseries.filtered');
    catch imagesc(cburt.incoming.series(seriesnum).timeseries.raw');
    end
    
    colormap('gray');
else
    plot([1:size(cburt.incoming.series(seriesnum).timeseries.filtered,1)],cburt.incoming.series(seriesnum).timeseries.filtered);
end;
title('BOLD data');
ylabel('Signal');
%legend({cburt.rois.name},'Location','NorthWest');
subplot(412);
plot(cburt.incoming.series(seriesnum).realignmentparms(:,1:3));
title('Translation');
ylabel('(mm)');
subplot(413);
plot(2*pi/360*cburt.incoming.series(seriesnum).realignmentparms(:,4:6));
title('Rotations');
ylabel('(degrees)');
subplot(414);
plot(cburt.incoming.series(seriesnum).timeseries.global);
title('Global signal');
ylabel('(arb units)');
xlabel('Scan');
