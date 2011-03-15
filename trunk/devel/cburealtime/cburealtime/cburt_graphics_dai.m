function [cburt]=cburt_graphics_dai(cburt,seriesnum)

dai=cburt.incoming.series(seriesnum).dai;
B=cburt.incoming.series(seriesnum).model.betas*cburt.model.contrast;
whichX=cburt.incoming.series(seriesnum).model.whichX;
whichX=cburt.incoming.series(seriesnum).model.X.columnofinterest(whichX);

if (any(whichX))

    B=B(whichX);
    stim=cburt.model.series(seriesnum).actualstimuli(whichX);

    figure (15); set(gcf,'toolbar','none'); set(gcf,'name','cbuRT:Bayesian model for Dynamically Adaptive Imaging'); set(gcf,'menubar','none'); set(gcf,'NumberTitle','off')

    subplot(3,2,3);
    scatter(stim,B,'+');
    xlim([min(dai.xrange) max(dai.xrange)])
    title(sprintf('Actual data [%d points]',length(B)));
    xlabel('Stimulus strength')
    ylabel('Predicted BOLD response');

    % plot current s t estimates
    subplot(3,2,1);
    imagesc(dai.trange,dai.srange,dai.Pst,[0 max(dai.Pst(:))]);
    axis xy;
    colorbar;
    xlabel('threshold (t)');
    ylabel('signal change (s)');
    title('Probability distribution function');

    if (isfield(dai,'Bmean'))
        subplot(3,2,2);
        errorbar(dai.xrange',dai.Bmean,dai.Bstd);
        axis tight
        title('Predictions given current estimates of s and t');    [t_maxacrosss tind]=max(max(dai.Pst,[],1),[],2);
    [s_maxacrosst sind]=max(max(dai.Pst,[],2),[],1);
    tpdf=log(dai.Pst(sind,:));
    [cburt tdesc dai.t.ML dai.t.lb dai.t.ub]=cburt_dai_findML(cburt,dai.trange,tpdf);
    spdf=log(dai.Pst(:,tind));
    [cburt sdesc dai.s.ML dai.s.lb dai.s.ub]=cburt_dai_findML(cburt,dai.srange,spdf);

        xlabel('Stimulus strength')
        ylabel('Predicted BOLD response');
    end;

    [t_maxacrosss tind]=max(max(dai.Pst,[],1),[],2);
    [s_maxacrosst sind]=max(max(dai.Pst,[],2),[],1);
    tpdf=log(dai.Pst(sind,:));
    [cburt tdesc dai.t.ML dai.t.lb dai.t.ub]=cburt_dai_findML(cburt,dai.trange,tpdf);
    spdf=log(dai.Pst(:,tind));
    [cburt sdesc dai.s.ML dai.s.lb dai.s.ub]=cburt_dai_findML(cburt,dai.srange,spdf);


    subplot(325);
    plot(dai.srange,spdf);
    xlabel('Signal change (%)');
    ylabel('Log likelihood');
    title(sdesc);
    subplot(326);
    plot(dai.trange,tpdf);
    xlabel('Threshold');
    ylabel('Log likelihood');
    title(tdesc);
    drawnow;

    cburt.incoming.series(seriesnum).dai=dai;

end;