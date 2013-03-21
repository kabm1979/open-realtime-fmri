function [cburt]=cburt_graphics_motion_globals(cburt,seriesnum,imgnum)

figure(12); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:Incoming data'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')
subplot(411);
plot(cburt.incoming.series(seriesnum).realignmentparms(:,1:3));
title('Translation');
ylabel('(mm)');
subplot(412);
plot(2*pi/360*cburt.incoming.series(seriesnum).realignmentparms(:,4:6));
title('Rotations');
ylabel('(degrees)');


% Calculate global if not done already
if ~isfield(cburt.incoming.series(seriesnum).timeseries,'global') || length(cburt.incoming.series(seriesnum).timeseries.global)<imgnum
    V=spm_vol(cburt_getimages(cburt,seriesnum,imgnum,'r'));
    Y=spm_read_vols(V);
    cburt.incoming.series(seriesnum).timeseries.global(imgnum)=mean(Y(:));
end;

% Plot global
subplot(413);
plot(cburt.incoming.series(seriesnum).timeseries.global);
title('Global signal');
ylabel('(arb units)');
xlabel('Scan');

% RMS diff
subplot(414);
if (imgnum>1)
    semilogy(cburt.incoming.series(seriesnum).rmsdiff(2:end));
    title('RMS diff');
    ylabel('(arb units)');
    xlabel('Scan');
end;