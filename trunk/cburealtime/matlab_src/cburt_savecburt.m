function [cburt]=cburt_savecburt(cburt,seriesnum)

save(fullfile(cburt.incoming.processeddata,'cburt.mat'),'cburt');
save(fullfile(cburt.incoming.processeddata,sprintf('cburt_series%02d.mat',seriesnum)),'cburt');