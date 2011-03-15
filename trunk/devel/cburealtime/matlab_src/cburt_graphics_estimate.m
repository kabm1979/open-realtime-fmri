function [cburt]=cburt_graphics_estimate(cburt,seriesnum)

figure(14); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:Modelling'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')

subplot(511); plot(cburt.incoming.series(seriesnum).timeseries.filtered); 
title('BOLD data');

subplot(512); plot(cburt.incoming.series(seriesnum).model.Xtrim)
title('Current design matrix');

try
    if (cburt.options.graphics.estimate.showmeanbeta)
        mb=mean(cburt.incoming.series(seriesnum).model.betas,2);
        mb=mb(1:(end-1));
        subplot(513); bar(mb');
    else
        subplot(513); bar(cburt.incoming.series(seriesnum).model.betas',2);
    end;
catch
    subplot(513); bar(cburt.incoming.series(seriesnum).model.betas',2);
end;
title('Estimated betas')

subplot(514); plot(cburt.incoming.series(seriesnum).model.fit)
title('Fit');

subplot(515); plot(cburt.incoming.series(seriesnum).model.residuals)
title('Residuals');

drawnow;