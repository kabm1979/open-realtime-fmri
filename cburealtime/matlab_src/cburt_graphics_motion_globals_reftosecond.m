function [cburt]=cburt_graphics_motion_globals_reftosecond(cburt,seriesnum,imgnum)

if (imgnum>2)
    figure(12); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:Incoming data'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')
    rps=cburt.incoming.series(seriesnum).realignmentparms;
    rps=rps(2:end,:)-repmat(rps(2,:),[size(rps,1)-1 1]);
    subplot(411);
    plot(rps(:,1:3));
    title('Translation');
    ylabel('(mm)');
    subplot(412);
    plot(180/pi*rps(:,4:6));
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
    plot(cburt.incoming.series(seriesnum).timeseries.global(2:end)-cburt.incoming.series(seriesnum).timeseries.global(1));
    title('Global signal');
    ylabel('(arb units)');
    xlabel('Scan');
    
    % RMS diff
    subplot(414);
    
    semilogy(cburt.incoming.series(seriesnum).rmsdiff(3:end));
    title('RMS diff');
    ylabel('(arb units)');
    xlabel('Scan');
    
end;