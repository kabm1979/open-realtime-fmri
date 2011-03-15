function [cburt]=cburt_finalsummary(subjlist)

summary.betas=[];
summary.stim=[];
summary.actualstim=[];
figure(18);
ns=length(subjlist);
w=4;

figind=1;
for k=1:length(subjlist)
    % Load up previous cburt path
    load(fullfile(subjlist{k},'cburt'))
    ind=0;
    for i=1:length(cburt.incoming.series)
        if (strfind(cburt.incoming.series(i).protocolname,'CBU_EPI'))
            ind=ind+1;
            whichX=cburt.incoming.series(i).model.whichX;
            whichX=cburt.incoming.series(i).model.X.columnofinterest(whichX);            
            B=cburt.incoming.series(i).model.betas(whichX,:)*cburt.model.contrast;
            summary.betas=[summary.betas;B];
            summary.actualstim=[summary.actualstim;cburt.model.series(i).actualstimuli];
            summary.stim=[summary.stim; cburt.model.series(i).stimuli];
            subplot(ns,w,figind);
            scatter(cburt.model.series(i).actualstimuli,B);
            figind=figind+1;
        end;
    end;
    
end;

figure(17);
subplot 411;
scatter(summary.actualstim, summary.betas);
subplot 412;
hist(summary.betas);
title(sprintf('Mean beta %f +/- %f\n',mean(summary.betas),std(summary.betas)));
subplot 413;
hist(summary.stim(:));
subplot 414;
hist(summary.actualstim(:));
