function [cburt]=cburt_dumpfigures(cburt,seriesnum)

print('-f12','-r600','-depsc',fullfile(cburt.incoming.processeddata,sprintf('series%d_incomingdata',seriesnum)));
print('-f14','-r600','-depsc',fullfile(cburt.incoming.processeddata,sprintf('series%d_modelling',seriesnum)));
print('-f15','-r600','-depsc',fullfile(cburt.incoming.processeddata,sprintf('series%d_dai',seriesnum)));
try
    print('-f17','-r600','-depsc',fullfile(cburt.incoming.processeddata,sprintf('series%d_betasbyregion',seriesnum)));
catch
end;