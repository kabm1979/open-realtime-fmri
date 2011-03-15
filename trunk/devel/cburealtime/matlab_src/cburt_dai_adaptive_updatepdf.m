function [cburt]=cburt_dai_adaptive_updatepdf(cburt,seriesnum,imgnum)

dai=cburt.incoming.series(seriesnum).dai;
if (cburt.model.loadstimuli)
    % load up the stimuli that have actually happened 
    stimfn=cburt.model.stimlistfilename;
    stimlist=load(stimfn);
    lastrestart=find(stimlist(:,1)==0);
    stimlist=stimlist(lastrestart(end):end,:);
    cburt.model.series(seriesnum).actualstimuli=stimlist(:,2);
end;

% we're not interested in the mean, so leave off the last beta
B=cburt.incoming.series(seriesnum).model.betas*cburt.model.contrast;
whichX=cburt.incoming.series(seriesnum).model(end).whichX;
whichX=cburt.incoming.series(seriesnum).model.X.columnofinterest(whichX);
if (~any(whichX))
    B=[];
    whichX=[];
    stim=[];
else
    B=B(whichX);
    stim=cburt.model.series(seriesnum).actualstimuli(whichX);
end;

dai.Pst=dai.priorPst;

if (any(whichX))

    % Estimate noise in BOLD data
    sigma=norm(cburt.incoming.series(seriesnum).model.stdev_beta+cburt.model.psychologicalbetastdev);
    
    % Calculate posterior given data
    for i=1:length(B)
        [dai.tvals dai.svals]=meshgrid(dai.trange,dai.srange);
        % and update estimates of s & t
        L=likelihood(B(i),stim(i),dai.svals,dai.tvals,sigma);
        % calculate posterior
        dai.Pst=dai.Pst.*L;
        % Find ML estimate
        [tmp tind]=max(max(dai.Pst));
        [tmp sind]=max(max(dai.Pst'));
        MLs=dai.srange(sind);
        MLt=dai.trange(tind);
    end

    % normalise
    dai.Pst=dai.Pst/sum(dai.Pst(:));

    
end;

cburt=cburt_graphics_dai(cburt,seriesnum);

cburt.incoming.series(seriesnum).dai=dai;
